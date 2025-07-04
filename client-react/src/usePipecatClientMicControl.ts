/**
 * Copyright (c) 2024, Daily.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import { useContext } from "react";

import { PipecatClientMicStateContext } from "./PipecatClientState";

/**
 * Hook to control microphone state
 */
export const useRTVIClientMicControl = () =>
  useContext(PipecatClientMicStateContext);
