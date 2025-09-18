/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/rxdart.dart';
import 'package:logger/logger.dart';

import '../models/rtvi_message_model.dart';
import '../../domain/entities/transport_state.dart';
import '../../core/constants/rtvi_events.dart';
import '../../core/errors/rtvi_error.dart';
import 'transport.dart';

/// WebSocket transport implementation for Flutter (audio-only)
class WebSocketTransport extends Transport {
  WebSocketTransport() {
    _logger = Logger();
    _stateController = BehaviorSubject<TransportState>.seeded(
      const TransportState.disconnected(),
    );
    _messageController = StreamController<RTVIMessageModel>.broadcast();
    _eventController = StreamController<RTVIEventData>.broadcast();
  }

  late final Logger _logger;
  late final BehaviorSubject<TransportState> _stateController;
  late final StreamController<RTVIMessageModel> _messageController;
  late final StreamController<RTVIEventData> _eventController;

  WebSocketChannel? _webSocketChannel;
  MediaStream? _localStream;

  bool _micEnabled = true;

  @override
  TransportState get state => _stateController.value;

  @override
  Stream<TransportState> get stateStream => _stateController.stream;

  @override
  Stream<RTVIMessageModel> get messageStream => _messageController.stream;

  @override
  Stream<RTVIEventData> get eventStream => _eventController.stream;

  @override
  Future<void> initialize({
    bool enableMic = true,
    bool enableCam = false,
  }) async {
    try {
      _micEnabled = enableMic;

      // Request user media for audio only
      if (enableMic) {
        await _getUserMedia();
      }

      _logger.i('Transport initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize transport: $e');
      _updateState(TransportState.error('Failed to initialize: $e'));
      throw DeviceError('Failed to initialize transport: $e');
    }
  }

  @override
  Future<void> connect({
    required String endpoint,
    Map<String, dynamic>? params,
  }) async {
    try {
      _updateState(const TransportState.connecting());

      // Connect WebSocket
      await _connectWebSocket(endpoint, params);

      _updateState(const TransportState.connected());
      _emitEvent(RTVIEvent.connected);

      // Send initial messages to match Twilio protocol
      await _sendInitialMessages();

      _logger.i('Connected to $endpoint');
    } catch (e) {
      _logger.e('Failed to connect: $e');
      _updateState(TransportState.error('Connection failed: $e'));
      throw ConnectionError('Failed to connect: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      // Close WebSocket
      await _webSocketChannel?.sink.close();
      _webSocketChannel = null;

      // Stop local stream
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream = null;

      _updateState(const TransportState.disconnected());
      _emitEvent(RTVIEvent.disconnected);

      _logger.i('Disconnected successfully');
    } catch (e) {
      _logger.e('Error during disconnect: $e');
      _updateState(TransportState.error('Disconnect failed: $e'));
    }
  }

  @override
  Future<void> sendMessage(RTVIMessageModel message) async {
    if (_webSocketChannel == null) {
      throw MessageError('Not connected');
    }

    try {
      final jsonMessage = jsonEncode(message.toJson());
      _webSocketChannel!.sink.add(jsonMessage);
      _logger.d('Sent message: ${message.type}');
    } catch (e) {
      _logger.e('Failed to send message: $e');
      throw MessageError('Failed to send message: $e');
    }
  }

  @override
  Future<void> enableMic(bool enable) async {
    _micEnabled = enable;

    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      for (final track in audioTracks) {
        track.enabled = enable;
      }
    }

    _emitEvent(RTVIEvent.micUpdated, {'enabled': enable});
  }

  @override
  bool get isMicEnabled => _micEnabled;


  @override
  Future<List<MediaDeviceInfo>> getAvailableMics() async {
    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      return devices
          .where((device) => device.kind == 'audioinput')
          .toList();
    } catch (e) {
      _logger.e('Failed to get microphones: $e');
      return [];
    }
  }


  @override
  Future<void> setMic(String deviceId) async {
    // Implementation for switching microphone
    _logger.i('Switching to microphone: $deviceId');
    // This would require re-initializing the media stream with specific device
  }

  @override
  Future<void> startRecording() async {
    _logger.w('Audio recording not implemented in basic WebSocket transport');
    // No-op for basic transport - audio streaming implemented in WebSocketAudioTransport
  }

  @override
  Future<void> stopRecording() async {
    _logger.w('Audio recording not implemented in basic WebSocket transport');
    // No-op for basic transport - audio streaming implemented in WebSocketAudioTransport
  }

  @override
  bool get isRecording => false; // Not supported in basic transport

  @override
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _messageController.close();
    await _eventController.close();
  }

  // Private helper methods

  Future<void> _getUserMedia() async {
    final constraints = {
      'audio': _micEnabled,
      'video': false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    _logger.i('Got user media (audio only)');
  }

  Future<void> _connectWebSocket(String endpoint, Map<String, dynamic>? params) async {
    final uri = Uri.parse(endpoint);
    _webSocketChannel = WebSocketChannel.connect(uri);

    _webSocketChannel!.stream.listen(
      (message) => _handleWebSocketMessage(message),
      onError: (error) {
        _logger.e('WebSocket error: $error');
        _updateState(TransportState.error('WebSocket error: $error'));
      },
      onDone: () {
        _logger.i('WebSocket connection closed');
        if (state.isConnected) {
          _updateState(const TransportState.disconnected());
          _emitEvent(RTVIEvent.disconnected);
        }
      },
    );
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final rtviMessage = RTVIMessageModel.fromJson(data);
      
      _messageController.add(rtviMessage);
      _handleRTVIMessage(rtviMessage);
    } catch (e) {
      _logger.e('Failed to parse message: $e');
    }
  }

  void _handleRTVIMessage(RTVIMessageModel message) {
    switch (message.type) {
      case 'setup-complete':
        _updateState(const TransportState.ready());
        _emitEvent(RTVIEvent.botReady);
        break;
      case 'bot-ready':
        _emitEvent(RTVIEvent.botReady);
        break;
      case 'error':
        final error = message.data['error'] ?? 'Unknown error';
        _updateState(TransportState.error(error));
        _emitEvent(RTVIEvent.error, message.data);
        break;
      default:
        // Handle other message types
        _logger.d('Received message type: ${message.type}');
    }
  }

  Future<void> _sendRawMessage(Map<String, dynamic> message) async {
    if (_webSocketChannel != null) {
      _webSocketChannel!.sink.add(jsonEncode(message));
      _logger.d('Sent raw message: ${message['event']}');
    }
  }


  Future<void> _sendInitialMessages() async {
    try {
      // Send "connected" message to match Twilio protocol
      await _sendRawMessage({
        'event': 'connected',
        'protocol': 'Call',
        'version': '1.0.0',
      });

      // Wait a bit before sending start message
      await Future.delayed(const Duration(milliseconds: 100));

      // Send "start" message to match Twilio protocol
      await _sendRawMessage({
        'event': 'start',
        'start': {
          'streamSid': 'test_stream_sid',
          'callSid': 'test_call_sid',
        },
      });

      _logger.i('Initial messages sent to match Twilio protocol');
    } catch (e) {
      _logger.e('Failed to send initial messages: $e');
    }
  }

  void _updateState(TransportState newState) {
    _stateController.add(newState);
  }

  void _emitEvent(RTVIEvent event, [Map<String, dynamic>? data]) {
    _eventController.add(RTVIEventData(event: event, data: data));
  }
}