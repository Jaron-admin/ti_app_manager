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

/// Answers per command so a page can search, install and reload. `route` picks
/// the key, because the uninstall flow talks to winget and to powershell.
class RoutingProcessRunner implements ProcessRunner {
  RoutingProcessRunner(this.byCommand, {String Function(List<String>)? route})
    : _route = route ?? _wingetVerb;

  final Map<String, CommandResult> byCommand;
  final String Function(List<String> command) _route;
  final List<List<String>> calls = [];

  static String _wingetVerb(List<String> command) =>
      command.length > 1 ? command[1] : command[0];

  @override
  Future<CommandResult> run(List<String> command, {Duration? timeout}) async {
    calls.add(command);
    return byCommand[_route(command)] ??
        const CommandResult(exitCode: 0, stdoutText: '');
  }
}

/// Answers from a queue per winget subcommand, so a batch can fail after the
/// first read succeeded. The last answer stays in place.
class SequencedProcessRunner implements ProcessRunner {
  SequencedProcessRunner(Map<String, List<CommandResult>> byCommand)
    : _byCommand = {
        for (final entry in byCommand.entries) entry.key: [...entry.value],
      };

  final Map<String, List<CommandResult>> _byCommand;
  final List<List<String>> calls = [];

  @override
  Future<CommandResult> run(List<String> command, {Duration? timeout}) async {
    calls.add(command);
    final verb = command.length > 1 ? command[1] : command[0];
    final queue = _byCommand[verb];
    if (queue == null || queue.isEmpty) {
      return const CommandResult(exitCode: 0, stdoutText: '');
    }
    return queue.length == 1 ? queue.first : queue.removeAt(0);
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

const upgradeTable = r'''
Name                        Id                      Version          Available        Source
---------------------------------------------------------------------------------------------
7-Zip 26.03 (x64)           7zip.7zip               26.03            26.05            winget
LocalSend 版本 1.17.0       LocalSend.LocalSend     1.17.0           1.18.2           winget
PowerToys (Preview) x64     XP89DCGQ3K6VLD          0.101.2362.0     0.102.2933.0     msstore
''';

/// What powershell answers for a key that registers a silent uninstaller: the
/// quiet string, a tab, then the interactive one.
const registryLine =
    '"D:\\App\\AbleHorse\\Uninstall.exe" /S'
    '\t'
    '"D:\\App\\AbleHorse\\Uninstall.exe"';

/// A key that exists but never registered an uninstaller at all.
const registryNothing = '\t';
