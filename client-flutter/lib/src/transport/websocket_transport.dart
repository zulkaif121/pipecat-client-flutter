/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

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
    this.recorderSampleRate = 8000,  // CRITICAL: Match TypeScript example
    this.playerSampleRate = 8000,    // CRITICAL: Match TypeScript example
  });
}

class WebSocketTransport {
  WebSocketChannel? _channel;
  TransportState _state = TransportState.disconnected;

  final WebSocketTransportOptions options;
  late final WebSocketSerializer _serializer;

  // Flutter packages for audio handling
  AudioRecorder? _audioRecorder;
  FlutterSoundPlayer? _audioPlayer;
  
  bool _isMicEnabled = false;
  final List<Uint8List> _audioQueue = [];
  StreamSubscription<Uint8List>? _recordingSubscription;
  
  // Audio queue protection
  static const int maxAudioQueueSize = 100; // Prevent memory overflow

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
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (micPermission != PermissionStatus.granted) {
        throw Exception('Microphone permission not granted');
      }

      // Initialize audio recorder
      _audioRecorder = AudioRecorder();
      
      // Initialize audio player for PCM stream playback
      _audioPlayer = FlutterSoundPlayer();
      await _audioPlayer!.openPlayer();
      
      // Start player session for feeding audio stream
      await _audioPlayer!.startPlayerFromStream(
        codec: Codec.pcm16,
        sampleRate: options.playerSampleRate,
        numChannels: 1,
        bufferSize: 4096,
        interleaved: true,
      );

      print('Audio devices initialized successfully');
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

    // Stop recording and close audio components
    await _recordingSubscription?.cancel();
    _recordingSubscription = null;
    
    // Clear audio queue to free memory
    _audioQueue.clear();
    
    // Close audio player safely
    try {
      await _audioPlayer?.closePlayer();
    } catch (e) {
      print('Warning: Error closing audio player: $e');
    }
    _audioPlayer = null;
    _audioRecorder = null;

    // Close WebSocket safely
    try {
      await _channel?.sink.close();
    } catch (e) {
      print('Warning: Error closing WebSocket: $e');
    }
    _channel = null;

    _state = TransportState.disconnected;
    _clientOptions?.callbacks?.onDisconnected();
    _clientOptions?.callbacks?.onTransportStateChanged(_state);
  }

  Future<void> enableMic(bool enable) async {
    if (enable == _isMicEnabled) return;

    _isMicEnabled = enable;

    if (enable) {
      await _startMicrophoneRecording();
    } else {
      await _stopMicrophoneRecording();
    }

    print('Microphone ${enable ? 'enabled' : 'disabled'}');
  }

  Future<void> _startMicrophoneRecording() async {
    if (_audioRecorder == null) return;

    try {
      // Check if the recorder has permission
      if (!await _audioRecorder!.hasPermission()) {
        throw Exception('Recording permission not granted');
      }

      // Configure recording to capture PCM stream - MATCH TypeScript example exactly
      final recordConfig = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: options.recorderSampleRate,  // Now defaults to 8000 to match TypeScript
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      );

      // Start recording with stream
      final stream = await _audioRecorder!.startStream(recordConfig);
      
      _recordingSubscription = stream.listen((audioData) {
        print('Received audio data: ${audioData.length} bytes, state: $_state');
        if (_state == TransportState.ready) {
          _sendAudioData(audioData);
        } else {
          // Protect against memory overflow
          if (_audioQueue.length >= maxAudioQueueSize) {
            print('Warning: Audio queue full, dropping oldest audio data');
            _audioQueue.removeAt(0);
          }
          _audioQueue.add(audioData);
          print('Queued audio data, queue size: ${_audioQueue.length}');
        }
      });

      print('Microphone recording started');
    } catch (e) {
      print('Failed to start microphone recording: $e');
    }
  }

  Future<void> _stopMicrophoneRecording() async {
    try {
      await _recordingSubscription?.cancel();
      _recordingSubscription = null;
      
      await _audioRecorder?.stop();
      print('Microphone recording stopped');
    } catch (e) {
      print('Error stopping microphone recording: $e');
    }
  }

  void _sendAudioData(Uint8List audioData) {
    // Validate audio data
    if (audioData.isEmpty) {
      print('Warning: Received empty audio data, skipping');
      return;
    }
    
    if (_channel == null) {
      print('Cannot send audio: WebSocket channel is null');
      return;
    }
    
    try {
      print('Sending audio data: ${audioData.length} bytes');
      
      // The record package gives us raw PCM16 bytes, which is what the web client uses
      // No conversion needed - the TwilioSerializer will handle PCM16 to μ-law conversion
      final serialized = _serializer.serializeAudio(
        audioData,
        options.recorderSampleRate,
        1,
      );
      _channel?.sink.add(serialized);
      print('Audio data sent via WebSocket');
    } catch (e) {
      print('Error sending audio data: $e');
      // Don't rethrow - continue with other audio chunks
    }
  }

  void _flushAudioQueue() {
    while (_audioQueue.isNotEmpty) {
      final data = _audioQueue.removeAt(0);
      _sendAudioData(data);
    }
  }

  void sendReadyMessage() {
    print('Setting transport state to ready');
    _state = TransportState.ready;
    _clientOptions?.callbacks?.onTransportStateChanged(_state);
    
    // Emulate Twilio messages like the working TypeScript example
    _emulateTwilioMessages();
    
    sendMessage(RTVIMessage.clientReady());
    print('Flushing audio queue with ${_audioQueue.length} items');
    _flushAudioQueue();
  }

  void _emulateTwilioMessages() {
    print('Emulating Twilio messages for backend compatibility');
    
    // Send connected message
    final connectedMessage = {
      'event': 'connected',
      'protocol': 'Call',
      'version': '1.0.0',
    };
    sendRawMessage(connectedMessage);
    print('Sent Twilio connected message');
    
    // Send start message
    final startMessage = {
      'event': 'start',
      'start': {
        'streamSid': 'test_stream_sid',
        'callSid': 'test_call_sid',
      },
    };
    sendRawMessage(startMessage);
    print('Sent Twilio start message');
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

  Future<void> _playAudio(Uint8List audioData) async {
    try {
      if (_audioPlayer != null) {
        // Use flutter_sound to play PCM audio data directly
        await _audioPlayer!.feedUint8FromStream(audioData);
      }
    } catch (e) {
      print('Audio playback error: $e');
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
