/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

class TranscriptData {
  final String text;
  final bool final_;
  final int? timestamp;

  const TranscriptData({
    required this.text,
    required this.final_,
    this.timestamp,
  });

  factory TranscriptData.fromJson(Map<String, dynamic> json) {
    return TranscriptData(
      text: json['text'] as String? ?? '',
      final_: json['final'] as bool? ?? false,
      timestamp: json['timestamp'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'final': final_,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }
}

class BotLLMTextData {
  final String text;
  final int? timestamp;

  const BotLLMTextData({
    required this.text,
    this.timestamp,
  });

  factory BotLLMTextData.fromJson(Map<String, dynamic> json) {
    return BotLLMTextData(
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }
}