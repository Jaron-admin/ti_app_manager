import 'dart:async';

import 'package:ti_app_manager/shared/process_runner.dart';

/// Every winget call must carry these, or a prompt can hang the app.
const quiet = ['--accept-source-agreements', '--disable-interactivity'];

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

/// Answers per winget subcommand so a page can search, install and reload.
class RoutingProcessRunner implements ProcessRunner {
  RoutingProcessRunner(this.byCommand);

  final Map<String, CommandResult> byCommand;
  final List<List<String>> calls = [];

  @override
  Future<CommandResult> run(List<String> command, {Duration? timeout}) async {
    calls.add(command);
    final verb = command.length > 1 ? command[1] : command[0];
    return byCommand[verb] ?? const CommandResult(exitCode: 0, stdoutText: '');
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

const searchTable = r'''
Name                Id              Version     Match         Source
----------------------------------------------------------------------
7-Zip               7zip.7zip       26.05       Moniker: 7zip winget
NanaZip             M2Team.NanaZip  7.0.1873.0  Tag: 7zip     winget
7zip tool           XP8C87R6J42SKH  Unknown                   msstore
''';
