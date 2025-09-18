/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import '../entities/rtvi_message.dart';
import '../repositories/pipecat_client_repository.dart';
import '../../core/usecases/usecase.dart';

/// Use case for sending messages to the bot
class SendMessage implements UseCase<void, SendMessageParams> {
  SendMessage(this._repository);

  final PipecatClientRepository _repository;

  @override
  Future<void> call(SendMessageParams params) async {
    await _repository.sendMessage(params.message);
  }
}



/// Parameters for sending a message
class SendMessageParams {
  SendMessageParams({required this.message});
  
  final RTVIMessage message;
}

