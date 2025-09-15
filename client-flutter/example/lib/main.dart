/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pipecat_client_flutter/pipecat_client_flutter.dart';

void main() {
  runApp(const PipecatExampleApp());
}

class PipecatExampleApp extends StatelessWidget {
  const PipecatExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pipecat Flutter Client',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PipecatHomePage(),
    );
  }
}

class PipecatHomePage extends StatefulWidget {
  const PipecatHomePage({super.key});

  @override
  State<PipecatHomePage> createState() => _PipecatHomePageState();
}

class _PipecatHomePageState extends State<PipecatHomePage> {
  late final PipecatClient _pipecatClient;
  final TextEditingController _endpointController = TextEditingController(
    text: 'wss://your-server-endpoint.com/connect',
  );

  @override
  void initState() {
    super.initState();
    _pipecatClient = PipecatClientFactory.createWebRTCClient();
  }

  @override
  void dispose() {
    _pipecatClient.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _pipecatClient.clientProvider),
        ChangeNotifierProvider.value(value: _pipecatClient.connectionStateProvider),
      ],
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Pipecat Flutter Client'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildConnectionSection(),
              const SizedBox(height: 24),
              _buildControlsSection(),
              const SizedBox(height: 24),
              _buildMediaSection(),
              const SizedBox(height: 24),
              _buildStatusSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _endpointController,
              decoration: const InputDecoration(
                labelText: 'Server Endpoint',
                hintText: 'wss://your-server.com/connect',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<ConnectionStateProvider>(
              builder: (context, connectionState, child) {
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: connectionState.isConnected || connectionState.isConnecting
                            ? null
                            : _connect,
                        icon: connectionState.isConnecting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.connect_without_contact),
                        label: Text(connectionState.isConnecting ? 'Connecting...' : 'Connect'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: connectionState.isConnected ? _disconnect : null,
                        icon: const Icon(Icons.disconnect),
                        label: const Text('Disconnect'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controls',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const PipecatMicToggle(iconSize: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Microphone',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                Column(
                  children: [
                    const PipecatCamToggle(iconSize: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Camera',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return const Column(
      children: [
        PipecatClientAudio(),
        SizedBox(height: 16),
        PipecatClientVideo(),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Consumer2<PipecatClientProvider, ConnectionStateProvider>(
      builder: (context, client, connectionState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildStatusRow('Connection', connectionState.statusDescription),
                _buildStatusRow('Bot Ready', connectionState.isBotReady ? 'Yes' : 'No'),
                if (connectionState.connectionDuration != null)
                  _buildStatusRow(
                    'Connected for',
                    _formatDuration(connectionState.connectionDuration!),
                  ),
                if (client.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            client.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: client.clearError,
                          icon: const Icon(Icons.close),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Future<void> _connect() async {
    try {
      final endpoint = _endpointController.text.trim();
      if (endpoint.isEmpty) {
        _showError('Please enter a server endpoint');
        return;
      }

      await _pipecatClient.connect(
        endpoint: endpoint,
        enableMic: true,
        enableCam: false,
      );
    } catch (e) {
      _showError('Failed to connect: $e');
    }
  }

  Future<void> _disconnect() async {
    try {
      await _pipecatClient.disconnect();
    } catch (e) {
      _showError('Failed to disconnect: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}