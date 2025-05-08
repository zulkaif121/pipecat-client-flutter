import React, { useCallback } from "react";
import { useRTVIClientCamControl } from "./useRTVIClientCamControl";

export interface RTVIClientCamToggleProps {
  /**
   * Callback fired when camera state changes
   */
  onCamEnabledChanged?: (enabled: boolean) => void;

  /**
   * Optional prop to disable the cam toggle.
   * When disabled, changes are not applied to the client.
   * @default false
   */
  disabled?: boolean;

  /**
   * Render prop that provides state and handlers to the children
   */
  children: (props: {
    disabled?: boolean;
    isCamEnabled: boolean;
    onClick: () => void;
  }) => React.ReactNode;
}

/**
 * Headless component for controlling camera state
 */
export const RTVIClientCamToggle: React.FC<RTVIClientCamToggleProps> = ({
  onCamEnabledChanged,
  disabled = false,
  children,
}) => {
  const { isCamEnabled, enableCam } = useRTVIClientCamControl();

  const handleToggleCam = useCallback(() => {
    if (disabled) return;

    const newEnabledState = !isCamEnabled;
    enableCam(newEnabledState);
    onCamEnabledChanged?.(newEnabledState);
  }, [disabled, isCamEnabled, onCamEnabledChanged]);

  return (
    <>
      {children({
        isCamEnabled,
        onClick: handleToggleCam,
        disabled,
      })}
    </>
  );
};

export default RTVIClientCamToggle;
