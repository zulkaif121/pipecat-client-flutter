/**
 * Copyright (c) 2024, Daily.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import { v4 as uuidv4 } from "uuid";

import { logger } from "./logger";
import { Transport } from "./transport";

export const PCI_MESSAGE_LABEL = "rtvi-ai";

/**
 * Messages the corresponding server-side client expects to receive about
 * our client-side state.
 */
export enum OutboundMessageTypes {
  CLIENT_READY = "client-ready",
  DISCONNECT_BOT = "disconnect-bot",
  // Client-to-server messages
  CLIENT_MESSAGE = "client-message",
  APPEND_TO_CONTEXT = "append-to-context",
}

/**
 * Messages the server-side client sends to our client-side client regarding
 * its state or other non-service-specific messaging.
 */
export enum InboundMessageTypes {
  BOT_READY = "bot-ready", // Bot is connected and ready to receive messages
  ERROR = "error", // Bot initialization error
  METRICS = "metrics", // PCI reporting metrics
  SERVER_MESSAGE = "server-message", // Custom server-to-client message
  SERVER_RESPONSE = "server-response", // Server response to client message
  ERROR_RESPONSE = "error-response", // Error message in response to an outbound message
  APPEND_TO_CONTEXT_RESULT = "append-to-context-result", // Result of appending to context
}

export enum TranscriptionMessageTypes {
  USER_TRANSCRIPTION = "user-transcription", // Local user speech to text transcription (partials and finals)
  BOT_TRANSCRIPTION = "bot-transcription", // Bot full text transcription (sentence aggregated)
  USER_STARTED_SPEAKING = "user-started-speaking", // User started speaking
  USER_STOPPED_SPEAKING = "user-stopped-speaking", // User stopped speaking
  BOT_STARTED_SPEAKING = "bot-started-speaking", // Bot started speaking
  BOT_STOPPED_SPEAKING = "bot-stopped-speaking", // Bot stopped speaking
}

export enum LLMMessageTypes {
  USER_LLM_TEXT = "user-llm-text", // Aggregated user input text which is sent to LLM
  BOT_LLM_TEXT = "bot-llm-text", // Streamed token returned by the LLM
  BOT_LLM_STARTED = "bot-llm-started", // Bot LLM inference starts
  BOT_LLM_STOPPED = "bot-llm-stopped", // Bot LLM inference stops

  // Function calling
  LLM_FUNCTION_CALL = "llm-function-call", // Inbound function call from LLM
  LLM_FUNCTION_CALL_RESULT = "llm-function-call-result", // Outbound result of function call
}

export enum TTSMessageTypes {
  BOT_TTS_TEXT = "bot-tts-text", // Bot TTS text output (streamed word as it is spoken)
  BOT_TTS_STARTED = "bot-tts-started", // Bot TTS response starts
  BOT_TTS_STOPPED = "bot-tts-stopped", // Bot TTS response stops
}

export const PCIMessageType = {
  ...OutboundMessageTypes,
  ...InboundMessageTypes,
  ...TranscriptionMessageTypes,
  ...LLMMessageTypes,
  ...TTSMessageTypes,
};

// ----- Message Data Types

export type BotReadyData = {
  version: string;
};

export type ErrorData = {
  message: string;
  fatal: boolean;
};

export type PipecatMetricData = {
  processor: string;
  value: number;
};

export type PipecatMetricsData = {
  processing?: PipecatMetricData[];
  ttfb?: PipecatMetricData[];
  characters?: PipecatMetricData[];
};

export type TranscriptData = {
  text: string;
  final: boolean;
  timestamp: string;
  user_id: string;
};

export type BotLLMTextData = {
  text: string;
};

export type BotTTSTextData = {
  text: string;
};

export type ServerMessageData = {
  data: any;
};

export type LLMFunctionCallData = {
  function_name: string;
  tool_call_id: string;
  args: Record<string, unknown>;
};

export type LLMFunctionCallResult = Record<string, unknown> | string;

export type LLMFunctionCallResultResponse = {
  function_name: string;
  tool_call_id: string;
  args: Record<string, unknown>;
  result: LLMFunctionCallResult;
};

export type LLMContextMessage = {
  role: "user" | "assistant";
  content: unknown;
  runImmediately?: boolean;
};

export type AppendToContextResultData = {
  result: Record<string, unknown> | string;
};

// ----- Message Classes

export class PCIMessage {
  id: string;
  label: string = PCI_MESSAGE_LABEL;
  type: string;
  data: unknown;

  constructor(type: string, data: unknown, id?: string) {
    this.type = type;
    this.data = data;
    this.id = id || uuidv4().slice(0, 8);
  }

  // Outbound message types
  static clientReady(): PCIMessage {
    return new PCIMessage(PCIMessageType.CLIENT_READY, {});
  }

  static disconnectBot(): PCIMessage {
    return new PCIMessage(PCIMessageType.DISCONNECT_BOT, {});
  }

  static error(message: string, fatal = false): PCIMessage {
    return new PCIMessage(PCIMessageType.ERROR, { message, fatal });
  }
}

// ----- Message Dispatcher

interface QueuedPCIMessage {
  message: PCIMessage;
  timestamp: number;
  resolve: (value: unknown) => void;
  reject: (reason?: unknown) => void;
}

export class MessageDispatcher {
  private _transport: Transport;
  private _gcTime: number;
  private _queue = new Array<QueuedPCIMessage>();

  constructor(transport: Transport) {
    this._gcTime = 10000; // How long to wait before resolving the message
    this._queue = [];
    this._transport = transport;
  }

  public dispatch(
    message_data: unknown,
    type = PCIMessageType.CLIENT_MESSAGE
  ): Promise<PCIMessage> {
    const message = new PCIMessage(type, message_data);
    const promise = new Promise((resolve, reject) => {
      this._queue.push({
        message,
        timestamp: Date.now(),
        resolve,
        reject,
      });
    });

    logger.debug("[MessageDispatcher] dispatch", message);

    try {
      this._transport.sendMessage(message);
    } catch (e) {
      logger.error("[MessageDispatcher] Error sending message", e);
      return Promise.reject(e);
    }

    this._gc();

    return promise as Promise<PCIMessage>;
  }

  public clearQueue() {
    // TODO: Should we reject all messages in the queue? (we weren't before)
    this._queue = [];
  }

  private _resolveReject(
    message: PCIMessage,
    resolve: boolean = true
  ): PCIMessage {
    const queuedMessage = this._queue.find(
      (msg) => msg.message.id === message.id
    );

    if (queuedMessage) {
      if (resolve) {
        logger.debug("[MessageDispatcher] Resolve", message);
        queuedMessage.resolve(message as PCIMessage);
      } else {
        logger.debug("[MessageDispatcher] Reject", message);
        queuedMessage.reject(message as PCIMessage);
      }
      // Remove message from queue
      this._queue = this._queue.filter((msg) => msg.message.id !== message.id);
      logger.debug("[MessageDispatcher] Queue", this._queue);
    }

    return message;
  }

  public resolve(message: PCIMessage): PCIMessage {
    return this._resolveReject(message, true);
  }

  public reject(message: PCIMessage): PCIMessage {
    return this._resolveReject(message, false);
  }

  private _gc() {
    this._queue = this._queue.filter((msg) => {
      return Date.now() - msg.timestamp < this._gcTime;
    });
    logger.debug("[MessageDispatcher] GC", this._queue);
  }
}
