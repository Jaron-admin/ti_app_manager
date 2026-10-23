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

  static const _quiet = [
    '--accept-source-agreements',
    // A prompt winget would show a human would hang us forever.
    '--disable-interactivity',
  ];

  Future<List<InstalledApp>> installedApps() async =>
      parseInstalledList(await _read(['list']));

  Future<List<UpdateEntry>> availableUpdates() async =>
      parseUpgradeList(await _read(['upgrade']));

  Future<List<SearchResult>> search(String query) async =>
      parseSearchResults(await _read(['search', query]));

  Future<void> update(UpdateEntry target) async {
    await _run(_write(['upgrade', '--id', target.id], target.source));
  }

  Future<void> install(SearchResult target) async {
    await _run(_write(['install', target.id], target.source));
  }

  List<String> _write(List<String> arguments, String source) => [
    _executable,
    ...arguments,
    '--exact',
    '--source',
    source,
    '--silent',
    '--accept-package-agreements',
    ..._quiet,
  ];

  Future<String?> version() async {
    try {
      final result = await _runner.run([_executable, '--version']);
      return result.isSuccess ? result.stdoutText.trim() : null;
    } on ProcessException {
      return null;
    }
  }

  Future<String> _read(List<String> arguments) async {
    final result = await _run([_executable, ...arguments, ..._quiet]);
    return result.stdoutText;
  }

  Future<CommandResult> _run(List<String> command) async {
    final result = await _runner.run(command);
    if (!result.isSuccess) {
      throw WingetException(_failure(result), exitCode: result.exitCode);
    }
    return result;
  }
}

/// winget fills stdout with progress lines, so the last written line is the one
/// that explains what happened.
String _failure(CommandResult result) {
  for (final text in [result.stderrText, result.stdoutText]) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isNotEmpty) return lines.last;
  }
  return 'winget 没有给出原因';
}
