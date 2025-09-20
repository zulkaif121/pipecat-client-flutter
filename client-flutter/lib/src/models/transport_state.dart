/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

enum TransportState {
  disconnected,
  initializing,
  initialized,
  authenticating,
  authenticated,
  connecting,
  connected,
  ready,
  disconnecting,
  error,
}

extension TransportStateExtension on TransportState {
  bool get isConnected => [
        TransportState.connected,
        TransportState.ready,
      ].contains(this);

  bool get isConnecting => this == TransportState.connecting;

  bool get canConnect => [
        TransportState.disconnected,
        TransportState.initialized,
        TransportState.error,
      ].contains(this);
}