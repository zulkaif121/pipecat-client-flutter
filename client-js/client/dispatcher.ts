/**
 * Copyright (c) 2024, Daily.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import { RTVIMessage, RTVIMessageType } from "../rtvi";
import { logger } from "./logger";

interface QueuedRTVIMessage {
  message: RTVIMessage;
  timestamp: number;
  resolve: (value: unknown) => void;
  reject: (reason?: unknown) => void;
}

export class MessageDispatcher {
  protected _sendMethod: (message: RTVIMessage) => void;
  protected _gcTime: number;
  protected _queue = new Array<QueuedRTVIMessage>();

  constructor(sendMethod: (message: RTVIMessage) => void) {
    this._gcTime = 10000; // How long to wait before resolving the message
    this._queue = [];
    this._sendMethod = sendMethod;
  }

  public dispatch(
    message_data: unknown,
    type = RTVIMessageType.CLIENT_MESSAGE
  ): Promise<RTVIMessage> {
    const message = new RTVIMessage(type, message_data);
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
      this._sendMethod(message);
    } catch (e) {
      logger.error("[MessageDispatcher] Error sending message", e);
      return Promise.reject(e);
    }

    this._gc();

    return promise as Promise<RTVIMessage>;
  }

  public clearQueue() {
    // TODO: Should we reject all messages in the queue? (we weren't before)
    this._queue = [];
  }

  private _resolveReject(
    message: RTVIMessage,
    resolve: boolean = true
  ): RTVIMessage {
    const queuedMessage = this._queue.find(
      (msg) => msg.message.id === message.id
    );

    if (queuedMessage) {
      if (resolve) {
        logger.debug("[MessageDispatcher] Resolve", message);
        queuedMessage.resolve(message as RTVIMessage);
      } else {
        logger.debug("[MessageDispatcher] Reject", message);
        queuedMessage.reject(message as RTVIMessage);
      }
      // Remove message from queue
      this._queue = this._queue.filter((msg) => msg.message.id !== message.id);
      logger.debug("[MessageDispatcher] Queue", this._queue);
    }

    return message;
  }

  public resolve(message: RTVIMessage): RTVIMessage {
    return this._resolveReject(message, true);
  }

  public reject(message: RTVIMessage): RTVIMessage {
    return this._resolveReject(message, false);
  }

  protected _gc() {
    this._queue = this._queue.filter((msg) => {
      return Date.now() - msg.timestamp < this._gcTime;
    });
    logger.debug("[MessageDispatcher] GC", this._queue);
  }
}
