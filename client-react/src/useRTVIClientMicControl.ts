import { useCallback, useEffect, useState } from "react";

import { useRTVIClient } from "./useRTVIClient";
import { useRTVIClientTransportState } from "./useRTVIClientTransportState";

/**
 * Hook to control microphone state
 */
export const useRTVIClientMicControl = () => {
  const client = useRTVIClient();

  const [isMicEnabled, setIsMicEnabled] = useState(
    client?.isMicEnabled ?? false
  );

  const transportState = useRTVIClientTransportState();

  // Sync component state with client state initially
  useEffect(() => {
    if (
      !client ||
      transportState !== "initialized" ||
      typeof client.isMicEnabled !== "boolean"
    )
      return;
    setIsMicEnabled(client.isMicEnabled);
  }, [client, transportState]);

  const enableMic = useCallback(
    (enabled: boolean) => {
      setIsMicEnabled(enabled);
      client?.enableMic?.(enabled);
    },
    [client]
  );

  return {
    enableMic,
    isMicEnabled,
  };
};
