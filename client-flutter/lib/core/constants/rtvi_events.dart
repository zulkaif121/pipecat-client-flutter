/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

/// Enumeration of RTVI events that can occur during client operation
enum RTVIEvent {
  // Local connection state events
  connected('connected'),
  disconnected('disconnected'),
  transportStateChanged('transportStateChanged'),

  // Remote connection state events
  botConnected('botConnected'),
  botReady('botReady'),
  botDisconnected('botDisconnected'),
  error('error'),

  // Server messaging
  serverMessage('serverMessage'),
  serverResponse('serverResponse'),
  messageError('messageError'),

  // Service events
  metrics('metrics'),

  // VAD events
  botStartedSpeaking('botStartedSpeaking'),
  botStoppedSpeaking('botStoppedSpeaking'),
  userStartedSpeaking('userStartedSpeaking'),
  userStoppedSpeaking('userStoppedSpeaking'),

  // STT events
  userTranscript('userTranscript'),
  botTranscript('botTranscript'),

  // LLM events
  botLLMText('botLLMText'),
  botLLMSearchResponse('botLLMSearchResponse'),
  llmFunctionCall('llmFunctionCall'),

  // TTS events
  botTTSText('botTTSText'),

  // Audio events
  botAudio('botAudio'),

  // Media device events
  availableCamsUpdated('availableCamsUpdated'),
  availableMicsUpdated('availableMicsUpdated'),
  camUpdated('camUpdated'),
  micUpdated('micUpdated'),

  // Track events
  trackStarted('trackStarted'),
  trackStopped('trackStopped');

  const RTVIEvent(this.value);
  
  final String value;
  
  @override
  String toString() => value;
}