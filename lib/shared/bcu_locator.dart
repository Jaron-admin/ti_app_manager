import 'dart:io';

class BcuInstall {
  const BcuInstall({required this.directory, required this.guiExe});

  final String directory;
  final String guiExe;
}

/// BCUninstaller is an optional engine: we point at the user's own copy
/// instead of shipping a third-party binary inside our zip.
class BcuLocator {
  const BcuLocator({
    required Map<String, String> environment,
    required bool Function(String path) fileExists,
  }) : _environment = environment,
       _fileExists = fileExists;

  factory BcuLocator.system() => BcuLocator(
    environment: Platform.environment,
    fileExists: (path) => File(path).existsSync(),
  );

  static const _folder = 'BCUninstaller';
  static const _roots = ['ProgramFiles', 'ProgramFiles(x86)', 'LocalAppData'];

  final Map<String, String> _environment;
  final bool Function(String path) _fileExists;

  BcuInstall? find() {
    for (final root in _roots) {
      final path = _environment[root];
      if (path == null) continue;
      final directory = '$path\\$_folder';
      final gui = '$directory\\BCUninstaller.exe';
      if (!_fileExists(gui)) continue;

      return BcuInstall(directory: directory, guiExe: gui);
    }
    return null;
  }
}
