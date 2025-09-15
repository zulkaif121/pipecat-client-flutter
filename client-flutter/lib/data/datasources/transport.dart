/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import '../models/rtvi_message_model.dart';
import '../../domain/entities/transport_state.dart';
import '../../core/constants/rtvi_events.dart';

/// Abstract base class for transport implementations
abstract class Transport {
  /// Initialize the transport with configuration
  Future<void> initialize({
    bool enableMic = true,
    bool enableCam = false,
  });

  /// Connect to the remote endpoint
  Future<void> connect({
    required String endpoint,
    Map<String, dynamic>? params,
  });

  /// Disconnect from the remote endpoint
  Future<void> disconnect();

  /// Send a message through the transport
  Future<void> sendMessage(RTVIMessageModel message);

  /// Current transport state
  TransportState get state;

  /// Stream of transport state changes
  Stream<TransportState> get stateStream;

  /// Stream of received messages
  Stream<RTVIMessageModel> get messageStream;

  /// Stream of RTVI events
  Stream<RTVIEventData> get eventStream;

  /// Enable or disable microphone
  Future<void> enableMic(bool enable);

  /// Enable or disable camera  
  Future<void> enableCam(bool enable);

  /// Get available microphone devices
  Future<List<MediaDeviceInfo>> getAvailableMics();

  /// Get available camera devices
  Future<List<MediaDeviceInfo>> getAvailableCams();

  /// Set active microphone device
  Future<void> setMic(String deviceId);

  /// Set active camera device
  Future<void> setCam(String deviceId);

  /// Dispose of resources
  Future<void> dispose();
}

/// Event data for RTVI events
class RTVIEventData {
  RTVIEventData({
    required this.event,
    this.data,
  });

  final RTVIEvent event;
  final Map<String, dynamic>? data;
}

/// Media device information
class MediaDeviceInfo {
  MediaDeviceInfo({
    required this.deviceId,
    required this.label,
    required this.kind,
  });

  final String deviceId;
  final String label;
  final String kind;
}