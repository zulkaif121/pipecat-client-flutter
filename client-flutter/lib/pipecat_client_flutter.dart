/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

library pipecat_client_flutter;

// Main client (simplified API matching official Pipecat SDK)
export 'pipecat_client.dart';

// Core exports (essential only)
export 'core/constants/rtvi_events.dart';
export 'core/errors/rtvi_error.dart';

// Transport layer (essential only)
export 'data/datasources/transport.dart';
export 'data/transports/websocket_audio_transport.dart';
export 'data/models/rtvi_message_model.dart';
export 'domain/entities/transport_state.dart';