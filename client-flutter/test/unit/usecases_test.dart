/// Copyright (c) 2024, Pipecat AI.
/// 
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:pipecat_client_flutter/domain/repositories/pipecat_client_repository.dart';
import 'package:pipecat_client_flutter/domain/usecases/connect_to_bot.dart';
import 'package:pipecat_client_flutter/domain/usecases/disconnect_from_bot.dart';
import 'package:pipecat_client_flutter/domain/usecases/send_action.dart';
import 'package:pipecat_client_flutter/domain/usecases/send_message.dart';
import 'package:pipecat_client_flutter/domain/entities/rtvi_message.dart';
import 'package:pipecat_client_flutter/core/usecases/usecase.dart';

import 'usecases_test.mocks.dart';

@GenerateMocks([PipecatClientRepository])
void main() {
  group('ConnectToBot', () {
    late MockPipecatClientRepository mockRepository;
    late ConnectToBot usecase;

    setUp(() {
      mockRepository = MockPipecatClientRepository();
      usecase = ConnectToBot(mockRepository);
    });

    test('should connect to bot with default parameters', () async {
      // arrange
      when(mockRepository.isConnected).thenReturn(false);
      when(mockRepository.initDevices(enableMic: true, enableCam: false))
          .thenAnswer((_) async {});
      when(mockRepository.connect(
        endpoint: 'wss://test.com',
        params: null,
      )).thenAnswer((_) async {});

      // act
      await usecase(ConnectToBotParams(endpoint: 'wss://test.com'));

      // assert
      verify(mockRepository.initDevices(enableMic: true, enableCam: false));
      verify(mockRepository.connect(endpoint: 'wss://test.com', params: null));
    });

    test('should not initialize devices if already connected', () async {
      // arrange
      when(mockRepository.isConnected).thenReturn(true);
      when(mockRepository.connect(
        endpoint: 'wss://test.com',
        params: null,
      )).thenAnswer((_) async {});

      // act
      await usecase(ConnectToBotParams(endpoint: 'wss://test.com'));

      // assert
      verifyNever(mockRepository.initDevices(enableMic: anyNamed('enableMic'), enableCam: anyNamed('enableCam')));
      verify(mockRepository.connect(endpoint: 'wss://test.com', params: null));
    });
  });

  group('DisconnectFromBot', () {
    late MockPipecatClientRepository mockRepository;
    late DisconnectFromBot usecase;

    setUp(() {
      mockRepository = MockPipecatClientRepository();
      usecase = DisconnectFromBot(mockRepository);
    });

    test('should disconnect from bot', () async {
      // arrange
      when(mockRepository.disconnect()).thenAnswer((_) async {});

      // act
      await usecase(NoParams());

      // assert
      verify(mockRepository.disconnect());
    });
  });

  group('SendMessage', () {
    late MockPipecatClientRepository mockRepository;
    late SendMessage usecase;

    setUp(() {
      mockRepository = MockPipecatClientRepository();
      usecase = SendMessage(mockRepository);
    });

    test('should send message to repository', () async {
      // arrange
      const message = RTVIMessage(
        id: 'test-id',
        type: 'action',
        data: {'action': 'test'},
      );
      when(mockRepository.sendMessage(message)).thenAnswer((_) async {});

      // act
      await usecase(SendMessageParams(message: message));

      // assert
      verify(mockRepository.sendMessage(message));
    });
  });

  group('SendAction', () {
    late MockPipecatClientRepository mockRepository;
    late SendAction usecase;

    setUp(() {
      mockRepository = MockPipecatClientRepository();
      usecase = SendAction(mockRepository);
    });

    test('should send action to repository', () async {
      // arrange
      const action = 'test_action';
      const data = {'key': 'value'};
      when(mockRepository.sendAction(action: action, data: data))
          .thenAnswer((_) async {});

      // act
      await usecase(SendActionParams(action: action, data: data));

      // assert
      verify(mockRepository.sendAction(action: action, data: data));
    });
  });
}