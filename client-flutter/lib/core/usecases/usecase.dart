/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

/// Base class for all use cases
abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

/// For use cases that don't require parameters
class NoParams {}