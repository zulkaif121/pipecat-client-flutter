/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pipecat_client_provider.dart';

/// Toggle button for camera control
class PipecatCamToggle extends StatefulWidget {
  const PipecatCamToggle({
    super.key,
    this.onToggle,
    this.enabled = true,
    this.iconSize = 24.0,
  });

  final VoidCallback? onToggle;
  final bool enabled;
  final double iconSize;

  @override
  State<PipecatCamToggle> createState() => _PipecatCamToggleState();
}

class _PipecatCamToggleState extends State<PipecatCamToggle> {
  bool _camEnabled = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<PipecatClientProvider>(
      builder: (context, client, child) {
        return IconButton(
          onPressed: widget.enabled && !_isLoading ? _toggleCam : null,
          icon: _isLoading
              ? SizedBox(
                  width: widget.iconSize,
                  height: widget.iconSize,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _camEnabled ? Icons.videocam : Icons.videocam_off,
                  size: widget.iconSize,
                  color: _camEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          tooltip: _camEnabled ? 'Turn off camera' : 'Turn on camera',
        );
      },
    );
  }

  Future<void> _toggleCam() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newState = !_camEnabled;
      await context.read<PipecatClientProvider>().enableCam(newState);
      
      setState(() {
        _camEnabled = newState;
      });
      
      widget.onToggle?.call();
    } catch (e) {
      // Error handling is done in the provider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle camera: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}