import { RTVIEvent, RTVIEventHandler } from "@pipecat-ai/client-js";
import { createContext } from "react";

export const RTVIEventContext = createContext<{
  on: <E extends RTVIEvent>(event: E, handler: RTVIEventHandler<E>) => void;
  off: <E extends RTVIEvent>(event: E, handler: RTVIEventHandler<E>) => void;
}>({
  on: () => {},
  off: () => {},
});
