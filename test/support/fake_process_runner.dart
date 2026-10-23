import 'dart:async';

import 'package:ti_app_manager/shared/process_runner.dart';

class FakeProcessRunner implements ProcessRunner {
  FakeProcessRunner([
    this.result = const CommandResult(exitCode: 0, stdoutText: ''),
  ]);

  CommandResult result;
  final List<List<String>> calls = [];

  @override
  Future<CommandResult> run(List<String> command, {Duration? timeout}) async {
    calls.add(command);
    return result;
  }
}

class PendingProcessRunner implements ProcessRunner {
  final Completer<CommandResult> completion = Completer<CommandResult>();

  @override
  Future<CommandResult> run(List<String> command, {Duration? timeout}) =>
      completion.future;
}

const installedTable = r'''
Name                          Id                        Version   Available Source
------------------------------------------------------------------------------------
7-Zip 26.03 (x64)             7zip.7zip                 26.03     26.05     winget
Blender                       BlenderFoundation.Blender 5.2.2               winget
AbleHorse                     ARP\Machine\X64\AbleHorse 5.0.3.7
''';
