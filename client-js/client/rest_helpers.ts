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
