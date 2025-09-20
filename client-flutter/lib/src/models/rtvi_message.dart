/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

enum RTVIMessageType {
  clientReady('client-ready'),
  botReady('bot-ready'),
  userStartedSpeaking('user-started-speaking'),
  userStoppedSpeaking('user-stopped-speaking'),
  botStartedSpeaking('bot-started-speaking'),
  botStoppedSpeaking('bot-stopped-speaking'),
  userTranscript('user-transcript'),
  botTranscript('bot-transcript'),
  error('error'),
  serverResponse('server-response'),
  errorResponse('error-response');

  const RTVIMessageType(this.value);
  final String value;
}

class RTVIMessage {
  final RTVIMessageType type;
  final Map<String, dynamic> data;
  final String? id;

  const RTVIMessage({
    required this.type,
    required this.data,
    this.id,
  });

  factory RTVIMessage.fromJson(Map<String, dynamic> json) {
    final typeValue = json['type'] as String?;
    final type = RTVIMessageType.values.firstWhere(
      (t) => t.value == typeValue,
      orElse: () => RTVIMessageType.error,
    );

    return RTVIMessage(
      type: type,
      data: json['data'] as Map<String, dynamic>? ?? {},
      id: json['id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'data': data,
      if (id != null) 'id': id,
    };
  }

  static RTVIMessage clientReady() {
    return const RTVIMessage(
      type: RTVIMessageType.clientReady,
      data: {},
    );
  }
}