/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter/material.dart';
import 'package:pipecat_client_flutter/pipecat_client_sdk.dart';

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
    text:
        'wss://d751acb421f4.ngrok-free.app/ws/test/06498233-ca75-47e7-9e14-34fc1d627030',
  );
  bool _connected = false;
  bool _connecting = false;
  bool _micEnabled = true;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _pipecatClient = PipecatClient(PipecatClientOptions(
      enableMic: true,
      callbacks: PipecatClientCallbacks(
        onConnected: () {
          setState(() {
            _connected = true;
            _connecting = false;
          });
          _addLog('Connected to bot');
        },
        onDisconnected: () {
          setState(() {
            _connected = false;
            _connecting = false;
          });
          _addLog('Disconnected from bot');
        },
        onBotReady: (data) {
          _addLog('Bot ready: ${data.toString()}');
        },
        onUserTranscript: (data) {
          if (data.isFinal) {
            _addLog('User: ${data.text}');
          }
        },
        onBotTranscript: (data) {
          _addLog('Bot: ${data.text}');
        },
        onError: (error) {
          _addLog('Error: ${error.data}');
        },
        
      ),
    ));
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(
          0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_logs.length > 50) {
        _logs.removeLast();
      }
    });
  }

  @override
  void dispose() {
    _pipecatClient.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            _buildStatusSection(),
          ],
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
                hintText: 'ws://your-server.com/ws/test/agent-id',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _connected || _connecting ? null : _connect,
                    icon: _connecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.connect_without_contact),
                    label: Text(_connecting ? 'Connecting...' : 'Connect'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _connected ? _disconnect : null,
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disconnect'),
                  ),
                ),
              ],
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
              'Controls (Audio Only)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    IconButton(
                      onPressed: _connected ? _toggleMic : null,
                      iconSize: 32,
                      icon: Icon(
                        _micEnabled ? Icons.mic : Icons.mic_off,
                        color: _micEnabled
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Microphone',
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

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status & Logs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
                'Connection', _connected ? 'Connected' : 'Disconnected'),
            _buildStatusRow('Microphone', _micEnabled ? 'Enabled' : 'Disabled'),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Text(
                    _logs[index],
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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

  Future<void> _connect() async {
    try {
      final endpoint = _endpointController.text.trim();
      if (endpoint.isEmpty) {
        _showError('Please enter a server endpoint');
        return;
      }

      setState(() {
        _connecting = true;
      });

      await _pipecatClient.initDevices();
      await _pipecatClient.connectWithEndpoint(endpoint);
    } catch (e) {
      setState(() {
        _connecting = false;
      });
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

  Future<void> _toggleMic() async {
    try {
      final newState = !_micEnabled;
      await _pipecatClient.enableMic(newState);
      setState(() {
        _micEnabled = newState;
      });
      _addLog(newState ? 'Microphone enabled' : 'Microphone disabled');
    } catch (e) {
      _showError('Failed to toggle microphone: $e');
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
