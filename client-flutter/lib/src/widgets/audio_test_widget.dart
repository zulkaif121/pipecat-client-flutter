/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pipecat_provider.dart';
import '../client/pipecat_client_options.dart';
import '../transport/websocket_transport.dart';
import '../transport/twilio_serializer.dart';
import '../models/transport_state.dart';

class AudioTestWidget extends StatefulWidget {
  final String? agentId;
  final String? baseUrl;

  const AudioTestWidget({
    super.key,
    this.agentId,
    this.baseUrl,
  });

  @override
  State<AudioTestWidget> createState() => _AudioTestWidgetState();
}

class _AudioTestWidgetState extends State<AudioTestWidget> {
  late PipecatProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = PipecatProvider();
    _initializeClient();
  }

  void _initializeClient() {
    final agentId = widget.agentId ?? 'test';
    final baseUrl = widget.baseUrl ?? 'ws://localhost:8000';
    final wsUrl = '$baseUrl/ws/test/$agentId';

    final transport = WebSocketTransport(
      WebSocketTransportOptions(
        wsUrl: wsUrl,
        serializer: TwilioSerializer(),
        recorderSampleRate: 8000,
        playerSampleRate: 8000,
      ),
    );

    final options = PipecatClientOptions(
      transport: transport,
      enableMic: true,
      enableCam: false,
    );

    _provider.initialize(options);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0C10),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildStatusCard(),
                const SizedBox(height: 16),
                _buildInstructionsCard(),
                const SizedBox(height: 16),
                Expanded(child: _buildLogCard()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Voice Agent Test Client',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFFE0E6F1),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Consumer<PipecatProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10141A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            children: [
              _buildStatusIndicator(provider.state),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getStatusText(provider.state),
                  style: const TextStyle(
                    color: Color(0xFFE0E6F1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildMicButton(provider),
              const SizedBox(width: 8),
              _buildConnectButton(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(TransportState state) {
    Color color;
    if (state.isConnected) {
      color = Colors.green;
    } else if (state.isConnecting) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  String _getStatusText(TransportState state) {
    switch (state) {
      case TransportState.connected:
      case TransportState.ready:
        return 'Connected';
      case TransportState.connecting:
      case TransportState.initializing:
        return 'Connecting...';
      case TransportState.disconnected:
        return 'Disconnected';
      case TransportState.error:
        return 'Error';
      default:
        return state.name;
    }
  }

  Widget _buildMicButton(PipecatProvider provider) {
    return IconButton(
      onPressed: provider.connected ? () => provider.toggleMic() : null,
      icon: Icon(
        provider.isMicEnabled ? Icons.mic : Icons.mic_off,
        color: provider.isMicEnabled ? Colors.white : const Color(0xFFE0E6F1),
      ),
      style: IconButton.styleFrom(
        backgroundColor: provider.isMicEnabled
            ? const Color(0xFFF47174)
            : const Color(0xFF334155),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildConnectButton(PipecatProvider provider) {
    final isConnected = provider.connected;
    final isConnecting = provider.connecting;

    return IconButton(
      onPressed: isConnecting
          ? null
          : isConnected
              ? () => provider.disconnect()
              : () => _connect(provider),
      icon: Icon(
        isConnected ? Icons.call_end : Icons.call,
        color: Colors.white,
      ),
      style: IconButton.styleFrom(
        backgroundColor: isConnected
            ? const Color(0xFFF47174)
            : const Color(0xFF22C55E),
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _connect(PipecatProvider provider) async {
    try {
      await provider.connect();
      
      // Emulate Twilio messages like in the web client
      await Future.delayed(const Duration(milliseconds: 100));
      provider.client?.transport.sendRawMessage({
        'event': 'connected',
        'protocol': 'Call',
        'version': '1.0.0',
      });

      await Future.delayed(const Duration(milliseconds: 100));
      provider.client?.transport.sendRawMessage({
        'event': 'start',
        'start': {
          'streamSid': 'test_stream_sid',
          'callSid': 'test_call_sid',
        },
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    }
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to use:',
            style: TextStyle(
              color: Color(0xFF3B82F6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildInstruction('1. Tap the call button to connect to your agent'),
          _buildInstruction('2. Allow microphone access when prompted'),
          _buildInstruction('3. Start speaking - your agent will respond with voice'),
          _buildInstruction('4. Use the microphone button to mute/unmute yourself'),
          _buildInstruction('5. Tap the hang-up button to disconnect'),
        ],
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLogCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0C10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Debug Log:',
                style: TextStyle(
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Consumer<PipecatProvider>(
                builder: (context, provider, child) {
                  return TextButton(
                    onPressed: provider.clearLogs,
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<PipecatProvider>(
              builder: (context, provider, child) {
                if (provider.logs.isEmpty) {
                  return const Text(
                    'No logs yet...',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  );
                }

                return ListView.builder(
                  itemCount: provider.logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        provider.logs[index],
                        style: const TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}