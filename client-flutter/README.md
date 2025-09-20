# Pipecat Flutter Client

A minimal Flutter library for connecting to Pipecat AI voice agents, inspired by the architecture of `pipecat-client-web` and `naturalflow-website-official` test client.

## Features

- **WebSocket Transport**: Real-time bidirectional communication with Pipecat backend
- **Twilio Serialization**: Compatible with Twilio media streaming format
- **Audio Streaming**: Real-time audio capture and playback
- **State Management**: Provider-based state management for easy integration
- **Clean Architecture**: Follows pipecat-client-web patterns

## Quick Start

### 1. Add Dependency

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  pipecat_client_flutter:
    path: path/to/pipecat-client-flutter/client-flutter
```

### 2. Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:pipecat_client_flutter/pipecat_client_flutter.dart';

class MyVoiceAgent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TwilioExample(); // Ready-to-use widget
  }
}
```

### 3. Custom Implementation

```dart
import 'package:pipecat_client_flutter/pipecat_client_flutter.dart';

// 1. Create transport
final transport = WebSocketTransport(
  WebSocketTransportOptions(
    wsUrl: 'ws://localhost:8000/ws/test/your-agent-id',
    serializer: TwilioSerializer(),
    recorderSampleRate: 8000,
    playerSampleRate: 8000,
  ),
);

// 2. Create client options
final options = PipecatClientOptions(
  transport: transport,
  enableMic: true,
  enableCam: false,
  callbacks: MyEventCallbacks(), // Implement PipecatEventCallbacks
);

// 3. Initialize client
final client = PipecatClient(options);

// 4. Connect
await client.initDevices();
await client.connect();

// 5. Control microphone
await client.enableMic(true);
```

## Architecture

The library follows the same patterns as `pipecat-client-web`:

- **PipecatClient**: Main client class for managing connections
- **WebSocketTransport**: Handles WebSocket communication and audio streaming
- **TwilioSerializer**: Serializes/deserializes messages in Twilio format
- **PipecatProvider**: State management using Flutter's Provider pattern

## Widgets

### TwilioExample

A complete example widget that demonstrates the library usage:

```dart
TwilioExample() // Shows configuration UI, connection controls, and debug logs
```

### AudioTestWidget

A simpler widget for testing audio connections:

```dart
AudioTestWidget(
  agentId: 'your-agent-id',
  baseUrl: 'ws://localhost:8000',
)
```

## Event Handling

Implement `PipecatEventCallbacks` to handle events:

```dart
class MyEventCallbacks extends PipecatEventCallbacks {
  @override
  void onConnected() {
    print('Connected to agent');
  }

  @override
  void onUserTranscript(TranscriptData data) {
    if (data.final_) {
      print('User said: ${data.text}');
    }
  }

  @override
  void onBotTranscript(BotLLMTextData data) {
    print('Bot said: ${data.text}');
  }
}
```

## State Management with Provider

Use `PipecatProvider` for reactive state management:

```dart
ChangeNotifierProvider(
  create: (_) => PipecatProvider()..initialize(options),
  child: Consumer<PipecatProvider>(
    builder: (context, provider, child) {
      return Column(
        children: [
          Text('Status: ${provider.connected ? 'Connected' : 'Disconnected'}'),
          ElevatedButton(
            onPressed: provider.connected ? provider.disconnect : provider.connect,
            child: Text(provider.connected ? 'Disconnect' : 'Connect'),
          ),
        ],
      );
    },
  ),
)
```

## Permissions

The library requires microphone permissions. Add to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

For iOS, add to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to communicate with voice agents</string>
```

## Example Usage

See the example app for a complete implementation similar to the naturalflow-website test client.

## License

BSD-2-Clause - see LICENSE file for details.