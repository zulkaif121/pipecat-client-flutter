/**
 * Copyright (c) 2024, Daily.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import { useContext } from "react";

import { PipecatClientTransportStateContext } from "./PipecatClientState";

export const usePipecatClientTransportState = () =>
  useContext(PipecatClientTransportStateContext);
