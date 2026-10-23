import 'dart:io';

import 'models.dart';
import 'process_runner.dart';
import 'winget_output_parser.dart';

class WingetException implements Exception {
  const WingetException(this.message, {required this.exitCode});

  final String message;
  final int exitCode;

  @override
  String toString() => 'winget exited with $exitCode: $message';
}

class WingetService {
  WingetService({required ProcessRunner runner, String executable = 'winget'})
    : _runner = runner,
      _executable = executable;

  final ProcessRunner _runner;
  final String _executable;

  Future<List<InstalledApp>> installedApps() async =>
      parseInstalledList(await _table(['list']));

  Future<List<UpdateEntry>> availableUpdates() async =>
      parseUpgradeList(await _table(['upgrade']));

  Future<List<SearchResult>> search(String query) async =>
      parseSearchResults(await _table(['search', query]));

  Future<String?> version() async {
    try {
      final result = await _runner.run([_executable, '--version']);
      return result.isSuccess ? result.stdoutText.trim() : null;
    } on ProcessException {
      return null;
    }
  }

  Future<String> _table(List<String> arguments) async {
    final result = await _runner.run([
      _executable,
      ...arguments,
      '--accept-source-agreements',
      // A prompt winget would show a human would hang us forever.
      '--disable-interactivity',
    ]);
    if (!result.isSuccess) {
      final message = result.stderrText.trim().isEmpty
          ? result.stdoutText.trim()
          : result.stderrText.trim();
      throw WingetException(message, exitCode: result.exitCode);
    }
    return result.stdoutText;
  }
}
