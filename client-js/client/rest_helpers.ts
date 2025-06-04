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

export async function getDailyRoomAndToken(
  params: ConnectionEndpoint,
  abortController?: AbortController
): Promise<TransportConnectionParams> {
  if (!abortController) {
    abortController = new AbortController();
  }
  let handshakeTimeout: ReturnType<typeof setTimeout> | undefined;

  return new Promise((resolve, reject) => {
    (async () => {
      if (params.timeout) {
        handshakeTimeout = setTimeout(async () => {
          abortController.abort();
          reject(new Error("Timed out"));
        }, params.timeout);
      }

      console.log(
        `[PCI Transport] Fetching room and token from ${params.endpoint}`
      );
      fetch(params.endpoint, {
        method: "POST",
        mode: "cors",
        headers: new Headers({
          "Content-Type": "application/json",
          ...Object.fromEntries((params.headers ?? new Headers()).entries()),
        }),
        body: JSON.stringify(params.requestData),
        signal: abortController?.signal,
      })
        .then((res) => {
          console.log(
            `[PCI Transport] Received response from ${params.endpoint}`
          );
          if (!res.ok) {
            throw new Error(
              `Error fetching room and token: ${res.status} ${res.statusText}`
            );
          }
          res.json().then((data) => {
            if (data.room_url) {
              data.url = data.room_url;
              delete data.room_url;
            }
            if (!data.token) {
              // Daily doesn't like token being in the map and undefined or null
              delete data.token;
            }
            console.log("resolve", data);
            resolve(data);
          });
        })
        .catch((err) => {
          console.error(
            `[PCI Transport] Error fetching room and token: ${err}`
          );
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
