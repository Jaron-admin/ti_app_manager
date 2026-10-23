import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ti_app_manager/shared/models.dart';
import 'package:ti_app_manager/shared/winget_output_parser.dart';

void main() {
  Future<String> fixture(String name) async =>
      File('test/fixtures/$name').readAsString();

  group('installed list', () {
    test('reads rows, updates and missing source', () async {
      final apps = parseInstalledList(await fixture('winget_list.txt'));

      expect(apps, isNotEmpty);
      final sevenZip = apps.firstWhere((app) => app.id == '7zip.7zip');
      expect(sevenZip.name, '7-Zip 26.03 (x64)');
      expect(sevenZip.version, '26.03');
      expect(sevenZip.availableVersion, '26.05');
      expect(sevenZip.source, 'winget');
      expect(sevenZip.updateAvailable, isTrue);

      final localOnly = apps.firstWhere((app) => app.name == '3x-ui');
      expect(localOnly.id, r'ARP\User\X64\0257f8863d4ebf4ebf2d5c0a828395a9');
      expect(localOnly.version, '1.0');
      expect(localOnly.availableVersion, isNull);
      expect(localOnly.source, isEmpty);
      expect(localOnly.updateAvailable, isFalse);

      final msix = apps.firstWhere((app) => app.name == 'Apple Music');
      expect(msix.id, startsWith(r'MSIX\'));
      expect(msix.version, '1.1540.23042.0');
      expect(msix.availableVersion, isNull);
    });

    test('keeps Chinese names intact', () async {
      final apps = parseInstalledList(await fixture('winget_list.txt'));

      expect(apps.map((app) => app.name), contains('AVC 编码器视频扩展'));
    });

    test('returns nothing when winget has no packages', () {
      expect(parseInstalledList('No installed packages found.'), isEmpty);
    });
  });

  group('upgrade list', () {
    test('reads current and available versions', () async {
      final updates = parseUpgradeList(await fixture('winget_upgrade.txt'));

      expect(updates, isNotEmpty);
      final sevenZip = updates.firstWhere((update) => update.id == '7zip.7zip');
      expect(sevenZip.name, '7-Zip 26.03 (x64)');
      expect(sevenZip.currentVersion, '26.03');
      expect(sevenZip.availableVersion, '26.05');
      expect(sevenZip.source, 'winget');

      final localSend = updates.firstWhere(
        (update) => update.name == 'LocalSend 版本 1.17.0',
      );
      expect(localSend.id, 'LocalSend.LocalSend');
      expect(localSend.currentVersion, '1.17.0');
      expect(localSend.availableVersion, '1.18.2');

      final launcher = updates.firstWhere(
        (update) => update.id == 'Python.Launcher',
      );
      expect(launcher.currentVersion, '< 3.14.7');
    });

    test('returns nothing when everything is current', () {
      expect(parseUpgradeList('No applicable update found.'), isEmpty);
    });
  });

  group('search results', () {
    test('reads match column and msstore rows', () async {
      final results = parseSearchResults(await fixture('winget_search.txt'));

      expect(results, isNotEmpty);
      final sevenZip = results.firstWhere((result) => result.id == '7zip.7zip');
      expect(sevenZip.name, '7-Zip');
      expect(sevenZip.version, '26.05');
      expect(sevenZip.match, 'Moniker: 7zip');
      expect(sevenZip.source, 'winget');

      final store = results.firstWhere((result) => result.source == 'msstore');
      expect(store.name, '7zip解压缩软件');
      expect(store.id, 'XP8C87R6J42SKH');
      expect(store.version, 'Unknown');
      expect(store.match, isEmpty);

      final crowded = results.firstWhere(
        (result) => result.id == 'Elcomsoft.ArchivePassword',
      );
      expect(crowded.name, 'Advanced Archive Password Recovery');
      expect(crowded.version, '4.66.266.6965');
      expect(crowded.match, 'Tag: 7zip');
    });
  });

  group('InstalledApp', () {
    test('is not update-ready without an available version', () {
      const app = InstalledApp(
        name: 'Demo',
        id: 'Demo.App',
        version: '1.0',
        source: 'winget',
      );

      expect(app.updateAvailable, isFalse);
    });
  });
}
