import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ti_app_manager/app/app.dart';
import 'package:ti_app_manager/app/providers.dart';
import 'package:ti_app_manager/shared/process_runner.dart';

import 'support/fake_process_runner.dart';

void main() {
  Future<void> pumpInstalled(
    WidgetTester tester,
    ProcessRunner runner, {
    bool settle = true,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [processRunnerProvider.overrideWithValue(runner)],
        child: const TiApp(),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  const readTable = CommandResult(exitCode: 0, stdoutText: installedTable);

  testWidgets('lists software with versions and updates', (tester) async {
    await pumpInstalled(tester, FakeProcessRunner(readTable));

    expect(find.text('这台电脑上的 3 个软件'), findsOneWidget);
    expect(find.text('7-Zip 26.03 (x64)'), findsOneWidget);
    expect(find.text('可更新 26.05'), findsOneWidget);
    expect(find.text('Blender'), findsOneWidget);
    expect(find.text('本机'), findsOneWidget);

    final row = tester.getRect(find.text('7-Zip 26.03 (x64)'));
    expect(row.top, greaterThan(0));
    expect(row.height, greaterThan(0));
  });

  testWidgets('narrows the list while typing', (tester) async {
    await pumpInstalled(tester, FakeProcessRunner(readTable));

    await tester.enterText(find.byKey(const Key('installed-search')), 'blend');
    await tester.pump();

    expect(find.text('Blender'), findsOneWidget);
    expect(find.text('7-Zip 26.03 (x64)'), findsNothing);
    expect(find.text('AbleHorse'), findsNothing);

    await tester.enterText(find.byKey(const Key('installed-search')), 'arp');
    await tester.pump();

    expect(find.text('AbleHorse'), findsOneWidget);
    expect(find.text('Blender'), findsNothing);

    await tester.enterText(find.byKey(const Key('installed-search')), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('没有匹配的软件'), findsOneWidget);
  });

  testWidgets('waits for winget before showing rows', (tester) async {
    final runner = PendingProcessRunner();
    await pumpInstalled(tester, runner, settle: false);

    expect(find.text('正在读取'), findsOneWidget);
    expect(find.byKey(const Key('installed-list')), findsNothing);

    runner.completion.complete(readTable);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('installed-list')), findsOneWidget);
    expect(find.text('正在读取'), findsNothing);
  });

  testWidgets('offers a retry when winget fails', (tester) async {
    final runner = FakeProcessRunner(
      const CommandResult(
        exitCode: 1,
        stdoutText: '',
        stderrText: 'The term source could not be found.',
      ),
    );
    await pumpInstalled(tester, runner);

    expect(find.text('读取失败'), findsOneWidget);
    expect(
      find.textContaining('The term source could not be found.'),
      findsOneWidget,
    );

    runner.result = readTable;
    await tester.tap(find.byKey(const Key('installed-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('installed-list')), findsOneWidget);
    expect(find.text('读取失败'), findsNothing);
  });

  testWidgets('shows an empty library without a filter', (tester) async {
    await pumpInstalled(
      tester,
      FakeProcessRunner(
        const CommandResult(
          exitCode: 0,
          stdoutText: 'No installed packages found.',
        ),
      ),
    );

    expect(find.text('没有软件'), findsOneWidget);
    expect(find.text('这台电脑上的 0 个软件'), findsOneWidget);
  });
}
