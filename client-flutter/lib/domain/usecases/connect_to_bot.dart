/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import '../repositories/pipecat_client_repository.dart';
import '../../core/usecases/usecase.dart';

/// Use case for connecting to a bot
class ConnectToBot implements UseCase<void, ConnectToBotParams> {
  ConnectToBot(this._repository);

  final PipecatClientRepository _repository;

  @override
  Future<void> call(ConnectToBotParams params) async {
    // Initialize devices if not already done
    if (!_repository.isConnected) {
      await _repository.initDevices(
        enableMic: params.enableMic,
        enableCam: params.enableCam,
      );
    }

    // Connect to the bot
    await _repository.connect(
      endpoint: params.endpoint,
      params: params.connectionParams,
    );
  }
}

/// Parameters for connecting to a bot
class ConnectToBotParams {
  ConnectToBotParams({
    required this.endpoint,
    this.enableMic = true,
    this.enableCam = false,
    this.connectionParams,
  });

  final String endpoint;
  final bool enableMic;
  final bool enableCam;
  final Map<String, dynamic>? connectionParams;
}