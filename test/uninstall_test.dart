import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ti_app_manager/app/app.dart';
import 'package:ti_app_manager/app/providers.dart';
import 'package:ti_app_manager/features/installed/uninstall_action.dart';
import 'package:ti_app_manager/shared/bcu_locator.dart';
import 'package:ti_app_manager/shared/process_runner.dart';

import 'support/fake_process_runner.dart';
import 'support/fake_snapshot_store.dart';

void main() {
  const readTable = CommandResult(exitCode: 0, stdoutText: installedTable);
  const bcuExe = r'C:\Program Files\BCUninstaller\BCUninstaller.exe';

  // winget is asked by subcommand, the registry by the executable name, and
  // an uninstaller launched on its own has no subcommand to read.
  String route(List<String> command) => switch (command.first) {
    'powershell' => 'registry',
    _ => command.length > 1 ? command[1] : command[0],
  };

  Future<RoutingProcessRunner> pumpUninstall(
    WidgetTester tester,
    Map<String, CommandResult> answers, {
    bool bcuInstalled = false,
  }) async {
    final runner = RoutingProcessRunner(answers, route: route);
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          processRunnerProvider.overrideWithValue(runner),
          snapshotStoreProvider.overrideWithValue(
            MemoryInstalledSnapshotStore(),
          ),
          bcuLocatorProvider.overrideWithValue(
            BcuLocator(
              environment: const {'ProgramFiles': r'C:\Program Files'},
              fileExists: bcuInstalled ? {bcuExe}.contains : (_) => false,
            ),
          ),
        ],
        child: const TiApp(),
      ),
    );
    await tester.pumpAndSettle();
    return runner;
  }

  Future<void> openMenu(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(Key('uninstall-$id')));
    await tester.pumpAndSettle();
  }

  bool disabled(WidgetTester tester, String label) {
    final item = tester.widget<PopupMenuItem<UninstallEngine>>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(PopupMenuItem<UninstallEngine>),
      ),
    );
    return !item.enabled;
  }

  testWidgets('offers only the engines a row can actually use', (tester) async {
    await pumpUninstall(tester, const {'list': readTable});

    // AbleHorse came from the registry: winget never tracked it, no BCU here.
    await openMenu(tester, r'ARP\Machine\X64\AbleHorse');
    expect(disabled(tester, 'winget 卸载'), isTrue);
    expect(disabled(tester, 'BCU 深度清理'), isTrue);
    expect(disabled(tester, '程序自带卸载器'), isFalse);

    await tester.tapAt(const Offset(1200, 700));
    await tester.pumpAndSettle();

    await openMenu(tester, '7zip.7zip');
    expect(disabled(tester, 'winget 卸载'), isFalse);
    expect(find.text('无注册表项'), findsOneWidget);
  });

  testWidgets('uninstalls through winget and reloads the list', (tester) async {
    final runner = await pumpUninstall(tester, const {'list': readTable});

    await openMenu(tester, '7zip.7zip');
    await tester.tap(find.text('winget 卸载'));
    await tester.pumpAndSettle();

    expect(find.text('卸载 7-Zip 26.03 (x64)？'), findsOneWidget);
    expect(find.textContaining('--source winget'), findsOneWidget);

    await tester.tap(find.byKey(const Key('uninstall-confirm')));
    await tester.pumpAndSettle();

    expect(
      runner.calls
          .where((call) => call[1] == 'uninstall')
          .map((call) => call.join(' '))
          .toList(),
      [
        'winget uninstall --id 7zip.7zip --exact --source winget --silent '
            '--accept-package-agreements ${quiet.join(' ')}',
      ],
    );
    expect(find.text('卸载完成'), findsOneWidget);

    await tester.tap(find.byKey(const Key('uninstall-close')));
    await tester.pumpAndSettle();

    expect(runner.calls.where((call) => call[1] == 'list').length, 2);
  });

  testWidgets('shows the registry command before running the quiet one', (
    tester,
  ) async {
    final runner = await pumpUninstall(tester, const {
      'list': readTable,
      'registry': CommandResult(exitCode: 0, stdoutText: registryLine),
    });

    await openMenu(tester, r'ARP\Machine\X64\AbleHorse');
    await tester.tap(find.text('程序自带卸载器'));
    await tester.pumpAndSettle();

    expect(
      runner.calls.last.join(' '),
      allOf(
        startsWith('powershell -NoProfile -NonInteractive -Command'),
        contains(
          r'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion'
          r'\Uninstall\AbleHorse',
        ),
      ),
    );
    expect(
      find.textContaining('"D:\\App\\AbleHorse\\Uninstall.exe" /S'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('uninstall-confirm')));
    await tester.pumpAndSettle();

    expect(runner.calls.last, [r'D:\App\AbleHorse\Uninstall.exe', '/S']);
    expect(find.text('卸载完成'), findsOneWidget);
  });

  testWidgets('says so when the registry has no uninstaller', (tester) async {
    final runner = await pumpUninstall(tester, const {
      'list': readTable,
      'registry': CommandResult(exitCode: 0, stdoutText: registryNothing),
    });

    await openMenu(tester, r'ARP\Machine\X64\AbleHorse');
    await tester.tap(find.text('程序自带卸载器'));
    await tester.pumpAndSettle();

    expect(find.text('这个程序没有登记卸载命令。'), findsOneWidget);
    expect(find.byKey(const Key('uninstall-confirm')), findsNothing);

    await tester.tap(find.byKey(const Key('uninstall-cancel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('page-installed')), findsOneWidget);
    expect(
      runner.calls.where((call) => call.first == 'powershell'),
      hasLength(1),
    );
  });

  testWidgets('opens the local BCUninstaller for a deep clean', (tester) async {
    final runner = await pumpUninstall(tester, const {
      'list': readTable,
    }, bcuInstalled: true);

    await openMenu(tester, r'ARP\Machine\X64\AbleHorse');
    await tester.tap(find.text('BCU 深度清理'));
    await tester.pumpAndSettle();

    expect(find.text('在 BCUninstaller 里清理 AbleHorse？'), findsOneWidget);
    expect(find.text(r'C:\Program Files\BCUninstaller'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bcu-open')));
    await tester.pumpAndSettle();

    expect(runner.calls.last, [bcuExe]);
    expect(find.byKey(const Key('page-installed')), findsOneWidget);
  });

  testWidgets('cancelling runs no process at all', (tester) async {
    final runner = await pumpUninstall(tester, const {'list': readTable});

    await openMenu(tester, '7zip.7zip');
    await tester.tap(find.text('winget 卸载'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('uninstall-cancel')));
    await tester.pumpAndSettle();

    // Cancelling must not spawn anything: the only call is the startup read
    // for the page on screen.
    expect(runner.calls.map((call) => call.take(2).join(' ')), ['winget list']);
  });

  testWidgets('reports the engine error instead of hiding it', (tester) async {
    await pumpUninstall(tester, const {
      'list': readTable,
      'uninstall': CommandResult(
        exitCode: 1,
        stdoutText: 'No packages found matching the given criteria.',
      ),
    });

    await openMenu(tester, '7zip.7zip');
    await tester.tap(find.text('winget 卸载'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('uninstall-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('卸载失败'), findsOneWidget);
    expect(
      find.textContaining('No packages found matching the given criteria.'),
      findsOneWidget,
    );
  });
}
