/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

import '../models/rtvi_message.dart';
import '../models/transport_state.dart';
import '../models/participant.dart';
import '../models/transcript_data.dart';

abstract class PipecatEventCallbacks {
  void onConnected() {}
  void onDisconnected() {}
  void onError(RTVIMessage message) {}
  void onTransportStateChanged(TransportState state) {}
  
  void onBotReady(Map<String, dynamic> data) {}
  void onBotConnected(Participant participant) {}
  void onBotDisconnected(Participant participant) {}
  
  void onUserStartedSpeaking() {}
  void onUserStoppedSpeaking() {}
  void onBotStartedSpeaking() {}
  void onBotStoppedSpeaking() {}
  
  void onUserTranscript(TranscriptData data) {}
  void onBotTranscript(BotLLMTextData data) {}
  
  void onMessageError(RTVIMessage message) {}
}