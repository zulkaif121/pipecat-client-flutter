/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

library pipecat_client_flutter;

// Core exports
export 'src/client/pipecat_client.dart';
export 'src/client/pipecat_client_options.dart';
export 'src/client/pipecat_events.dart';

// Transport exports
export 'src/transport/websocket_transport.dart';
export 'src/transport/twilio_serializer.dart';

// State management exports
export 'src/providers/pipecat_provider.dart';

// Widget exports
export 'src/widgets/audio_test_widget.dart';
export 'src/widgets/twilio_example.dart';

// Models
export 'src/models/rtvi_message.dart';
export 'src/models/transport_state.dart';
export 'src/models/participant.dart';
export 'src/models/transcript_data.dart';