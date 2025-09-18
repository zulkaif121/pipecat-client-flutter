/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter/foundation.dart';

import '../../domain/entities/transport_state.dart';
import '../../core/constants/rtvi_events.dart';
import 'pipecat_client_provider.dart';

/// Provider specifically for connection state management
class ConnectionStateProvider extends ChangeNotifier {
  ConnectionStateProvider({
    required PipecatClientProvider clientProvider,
  }) : _clientProvider = clientProvider {
    _init();
  }

  final PipecatClientProvider _clientProvider;

  TransportState _transportState = const TransportState.disconnected();
  bool _isBotReady = false;
  DateTime? _lastConnectedAt;
  DateTime? _lastDisconnectedAt;
  int _reconnectAttempts = 0;

  // Getters
  TransportState get transportState => _transportState;
  bool get isBotReady => _isBotReady;
  bool get isConnected => _transportState.isConnected;
  bool get isConnecting => _transportState.isConnecting;
  bool get isDisconnected => _transportState.isDisconnected;
  bool get hasError => _transportState.isError;
  DateTime? get lastConnectedAt => _lastConnectedAt;
  DateTime? get lastDisconnectedAt => _lastDisconnectedAt;
  int get reconnectAttempts => _reconnectAttempts;

  String? get errorMessage {
    return _transportState.whenOrNull(
      error: (message) => message,
    );
  }

  void _init() {
    // Listen to transport state changes
    _clientProvider.transportStateStream.listen((state) {
      final previousState = _transportState;
      _transportState = state;

      // Track connection timing
      if (state.isConnected && !previousState.isConnected) {
        _lastConnectedAt = DateTime.now();
        _reconnectAttempts = 0;
      } else if (state.isDisconnected && !previousState.isDisconnected) {
        _lastDisconnectedAt = DateTime.now();
      } else if (state.isError) {
        _reconnectAttempts++;
      }

      notifyListeners();
    });

    // Listen to bot ready events
    _clientProvider.eventStream.listen((eventData) {
      switch (eventData.event) {
        case RTVIEvent.botReady:
          _isBotReady = true;
          notifyListeners();
          break;
        case RTVIEvent.botDisconnected:
          _isBotReady = false;
          notifyListeners();
          break;
        case RTVIEvent.disconnected:
          _isBotReady = false;
          notifyListeners();
          break;
        default:
          break;
      }
    });
  }

  /// Reset reconnection attempts counter
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
    notifyListeners();
  }

  /// Get connection status description
  String get statusDescription {
    return _transportState.when(
      disconnected: () => 'Disconnected',
      initializing: () => 'Initializing...',
      initialized: () => 'Initialized',
      connecting: () => 'Connecting...',
      connected: () => _isBotReady ? 'Connected and Ready' : 'Connected',
      disconnecting: () => 'Disconnecting...',
      ready: () => 'Ready',
      error: (message) => 'Error: $message',
    );
  }

  /// Get connection duration if connected
  Duration? get connectionDuration {
    if (_lastConnectedAt != null && isConnected) {
      return DateTime.now().difference(_lastConnectedAt!);
    }
    return null;
  }
}