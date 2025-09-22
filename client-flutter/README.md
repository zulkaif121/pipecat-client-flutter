# Pipecat Client Flutter

A Flutter client library for real-time voice conversations with AI agents, compatible with [Pipecat](https://github.com/pipecat-ai/pipecat) framework. Built with native Flutter packages for cross-platform audio streaming support.

## ✅ Features

- **WebSocket Transport**: Real-time bidirectional communication with Pipecat backend
- **Twilio Serialization**: Compatible with Twilio media streaming format  
- **Cross-Platform Audio**: Native audio recording and playback on web, iOS, and Android
- **Native Flutter Packages**: Uses `record`, `flutter_sound`, and `web_socket_channel`
- **PCM Audio Streaming**: 8kHz PCM16 → μ-law conversion for optimal compatibility
- **Memory Safe**: Robust error handling and resource management
- **State Management**: Provider-based state management for easy integration
- **Clean Architecture**: Follows pipecat-client-web patterns

## Quick Start

### 1. Add Dependency

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  pipecat_client_flutter:
    git:
      url: https://github.com/zulkaif121/pipecat-client-flutter.git
      path: client-flutter
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

### Simple Configuration

The example widget uses a single WebSocket URL field for easy configuration:

```dart
// Just provide the complete WebSocket URL
TwilioExample() // UI allows entering: ws://localhost:8000/ws/test/demo
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

## 🔧 Technical Details

### Native Flutter Audio Pipeline
Uses native Flutter packages for cross-platform audio handling:

```dart
// ✅ Native Flutter packages (no JavaScript dependencies)
Future<void> _startMicrophoneRecording() async {
  // Configure native recording
  const recordConfig = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 8000,  // Matches TypeScript example
    numChannels: 1,
    autoGain: true,
    echoCancel: true,
    noiseSuppress: true,
  );

  // Start native PCM stream
  final stream = await _audioRecorder!.startStream(recordConfig);
  _recordingSubscription = stream.listen((audioData) {
    _sendAudioData(audioData); // Direct PCM16 → μ-law → WebSocket
  });
}
```

### Key Packages Used
- ✅ **record**: Native microphone recording to PCM stream
- ✅ **flutter_sound**: Native PCM audio playback 
- ✅ **web_socket_channel**: WebSocket communication
- ✅ **permission_handler**: Cross-platform permission requests

### Audio Flow
1. **Microphone** → `record` package → PCM16 stream → μ-law → WebSocket
2. **WebSocket** → μ-law → PCM16 → `flutter_sound` → Speakers  
3. **Cross-platform**: Works on web, iOS, and Android with same code
4. **8kHz sample rate**: Optimized for voice communication

### Robustness Features
- **Memory Protection**: Audio queue size limits prevent memory overflow
- **Error Isolation**: Individual audio chunk failures don't break the stream
- **Resource Cleanup**: Proper disposal of subscriptions and audio components
- **Input Validation**: Empty audio data and null checks
- **Safe Operations**: Try-catch blocks around critical audio operations

## 🚀 Getting Started

1. **Clone and run the example**:
   ```bash
   cd example
   flutter run -d chrome
   ```

2. **Test with your endpoint**:
   - Enter your WebSocket URL (e.g., `ws://localhost:8000/ws/test/agent-id`)
   - Click "Connect" 
   - Allow microphone permissions
   - Start talking - you should now hear the bot respond! 🎉

## Example Usage

See the example app (`example/lib/main.dart`) for a complete implementation similar to the naturalflow-website test client.

## Contributing

We welcome contributions to the Pipecat Client Flutter! Whether you've found a bug, have a feature idea, or want to improve documentation, we'd love to hear from you.

- **Found a bug?** Open an [issue](https://github.com/pipecat-ai/pipecat-client-web/issues)
- **Have a feature idea?** Start a [discussion](https://github.com/pipecat-ai/pipecat-client-web/discussions)
- **Want to contribute code?** Check our [CONTRIBUTING.md](https://github.com/pipecat-ai/pipecat-client-web/blob/main/CONTRIBUTING.md) guide
- **Documentation improvements?** Docs PRs are always welcome

## Support

- [Documentation](https://docs.pipecat.ai)
- [Discord](https://discord.gg/pipecat)
- [X (Twitter)](https://x.com/pipecat_ai)

## License

BSD-2-Clause - see LICENSE file for details.