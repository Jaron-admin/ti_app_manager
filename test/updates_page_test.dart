import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ti_app_manager/app/app.dart';
import 'package:ti_app_manager/app/providers.dart';
import 'package:ti_app_manager/shared/process_runner.dart';

import 'support/fake_process_runner.dart';

void main() {
  const updates = CommandResult(exitCode: 0, stdoutText: upgradeTable);
  const known = CommandResult(exitCode: 0, stdoutText: installedTable);
  const failed = CommandResult(
    exitCode: 5,
    stdoutText: 'No applicable installer was found.',
  );

  Future<SequencedProcessRunner> pumpUpdates(
    WidgetTester tester, {
    List<CommandResult> upgrade = const [updates],
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final runner = SequencedProcessRunner({
      'upgrade': upgrade,
      'list': [known],
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [processRunnerProvider.overrideWithValue(runner)],
        child: const TiApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-updates')));
    await tester.pumpAndSettle();
    return runner;
  }

  Checkbox checkbox(WidgetTester tester, String id) =>
      tester.widget<Checkbox>(find.byKey(Key('check-$id')));

  Checkbox selectAll(WidgetTester tester) =>
      tester.widget<Checkbox>(find.byKey(const Key('updates-select-all')));

  testWidgets('lists what winget can upgrade', (tester) async {
    await pumpUpdates(tester);

    expect(find.text('3 个软件可以更新'), findsOneWidget);
    expect(find.text('LocalSend 版本 1.17.0'), findsOneWidget);
    expect(find.text('1.17.0'), findsOneWidget);
    expect(find.text('→ 1.18.2'), findsOneWidget);
    expect(find.textContaining('msstore'), findsOneWidget);
  });

  testWidgets('starts with every update selected', (tester) async {
    await pumpUpdates(tester);

    expect(find.text('更新 3 个'), findsOneWidget);
    expect(checkbox(tester, '7zip.7zip').value, isTrue);
    expect(selectAll(tester).value, isTrue);

    await tester.tap(find.byKey(const Key('check-7zip.7zip')));
    await tester.pumpAndSettle();

    expect(find.text('更新 2 个'), findsOneWidget);
    expect(selectAll(tester).value, isNull);
  });

  testWidgets('confirms before running winget per package', (tester) async {
    final runner = await pumpUpdates(tester);

    await tester.tap(find.byKey(const Key('check-XP89DCGQ3K6VLD')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('updates-run')));
    await tester.pumpAndSettle();

    expect(find.text('更新 2 个软件？'), findsOneWidget);
    expect(find.text('开始更新'), findsOneWidget);

    await tester.tap(find.byKey(const Key('updates-confirm')));
    await tester.pumpAndSettle();

    final run = runner.calls.where((call) => call[1] == 'upgrade').skip(1);
    expect(run.map((call) => call.join(' ')), [
      'winget upgrade --id 7zip.7zip --exact --source winget --silent --accept-package-agreements ${quiet.join(' ')}',
      'winget upgrade --id LocalSend.LocalSend --exact --source winget --silent --accept-package-agreements ${quiet.join(' ')}',
    ]);
    expect(find.text('完成 2'), findsOneWidget);
    // The hidden installed page only re-reads winget once it is shown again.
    await tester.tap(find.byKey(const Key('nav-installed')));
    await tester.pumpAndSettle();
    expect(runner.calls.where((call) => call[1] == 'list').length, 2);
  });

  testWidgets('keeps going when a package fails', (tester) async {
    final runner = await pumpUpdates(tester, upgrade: const [updates, failed]);

    await tester.tap(find.byKey(const Key('updates-run')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('updates-confirm')));
    await tester.pumpAndSettle();

    expect(runner.calls.where((call) => call[1] == 'upgrade').length, 4);
    expect(find.textContaining('失败 3'), findsOneWidget);
    expect(find.textContaining('No applicable installer'), findsOneWidget);
    // Nothing was upgraded, so the installed list must not be re-read.
    expect(runner.calls.where((call) => call[1] == 'list').length, 1);
  });

  testWidgets('offers a retry when the check fails', (tester) async {
    await pumpUpdates(tester, upgrade: const [failed, updates]);

    expect(find.text('检查失败'), findsOneWidget);
    expect(find.textContaining('No applicable installer'), findsOneWidget);

    await tester.tap(find.byKey(const Key('updates-retry')));
    await tester.pumpAndSettle();

    expect(find.text('3 个软件可以更新'), findsOneWidget);
  });
}
