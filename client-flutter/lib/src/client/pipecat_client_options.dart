/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

import '../transport/websocket_transport.dart';
import 'pipecat_events.dart';

class PipecatClientOptions {
  final WebSocketTransport transport;
  final PipecatEventCallbacks? callbacks;
  final bool enableMic;
  final bool enableCam;

  const PipecatClientOptions({
    required this.transport,
    this.callbacks,
    this.enableMic = true,
    this.enableCam = false,
  });
}