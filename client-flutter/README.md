# Pipecat Client Flutter

Flutter client SDK for [Pipecat](https://github.com/pipecat-ai/pipecat) with clean architecture, provider state management, and universal libraries that work on both Android and web platforms.

## Features

- **Clean Architecture**: Organized into domain, data, and presentation layers
- **Provider State Management**: Reactive state management using Flutter Provider
- **Cross-Platform**: Works on Flutter Web and Android with universal libraries
- **WebRTC Integration**: Real-time audio/video communication
- **Event-Driven**: Comprehensive event system for bot interactions
- **Type-Safe**: Full Dart type safety with freezed data classes

## Architecture

This package follows clean architecture principles:

```
├── domain/              # Business logic layer
│   ├── entities/        # Core business objects
│   ├── repositories/    # Abstract repository interfaces
│   └── usecases/        # Business use cases
├── data/                # Data access layer
│   ├── datasources/     # Data sources (Transport implementations)
│   ├── models/          # Data models
│   └── repositories/    # Repository implementations
└── presentation/        # UI layer
    ├── providers/       # State management providers
    └── widgets/         # Reusable UI components
```

## Getting Started

### Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  pipecat_client_flutter: ^1.0.0
  provider: ^6.1.1
```

### Basic Usage

1. **Create a Pipecat client:**

```dart
import 'package:pipecat_client_flutter/pipecat_client_flutter.dart';

final pipecatClient = PipecatClientFactory.createWebRTCClient();
```

2. **Set up providers:**

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: pipecatClient.clientProvider),
    ChangeNotifierProvider.value(value: pipecatClient.connectionStateProvider),
  ],
  child: MyApp(),
)
```

3. **Connect to a bot:**

```dart
await pipecatClient.connect(
  endpoint: 'wss://your-server.com/connect',
  enableMic: true,
  enableCam: false,
);
```

## Example Usage

### Connection Management

```dart
Consumer<ConnectionStateProvider>(
  builder: (context, connectionState, child) {
    return ElevatedButton(
      onPressed: connectionState.isConnected ? null : () async {
        await context.read<PipecatClientProvider>().connect(
          endpoint: 'wss://your-server.com/connect',
        );
      },
      child: Text(connectionState.isConnecting ? 'Connecting...' : 'Connect'),
    );
  },
)
```

### Media Controls

```dart
// Microphone toggle
PipecatMicToggle(
  onToggle: () {
    print('Microphone toggled');
  },
)

// Camera toggle
PipecatCamToggle(
  onToggle: () {
    print('Camera toggled');
  },
)

// Audio visualization
PipecatClientAudio(
  showControls: true,
  showVisualization: true,
)

// Video display
PipecatClientVideo(
  showLocalVideo: true,
  showRemoteVideo: true,
  showControls: true,
)
```

### Event Handling

```dart
Consumer<PipecatClientProvider>(
  builder: (context, client, child) {
    return StreamBuilder<RTVIEventData>(
      stream: client.eventStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final event = snapshot.data!;
          switch (event.event) {
            case RTVIEvent.botReady:
              return Text('Bot is ready!');
            case RTVIEvent.userStartedSpeaking:
              return Text('User started speaking');
            case RTVIEvent.botStartedSpeaking:
              return Text('Bot started speaking');
            default:
              return Text('Event: ${event.event}');
          }
        }
        return Container();
      },
    );
  },
)
```

### Sending Messages and Actions

```dart
// Send a custom action
await context.read<PipecatClientProvider>().sendAction(
  action: 'set_context',
  data: {
    'context': 'You are a helpful assistant.',
  },
);

// Send a raw message
final message = RTVIMessageHelpers.action(
  action: 'llm_function_call',
  data: {
    'function_name': 'get_weather',
    'arguments': {'location': 'San Francisco'},
  },
);
await context.read<PipecatClientProvider>().sendMessage(message);
```

## State Management

The package provides two main providers:

### PipecatClientProvider

Main provider for client operations:

- `connect()` - Connect to a bot
- `disconnect()` - Disconnect from bot
- `sendMessage()` - Send messages
- `sendAction()` - Send actions
- `enableMic()` / `enableCam()` - Control media
- `isConnected` - Connection status
- `isBotReady` - Bot ready status
- `eventStream` - Stream of RTVI events
- `messageStream` - Stream of messages

### ConnectionStateProvider

Specialized provider for connection state:

- `transportState` - Current transport state
- `isBotReady` - Bot ready status
- `connectionDuration` - How long connected
- `statusDescription` - Human-readable status
- `reconnectAttempts` - Number of reconnection attempts

## Transport Implementations

### WebRTC Transport (Default)

The default transport uses WebRTC for real-time communication:

```dart
final client = PipecatClientFactory.createWebRTCClient();
```

### Custom Transport

You can implement custom transports by extending the `Transport` class:

```dart
class MyCustomTransport extends Transport {
  // Implement required methods
}

final client = PipecatClientFactory.createWithTransport(
  transport: MyCustomTransport(),
);
```

## Events

The client emits various events during operation:

- **Connection Events**: `connected`, `disconnected`, `transportStateChanged`
- **Bot Events**: `botConnected`, `botReady`, `botDisconnected`
- **Media Events**: `userStartedSpeaking`, `botStartedSpeaking`, `trackStarted`
- **Message Events**: `serverMessage`, `serverResponse`, `messageError`
- **Device Events**: `availableMicsUpdated`, `availableCamsUpdated`

## Error Handling

The package provides comprehensive error handling:

```dart
Consumer<PipecatClientProvider>(
  builder: (context, client, child) {
    if (client.errorMessage != null) {
      return Text('Error: ${client.errorMessage}');
    }
    return YourWidget();
  },
)
```

## Development

### Running the Example

```bash
cd example
flutter run -d chrome
```

### Testing

```bash
flutter test
```

### Code Generation

This package uses code generation for JSON serialization and freezed classes:

```bash
flutter packages pub run build_runner build
```

## Platform Support

- ✅ Flutter Web
- ✅ Android
- 🚧 iOS (planned)
- 🚧 Desktop (planned)

## Dependencies

- `provider` - State management
- `flutter_webrtc` - WebRTC implementation
- `freezed` - Immutable data classes
- `json_annotation` - JSON serialization
- `rxdart` - Reactive streams
- `web_socket_channel` - WebSocket communication

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

BSD-2-Clause License - see [LICENSE.md](../LICENSE.md) for details.