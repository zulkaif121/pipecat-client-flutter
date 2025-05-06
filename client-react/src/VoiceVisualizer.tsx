/**
 * Copyright (c) 2024, Daily.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import React, { useEffect, useRef } from "react";
import { useRTVIClientMediaTrack } from "./useRTVIClientMediaTrack";

type ParticipantType = Parameters<typeof useRTVIClientMediaTrack>[1];

interface Props {
  backgroundColor?: string;
  barColor?: string;
  barCount?: number;
  barGap?: number;
  barMaxHeight?: number;
  barWidth?: number;
  participantType: ParticipantType;
}

export const VoiceVisualizer: React.FC<Props> = React.memo(
  ({
    backgroundColor = "transparent",
    barColor = "black",
    barWidth = 30,
    barGap = 12,
    barMaxHeight = 120,
    barCount = 5,
    participantType,
  }) => {
    const canvasRef = useRef<HTMLCanvasElement>(null);

    const track: MediaStreamTrack | null = useRTVIClientMediaTrack(
      "audio",
      participantType
    );

    useEffect(() => {
      if (!canvasRef.current) return;

      const canvasWidth = barCount * barWidth + (barCount - 1) * barGap;
      const canvasHeight = barMaxHeight;

      const canvas = canvasRef.current;

      const scaleFactor = 2;

      // Make canvas fill the width and height of its container
      const resizeCanvas = () => {
        canvas.width = canvasWidth * scaleFactor;
        canvas.height = canvasHeight * scaleFactor;

        canvas.style.width = `${canvasWidth}px`;
        canvas.style.height = `${canvasHeight}px`;

        canvasCtx.lineCap = "round";
        canvasCtx.scale(scaleFactor, scaleFactor);
      };

      const canvasCtx = canvas.getContext("2d")!;
      resizeCanvas();

      if (!track) return;

      const audioContext = new AudioContext();
      const source = audioContext.createMediaStreamSource(
        new MediaStream([track])
      );
      const analyser = audioContext.createAnalyser();

      analyser.fftSize = 1024;

      source.connect(analyser);

      const frequencyData = new Uint8Array(analyser.frequencyBinCount);

      canvasCtx.lineCap = "round";

      // Create frequency bands based on barCount
      const bands = Array.from({ length: barCount }, (_, i) => {
        // Use improved logarithmic scale for better frequency distribution
        const minFreq = barCount > 20 ? 200 : 80; // Adjust min frequency based on bar count
        const maxFreq = 10000; // Cover most important audio frequencies

        // Use Mel scale inspired approach for more perceptually uniform distribution
        // This helps with a large number of bars by placing fewer in the very low range
        // https://en.wikipedia.org/wiki/Mel_scale
        const melMin = 2595 * Math.log10(1 + minFreq / 700);
        const melMax = 2595 * Math.log10(1 + maxFreq / 700);
        const melStep = (melMax - melMin) / barCount;

        const melValue = melMin + i * melStep;
        const startFreq = 700 * (Math.pow(10, melValue / 2595) - 1);
        const endFreq = 700 * (Math.pow(10, (melValue + melStep) / 2595) - 1);

        return {
          startFreq,
          endFreq,
          smoothValue: 0,
        };
      });

      const getFrequencyBinIndex = (frequency: number) => {
        const nyquist = audioContext.sampleRate / 2;
        return Math.round(
          (frequency / nyquist) * (analyser.frequencyBinCount - 1)
        );
      };

      function drawSpectrum() {
        analyser.getByteFrequencyData(frequencyData);
        canvasCtx.clearRect(
          0,
          0,
          canvas.width / scaleFactor,
          canvas.height / scaleFactor
        );
        canvasCtx.fillStyle = backgroundColor;
        canvasCtx.fillRect(
          0,
          0,
          canvas.width / scaleFactor,
          canvas.height / scaleFactor
        );

        let isActive = false;

        const totalBarsWidth =
          bands.length * barWidth + (bands.length - 1) * barGap;
        const startX = (canvas.width / scaleFactor - totalBarsWidth) / 2; // Center bars

        const adjustedCircleRadius = barWidth / 2; // Fixed radius for reset circles

        bands.forEach((band, i) => {
          const startIndex = getFrequencyBinIndex(band.startFreq);
          const endIndex = getFrequencyBinIndex(band.endFreq);
          const bandData = frequencyData.slice(startIndex, endIndex);
          const bandValue =
            bandData.reduce((acc, val) => acc + val, 0) / bandData.length;

          const smoothingFactor = 0.2;

          if (bandValue < 1) {
            band.smoothValue = Math.max(
              band.smoothValue - smoothingFactor * 5,
              0
            );
          } else {
            band.smoothValue =
              band.smoothValue +
              (bandValue - band.smoothValue) * smoothingFactor;
            isActive = true;
          }

          const x = startX + i * (barWidth + barGap);
          // Calculate bar height with a maximum cap
          const barHeight = Math.min(
            (band.smoothValue / 255) * barMaxHeight,
            barMaxHeight
          );

          const yTop = Math.max(
            canvas.height / scaleFactor / 2 - barHeight / 2,
            adjustedCircleRadius
          );
          const yBottom = Math.min(
            canvas.height / scaleFactor / 2 + barHeight / 2,
            canvas.height / scaleFactor - adjustedCircleRadius
          );

          if (band.smoothValue > 0) {
            canvasCtx.beginPath();
            canvasCtx.moveTo(x + barWidth / 2, yTop);
            canvasCtx.lineTo(x + barWidth / 2, yBottom);
            canvasCtx.lineWidth = barWidth;
            canvasCtx.strokeStyle = barColor;
            canvasCtx.stroke();
          } else {
            canvasCtx.beginPath();
            canvasCtx.arc(
              x + barWidth / 2,
              canvas.height / scaleFactor / 2,
              adjustedCircleRadius,
              0,
              2 * Math.PI
            );
            canvasCtx.fillStyle = barColor;
            canvasCtx.fill();
            canvasCtx.closePath();
          }
        });

        if (!isActive) {
          drawInactiveCircles(adjustedCircleRadius, barColor);
        }

        requestAnimationFrame(drawSpectrum);
      }

      function drawInactiveCircles(circleRadius: number, color: string) {
        const totalBarsWidth =
          bands.length * barWidth + (bands.length - 1) * barGap;
        const startX = (canvas.width / scaleFactor - totalBarsWidth) / 2;
        const y = canvas.height / scaleFactor / 2;

        bands.forEach((_, i) => {
          const x = startX + i * (barWidth + barGap);

          canvasCtx.beginPath();
          canvasCtx.arc(x + barWidth / 2, y, circleRadius, 0, 2 * Math.PI);
          canvasCtx.fillStyle = color;
          canvasCtx.fill();
          canvasCtx.closePath();
        });
      }

      drawSpectrum();

      // Handle resizing
      window.addEventListener("resize", resizeCanvas);

      return () => {
        audioContext.close();
        window.removeEventListener("resize", resizeCanvas);
      };
    }, [
      backgroundColor,
      barColor,
      barGap,
      barMaxHeight,
      barWidth,
      barCount,
      track,
    ]);

    return (
      <canvas
        ref={canvasRef}
        style={{
          display: "block",
          width: "100%",
          height: "100%",
        }}
      />
    );
  }
);

VoiceVisualizer.displayName = "VoiceVisualizer";
