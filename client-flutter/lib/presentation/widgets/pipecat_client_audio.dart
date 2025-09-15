/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: StreamBuilder(
        stream: client.eventStream,
        builder: (context, snapshot) {
          // Simple placeholder for audio visualization
          // In a real implementation, this would show audio levels
          return const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AudioBar(height: 20),
                SizedBox(width: 4),
                _AudioBar(height: 35),
                SizedBox(width: 4),
                _AudioBar(height: 45),
                SizedBox(width: 4),
                _AudioBar(height: 30),
                SizedBox(width: 4),
                _AudioBar(height: 25),
              ],
            ),
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
                      value: device.id,
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
          onPressed: () {
            // Toggle mute/unmute
          },
          icon: const Icon(Icons.mic),
          tooltip: 'Toggle Microphone',
        ),
      ],
    );
  }
}

class _AudioBar extends StatelessWidget {
  const _AudioBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 6,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}