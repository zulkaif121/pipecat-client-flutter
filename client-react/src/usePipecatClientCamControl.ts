/**
 * Copyright (c) 2024, Daily.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */
import { useContext } from "react";

import { PipecatClientCamStateContext } from "./PipecatClientState";

/**
 * Hook to control camera state
 */
export const usePipecatClientCamControl = () =>
  useContext(PipecatClientCamStateContext);
