import { useCallback, useEffect, useState } from "react";

import { useRTVIClient } from "./useRTVIClient";

/**
 * Hook to control microphone state
 */
export const useRTVIClientMicControl = () => {
  const client = useRTVIClient();

  const [isMicEnabled, setIsMicEnabled] = useState(
    client?.isMicEnabled ?? false
  );

  // Sync component state with client state initially
  useEffect(() => {
    if (!client) return;
    setIsMicEnabled(client.isMicEnabled);
  }, [client]);

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
