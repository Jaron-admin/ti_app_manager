import 'dart:async';
import 'dart:convert';
import 'dart:io';

class CommandResult {
  const CommandResult({
    required this.exitCode,
    required this.stdoutText,
    this.stderrText = '',
  });

  final int exitCode;
  final String stdoutText;
  final String stderrText;

  bool get isSuccess => exitCode == 0;
}

abstract interface class ProcessRunner {
  Future<CommandResult> run(List<String> command, {Duration? timeout});
}

class SystemProcessRunner implements ProcessRunner {
  const SystemProcessRunner();

  @override
  Future<CommandResult> run(List<String> command, {Duration? timeout}) async {
    final process = await Process.start(command.first, command.sublist(1));
    final collected = Future.wait([
      _drain(process.stdout),
      _drain(process.stderr),
    ]);
    final exitCode = timeout == null
        ? await process.exitCode
        : await process.exitCode.timeout(
            timeout,
            onTimeout: () {
              process.kill(ProcessSignal.sigterm);
              throw TimeoutException(command.join(' '), timeout);
            },
          );
    final streams = await collected;

    return CommandResult(
      exitCode: exitCode,
      stdoutText: _decode(streams[0]),
      stderrText: _decode(streams[1]),
    );
  }
}

Future<List<int>> _drain(Stream<List<int>> stream) async {
  final bytes = <int>[];
  await for (final chunk in stream) {
    bytes.addAll(chunk);
  }
  return bytes;
}

// winget writes utf-8 while the Windows console default is an ansi code page.
String _decode(List<int> bytes) => utf8.decode(bytes, allowMalformed: true);
