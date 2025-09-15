/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

library pipecat_client_flutter;

// Core exports
export 'core/constants/rtvi_events.dart';
export 'core/errors/rtvi_error.dart';
export 'core/usecases/usecase.dart';

// Domain exports
export 'domain/entities/participant.dart';
export 'domain/entities/rtvi_message.dart';
export 'domain/entities/transport_state.dart';
export 'domain/repositories/pipecat_client_repository.dart';
export 'domain/usecases/connect_to_bot.dart';
export 'domain/usecases/disconnect_from_bot.dart';
export 'domain/usecases/send_message.dart';

// Data exports
export 'data/datasources/transport.dart';
export 'data/datasources/webrtc_transport.dart';
export 'data/models/rtvi_message_model.dart';
export 'data/repositories/pipecat_client_repository_impl.dart';

// Presentation exports
export 'presentation/providers/pipecat_client_provider.dart';
export 'presentation/providers/connection_state_provider.dart';
export 'presentation/widgets/pipecat_client_audio.dart';
export 'presentation/widgets/pipecat_client_video.dart';
export 'presentation/widgets/pipecat_mic_toggle.dart';
export 'presentation/widgets/pipecat_cam_toggle.dart';

// Main client
export 'pipecat_client.dart';