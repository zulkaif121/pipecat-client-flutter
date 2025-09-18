/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain/entities/participant.dart';
import '../../domain/entities/rtvi_message.dart';
import '../../domain/entities/transport_state.dart';
import '../../domain/repositories/pipecat_client_repository.dart';
import '../../core/constants/rtvi_events.dart';
import '../datasources/transport.dart';
import '../transports/websocket_audio_transport.dart';
import '../models/rtvi_message_model.dart';

/// Implementation of PipecatClientRepository
class PipecatClientRepositoryImpl implements PipecatClientRepository {
  PipecatClientRepositoryImpl({
    required Transport transport,
  }) : _transport = transport {
    _participantsController = BehaviorSubject<List<Participant>>.seeded([]);
    
    // Listen to transport events and messages
    _setupEventListeners();
  }

  final Transport _transport;
  late final BehaviorSubject<List<Participant>> _participantsController;
  
  bool _isBotReady = false;
  final List<Participant> _participants = [];

  @override
  Future<void> initDevices({
    bool enableMic = true,
    bool enableCam = false,
  }) async {
    await _transport.initialize(
      enableMic: enableMic,
      enableCam: enableCam,
    );
  }

  @override
  Future<void> connect({
    required String endpoint,
    Map<String, dynamic>? params,
  }) async {
    await _transport.connect(
      endpoint: endpoint,
      params: params,
    );
  }

  @override
  Future<void> disconnect() async {
    await _transport.disconnect();
    _isBotReady = false;
    _participants.clear();
    _participantsController.add([]);
  }

  @override
  Future<void> sendMessage(RTVIMessage message) async {
    await _transport.sendMessage(message.toModel());
  }

  @override
  Future<void> sendAction({
    required String action,
    Map<String, dynamic>? data,
  }) async {
    final message = RTVIMessageHelpers.action(
      action: action,
      data: data,
    );
    await sendMessage(message);
  }

  @override
  TransportState get transportState => _transport.state;

  @override
  Stream<TransportState> get transportStateStream => _transport.stateStream;

  @override
  Stream<RTVIEventData> get eventStream => _transport.eventStream;

  @override
  Stream<RTVIMessage> get messageStream => 
      _transport.messageStream.map((model) => model.toDomain());

  @override
  List<Participant> get participants => List.unmodifiable(_participants);

  @override
  Stream<List<Participant>> get participantsStream => 
      _participantsController.stream;

  @override
  bool get isConnected => _transport.state.isConnected;

  @override
  bool get isBotReady => _isBotReady;

  @override
  bool get isMicEnabled => _transport.isMicEnabled;

  @override
  Future<void> enableMic(bool enable) async {
    await _transport.enableMic(enable);
  }

  @override
  Future<void> enableCam(bool enable) async {
    // Camera functionality removed - audio only
    throw UnsupportedError('Camera functionality not supported in audio-only mode');
  }

  @override
  Future<List<MediaDeviceInfo>> getAvailableMics() async {
    return await _transport.getAvailableMics();
  }

  @override
  Future<List<MediaDeviceInfo>> getAvailableCams() async {
    // Camera functionality removed - audio only
    return <MediaDeviceInfo>[];
  }

  @override
  Future<void> setMic(String deviceId) async {
    await _transport.setMic(deviceId);
  }

  @override
  Future<void> setCam(String deviceId) async {
    // Camera functionality removed - audio only
    throw UnsupportedError('Camera functionality not supported in audio-only mode');
  }

  /// Get audio playback stream (only available with WebSocketAudioTransport)
  Stream<bool>? get audioPlaybackStream {
    if (_transport is WebSocketAudioTransport) {
      return (_transport as WebSocketAudioTransport).audioPlaybackStream;
    }
    return null;
  }

  /// Check if audio is currently playing (only available with WebSocketAudioTransport)
  bool get isAudioPlaying {
    if (_transport is WebSocketAudioTransport) {
      return (_transport as WebSocketAudioTransport).isAudioPlaying;
    }
    return false;
  }

  @override
  Future<void> dispose() async {
    await _transport.dispose();
    await _participantsController.close();
  }

  // Private methods

  void _setupEventListeners() {
    // Listen to events from transport
    _transport.eventStream.listen((eventData) {
      _handleTransportEvent(eventData);
    });

    // Listen to messages from transport
    _transport.messageStream.listen((message) {
      _handleTransportMessage(message);
    });
  }

  void _handleTransportEvent(RTVIEventData eventData) {
    switch (eventData.event) {
      case RTVIEvent.botReady:
        _isBotReady = true;
        break;
      case RTVIEvent.botDisconnected:
        _isBotReady = false;
        break;
      case RTVIEvent.connected:
        // Add local participant
        _addParticipant(Participant(
          id: 'local',
          name: 'You',
          isLocal: true,
        ));
        break;
      case RTVIEvent.disconnected:
        _participants.clear();
        _participantsController.add([]);
        break;
      default:
        // Handle other events as needed
        break;
    }
  }

  void _handleTransportMessage(RTVIMessageModel message) {
    // Handle specific message types that affect repository state
    switch (message.type) {
      case 'participant-joined':
        _handleParticipantJoined(message.data);
        break;
      case 'participant-left':
        _handleParticipantLeft(message.data);
        break;
      default:
        // Other messages are handled by the presentation layer
        break;
    }
  }

  void _handleParticipantJoined(Map<String, dynamic> data) {
    final participant = Participant.fromJson(data);
    _addParticipant(participant);
  }

  void _handleParticipantLeft(Map<String, dynamic> data) {
    final participantId = data['id'] as String?;
    if (participantId != null) {
      _removeParticipant(participantId);
    }
  }

  void _addParticipant(Participant participant) {
    if (!_participants.any((p) => p.id == participant.id)) {
      _participants.add(participant);
      _participantsController.add(List.from(_participants));
    }
  }

  void _removeParticipant(String participantId) {
    _participants.removeWhere((p) => p.id == participantId);
    _participantsController.add(List.from(_participants));
  }
}