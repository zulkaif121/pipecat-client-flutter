/**
 * Copyright (c) 2024, Daily.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import { RTVIEvent, RTVIEventHandler } from "@pipecat-ai/client-js";
import { useContext, useEffect } from "react";

import { EventContext } from "./RTVIClientProvider";

export const useRTVIClientEvent = <E extends RTVIEvent>(
  event: E,
  handler: RTVIEventHandler<E>
) => {
  const { on, off } = useContext(EventContext);

  useEffect(() => {
    on(event, handler);
    return () => {
      off(event, handler);
    };
  }, [event, handler, on, off]);
};
