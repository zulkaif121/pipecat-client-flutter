/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

/// Custom exception class for RTVI-related errors
class RTVIError extends Error {
  RTVIError(this.message, [this.details]);

  final String message;
  final Map<String, dynamic>? details;

  @override
  String toString() {
    if (details != null) {
      return 'RTVIError: $message\nDetails: $details';
    }
    return 'RTVIError: $message';
  }
}

/// Error thrown when transport is not initialized
class TransportNotInitializedError extends RTVIError {
  TransportNotInitializedError() 
    : super('Transport not initialized. Call initDevices() first.');
}

/// Error thrown when connection fails
class ConnectionError extends RTVIError {
  ConnectionError(String message, [Map<String, dynamic>? details]) 
    : super(message, details);
}

/// Error thrown when device access fails
class DeviceError extends RTVIError {
  DeviceError(String message, [Map<String, dynamic>? details]) 
    : super(message, details);
}

/// Error thrown when message sending fails
class MessageError extends RTVIError {
  MessageError(String message, [Map<String, dynamic>? details]) 
    : super(message, details);
}