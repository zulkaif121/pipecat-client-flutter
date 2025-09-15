# Pipecat Flutter Client - Quick Start Guide

This guide will help you get started with the Pipecat Flutter Client quickly.

## Prerequisites

- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- A Pipecat server endpoint

## Installation

### 1. Add to your Flutter project

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  pipecat_client_flutter:
    git:
      url: https://github.com/zulkaif121/pipecat-client-flutter.git
      path: client-flutter
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Generate code (if using from source)

```bash
flutter pub run build_runner build
```

## Basic Implementation

### 1. Set up the client in your app

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pipecat_client_flutter/pipecat_client_flutter.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final PipecatClient _pipecatClient;

  @override
  void initState() {
    super.initState();
    _pipecatClient = PipecatClientFactory.createWebRTCClient();
  }

  @override
  void dispose() {
    _pipecatClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _pipecatClient.clientProvider),
        ChangeNotifierProvider.value(value: _pipecatClient.connectionStateProvider),
      ],
      child: MaterialApp(
        title: 'My Pipecat App',
        home: MyHomePage(),
      ),
    );
  }
}
```

### 2. Create a simple chat interface

```dart
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _endpointController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pipecat Chat')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Connection Section
            _buildConnectionSection(),
            
            // Media Controls
            _buildMediaControls(),
            
            // Status Display
            _buildStatusDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionSection() {
    return Consumer<ConnectionStateProvider>(
      builder: (context, connectionState, child) {
        return Column(
          children: [
            TextField(
              controller: _endpointController,
              decoration: InputDecoration(
                labelText: 'Server Endpoint',
                hintText: 'wss://your-server.com/connect',
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: connectionState.isConnected 
                        ? null 
                        : _connect,
                    child: Text(
                      connectionState.isConnecting 
                          ? 'Connecting...' 
                          : 'Connect'
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: connectionState.isConnected 
                        ? _disconnect 
                        : null,
                    child: Text('Disconnect'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMediaControls() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                PipecatMicToggle(),
                Text('Microphone'),
              ],
            ),
            Column(
              children: [
                PipecatCamToggle(),
                Text('Camera'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDisplay() {
    return Consumer2<PipecatClientProvider, ConnectionStateProvider>(
      builder: (context, client, connectionState, child) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${connectionState.statusDescription}'),
                Text('Bot Ready: ${connectionState.isBotReady ? "Yes" : "No"}'),
                if (client.errorMessage != null)
                  Text(
                    'Error: ${client.errorMessage}',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _connect() async {
    try {
      await context.read<PipecatClientProvider>().connect(
        endpoint: _endpointController.text.trim(),
        enableMic: true,
        enableCam: false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }

  Future<void> _disconnect() async {
    try {
      await context.read<PipecatClientProvider>().disconnect();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnect failed: $e')),
      );
    }
  }
}
```

## Advanced Usage

### Custom Transport

```dart
class MyCustomTransport extends Transport {
  // Implement your custom transport logic
  
  @override
  Future<void> connect({required String endpoint, Map<String, dynamic>? params}) async {
    // Custom connection logic
  }
  
  // Implement other required methods...
}

// Use custom transport
final client = PipecatClientFactory.createWithTransport(
  transport: MyCustomTransport(),
);
```

### Event Handling

```dart
StreamBuilder<RTVIEventData>(
  stream: context.read<PipecatClientProvider>().eventStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final event = snapshot.data!;
      switch (event.event) {
        case RTVIEvent.botStartedSpeaking:
          return Text('🤖 Bot is speaking...');
        case RTVIEvent.userStartedSpeaking:
          return Text('🎤 You are speaking...');
        case RTVIEvent.botReady:
          return Text('✅ Bot is ready');
        default:
          return Text('Event: ${event.event}');
      }
    }
    return Container();
  },
)
```

### Sending Custom Actions

```dart
// Send a custom action to the bot
await context.read<PipecatClientProvider>().sendAction(
  action: 'set_context',
  data: {
    'context': 'You are a helpful cooking assistant.',
    'temperature': 0.7,
  },
);

// Send a function call
await context.read<PipecatClientProvider>().sendAction(
  action: 'llm_function_call',
  data: {
    'function_name': 'get_recipe',
    'arguments': {'dish': 'pasta carbonara'},
  },
);
```

## Platform Support

### Web Configuration

Add to your `web/index.html`:

```html
<script src="https://unpkg.com/flutter_webrtc@^0.10.7/lib/src/web/adapter.js"></script>
```

### Android Configuration

Add to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

## Troubleshooting

### Common Issues

1. **WebRTC not working on web**: Make sure you're serving over HTTPS or localhost
2. **Permission errors**: Ensure camera/microphone permissions are granted
3. **Connection failures**: Check your server endpoint and network connectivity

### Debug Mode

Enable debug logging:

```dart
Logger.root.level = Level.ALL;
Logger.root.onRecord.listen((record) {
  print('${record.level.name}: ${record.time}: ${record.message}');
});
```

## Testing

Run the included tests:

```bash
cd client-flutter
flutter test
```

## Example

A complete example application is available in the `example/` directory. To run it:

```bash
cd client-flutter/example
flutter run -d chrome
```

This will start the example app in Chrome where you can test the connection and features.

## Support

For issues and questions:
- Check the [documentation](README.md)
- Look at the [example app](example/lib/main.dart)
- Review the [test files](test/) for usage patterns