/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:freezed_annotation/freezed_annotation.dart';

part 'participant.freezed.dart';
part 'participant.g.dart';

/// Represents a participant in the conversation
@freezed
class Participant with _$Participant {
  const factory Participant({
    required String id,
    required String name,
    @Default(false) bool isLocal,
    @Default(false) bool isBot,
    Map<String, dynamic>? metadata,
  }) = _Participant;

  factory Participant.fromJson(Map<String, dynamic> json) =>
      _$ParticipantFromJson(json);
}