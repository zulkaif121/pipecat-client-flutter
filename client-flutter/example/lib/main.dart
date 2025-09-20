/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

import 'package:flutter/material.dart';
import 'package:pipecat_client_flutter/pipecat_client_flutter.dart';

void main() {
  runApp(const PipecatExampleApp());
}

class PipecatExampleApp extends StatelessWidget {
  const PipecatExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pipecat Flutter Client',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PipecatHomePage(),
    );
  }
}

class PipecatHomePage extends StatelessWidget {
  const PipecatHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TwilioExample();
  }
}

