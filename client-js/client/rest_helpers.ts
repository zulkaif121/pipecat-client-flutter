import * as RTVIErrors from "../rtvi/errors";
import { logger } from "./logger";
import { TransportConnectionParams } from "./transport";

export interface ConnectionEndpoint {
  endpoint: string;
  headers?: Headers;
  requestData?: object;
  timeout?: number;
}

export function isConnectionEndpoint(value: unknown): boolean {
  if (
    typeof value === "object" &&
    value !== null &&
    Object.keys(value).includes("endpoint")
  ) {
    return typeof (value as ConnectionEndpoint)["endpoint"] === "string";
  }
  return false;
}

export async function getTransportConnectionParams(
  cxnOpts: ConnectionEndpoint,
  abortController?: AbortController
): Promise<TransportConnectionParams> {
  if (!abortController) {
    abortController = new AbortController();
  }
  let handshakeTimeout: ReturnType<typeof setTimeout> | undefined;

  return new Promise((resolve, reject) => {
    (async () => {
      if (cxnOpts.timeout) {
        handshakeTimeout = setTimeout(async () => {
          abortController.abort();
          reject(new Error("Timed out"));
        }, cxnOpts.timeout);
      }

      logger.debug(
        `[PCI Transport] Fetching connection params from ${cxnOpts.endpoint}`
      );
      fetch(cxnOpts.endpoint, {
        method: "POST",
        mode: "cors",
        headers: new Headers({
          "Content-Type": "application/json",
          ...Object.fromEntries((cxnOpts.headers ?? new Headers()).entries()),
        }),
        body: JSON.stringify(cxnOpts.requestData),
        signal: abortController?.signal,
      })
        .then((res) => {
          logger.debug(
            `[PCI Transport] Received response from ${cxnOpts.endpoint}`,
            res
          );
          if (!res.ok) {
            throw res;
          }
          res.json().then((data) => resolve(data));
        })
        .catch((err) => {
          logger.error(
            `[PCI Transport] Error fetching connection params: ${err}`
          );
          if (err instanceof Response) {
            err.json().then((errResp) => {
              reject(
                new RTVIErrors.StartBotError(
                  errResp.info ?? errResp.detail ?? err.statusText,
                  err.status
                )
              );
            });
          } else {
            reject(new RTVIErrors.StartBotError());
          }
        })
        .finally(() => {
          if (handshakeTimeout) {
            clearTimeout(handshakeTimeout);
          }
        });
    })();
  });
}
