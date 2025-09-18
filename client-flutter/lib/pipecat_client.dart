/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'data/datasources/transport.dart';
import 'data/models/rtvi_message_model.dart';
import 'data/transports/websocket_audio_transport.dart';
import 'domain/entities/transport_state.dart';
import 'core/constants/rtvi_events.dart';

/// Participant in a call
class Participant {
  Participant({
    required this.name,
    this.local = false,
  });

  final String name;
  final bool local;
}

/// Audio tracks from bot and user
class Tracks {
  Tracks({this.bot, this.local});

  final BotTracks? bot;
  final LocalTracks? local;
}

class BotTracks {
  BotTracks({this.audio});
  final MediaStreamTrack? audio;
}

class LocalTracks {
  LocalTracks({this.audio});
  final MediaStreamTrack? audio;
}

/// Transcript data
class TranscriptData {
  TranscriptData({
    required this.text,
    required this.isFinal,
    this.timestamp,
  });

  final String text;
  final bool isFinal;
  final DateTime? timestamp;
}

/// Bot LLM text data
class BotLLMTextData {
  BotLLMTextData({
    required this.text,
    this.timestamp,
  });

  final String text;
  final DateTime? timestamp;
}

/// Callbacks for PipecatClient events
class PipecatClientCallbacks {
  PipecatClientCallbacks({
    this.onConnected,
    this.onDisconnected,
    this.onBotReady,
    this.onUserTranscript,
    this.onBotTranscript,
    this.onError,
    this.onMessageError,
  });

  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final Function(Map<String, dynamic> data)? onBotReady;
  final Function(TranscriptData data)? onUserTranscript;
  final Function(BotLLMTextData data)? onBotTranscript;
  final Function(RTVIMessageModel error)? onError;
  final Function(RTVIMessageModel error)? onMessageError;
}

/// Configuration options for PipecatClient
class PipecatClientOptions {
  PipecatClientOptions({
    this.enableMic = true,
    this.enableCam = false, // Ignored - audio only
    this.transport,
    this.callbacks,
  });

  final bool enableMic;
  final bool enableCam; // Kept for API compatibility but ignored
  final Transport? transport;
  final PipecatClientCallbacks? callbacks;
}

/// Main Pipecat client class for Flutter (matches official SDK pattern)
class PipecatClient {
  PipecatClient(PipecatClientOptions options) : _options = options {
    _transport = options.transport ?? WebSocketAudioTransport();
    _setupEventListeners();
  }

  final PipecatClientOptions _options;
  late final Transport _transport;
  final Map<RTVIEvent, List<Function>> _eventListeners = {};
  StreamSubscription<RTVIEventData>? _eventSubscription;
  StreamSubscription<RTVIMessageModel>? _messageSubscription;
  StreamSubscription<TransportState>? _stateSubscription;

  bool _isConnected = false;
  Tracks? _tracks;

  /// Initialize device access
  Future<void> initDevices() async {
    await _transport.initialize(
      enableMic: _options.enableMic,
      enableCam: false, // Audio only
    );
  }

  /// Connect to a bot
  Future<void> connect() async {
    // This method is kept for API compatibility but transport handles connection details
    throw UnsupportedError('Use transport.connect() with endpoint instead');
  }

  /// Connect to a bot with endpoint
  Future<void> connectWithEndpoint(String endpoint) async {
    await _transport.connect(endpoint: endpoint);
  }

  /// Disconnect from the bot
  Future<void> disconnect() async {
    await _transport.disconnect();
  }

  /// Enable or disable microphone
  Future<void> enableMic(bool enable) async {
    await _transport.enableMic(enable);
  }

  /// Get available microphones
  Future<List<MediaDeviceInfo>> getAvailableMics() async {
    return _transport.getAvailableMics();
  }

  /// Set active microphone
  Future<void> setMic(String deviceId) async {
    await _transport.setMic(deviceId);
  }

  /// Add event listener
  void on(RTVIEvent event, Function callback) {
    if (!_eventListeners.containsKey(event)) {
      _eventListeners[event] = [];
    }
    _eventListeners[event]!.add(callback);
  }

  /// Remove event listener
  void off(RTVIEvent event, Function callback) {
    _eventListeners[event]?.remove(callback);
  }

  /// Get current tracks
  Tracks? tracks() => _tracks;

  /// Get connection state
  bool get connected => _isConnected;

  /// Send message to bot
  Future<void> sendMessage(RTVIMessageModel message) async {
    await _transport.sendMessage(message);
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _stateSubscription?.cancel();
    await _transport.dispose();
    _eventListeners.clear();
  }

  void _setupEventListeners() {
    // Listen to transport events
    _eventSubscription = _transport.eventStream.listen(_handleEvent);
    _messageSubscription = _transport.messageStream.listen(_handleMessage);
    _stateSubscription = _transport.stateStream.listen(_handleStateChange);
  }

  void _handleEvent(RTVIEventData eventData) {
    final listeners = _eventListeners[eventData.event] ?? [];
    for (final listener in listeners) {
      try {
        if (eventData.data != null) {
          if (listener is Function(Map<String, dynamic>)) {
            listener(eventData.data!);
          } else if (listener is Function(MediaStreamTrack, Participant?)) {
            // Handle track events
            final track = eventData.data!['track'] as MediaStreamTrack?;
            final participant = eventData.data!['participant'] as Participant?;
            if (track != null) {
              listener(track, participant);
            }
          } else {
            listener();
          }
        } else {
          listener();
        }
      } catch (e) {
        debugPrint('Error in event listener: $e');
      }
    }

    // Handle built-in callbacks
    switch (eventData.event) {
      case RTVIEvent.connected:
        _isConnected = true;
        _options.callbacks?.onConnected?.call();
        break;
      case RTVIEvent.disconnected:
        _isConnected = false;
        _options.callbacks?.onDisconnected?.call();
        break;
      case RTVIEvent.botReady:
        _options.callbacks?.onBotReady?.call(eventData.data ?? {});
        break;
      case RTVIEvent.trackStarted:
        // Update tracks when new track starts
        _updateTracks(eventData.data);
        break;
      default:
        break;
    }
  }

  void _handleMessage(RTVIMessageModel message) {
    // Handle specific message types that match TS client
    switch (message.type) {
      case 'user-transcript':
        if (_options.callbacks?.onUserTranscript != null) {
          final text = message.data['text'] as String? ?? '';
          final isFinal = message.data['final'] as bool? ?? false;
          _options.callbacks!.onUserTranscript!(TranscriptData(
            text: text,
            isFinal: isFinal,
            timestamp: DateTime.now(),
          ));
        }
        break;
      case 'bot-llm-text':
        if (_options.callbacks?.onBotTranscript != null) {
          final text = message.data['text'] as String? ?? '';
          _options.callbacks!.onBotTranscript!(BotLLMTextData(
            text: text,
            timestamp: DateTime.now(),
          ));
        }
        break;
      case 'error':
        _options.callbacks?.onError?.call(message);
        break;
      default:
        debugPrint('Unhandled message type: ${message.type}');
    }
  }

  void _handleStateChange(TransportState state) {
    if (state.isConnected) {
      _isConnected = true;
    } else if (state.isDisconnected) {
      _isConnected = false;
    }

    if (state.isError) {
      _options.callbacks?.onError?.call(RTVIMessageModel(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        type: 'error',
        data: {'error': state.error},
      ));
    }
  }

  void _updateTracks(Map<String, dynamic>? data) {
    if (data?['track'] is MediaStreamTrack) {
      final track = data!['track'] as MediaStreamTrack;
      final participant = data['participant'] as Participant?;

      if (participant?.local == true) {
        _tracks ??= Tracks();
        _tracks = Tracks(
          bot: _tracks?.bot,
          local: LocalTracks(audio: track),
        );
      } else {
        _tracks ??= Tracks();
        _tracks = Tracks(
          bot: BotTracks(audio: track),
          local: _tracks?.local,
        );
      }
    }
  }
}
