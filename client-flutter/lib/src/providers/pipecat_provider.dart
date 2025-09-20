/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter/foundation.dart';

import '../client/pipecat_client.dart';
import '../client/pipecat_client_options.dart';
import '../client/pipecat_events.dart';
import '../models/rtvi_message.dart';
import '../models/transport_state.dart';
import '../models/transcript_data.dart';
import '../models/participant.dart';

class PipecatProvider extends ChangeNotifier implements PipecatEventCallbacks {
  PipecatClient? _client;
  bool _disposed = false;
  
  // State
  TransportState _state = TransportState.disconnected;
  bool _isMicEnabled = false;
  String? _errorMessage;
  
  // Transcripts
  final List<String> _logs = [];
  String _userTranscript = '';
  String _botTranscript = '';

  // Getters
  PipecatClient? get client => _client;
  TransportState get state => _state;
  bool get connected => _state.isConnected;
  bool get connecting => _state.isConnecting;
  bool get isMicEnabled => _isMicEnabled;
  String? get errorMessage => _errorMessage;
  List<String> get logs => List.unmodifiable(_logs);
  String get userTranscript => _userTranscript;
  String get botTranscript => _botTranscript;

  // Safe notify listeners that checks if disposed
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void initialize(PipecatClientOptions options) {
    if (_disposed) return;
    
    // Dispose existing client without marking this provider as disposed
    _client?.dispose();
    _client = null;
    
    _client = PipecatClient(PipecatClientOptions(
      transport: options.transport,
      enableMic: options.enableMic,
      enableCam: options.enableCam,
      callbacks: this, // Use this provider as the callback handler
    ));
    
    _state = _client!.state;
    _isMicEnabled = _client!.isMicEnabled;
    _safeNotifyListeners();
  }

  Future<void> connect([Map<String, dynamic>? connectParams]) async {
    if (_client == null || _disposed) return;
    
    try {
      _errorMessage = null;
      _safeNotifyListeners();
      
      final result = await _client!.connect(connectParams);
      addLog('Connected to bot: ${result['version'] ?? 'unknown version'}');
    } catch (e) {
      _errorMessage = e.toString();
      addLog('Connection failed: $e');
      _safeNotifyListeners();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_client == null || _disposed) return;
    
    await _client!.disconnect();
    addLog('Disconnected from bot');
  }

  Future<void> toggleMic() async {
    if (_client == null || _disposed) return;
    
    await _client!.enableMic(!_isMicEnabled);
    addLog(_isMicEnabled ? 'Microphone enabled' : 'Microphone disabled');
  }

  void addLog(String message) {
    if (_disposed) return;
    
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    _logs.insert(0, '[$timestamp] $message');
    if (_logs.length > 50) {
      _logs.removeLast();
    }
    _safeNotifyListeners();
  }

  void clearLogs() {
    if (_disposed) return;
    
    _logs.clear();
    _safeNotifyListeners();
  }

  // PipecatEventCallbacks implementation
  @override
  void onConnected() {
    addLog('Transport connected');
  }

  @override
  void onDisconnected() {
    addLog('Transport disconnected');
  }

  @override
  void onError(RTVIMessage message) {
    if (_disposed) return;
    
    final errorMsg = message.data['message'] ?? 'Unknown error';
    _errorMessage = errorMsg;
    addLog('Error: $errorMsg');
    _safeNotifyListeners();
  }

  @override
  void onTransportStateChanged(TransportState state) {
    if (_disposed) return;
    
    _state = state;
    addLog('State changed: ${state.name}');
    _safeNotifyListeners();
  }

  @override
  void onBotReady(Map<String, dynamic> data) {
    addLog('Bot ready: ${data['version'] ?? 'unknown version'}');
  }

  @override
  void onUserStartedSpeaking() {
    addLog('User started speaking');
  }

  @override
  void onUserStoppedSpeaking() {
    addLog('User stopped speaking');
  }

  @override
  void onBotStartedSpeaking() {
    addLog('Bot started speaking');
  }

  @override
  void onBotStoppedSpeaking() {
    addLog('Bot stopped speaking');
  }

  @override
  void onUserTranscript(TranscriptData data) {
    if (_disposed) return;
    
    if (data.final_) {
      _userTranscript = data.text;
      addLog('User: ${data.text}');
      _safeNotifyListeners();
    }
  }

  @override
  void onBotTranscript(BotLLMTextData data) {
    if (_disposed) return;
    
    _botTranscript = data.text;
    addLog('Bot: ${data.text}');
    _safeNotifyListeners();
  }

  @override
  void onBotConnected(Participant participant) {
    addLog('Bot connected: ${participant.name ?? participant.id}');
  }

  @override
  void onBotDisconnected(Participant participant) {
    addLog('Bot disconnected: ${participant.name ?? participant.id}');
  }

  @override
  void onMessageError(RTVIMessage message) {
    addLog('Message error: ${message.data}');
  }

  @override
  void dispose() {
    _disposed = true;
    _client?.dispose();
    _client = null;
    super.dispose();
  }
}