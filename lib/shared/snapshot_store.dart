import 'dart:convert';
import 'dart:io';

import 'models.dart';

/// The rows from the last read that succeeded. winget needs around twenty
/// seconds to answer, so the first frame shows these while a fresh read runs.
class InstalledSnapshot {
  const InstalledSnapshot({required this.capturedAt, required this.apps});

  final DateTime capturedAt;
  final List<InstalledApp> apps;

  String get label =>
      '${capturedAt.year}-${_two(capturedAt.month)}-${_two(capturedAt.day)} '
      '${_two(capturedAt.hour)}:${_two(capturedAt.minute)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}

abstract class InstalledSnapshotStore {
  /// Null when there is nothing usable to show: reading the cache must never
  /// be the reason a page fails.
  InstalledSnapshot? read();

  void write(InstalledSnapshot snapshot);
}

/// One json file in the per-user data folder. The app is handed out as a
/// portable zip, so it writes nothing next to the executable.
class FileInstalledSnapshotStore implements InstalledSnapshotStore {
  FileInstalledSnapshotStore({required this.directory});

  /// Bump when the layout changes; an older or newer file is ignored, not
  /// migrated, because the next read overwrites it anyway.
  static const schema = 1;
  static const _fileName = 'installed-snapshot.json';

  final String directory;

  static String defaultDirectory() {
    final env = Platform.environment;
    final root = switch (env['LOCALAPPDATA']) {
      final String value when value.isNotEmpty => value,
      _ => '${env['HOME'] ?? '.'}${Platform.pathSeparator}.localappdata',
    };
    return '$root${Platform.pathSeparator}ti_app_manager';
  }

  File get _file => File('$directory${Platform.pathSeparator}$_fileName');

  @override
  InstalledSnapshot? read() {
    try {
      final decoded = jsonDecode(_file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['schema'] != schema) {
        return null;
      }
      final capturedAt = DateTime.tryParse('${decoded['capturedAt']}');
      final rows = decoded['apps'];
      if (capturedAt == null || rows is! List) return null;
      return InstalledSnapshot(
        capturedAt: capturedAt,
        apps: [
          for (final row in rows)
            if (row is Map<String, dynamic>) _appFrom(row),
        ],
      );
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  void write(InstalledSnapshot snapshot) {
    final body = jsonEncode({
      'schema': schema,
      'capturedAt': snapshot.capturedAt.toIso8601String(),
      'apps': [for (final app in snapshot.apps) _appTo(app)],
    });
    try {
      Directory(directory).createSync(recursive: true);
      _file.writeAsStringSync(body);
    } on FileSystemException {
      // Losing the cache costs the next startup its instant first frame and
      // nothing else, so a full or read-only folder is not worth reporting.
    }
  }
}

Map<String, dynamic> _appTo(InstalledApp app) => {
  'name': app.name,
  'id': app.id,
  'version': app.version,
  'available': app.availableVersion,
  'source': app.source,
};

InstalledApp _appFrom(Map<String, dynamic> json) => InstalledApp(
  name: '${json['name']}',
  id: '${json['id']}',
  version: '${json['version']}',
  availableVersion: json['available'] == null ? null : '${json['available']}',
  source: '${json['source'] ?? ''}',
);
