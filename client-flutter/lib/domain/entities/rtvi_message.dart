/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:freezed_annotation/freezed_annotation.dart';

part 'rtvi_message.freezed.dart';
part 'rtvi_message.g.dart';

/// Represents a message in the RTVI protocol
@freezed
class RTVIMessage with _$RTVIMessage {
  const factory RTVIMessage({
    String? id,
    String? type,
    @Default({}) Map<String, dynamic> data,
    String? requestId,
    @Default(false) bool isResponse,
  }) = _RTVIMessage;

  factory RTVIMessage.fromJson(Map<String, dynamic> json) =>
      _$RTVIMessageFromJson(json);
}

/// Message types used in RTVI protocol
class RTVIMessageType {
  static const String action = 'action';
  static const String response = 'response';
  static const String error = 'error';
  static const String event = 'event';
  static const String setupComplete = 'setup-complete';
  static const String botReady = 'bot-ready';
  static const String metrics = 'metrics';
  static const String transcript = 'transcript';
}

/// Helper functions for creating common message types
extension RTVIMessageHelpers on RTVIMessage {
  static RTVIMessage action({
    required String action,
    Map<String, dynamic>? data,
    String? requestId,
  }) {
    return RTVIMessage(
      id: requestId ?? _generateId(),
      type: RTVIMessageType.action,
      data: {
        'action': action,
        if (data != null) ...data,
      },
      requestId: requestId,
    );
  }

  static RTVIMessage response({
    required String requestId,
    Map<String, dynamic>? data,
  }) {
    return RTVIMessage(
      id: _generateId(),
      type: RTVIMessageType.response,
      data: data ?? {},
      requestId: requestId,
      isResponse: true,
    );
  }

  static RTVIMessage error({
    required String error,
    String? requestId,
    Map<String, dynamic>? details,
  }) {
    return RTVIMessage(
      id: _generateId(),
      type: RTVIMessageType.error,
      data: {
        'error': error,
        if (details != null) ...details,
      },
      requestId: requestId,
    );
  }
  
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}