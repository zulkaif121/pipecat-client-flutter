import { useCallback, useEffect, useState } from "react";

import { useRTVIClient } from "./useRTVIClient";

/**
 * Hook to control camera state
 */
export const useRTVIClientCamControl = () => {
  const client = useRTVIClient();

  const [isCamEnabled, setIsCamEnabled] = useState(
    client?.isCamEnabled ?? false
  );

  // Sync component state with client state initially
  useEffect(() => {
    if (!client) return;
    setIsCamEnabled(client.isCamEnabled);
  }, [client]);

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
