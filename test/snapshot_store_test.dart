import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ti_app_manager/shared/models.dart';
import 'package:ti_app_manager/shared/snapshot_store.dart';

void main() {
  late Directory folder;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('ti_snapshot');
  });

  tearDown(() => folder.deleteSync(recursive: true));

  FileInstalledSnapshotStore store() =>
      FileInstalledSnapshotStore(directory: folder.path);

  const apps = [
    InstalledApp(
      name: '7-Zip 26.03 (x64)',
      id: '7zip.7zip',
      version: '26.03',
      availableVersion: '26.05',
      source: 'winget',
    ),
    InstalledApp(
      name: 'AbleHorse',
      id: r'ARP\Machine\X64\AbleHorse',
      version: '5.0.3.7',
    ),
  ];

  test('round-trips rows and the capture time', () {
    store().write(
      InstalledSnapshot(capturedAt: DateTime(2026, 10, 23, 9, 5), apps: apps),
    );

    final snapshot = store().read();

    expect(snapshot?.capturedAt, DateTime(2026, 10, 23, 9, 5));
    expect(snapshot?.apps.length, 2);
    expect(snapshot?.apps.first.availableVersion, '26.05');
    // The row without a source is a registry entry: nothing to restore.
    expect(snapshot?.apps.last.source, '');
    expect(snapshot?.apps.last.updateAvailable, isFalse);
  });

  test('a missing file is an empty cache, not an error', () {
    expect(store().read(), isNull);
  });

  test('rows from a newer format are ignored rather than half-read', () {
    File(
      '${folder.path}${Platform.pathSeparator}installed-snapshot.json',
    ).writeAsStringSync(
      '{"schema":99,"capturedAt":"2026-10-23T09:05:00.000","apps":[]}',
    );

    expect(store().read(), isNull);
  });

  test('a half-written file is ignored rather than thrown at the page', () {
    File(
      '${folder.path}${Platform.pathSeparator}installed-snapshot.json',
    ).writeAsStringSync('{"schema":1,"apps":[{');

    expect(store().read(), isNull);
  });
}
