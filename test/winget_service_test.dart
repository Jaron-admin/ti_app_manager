import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ti_app_manager/shared/process_runner.dart';
import 'package:ti_app_manager/shared/winget_service.dart';

class _FakeRunner implements ProcessRunner {
  _FakeRunner([this.result = const CommandResult(exitCode: 0, stdoutText: '')]);

  final CommandResult result;
  final List<List<String>> calls = [];

  @override
  Future<CommandResult> run(List<String> command, {Duration? timeout}) async {
    calls.add(command);
    return result;
  }
}

void main() {
  const listOutput = '''
Name                Id            Version   Available  Source
------------------------------------------------------------
7-Zip 26.03 (x64)   7zip.7zip     26.03     26.05      winget
''';

  group('commands', () {
    test('reads the installed table', () async {
      final runner = _FakeRunner(
        const CommandResult(exitCode: 0, stdoutText: listOutput),
      );
      final service = WingetService(runner: runner);

      final apps = await service.installedApps();

      expect(runner.calls.single, [
        'winget',
        'list',
        '--accept-source-agreements',
      ]);
      expect(apps.single.id, '7zip.7zip');
      expect(apps.single.availableVersion, '26.05');
    });

    test('reads the update table', () async {
      final runner = _FakeRunner(
        const CommandResult(exitCode: 0, stdoutText: listOutput),
      );
      final service = WingetService(runner: runner);

      final updates = await service.availableUpdates();

      expect(runner.calls.single, [
        'winget',
        'upgrade',
        '--accept-source-agreements',
      ]);
      expect(updates.single.currentVersion, '26.03');
      expect(updates.single.availableVersion, '26.05');
    });

    test('passes a query with spaces as one argument', () async {
      final runner = _FakeRunner();
      final service = WingetService(runner: runner);

      await service.search('visual c++');

      expect(runner.calls.single, [
        'winget',
        'search',
        'visual c++',
        '--accept-source-agreements',
      ]);
    });

    test('reads the installed engine version', () async {
      final runner = _FakeRunner(
        const CommandResult(exitCode: 0, stdoutText: 'v1.29.380\r\n'),
      );
      final service = WingetService(runner: runner);

      expect(await service.version(), 'v1.29.380');
      expect(runner.calls.single, ['winget', '--version']);
    });

    test('reports no engine when winget is missing', () async {
      final runner = _ThrowingRunner();
      final service = WingetService(runner: runner);

      expect(await service.version(), isNull);
    });

    test('fails with the engine message', () async {
      final runner = _FakeRunner(
        const CommandResult(
          exitCode: -1978335189,
          stdoutText: '',
          stderrText: 'No installed packages found.',
        ),
      );
      final service = WingetService(runner: runner);

      await expectLater(
        service.installedApps(),
        throwsA(
          isA<WingetException>().having(
            (error) => error.message,
            'message',
            'No installed packages found.',
          ),
        ),
      );
    });

    test('uses a configurable executable', () async {
      final runner = _FakeRunner();
      final service = WingetService(
        runner: runner,
        executable: r'C:\winget.exe',
      );

      await service.search('zip');

      expect(runner.calls.single.first, r'C:\winget.exe');
    });
  });

  group('SystemProcessRunner', () {
    test('decodes utf-8 output, not the ansi code page', () async {
      final result = await const SystemProcessRunner().run([
        'powershell',
        '-NoProfile',
        '-Command',
        r"[Console]::OutputEncoding=[Text.Encoding]::UTF8; 'AVC 编码器视频扩展'",
      ]);

      expect(result.isSuccess, isTrue);
      expect(result.stdoutText.trim(), 'AVC 编码器视频扩展');
    });

    test('reports a failing exit code and stderr', () async {
      final result = await const SystemProcessRunner().run([
        'cmd',
        '/c',
        'echo oops 1>&2 & exit 7',
      ]);

      expect(result.exitCode, 7);
      expect(result.isSuccess, isFalse);
      expect(result.stderrText, contains('oops'));
    });
  });
}

class _ThrowingRunner implements ProcessRunner {
  @override
  Future<CommandResult> run(List<String> command, {Duration? timeout}) =>
      throw ProcessException(command.first, command.sublist(1));
}
