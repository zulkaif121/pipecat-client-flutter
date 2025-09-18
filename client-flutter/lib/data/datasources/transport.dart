/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/rtvi_message_model.dart';
import '../../domain/entities/transport_state.dart';
import '../../core/constants/rtvi_events.dart';

/// Abstract base class for transport implementations
abstract class Transport {
  /// Initialize the transport with configuration
  Future<void> initialize({
    bool enableMic = true,
    bool enableCam = false, // Ignored - audio only
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

  /// Check if microphone is currently enabled
  bool get isMicEnabled;

  /// Get available microphone devices
  Future<List<MediaDeviceInfo>> getAvailableMics();

  /// Set active microphone device
  Future<void> setMic(String deviceId);

  /// Start recording audio (for audio streaming)
  Future<void> startRecording();

  /// Stop recording audio
  Future<void> stopRecording();

  /// Check if currently recording
  bool get isRecording;

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

