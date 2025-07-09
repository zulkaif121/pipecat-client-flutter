/**
 * Copyright (c) 2024, Daily.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import { RTVIEvent, TransportState } from "@pipecat-ai/client-js";
import React, { createContext, useCallback, useState } from "react";

import { usePipecatClient } from "./usePipecatClient";
import { useRTVIClientEvent } from "./useRTVIClientEvent";

export const PipecatClientCamStateContext = createContext<{
  enableCam: (enabled: boolean) => void;
  isCamEnabled: boolean;
}>({
  enableCam: () => {
    throw new Error(
      "PipecatClientCamStateContext: enableCam() called outside of provider"
    );
  },
  isCamEnabled: false,
});
export const PipecatClientMicStateContext = createContext<{
  enableMic: (enabled: boolean) => void;
  isMicEnabled: boolean;
}>({
  enableMic: () => {
    throw new Error(
      "PipecatClientMicStateContext: enableMic() called outside of provider"
    );
  },
  isMicEnabled: false,
});
export const PipecatClientTransportStateContext =
  createContext<TransportState>("disconnected");

export const PipecatClientStateProvider: React.FC<React.PropsWithChildren> = ({
  children,
}) => {
  const client = usePipecatClient();
  const [isCamEnabled, setIsCamEnabled] = useState(false);
  const [isMicEnabled, setIsMicEnabled] = useState(false);
  const [transportState, setTransportState] =
    useState<TransportState>("disconnected");

  useRTVIClientEvent(RTVIEvent.TransportStateChanged, (state) => {
    setTransportState(state);
    if (state === "initialized" && client) {
      setIsCamEnabled(client.isCamEnabled ?? false);
      setIsMicEnabled(client.isMicEnabled ?? false);
    }
  });

  const enableCam = useCallback(
    (enabled: boolean) => {
      setIsCamEnabled(enabled);
      client?.enableCam?.(enabled);
    },
    [client]
  );

  const enableMic = useCallback(
    (enabled: boolean) => {
      setIsMicEnabled(enabled);
      client?.enableMic?.(enabled);
    },
    [client]
  );

  return (
    <PipecatClientTransportStateContext.Provider value={transportState}>
      <PipecatClientCamStateContext.Provider
        value={{ enableCam, isCamEnabled }}
      >
        <PipecatClientMicStateContext.Provider
          value={{ enableMic, isMicEnabled }}
        >
          {children}
        </PipecatClientMicStateContext.Provider>
      </PipecatClientCamStateContext.Provider>
    </PipecatClientTransportStateContext.Provider>
  );
};
