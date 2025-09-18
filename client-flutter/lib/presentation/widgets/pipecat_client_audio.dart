/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pipecat_client_provider.dart';

/// Widget for displaying audio visualization and controls
class PipecatClientAudio extends StatefulWidget {
  const PipecatClientAudio({
    super.key,
    this.showControls = true,
    this.showVisualization = true,
  });

  final bool showControls;
  final bool showVisualization;

  @override
  State<PipecatClientAudio> createState() => _PipecatClientAudioState();
}

class _PipecatClientAudioState extends State<PipecatClientAudio> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PipecatClientProvider>(
      builder: (context, client, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.volume_up,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Audio',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                if (widget.showVisualization) ...[
                  const SizedBox(height: 16),
                  _buildAudioVisualization(context, client),
                ],
                if (widget.showControls) ...[
                  const SizedBox(height: 16),
                  _buildAudioControls(context, client),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioVisualization(BuildContext context, PipecatClientProvider client) {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: StreamBuilder<bool>(
        stream: client.audioPlaybackStream,
        initialData: false,
        builder: (context, audioSnapshot) {
          final isConnected = client.isConnected;
          final isPlayingAudio = audioSnapshot.data ?? false;

          return StreamBuilder(
            stream: client.eventStream,
            builder: (context, eventSnapshot) {
              return Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isConnected
                        ? (isPlayingAudio ? 'Playing Audio' : 'Connected - Ready')
                        : 'Disconnected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isConnected
                          ? (isPlayingAudio ? Colors.green : Colors.blue)
                          : Colors.red,
                      ),
                    ),
                    if (isConnected) ...[
                      const SizedBox(width: 16),
                      _AudioBar(height: isPlayingAudio ? 40 : 20, isActive: isPlayingAudio),
                      const SizedBox(width: 4),
                      _AudioBar(height: isPlayingAudio ? 35 : 15, isActive: isPlayingAudio),
                      const SizedBox(width: 4),
                      _AudioBar(height: isPlayingAudio ? 45 : 25, isActive: isPlayingAudio),
                      const SizedBox(width: 4),
                      _AudioBar(height: isPlayingAudio ? 30 : 18, isActive: isPlayingAudio),
                      const SizedBox(width: 4),
                      _AudioBar(height: isPlayingAudio ? 25 : 12, isActive: isPlayingAudio),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAudioControls(BuildContext context, PipecatClientProvider client) {
    return Row(
      children: [
        Expanded(
          child: FutureBuilder(
            future: client.getAvailableMics(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final devices = snapshot.data!;
                return DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Select Microphone'),
                  items: devices.map((device) {
                    return DropdownMenuItem<String>(
                      value: device.deviceId,
                      child: Text(device.label),
                    );
                  }).toList(),
                  onChanged: (deviceId) {
                    if (deviceId != null) {
                      client.setMic(deviceId);
                    }
                  },
                );
              }
              return const Text('Loading microphones...');
            },
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: client.isMicEnabled ? () => client.enableMic(false) : () => client.enableMic(true),
          icon: Icon(client.isMicEnabled ? Icons.mic : Icons.mic_off),
          tooltip: client.isMicEnabled ? 'Mute Microphone' : 'Unmute Microphone',
        ),
      ],
    );
  }
}

class _AudioBar extends StatelessWidget {
  const _AudioBar({required this.height, this.isActive = false});

  final double height;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 6,
      height: height,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}