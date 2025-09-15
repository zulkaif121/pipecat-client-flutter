# Changelog

All notable changes to the Pipecat Flutter Client will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-09-15

### Added

- Initial release of Pipecat Flutter Client
- Clean architecture implementation with domain, data, and presentation layers
- Provider-based state management for reactive UI updates
- WebRTC transport implementation for real-time communication
- Cross-platform support for Flutter Web and Android
- Comprehensive event system for bot interactions
- Audio and video controls with device management
- Type-safe implementation using Freezed and JSON annotation
- Example Flutter web application demonstrating usage
- Unit tests for core functionality
- Comprehensive documentation and README

### Features

- **PipecatClient**: Main client class for bot communication
- **Transport Abstraction**: Pluggable transport system with WebRTC implementation
- **Provider Integration**: Ready-to-use providers for state management
- **UI Components**: Pre-built widgets for mic/cam controls, audio/video display
- **Event Handling**: Comprehensive RTVI event system
- **Error Management**: Centralized error handling and reporting
- **Device Management**: Audio/video device enumeration and control
- **Connection Management**: Automatic connection state tracking
- **Message System**: Type-safe message and action sending

### Technical Details

- Implements clean architecture principles
- Uses Provider pattern for state management
- Supports Flutter Web as primary platform
- WebRTC integration via flutter_webrtc package
- Reactive streams with RxDart
- Code generation with Freezed and JSON serialization
- Comprehensive error handling with custom exception types