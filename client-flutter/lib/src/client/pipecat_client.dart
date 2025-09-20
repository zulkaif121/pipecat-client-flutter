/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

import 'dart:async';

import '../models/rtvi_message.dart';
import '../models/transport_state.dart';
import '../models/transcript_data.dart';
import '../transport/websocket_transport.dart';
import 'pipecat_client_options.dart';

class PipecatClient {
  final PipecatClientOptions options;
  late final WebSocketTransport _transport;
  Completer<Map<String, dynamic>>? _connectCompleter;

  PipecatClient(this.options) {
    _transport = options.transport;
    _transport.initialize(options, _handleMessage);
  }

  // Getters
  bool get connected => _transport.state.isConnected;
  TransportState get state => _transport.state;
  bool get isMicEnabled => _transport.isMicEnabled;

  // Device initialization
  Future<void> initDevices() async {
    await _transport.initDevices();
  }

  // Connection management
  Future<Map<String, dynamic>> connect([Map<String, dynamic>? connectParams]) async {
    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      return _connectCompleter!.future;
    }

    _connectCompleter = Completer<Map<String, dynamic>>();

    try {
      if (_transport.state == TransportState.disconnected) {
        await initDevices();
      }

      await _transport.connect(connectParams);
      _transport.sendReadyMessage();

      return _connectCompleter!.future;
    } catch (e) {
      if (!_connectCompleter!.isCompleted) {
        _connectCompleter!.completeError(e);
      }
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _transport.disconnect();
    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      _connectCompleter!.completeError(Exception('Connection cancelled'));
    }
    _connectCompleter = null;
  }

  // Audio control
  Future<void> enableMic(bool enable) async {
    await _transport.enableMic(enable);
  }

  // Message handling
  void _handleMessage(RTVIMessage message) {
    switch (message.type) {
      case RTVIMessageType.botReady:
        if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
          _connectCompleter!.complete(message.data);
        }
        options.callbacks?.onBotReady(message.data);
        break;

      case RTVIMessageType.error:
        options.callbacks?.onError(message);
        if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
          _connectCompleter!.completeError(
            Exception(message.data['message'] ?? 'Unknown error'),
          );
        }
        break;

      case RTVIMessageType.userStartedSpeaking:
        options.callbacks?.onUserStartedSpeaking();
        break;

      case RTVIMessageType.userStoppedSpeaking:
        options.callbacks?.onUserStoppedSpeaking();
        break;

      case RTVIMessageType.botStartedSpeaking:
        options.callbacks?.onBotStartedSpeaking();
        break;

      case RTVIMessageType.botStoppedSpeaking:
        options.callbacks?.onBotStoppedSpeaking();
        break;

      case RTVIMessageType.userTranscript:
        final transcriptData = TranscriptData.fromJson(message.data);
        options.callbacks?.onUserTranscript(transcriptData);
        break;

      case RTVIMessageType.botTranscript:
        final transcriptData = BotLLMTextData.fromJson(message.data);
        options.callbacks?.onBotTranscript(transcriptData);
        break;

      default:
        // Handle other message types as needed
        break;
    }
  }

  // Transport access
  WebSocketTransport get transport => _transport;

  // Cleanup
  Future<void> dispose() async {
    await disconnect();
    await _transport.dispose();
  }
}