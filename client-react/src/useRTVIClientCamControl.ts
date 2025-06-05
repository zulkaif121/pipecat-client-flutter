import { useCallback, useEffect, useState } from "react";

import { useRTVIClient } from "./useRTVIClient";
import { useRTVIClientTransportState } from "./useRTVIClientTransportState";

/**
 * Hook to control camera state
 */
export const useRTVIClientCamControl = () => {
  const client = useRTVIClient();

  const [isCamEnabled, setIsCamEnabled] = useState(
    client?.isCamEnabled ?? false
  );

  const transportState = useRTVIClientTransportState();

  // Sync component state with client state initially
  useEffect(() => {
    if (
      !client ||
      transportState !== "initialized" ||
      typeof client.isCamEnabled !== "boolean"
    )
      return;
    setIsCamEnabled(client.isCamEnabled);
  }, [client, transportState]);

  const enableCam = useCallback(
    (enabled: boolean) => {
      setIsCamEnabled(enabled);
      client?.enableCam?.(enabled);
    },
    [client]
  );

  return {
    enableCam,
    isCamEnabled,
  };
};
