/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pipecat_client_provider.dart';

/// Toggle button for microphone control
class PipecatMicToggle extends StatefulWidget {
  const PipecatMicToggle({
    super.key,
    this.onToggle,
    this.enabled = true,
    this.iconSize = 24.0,
  });

  final VoidCallback? onToggle;
  final bool enabled;
  final double iconSize;

  @override
  State<PipecatMicToggle> createState() => _PipecatMicToggleState();
}

class _PipecatMicToggleState extends State<PipecatMicToggle> {
  bool _micEnabled = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<PipecatClientProvider>(
      builder: (context, client, child) {
        return IconButton(
          onPressed: widget.enabled && !_isLoading ? _toggleMic : null,
          icon: _isLoading
              ? SizedBox(
                  width: widget.iconSize,
                  height: widget.iconSize,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _micEnabled ? Icons.mic : Icons.mic_off,
                  size: widget.iconSize,
                  color: _micEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          tooltip: _micEnabled ? 'Mute microphone' : 'Unmute microphone',
        );
      },
    );
  }

  Future<void> _toggleMic() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newState = !_micEnabled;
      await context.read<PipecatClientProvider>().enableMic(newState);
      
      setState(() {
        _micEnabled = newState;
      });
      
      widget.onToggle?.call();
    } catch (e) {
      // Error handling is done in the provider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle microphone: $e'),
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