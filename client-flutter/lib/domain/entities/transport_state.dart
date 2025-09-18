/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:freezed_annotation/freezed_annotation.dart';

part 'transport_state.freezed.dart';

/// Represents the current state of the transport connection
@freezed
class TransportState with _$TransportState {
  const factory TransportState.disconnected() = _Disconnected;
  const factory TransportState.initializing() = _Initializing;
  const factory TransportState.initialized() = _Initialized;
  const factory TransportState.connecting() = _Connecting;
  const factory TransportState.connected() = _Connected;
  const factory TransportState.disconnecting() = _Disconnecting;
  const factory TransportState.ready() = _Ready;
  const factory TransportState.error(String message) = _Error;
}

/// Extension to convert TransportState to string for compatibility
extension TransportStateExtension on TransportState {
  String get value {
    return when(
      disconnected: () => 'disconnected',
      initializing: () => 'initializing',
      initialized: () => 'initialized',
      connecting: () => 'connecting',
      connected: () => 'connected',
      disconnecting: () => 'disconnecting',
      ready: () => 'ready',
      error: (message) => 'error',
    );
  }
  
  bool get isConnected => this is _Connected || this is _Ready;
  bool get isDisconnected => this is _Disconnected;
  bool get isConnecting => this is _Connecting;
  bool get isReady => this is _Ready;
  bool get isError => this is _Error;

  String? get error => maybeWhen(
    error: (message) => message,
    orElse: () => null,
  );
}