/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter/foundation.dart';

import 'data/datasources/transport.dart';
import 'data/datasources/webrtc_transport.dart';
import 'data/repositories/pipecat_client_repository_impl.dart';
import 'domain/repositories/pipecat_client_repository.dart';
import 'domain/usecases/connect_to_bot.dart';
import 'domain/usecases/disconnect_from_bot.dart';
import 'domain/usecases/send_message.dart';
import 'presentation/providers/pipecat_client_provider.dart';
import 'presentation/providers/connection_state_provider.dart';

/// Configuration options for PipecatClient
class PipecatClientOptions {
  PipecatClientOptions({
    this.enableMic = true,
    this.enableCam = false,
    this.transport,
  });

  final bool enableMic;
  final bool enableCam;
  final Transport? transport;
}

/// Main Pipecat client class for Flutter
class PipecatClient {
  PipecatClient({
    PipecatClientOptions? options,
    Transport? transport,
  }) : _options = options ?? PipecatClientOptions() {
    _transport = transport ?? _options.transport ?? WebRTCTransport();
    _repository = PipecatClientRepositoryImpl(transport: _transport);
    
    // Initialize use cases
    _connectToBot = ConnectToBot(_repository);
    _disconnectFromBot = DisconnectFromBot(_repository);
    _sendMessage = SendMessage(_repository);
    _sendAction = SendAction(_repository);
    
    // Initialize providers
    _clientProvider = PipecatClientProvider(
      repository: _repository,
      connectToBot: _connectToBot,
      disconnectFromBot: _disconnectFromBot,
      sendMessage: _sendMessage,
      sendAction: _sendAction,
    );
    
    _connectionStateProvider = ConnectionStateProvider(
      clientProvider: _clientProvider,
    );
  }

  final PipecatClientOptions _options;
  
  late final Transport _transport;
  late final PipecatClientRepository _repository;
  late final ConnectToBot _connectToBot;
  late final DisconnectFromBot _disconnectFromBot;
  late final SendMessage _sendMessage;
  late final SendAction _sendAction;
  late final PipecatClientProvider _clientProvider;
  late final ConnectionStateProvider _connectionStateProvider;

  /// Get the main client provider for use with Provider pattern
  PipecatClientProvider get clientProvider => _clientProvider;
  
  /// Get the connection state provider for use with Provider pattern
  ConnectionStateProvider get connectionStateProvider => _connectionStateProvider;
  
  /// Get the repository for direct access if needed
  PipecatClientRepository get repository => _repository;

  /// Initialize device access
  Future<void> initDevices({
    bool? enableMic,
    bool? enableCam,
  }) async {
    await _clientProvider.initDevices(
      enableMic: enableMic ?? _options.enableMic,
      enableCam: enableCam ?? _options.enableCam,
    );
  }

  /// Connect to a bot
  Future<void> connect({
    required String endpoint,
    bool? enableMic,
    bool? enableCam,
    Map<String, dynamic>? connectionParams,
  }) async {
    await _clientProvider.connect(
      endpoint: endpoint,
      enableMic: enableMic ?? _options.enableMic,
      enableCam: enableCam ?? _options.enableCam,
      connectionParams: connectionParams,
    );
  }

  /// Disconnect from the bot
  Future<void> disconnect() async {
    await _clientProvider.disconnect();
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await _repository.dispose();
    _clientProvider.dispose();
    _connectionStateProvider.dispose();
  }
}

/// Factory class for creating PipecatClient instances with different transports
class PipecatClientFactory {
  /// Create a client with WebRTC transport (default for web)
  static PipecatClient createWebRTCClient({
    PipecatClientOptions? options,
  }) {
    return PipecatClient(
      options: options,
      transport: WebRTCTransport(),
    );
  }

  /// Create a client with custom transport
  static PipecatClient createWithTransport({
    required Transport transport,
    PipecatClientOptions? options,
  }) {
    return PipecatClient(
      options: options,
      transport: transport,
    );
  }
}