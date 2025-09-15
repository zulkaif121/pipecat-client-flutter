/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import '../repositories/pipecat_client_repository.dart';
import '../../core/usecases/usecase.dart';

/// Use case for disconnecting from a bot
class DisconnectFromBot implements UseCase<void, NoParams> {
  DisconnectFromBot(this._repository);

  final PipecatClientRepository _repository;

  @override
  Future<void> call(NoParams params) async {
    await _repository.disconnect();
  }
}