/**
 * Copyright (c) 2024, Daily.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

export class PCIError extends Error {
  readonly status: number | undefined;

  constructor(message?: string, status?: number | undefined) {
    super(message);
    this.status = status;
  }
}

export class ConnectionTimeoutError extends PCIError {
  constructor(message?: string | undefined) {
    super(
      message ??
        "Bot did not enter ready state within the specified timeout period."
    );
  }
}

export class StartBotError extends PCIError {
  readonly error: string = "invalid-request-error";
  constructor(message?: string | undefined, status?: number) {
    super(
      message ?? `Failed to connect / invalid auth bundle from base url`,
      status ?? 500
    );
  }
}

export class TransportStartError extends PCIError {
  constructor(message?: string | undefined) {
    super(message ?? "Unable to connect to transport");
  }
}

export class BotNotReadyError extends PCIError {
  constructor(message?: string | undefined) {
    super(
      message ??
        "Attempt to call action on transport when not in 'ready' state."
    );
  }
}

export class UnsupportedFeatureError extends PCIError {
  constructor(feature: string, source?: string, message?: string) {
    let msg = `${feature} not supported${message ? `: ${message}` : ""}`;
    if (source) {
      msg = `${source} does not support ${feature}${
        message ? `: ${message}` : ""
      }`;
    }
    super(msg);
  }
}
