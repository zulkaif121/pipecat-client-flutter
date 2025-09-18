/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../data/datasources/transport.dart';
import '../../data/repositories/pipecat_client_repository_impl.dart';
import '../../domain/entities/participant.dart';
import '../../domain/entities/rtvi_message.dart';
import '../../domain/entities/transport_state.dart';
import '../../domain/repositories/pipecat_client_repository.dart';
import '../../domain/usecases/connect_to_bot.dart';
import '../../domain/usecases/disconnect_from_bot.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/send_action.dart';
import '../../core/usecases/usecase.dart';
import '../../core/constants/rtvi_events.dart';

/// Provider for managing Pipecat client state and operations
class PipecatClientProvider extends ChangeNotifier {
  PipecatClientProvider({
    required PipecatClientRepository repository,
    required ConnectToBot connectToBot,
    required DisconnectFromBot disconnectFromBot,
    required SendMessage sendMessage,
    required SendAction sendAction,
  })  : _repository = repository,
        _connectToBot = connectToBot,
        _disconnectFromBot = disconnectFromBot,
        _sendMessage = sendMessage,
        _sendAction = sendAction {
    _init();
  }

  final PipecatClientRepository _repository;
  final ConnectToBot _connectToBot;
  final DisconnectFromBot _disconnectFromBot;
  final SendMessage _sendMessage;
  final SendAction _sendAction;

  // State variables
  TransportState _transportState = const TransportState.disconnected();
  List<Participant> _participants = [];
  String? _errorMessage;
  bool _isConnecting = false;

  // Getters
  TransportState get transportState => _transportState;
  List<Participant> get participants => _participants;
  String? get errorMessage => _errorMessage;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _repository.isConnected;
  bool get isBotReady => _repository.isBotReady;
  bool get isMicEnabled => _repository.isMicEnabled;

  // Streams
  Stream<TransportState> get transportStateStream => _repository.transportStateStream;
  Stream<RTVIEventData> get eventStream => _repository.eventStream;
  Stream<RTVIMessage> get messageStream => _repository.messageStream;
  Stream<List<Participant>> get participantsStream => _repository.participantsStream;

  void _init() {
    // Listen to transport state changes
    _repository.transportStateStream.listen((state) {
      _transportState = state;
      _isConnecting = state.isConnecting;
      
      if (state.isError) {
        state.whenOrNull(
          error: (message) => _errorMessage = message,
        );
      } else {
        _errorMessage = null;
      }
      
      notifyListeners();
    });

    // Listen to participants changes
    _repository.participantsStream.listen((participants) {
      _participants = participants;
      notifyListeners();
    });

    // Listen to events for additional state updates
    _repository.eventStream.listen((eventData) {
      _handleEvent(eventData);
    });
  }

  /// Initialize device access
  Future<void> initDevices({
    bool enableMic = true,
    bool enableCam = false,
  }) async {
    try {
      await _repository.initDevices(
        enableMic: enableMic,
        enableCam: enableCam,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Connect to a bot
  Future<void> connect({
    required String endpoint,
    bool enableMic = true,
    bool enableCam = false,
    Map<String, dynamic>? connectionParams,
  }) async {
    try {
      _isConnecting = true;
      _errorMessage = null;
      notifyListeners();

      await _connectToBot(ConnectToBotParams(
        endpoint: endpoint,
        enableMic: enableMic,
        enableCam: enableCam,
        connectionParams: connectionParams,
      ));
    } catch (e) {
      _errorMessage = e.toString();
      _isConnecting = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Disconnect from the bot
  Future<void> disconnect() async {
    try {
      await _disconnectFromBot(NoParams());
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Send a message to the bot
  Future<void> sendMessage(RTVIMessage message) async {
    try {
      await _sendMessage(SendMessageParams(message: message));
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Send an action to the bot
  Future<void> sendAction({
    required String action,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _sendAction(SendActionParams(
        action: action,
        data: data,
      ));
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Enable or disable microphone
  Future<void> enableMic(bool enable) async {
    try {
      await _repository.enableMic(enable);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Enable or disable camera
  Future<void> enableCam(bool enable) async {
    try {
      await _repository.enableCam(enable);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get available microphone devices
  Future<List<MediaDeviceInfo>> getAvailableMics() async {
    try {
      return await _repository.getAvailableMics();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get available camera devices
  Future<List<MediaDeviceInfo>> getAvailableCams() async {
    try {
      return await _repository.getAvailableCams();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Set active microphone device
  Future<void> setMic(String deviceId) async {
    try {
      await _repository.setMic(deviceId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Set active camera device
  Future<void> setCam(String deviceId) async {
    try {
      await _repository.setCam(deviceId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get audio playback stream (only available with WebSocketAudioTransport)
  Stream<bool>? get audioPlaybackStream {
    if (_repository is PipecatClientRepositoryImpl) {
      return (_repository as PipecatClientRepositoryImpl).audioPlaybackStream;
    }
    return null;
  }

  /// Check if audio is currently playing (only available with WebSocketAudioTransport)
  bool get isAudioPlaying {
    if (_repository is PipecatClientRepositoryImpl) {
      return (_repository as PipecatClientRepositoryImpl).isAudioPlaying;
    }
    return false;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _handleEvent(RTVIEventData? eventData) {
    if (eventData == null) return;
    // Handle specific events that might require UI updates
    switch (eventData.event) {
      case RTVIEvent.error:
        _errorMessage = eventData.data?['error']?.toString() ?? 'Unknown error';
        notifyListeners();
        break;
      case RTVIEvent.botReady:
        // Bot is ready, any additional UI state updates can go here
        notifyListeners();
        break;
      default:
        // Most events are handled via streams, but some might need immediate UI updates
        break;
    }
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}