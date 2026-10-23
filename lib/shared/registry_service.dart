import 'process_runner.dart';

/// A registry entry that says how to remove the program behind it.
class RegistryUninstall {
  const RegistryUninstall({
    required this.path,
    required this.command,
    required this.quietCommand,
  });

  final String path;
  final String command;
  final String quietCommand;

  /// The vendor's own silent switch beats the interactive one.
  String get preferred => quietCommand.isNotEmpty ? quietCommand : command;
}

class RegistryException implements Exception {
  const RegistryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// winget names registry entries `ARP\<scope>\<arch>\<key name>`; ids from
/// another source have no key we could look up.
String? arpKeyPath(String id) {
  final parts = id.split(r'\');
  if (parts.length != 4 || parts.first != 'ARP') return null;
  final hive = switch (parts[1]) {
    'Machine' => 'HKLM',
    'User' => 'HKCU',
    _ => null,
  };
  final view = switch (parts[2]) {
    'X86' => r'SOFTWARE\WOW6432Node',
    'X64' => 'SOFTWARE',
    'Neutral' => 'SOFTWARE',
    _ => null,
  };
  if (hive == null || view == null || parts[3].isEmpty) return null;

  return '$hive\\$view\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${parts[3]}';
}

/// Reads `UninstallString` out of the registry. `reg query` writes the ansi code
/// page, which turns a Chinese path into mojibake, so powershell is asked to
/// switch its own output to utf-8 first.
class RegistryService {
  RegistryService({required ProcessRunner runner}) : _runner = runner;

  final ProcessRunner _runner;

  Future<RegistryUninstall?> uninstaller(String id) async {
    final path = arpKeyPath(id);
    if (path == null) return null;

    final result = await _runner.run([
      'powershell',
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      '[Console]::OutputEncoding=[Text.Encoding]::UTF8;'
      r' $p = Get-ItemProperty -LiteralPath '
      '${_quoted(_providerPath(path))}'
      r' -ErrorAction SilentlyContinue;'
      r' "$($p.QuietUninstallString)`t$($p.UninstallString)"',
    ]);
    if (!result.isSuccess) return null;

    final line = result.stdoutText.split('\n').first.split('\r').first;
    final values = line.split('\t');
    if (values.length != 2) return null;
    final quiet = values.first.trim();
    final command = values.last.trim();
    if (quiet.isEmpty && command.isEmpty) return null;

    return RegistryUninstall(
      path: path,
      command: command,
      quietCommand: quiet,
    );
  }

  Future<void> run(RegistryUninstall entry) async {
    final split = splitUninstallCommand(entry.preferred);
    if (split == null) {
      throw const RegistryException('注册表里没有可执行的卸载命令。');
    }
    final result = await _runner.run([split.exe, ...split.args]);
    if (!result.isSuccess) {
      throw RegistryException('卸载器退出码 ${result.exitCode}。');
    }
  }
}

({String exe, List<String> args})? splitUninstallCommand(String command) {
  final text = command.trim();
  if (text.isEmpty) return null;

  String exe;
  String rest;
  if (text.startsWith('"')) {
    final end = text.indexOf('"', 1);
    if (end == -1) {
      exe = text.substring(1);
      rest = '';
    } else {
      exe = text.substring(1, end);
      rest = text.substring(end + 1);
    }
  } else {
    // Plenty of vendors write `C:\Program Files\App\uninstall.exe" /S`, with
    // the opening quote missing, so the extension is the safer cut point.
    final cut = RegExp(r'\.exe(?=["\s]|$)', caseSensitive: false).firstMatch(text);
    if (cut == null) {
      final first = text.split(RegExp(r'[\s"]+')).first;
      exe = first;
      rest = text.substring(first.length);
    } else {
      exe = text.substring(0, cut.end);
      rest = text.substring(cut.end);
    }
  }

  final args = rest
      .replaceAll('"', '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((arg) => arg.isNotEmpty)
      .toList();
  return (exe: exe, args: args);
}

String _providerPath(String keyPath) {
  final split = keyPath.indexOf('\\');
  return '${keyPath.substring(0, split)}:\\${keyPath.substring(split + 1)}';
}

String _quoted(String value) => "'${value.replaceAll("'", "''")}'";
