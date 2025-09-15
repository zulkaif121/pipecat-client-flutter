/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import '../entities/participant.dart';
import '../entities/rtvi_message.dart';
import '../entities/transport_state.dart';
import '../../core/constants/rtvi_events.dart';

/// Repository interface for Pipecat client operations
abstract class PipecatClientRepository {
  /// Initialize device access (microphone, camera)
  Future<void> initDevices({
    bool enableMic = true,
    bool enableCam = false,
  });

  /// Connect to a bot with the given parameters
  Future<void> connect({
    required String endpoint,
    Map<String, dynamic>? params,
  });

  /// Disconnect from the current session
  Future<void> disconnect();

  /// Send a message to the bot
  Future<void> sendMessage(RTVIMessage message);

  /// Send an action to the bot
  Future<void> sendAction({
    required String action,
    Map<String, dynamic>? data,
  });

  /// Get current transport state
  TransportState get transportState;

  /// Stream of transport state changes
  Stream<TransportState> get transportStateStream;

  /// Stream of RTVI events
  Stream<RTVIEventData> get eventStream;

  /// Stream of received messages
  Stream<RTVIMessage> get messageStream;

  /// Get current participants
  List<Participant> get participants;

  /// Stream of participant changes
  Stream<List<Participant>> get participantsStream;

  /// Check if currently connected
  bool get isConnected;

  /// Check if bot is ready
  bool get isBotReady;

  /// Enable or disable microphone
  Future<void> enableMic(bool enable);

  /// Enable or disable camera
  Future<void> enableCam(bool enable);

  /// Get available microphone devices
  Future<List<MediaDevice>> getAvailableMics();

  /// Get available camera devices
  Future<List<MediaDevice>> getAvailableCams();

  /// Set active microphone device
  Future<void> setMic(String deviceId);

  /// Set active camera device
  Future<void> setCam(String deviceId);

  /// Dispose of resources
  Future<void> dispose();
}

/// Data class for RTVI events
class RTVIEventData {
  RTVIEventData({
    required this.event,
    this.data,
  });

  final RTVIEvent event;
  final Map<String, dynamic>? data;
}

/// Represents a media device (microphone or camera)
class MediaDevice {
  MediaDevice({
    required this.id,
    required this.label,
    required this.kind,
  });

  final String id;
  final String label;
  final String kind; // 'audioinput', 'videoinput'
}