/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter_test/flutter_test.dart';
import 'package:pipecat_client_flutter/domain/entities/transport_state.dart';
import 'package:pipecat_client_flutter/domain/entities/rtvi_message.dart';
import 'package:pipecat_client_flutter/domain/entities/participant.dart';

void main() {
  group('TransportState', () {
    test('should create disconnected state', () {
      const state = TransportState.disconnected();
      expect(state.value, 'disconnected');
      expect(state.isDisconnected, true);
      expect(state.isConnected, false);
    });

    test('should create connected state', () {
      const state = TransportState.connected();
      expect(state.value, 'connected');
      expect(state.isConnected, true);
      expect(state.isDisconnected, false);
    });

    test('should create error state', () {
      const state = TransportState.error('Test error');
      expect(state.value, 'error');
      expect(state.isError, true);
      expect(state.isConnected, false);
    });
  });

  group('RTVIMessage', () {
    test('should create message with required fields', () {
      const message = RTVIMessage(
        id: 'test-id',
        type: 'action',
        data: {'action': 'test'},
      );

      expect(message.id, 'test-id');
      expect(message.type, 'action');
      expect(message.data, {'action': 'test'});
      expect(message.isResponse, false);
    });

    test('should create action message helper', () {
      final message = RTVIMessageHelpers.action(
        action: 'test_action',
        data: {'key': 'value'},
      );

      expect(message.type, RTVIMessageType.action);
      expect(message.data['action'], 'test_action');
      expect(message.data['key'], 'value');
    });

    test('should create response message helper', () {
      final message = RTVIMessageHelpers.response(
        requestId: 'request-123',
        data: {'result': 'success'},
      );

      expect(message.type, RTVIMessageType.response);
      expect(message.requestId, 'request-123');
      expect(message.isResponse, true);
      expect(message.data['result'], 'success');
    });

    test('should create error message helper', () {
      final message = RTVIMessageHelpers.error(
        error: 'Test error',
        requestId: 'request-123',
        details: {'code': 500},
      );

      expect(message.type, RTVIMessageType.error);
      expect(message.requestId, 'request-123');
      expect(message.data['error'], 'Test error');
      expect(message.data['code'], 500);
    });
  });

  group('Participant', () {
    test('should create participant with required fields', () {
      const participant = Participant(
        id: 'user-123',
        name: 'John Doe',
      );

      expect(participant.id, 'user-123');
      expect(participant.name, 'John Doe');
      expect(participant.isLocal, false);
      expect(participant.isBot, false);
    });

    test('should create local participant', () {
      const participant = Participant(
        id: 'local',
        name: 'You',
        isLocal: true,
      );

      expect(participant.isLocal, true);
      expect(participant.isBot, false);
    });

    test('should create bot participant', () {
      const participant = Participant(
        id: 'bot',
        name: 'Assistant',
        isBot: true,
      );

      expect(participant.isLocal, false);
      expect(participant.isBot, true);
    });

    test('should handle metadata', () {
      const participant = Participant(
        id: 'user-123',
        name: 'John Doe',
        metadata: {'avatar': 'https://example.com/avatar.jpg'},
      );

      expect(participant.metadata?['avatar'], 'https://example.com/avatar.jpg');
    });
  });
}