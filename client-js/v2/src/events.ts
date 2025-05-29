/**
 * Copyright (c) 2024, Daily.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import {
  BotLLMTextData,
  BotReadyData,
  BotTTSTextData,
  LLMFunctionCallData,
  PipecatMetricsData,
  PCIMessage,
  TranscriptData,
} from "./messages";
import { Participant, TransportState } from "./transport";

export enum PCIEvent {
  /** local connection state events */
  Connected = "connected",
  Disconnected = "disconnected",
  TransportStateChanged = "transportStateChanged",

  BotConnected = "botConnected",
  BotReady = "botReady",
  BotDisconnected = "botDisconnected",
  Error = "error",

  /** server messaging */
  ServerMessage = "serverMessage",
  ServerResponse = "serverResponse",
  MessageError = "messageError",

  /** service events */
  Metrics = "metrics",

  // vad events
  BotStartedSpeaking = "botStartedSpeaking",
  BotStoppedSpeaking = "botStoppedSpeaking",
  UserStartedSpeaking = "userStartedSpeaking",
  UserStoppedSpeaking = "userStoppedSpeaking",

  // stt events
  UserTranscript = "userTranscript",
  BotTranscript = "botTranscript",

  // llm events
  BotLlmText = "botLlmText",
  BotLlmStarted = "botLlmStarted",
  BotLlmStopped = "botLlmStopped",

  LLMFunctionCall = "llmFunctionCall",

  // tts events
  BotTtsText = "botTtsText",
  BotTtsStarted = "botTtsStarted",
  BotTtsStopped = "botTtsStopped",

  /** participant events */
  ParticipantConnected = "participantConnected",
  ParticipantLeft = "participantLeft",

  /** media events */
  TrackStarted = "trackStarted",
  TrackStopped = "trackStopped",
  ScreenTrackStarted = "screenTrackStarted",
  ScreenTrackStopped = "screenTrackStopped",
  ScreenShareError = "screenShareError",

  LocalAudioLevel = "localAudioLevel",
  RemoteAudioLevel = "remoteAudioLevel",

  /** media device events */
  AvailableCamsUpdated = "availableCamsUpdated",
  AvailableMicsUpdated = "availableMicsUpdated",
  AvailableSpeakersUpdated = "availableSpeakersUpdated",
  CamUpdated = "camUpdated",
  MicUpdated = "micUpdated",
  SpeakerUpdated = "speakerUpdated",
}

export type PCIEvents = Partial<{
  /** local connection state events */
  connected: () => void;
  disconnected: () => void;
  transportStateChanged: (state: TransportState) => void;

  /** remote connection state events */
  botConnected: (participant: Participant) => void;
  botReady: (botData: BotReadyData) => void;
  botDisconnected: (participant: Participant) => void;
  error: (message: PCIMessage) => void;

  /** server messaging */
  serverMessage: (data: any) => void;
  serverResponse: (data: any) => void;
  messageError: (message: PCIMessage) => void;

  /** service events */
  metrics: (data: PipecatMetricsData) => void;

  // vad events
  botStartedSpeaking: () => void;
  botStoppedSpeaking: () => void;
  userStartedSpeaking: () => void;
  userStoppedSpeaking: () => void;

  // stt events
  userTranscript: (data: TranscriptData) => void;
  botTranscript: (data: BotLLMTextData) => void;

  // llm events
  botLlmText: (data: BotLLMTextData) => void;
  botLlmStarted: () => void;
  botLlmStopped: () => void;

  llmFunctionCall: (func: LLMFunctionCallData) => void;

  // tts events
  botTtsText: (data: BotTTSTextData) => void;
  botTtsStarted: () => void;
  botTtsStopped: () => void;

  /** participant events */
  participantConnected: (participant: Participant) => void;
  participantLeft: (participant: Participant) => void;

  /** media events */
  trackStarted: (track: MediaStreamTrack, participant?: Participant) => void;
  trackStopped: (track: MediaStreamTrack, participant?: Participant) => void;
  screenTrackStarted: (track: MediaStreamTrack, p?: Participant) => void;
  screenTrackStopped: (track: MediaStreamTrack, p?: Participant) => void;
  screenShareError: (errorMessage: string) => void;

  localAudioLevel: (level: number) => void;
  remoteAudioLevel: (level: number, p: Participant) => void;

  /** media device events */
  availableCamsUpdated: (cams: MediaDeviceInfo[]) => void;
  availableMicsUpdated: (mics: MediaDeviceInfo[]) => void;
  availableSpeakersUpdated: (speakers: MediaDeviceInfo[]) => void;
  camUpdated: (cam: MediaDeviceInfo) => void;
  micUpdated: (mic: MediaDeviceInfo) => void;
  speakerUpdated: (speaker: MediaDeviceInfo) => void;
}>;

export type PCIEventHandler<E extends PCIEvent> = E extends keyof PCIEvents
  ? PCIEvents[E]
  : never;
