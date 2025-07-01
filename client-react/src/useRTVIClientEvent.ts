/**
 * Copyright (c) 2024, Daily.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import { RTVIEvent, RTVIEventHandler } from "@pipecat-ai/client-js";
import { useContext, useEffect } from "react";

import { EventContext } from "./RTVIClientProvider";

let keyCounter = 0;
const uniqueKey = () => {
  return keyCounter++;
};

export const useRTVIClientEvent = <E extends RTVIEvent>(
  event: E,
  handler: RTVIEventHandler<E>
) => {
  const { on, off } = useContext(EventContext);

  useEffect(() => {
    const key = uniqueKey();
    on(event, handler, key);
    return () => {
      off(event, key);
    };
  }, [event, handler, on, off]);
};
