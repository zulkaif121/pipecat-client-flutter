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

/// Use case for sending actions to the bot
class SendAction implements UseCase<void, SendActionParams> {
  SendAction(this._repository);

  final PipecatClientRepository _repository;

  @override
  Future<void> call(SendActionParams params) async {
    await _repository.sendAction(
      action: params.action,
      data: params.data,
    );
  }
}

/// Parameters for sending a message
class SendMessageParams {
  SendMessageParams({required this.message});
  
  final RTVIMessage message;
}

/// Parameters for sending an action
class SendActionParams {
  SendActionParams({
    required this.action,
    this.data,
  });
  
  final String action;
  final Map<String, dynamic>? data;
}