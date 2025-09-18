/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/rtvi_message.dart';

part 'rtvi_message_model.freezed.dart';
part 'rtvi_message_model.g.dart';

/// Data model for RTVI messages
@freezed
class RTVIMessageModel with _$RTVIMessageModel {
  const factory RTVIMessageModel({
    String? id,
    String? type,
    @Default({}) Map<String, dynamic> data,
    String? requestId,
    @Default(false) bool isResponse,
  }) = _RTVIMessageModel;

  factory RTVIMessageModel.fromJson(Map<String, dynamic> json) =>
      _$RTVIMessageModelFromJson(json);
}

/// Extension to convert between domain and data models
extension RTVIMessageModelExtension on RTVIMessageModel {
  RTVIMessage toDomain() {
    return RTVIMessage(
      id: id,
      type: type,
      data: data,
      requestId: requestId,
      isResponse: isResponse,
    );
  }
}

extension RTVIMessageExtension on RTVIMessage {
  RTVIMessageModel toModel() {
    return RTVIMessageModel(
      id: id,
      type: type,
      data: data,
      requestId: requestId,
      isResponse: isResponse,
    );
  }
}