import { logger } from "./logger";

type Serializable =
  | string
  | number
  | boolean
  | null
  | Serializable[]
  | { [key: number | string]: Serializable };

export interface APIRequest {
  endpoint: string | URL | globalThis.Request;
  headers?: Headers;
  requestData?: Serializable;
  timeout?: number;
}

/**
 * @deprecated Use APIRequest instead
 */
export type ConnectionEndpoint = APIRequest;

export function isAPIRequest(value: unknown): boolean {
  if (
    typeof value === "object" &&
    value !== null &&
    Object.keys(value).includes("endpoint")
  ) {
    const endpoint = (value as APIRequest)["endpoint"];
    return (
      typeof endpoint === "string" ||
      endpoint instanceof URL ||
      (typeof Request !== "undefined" && endpoint instanceof Request)
    );
  }
  return false;
}

export async function makeRequest(
  cxnOpts: APIRequest,
  abortController?: AbortController
): Promise<unknown> {
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

      logger.debug(`[Pipecat Client] Fetching from ${cxnOpts.endpoint}`);
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
            `[Pipecat Client] Received response from ${cxnOpts.endpoint}`,
            res
          );
          if (!res.ok) {
            reject(res);
          }
          res.json().then((data) => resolve(data));
        })
        .catch((err) => {
          logger.error(`[Pipecat Client] Error fetching: ${err}`);
          reject(err);
        })
        .finally(() => {
          if (handshakeTimeout) {
            clearTimeout(handshakeTimeout);
          }
        });
    })();
  });
}
