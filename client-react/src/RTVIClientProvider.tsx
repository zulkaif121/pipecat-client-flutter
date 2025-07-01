/**
 * Copyright (c) 2024, Daily.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import { RTVIClient, RTVIEvent, RTVIEventHandler } from "@pipecat-ai/client-js";
import { createStore } from "jotai";
import { Provider as JotaiProvider } from "jotai/react";
import React, { createContext, useCallback, useEffect, useRef } from "react";

export interface Props {
  client: RTVIClient;
  jotaiStore?: React.ComponentProps<typeof JotaiProvider>["store"];
}

const defaultStore = createStore();

export const RTVIClientContext = createContext<{ client?: RTVIClient }>({});

type EventHandlersMap = Partial<{
  [E in RTVIEvent]: Map<number, RTVIEventHandler<E>>;
}>;

export const RTVIClientProvider: React.FC<React.PropsWithChildren<Props>> = ({
  children,
  client,
  jotaiStore = defaultStore,
}) => {
  const eventHandlersMap = useRef<EventHandlersMap>({});

  const handleEvent = useCallback(
    <E extends RTVIEvent>(
      event: E,
      ...payload: Parameters<RTVIEventHandler<E>>
    ) => {
      const handlers = eventHandlersMap.current[event];
      if (!handlers) return;
      Array.from(handlers.values()).forEach((h) => {
        (h as (...args: Parameters<RTVIEventHandler<E>>) => void)(...payload);
      });
    },
    []
  );

  const registeredEvents = useRef<RTVIEvent[]>([]);

  useEffect(
    function initEventHandlers() {
      if (!client) return;
      const events = Object.keys(eventHandlersMap.current ?? {}) as RTVIEvent[];
      const wrappedHandlers = events.map((event) => {
        // @ts-expect-error RTVIEventHandler type is not generic
        return (...payload: Parameters<RTVIEventHandler<typeof event>>) =>
          handleEvent(event, ...payload);
      });
      events.forEach((event, i) => {
        if (registeredEvents.current.includes(event)) return;
        registeredEvents.current.push(event);
        client.on(event as RTVIEvent, wrappedHandlers[i]);
      });
    },
    [client, handleEvent]
  );

  const on = useCallback(
    <E extends RTVIEvent>(
      event: E,
      handler: RTVIEventHandler<E>,
      key: number
    ) => {
      if (!client) return;
      if (!eventHandlersMap.current[event]) {
        eventHandlersMap.current[event] = new Map();
      }
      eventHandlersMap.current[event].set(key, handler);
      if (registeredEvents.current.includes(event)) return;
      registeredEvents.current.push(event);
      const wrappedHandler = (...payload: Parameters<RTVIEventHandler<E>>) =>
        handleEvent(event, ...payload);
      client.on(event as RTVIEvent, wrappedHandler);
    },
    [client, handleEvent]
  );

  const off = useCallback(<E extends RTVIEvent>(event: E, key: number) => {
    if (!eventHandlersMap.current[event]) return;
    eventHandlersMap.current[event].delete(key);
  }, []);

  return (
    <JotaiProvider store={jotaiStore}>
      <RTVIClientContext.Provider value={{ client }}>
        <EventContext.Provider value={{ on, off }}>
          {children}
        </EventContext.Provider>
      </RTVIClientContext.Provider>
    </JotaiProvider>
  );
};
RTVIClientProvider.displayName = "RTVIClientProvider";

export const EventContext = createContext<{
  on: <E extends RTVIEvent>(
    event: E,
    handler: RTVIEventHandler<E>,
    key: number
  ) => void;
  off: <E extends RTVIEvent>(event: E, key: number) => void;
}>({
  on: () => {},
  off: () => {},
});
