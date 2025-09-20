/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:html' as html;
import 'dart:js' as js;

import '../models/rtvi_message.dart';
import '../models/transport_state.dart';
import '../client/pipecat_client_options.dart';
import 'twilio_serializer.dart';

class WebSocketTransportOptions {
  final String wsUrl;
  final WebSocketSerializer? serializer;
  final int recorderSampleRate;
  final int playerSampleRate;

  const WebSocketTransportOptions({
    required this.wsUrl,
    this.serializer,
    this.recorderSampleRate = 16000,
    this.playerSampleRate = 24000,
  });
}

class WebSocketTransport {
  WebSocketChannel? _channel;
  TransportState _state = TransportState.disconnected;

  final WebSocketTransportOptions options;
  late final WebSocketSerializer _serializer;

  // Simple audio components (copying web client exactly)
  html.AudioElement? _audioElement;
  html.MediaStream? _localStream;
  js.JsObject? _audioContext;
  js.JsObject? _gainNode;

  // Microphone recording components
  js.JsObject? _recorderContext;
  js.JsObject? _micSource;
  js.JsObject? _scriptProcessor;

  bool _isMicEnabled = false;
  final List<Uint8List> _audioQueue = [];

  // Audio streaming for continuous playback
  final List<double> _audioBuffer = [];
  Timer? _audioTimer;

  // Callbacks
  PipecatClientOptions? _clientOptions;
  Function(RTVIMessage)? _onMessage;

  WebSocketTransport(this.options) {
    _serializer = options.serializer ?? TwilioSerializer();
  }

  TransportState get state => _state;
  bool get isMicEnabled => _isMicEnabled;

  void initialize(
      PipecatClientOptions clientOptions,
      Function(RTVIMessage) messageHandler,
      ) {
    _clientOptions = clientOptions;
    _onMessage = messageHandler;
    _state = TransportState.disconnected;
  }

  Future<void> initDevices() async {
    _state = TransportState.initializing;

    try {
      if (kIsWeb) {
        // Create audio element for playback (exactly like web client)
        _audioElement = html.AudioElement();
        _audioElement!.autoplay = true;
        html.document.body!.append(_audioElement!);

        // Initialize AudioContext for PCM audio playback
        _audioContext = js.JsObject(js.context['AudioContext']);
        _gainNode = _audioContext!.callMethod('createGain');
        _gainNode!.callMethod('connect', [_audioContext!['destination']]);

        // Start continuous audio playback
        _startContinuousPlayback();

        // Get user media for microphone (exactly like web client)
        _localStream = await html.window.navigator.mediaDevices!.getUserMedia({
          'audio': {
            'sampleRate': options.recorderSampleRate,
            'channelCount': 1,
            'echoCancellation': true,
            'noiseSuppression': true,
          },
          'video': false,
        });

        // Setup microphone recording
        _setupMicrophoneRecording();
      } else {
        throw Exception('Mobile not implemented yet');
      }

      _state = TransportState.initialized;
    } catch (e) {
      _state = TransportState.error;
      _clientOptions?.callbacks?.onError(RTVIMessage(
        type: RTVIMessageType.error,
        data: {'message': 'Failed to initialize devices: $e'},
      ));
      rethrow;
    }
  }

  Future<void> connect([Map<String, dynamic>? connectParams]) async {
    if (_state == TransportState.connected || _state == TransportState.ready) {
      return;
    }

    _state = TransportState.connecting;

    try {
      final uri = Uri.parse(options.wsUrl);
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketClose,
      );

      _state = TransportState.connected;
      _clientOptions?.callbacks?.onConnected();
      _clientOptions?.callbacks?.onTransportStateChanged(_state);

      if (_clientOptions?.enableMic == true) {
        await enableMic(true);
      }

    } catch (e) {
      _state = TransportState.error;
      _clientOptions?.callbacks?.onError(RTVIMessage(
        type: RTVIMessageType.error,
        data: {'message': 'Failed to connect: $e'},
      ));
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _state = TransportState.disconnecting;

    await enableMic(false);

    if (kIsWeb) {
      _stopMicrophoneRecording();
      _localStream?.getTracks().forEach((track) => track.stop());
      _audioElement?.remove();
      _audioElement = null;
      _localStream = null;
      _audioTimer?.cancel();
      _audioTimer = null;
      _audioBuffer.clear();
      _recorderContext = null;
      _micSource = null;
    }

    await _channel?.sink.close();
    _channel = null;

    _state = TransportState.disconnected;
    _clientOptions?.callbacks?.onDisconnected();
    _clientOptions?.callbacks?.onTransportStateChanged(_state);
  }

  Future<void> enableMic(bool enable) async {
    if (enable == _isMicEnabled) return;

    _isMicEnabled = enable;

    if (kIsWeb && _localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      for (final track in audioTracks) {
        track.enabled = enable;
      }

      if (enable) {
        _startMicrophoneRecording();
      } else {
        _stopMicrophoneRecording();
      }

      print('Microphone ${enable ? 'enabled' : 'disabled'}');
    }
  }

  void _setupMicrophoneRecording() {
    if (!kIsWeb || _localStream == null) return;

    try {
      // Create AudioContext for recording
      _recorderContext = js.JsObject(
        js.context['AudioContext'],
        [js.JsObject.jsify({'sampleRate': options.recorderSampleRate})],
      );

      // ✅ Use the full MediaStream instead of creating a new one
      _micSource = _recorderContext!.callMethod(
        'createMediaStreamSource',
        [_localStream],
      );

      print('Microphone recording setup complete');
    } catch (e) {
      print('Failed to setup microphone recording: $e');
    }
  }

  void _startMicrophoneRecording() {
    if (!kIsWeb || _recorderContext == null || _micSource == null) return;

    try {
      const bufferSize = 4096;
      _scriptProcessor = _recorderContext!.callMethod('createScriptProcessor', [bufferSize, 1, 1]);

      _scriptProcessor!['onaudioprocess'] = js.allowInterop((js.JsObject event) {
        final inputBuffer = event['inputBuffer'];
        final channelData = inputBuffer.callMethod('getChannelData', [0]);

        final samples = <int>[];
        final length = inputBuffer['length'];

        for (int i = 0; i < length; i++) {
          final sample = channelData[i] as double;
          final pcm16Sample = (sample * 32767).round().clamp(-32768, 32767);
          samples.add(pcm16Sample & 0xFF);
          samples.add((pcm16Sample >> 8) & 0xFF);
        }

        if (samples.isNotEmpty && _state == TransportState.ready) {
          final audioData = Uint8List.fromList(samples);
          _sendAudioData(audioData);
        } else if (samples.isNotEmpty && _state != TransportState.ready) {
          final audioData = Uint8List.fromList(samples);
          _audioQueue.add(audioData);
        }
      });

      _micSource!.callMethod('connect', [_scriptProcessor]);
      _scriptProcessor!.callMethod('connect', [_recorderContext!['destination']]);

      print('Microphone recording started');
    } catch (e) {
      print('Failed to start microphone recording: $e');
    }
  }

  void _stopMicrophoneRecording() {
    if (!kIsWeb) return;

    try {
      _scriptProcessor?.callMethod('disconnect');
      _scriptProcessor = null;
      print('Microphone recording stopped');
    } catch (e) {
      print('Error stopping microphone recording: $e');
    }
  }

  void _sendAudioData(Uint8List audioData) {
    if (_channel != null) {
      final serialized = _serializer.serializeAudio(
        audioData,
        options.recorderSampleRate,
        1,
      );
      _channel?.sink.add(serialized);
    }
  }

  void _flushAudioQueue() {
    while (_audioQueue.isNotEmpty) {
      final data = _audioQueue.removeAt(0);
      _sendAudioData(data);
    }
  }

  void sendReadyMessage() {
    _state = TransportState.ready;
    _clientOptions?.callbacks?.onTransportStateChanged(_state);
    sendMessage(RTVIMessage.clientReady());
    _flushAudioQueue();
  }

  void sendMessage(RTVIMessage message) {
    if (_channel != null) {
      final serialized = _serializer.serializeMessage(message);
      _channel?.sink.add(serialized);
    }
  }

  void sendRawMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      final serialized = _serializer.serialize(message);
      _channel?.sink.add(serialized);
    }
  }

  void _handleWebSocketMessage(dynamic data) async {
    try {
      final parsed = await _serializer.deserialize(data);

      if (parsed['type'] == 'audio') {
        await _playAudio(parsed['audio'] as Uint8List);
      } else if (parsed['type'] == 'message') {
        final message = parsed['message'] as RTVIMessage;
        _onMessage?.call(message);
      }
    } catch (e) {
      _clientOptions?.callbacks?.onError(RTVIMessage(
        type: RTVIMessageType.error,
        data: {'message': 'Failed to handle message: $e'},
      ));
    }
  }

  void setupAudioTrack(html.MediaStreamTrack track) {
    print('Setting up audio track');
    if (kIsWeb && _audioElement != null) {
      if (_audioElement!.srcObject != null) {
        final stream = _audioElement!.srcObject as html.MediaStream;
        final tracks = stream.getAudioTracks();
        if (tracks.isNotEmpty && tracks.first.id == track.id) return;
      }

      _audioElement!.srcObject = html.MediaStream([track]);
      _audioElement!.volume = 1.0;
      _audioElement!.muted = false;
      _audioElement!.play().catchError((e) {
        print('Audio play failed: $e');
      });
      print('Audio track setup complete');
    }
  }

  Future<void> _playAudio(Uint8List audioData) async {
    try {
      if (kIsWeb) {
        final samples = _bytesToFloatSamples(audioData);
        _audioBuffer.addAll(samples);
      } else {
        print('Received audio data: ${audioData.length} bytes');
        print('Audio playback not implemented for non-web platforms');
      }
    } catch (e) {
      print('Audio playback error: $e');
    }
  }

  List<double> _bytesToFloatSamples(Uint8List bytes) {
    final samples = <double>[];
    for (int i = 0; i < bytes.length; i += 2) {
      if (i + 1 < bytes.length) {
        final sample = bytes[i] | (bytes[i + 1] << 8);
        final signed = sample > 32767 ? sample - 65536 : sample;
        samples.add(signed / 32768.0);
      }
    }
    return samples;
  }

  void _startContinuousPlayback() {
    const chunkSize = 1024;
    const intervalMs = (chunkSize * 1000) ~/ 8000;

    _audioTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (_audioBuffer.length >= chunkSize) {
        _playAudioChunk(chunkSize);
      }
    });
  }

  void _playAudioChunk(int chunkSize) {
    try {
      final samplesToPlay = _audioBuffer.take(chunkSize).toList();
      _audioBuffer.removeRange(0, samplesToPlay.length);

      if (samplesToPlay.isEmpty) return;

      final buffer = _audioContext!.callMethod('createBuffer', [1, samplesToPlay.length, options.playerSampleRate]);
      final channelData = buffer.callMethod('getChannelData', [0]);

      for (int i = 0; i < samplesToPlay.length; i++) {
        channelData[i] = samplesToPlay[i];
      }

      final source = _audioContext!.callMethod('createBufferSource');
      source['buffer'] = buffer;
      source.callMethod('connect', [_gainNode]);
      source.callMethod('start');

    } catch (e) {
      print('Audio chunk playback error: $e');
    }
  }

  void _handleWebSocketError(dynamic error) {
    _clientOptions?.callbacks?.onError(RTVIMessage(
      type: RTVIMessageType.error,
      data: {'message': 'WebSocket error: $error'},
    ));
  }

  void _handleWebSocketClose() {
    _state = TransportState.disconnected;
    _clientOptions?.callbacks?.onDisconnected();
    _clientOptions?.callbacks?.onTransportStateChanged(_state);
  }

  Future<void> dispose() async {
    await disconnect();
  }
}
