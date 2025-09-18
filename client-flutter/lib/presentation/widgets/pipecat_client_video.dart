/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../providers/pipecat_client_provider.dart';

/// Widget for displaying video streams and camera controls
class PipecatClientVideo extends StatefulWidget {
  const PipecatClientVideo({
    super.key,
    this.showLocalVideo = true,
    this.showRemoteVideo = true,
    this.showControls = true,
  });

  final bool showLocalVideo;
  final bool showRemoteVideo;
  final bool showControls;

  @override
  State<PipecatClientVideo> createState() => _PipecatClientVideoState();
}

class _PipecatClientVideoState extends State<PipecatClientVideo> {
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
  }

  @override
  void dispose() {
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    super.dispose();
  }

  Future<void> _initializeRenderers() async {
    if (widget.showLocalVideo) {
      _localRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();
    }
    
    if (widget.showRemoteVideo) {
      _remoteRenderer = RTCVideoRenderer();
      await _remoteRenderer!.initialize();
    }
    
    setState(() {});
  }

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
                      Icons.videocam,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Video',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildVideoSection(context, client),
                if (widget.showControls) ...[
                  const SizedBox(height: 16),
                  _buildVideoControls(context, client),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoSection(BuildContext context, PipecatClientProvider client) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          if (widget.showLocalVideo) ...[
            Expanded(
              child: _buildVideoView(
                title: 'Local Video',
                renderer: _localRenderer,
                placeholder: Icons.person,
              ),
            ),
            if (widget.showRemoteVideo) const SizedBox(width: 8),
          ],
          if (widget.showRemoteVideo) ...[
            Expanded(
              child: _buildVideoView(
                title: 'Remote Video',
                renderer: _remoteRenderer,
                placeholder: Icons.smart_toy,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoView({
    required String title,
    required RTCVideoRenderer? renderer,
    required IconData placeholder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(
            child: renderer != null
                ? RTCVideoView(
                    renderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : Center(
                    child: Icon(
                      placeholder,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls(BuildContext context, PipecatClientProvider client) {
    return Row(
      children: [
        Expanded(
          child: FutureBuilder(
            future: client.getAvailableCams(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final devices = snapshot.data!;
                return DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Select Camera'),
                  items: devices.map((device) {
                    return DropdownMenuItem<String>(
                      value: device.deviceId,
                      child: Text(device.label),
                    );
                  }).toList(),
                  onChanged: (deviceId) {
                    if (deviceId != null) {
                      client.setCam(deviceId);
                    }
                  },
                );
              }
              return const Text('Loading cameras...');
            },
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () {
            // Toggle camera on/off
          },
          icon: const Icon(Icons.videocam),
          tooltip: 'Toggle Camera',
        ),
      ],
    );
  }
}