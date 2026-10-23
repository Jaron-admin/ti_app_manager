import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ti_app_manager/app/app.dart';
import 'package:ti_app_manager/app/providers.dart';
import 'package:ti_app_manager/shared/process_runner.dart';

import 'support/fake_process_runner.dart';

void main() {
  const found = CommandResult(exitCode: 0, stdoutText: searchTable);
  const known = CommandResult(exitCode: 0, stdoutText: installedTable);

  Future<RoutingProcessRunner> pumpDiscover(
    WidgetTester tester, {
    CommandResult search = found,
    CommandResult install = const CommandResult(exitCode: 0, stdoutText: ''),
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final runner = RoutingProcessRunner({
      'list': known,
      'search': search,
      'install': install,
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [processRunnerProvider.overrideWithValue(runner)],
        child: const TiApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-discover')));
    await tester.pumpAndSettle();
    return runner;
  }

  Future<void> submit(WidgetTester tester, String query) async {
    await tester.enterText(find.byKey(const Key('discover-search')), query);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  testWidgets('asks for a query before calling winget', (tester) async {
    final runner = await pumpDiscover(tester);

    expect(find.text('还没搜索'), findsOneWidget);
    expect(runner.calls.where((call) => call[1] == 'search'), isEmpty);
  });

  testWidgets('searches only when the query is submitted', (tester) async {
    final runner = await pumpDiscover(tester);

    await tester.enterText(find.byKey(const Key('discover-search')), '7zip');
    await tester.pump();

    expect(runner.calls.where((call) => call[1] == 'search'), isEmpty);
    expect(find.text('7-Zip'), findsNothing);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(runner.calls.where((call) => call[1] == 'search').single, [
      'winget',
      'search',
      '7zip',
      ...quiet,
    ]);
    expect(find.text('7-Zip'), findsOneWidget);
    expect(find.text('NanaZip'), findsOneWidget);
    expect(find.textContaining('msstore'), findsOneWidget);
  });

  testWidgets('marks a package already installed', (tester) async {
    await pumpDiscover(tester);
    await submit(tester, '7zip');

    // The sidebar also says 已安装, so only look inside the results.
    expect(
      find.descendant(
        of: find.byKey(const Key('discover-list')),
        matching: find.text('已安装'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('install-7zip.7zip')), findsNothing);
    expect(find.byKey(const Key('install-M2Team.NanaZip')), findsOneWidget);
  });

  testWidgets('installs after a confirmation and reloads the list', (
    tester,
  ) async {
    final runner = await pumpDiscover(tester);
    await submit(tester, '7zip');

    await tester.tap(find.byKey(const Key('install-M2Team.NanaZip')));
    await tester.pumpAndSettle();

    expect(find.text('安装 NanaZip？'), findsOneWidget);
    expect(find.text('M2Team.NanaZip'), findsOneWidget);
    expect(find.text('匹配 Tag: 7zip'), findsOneWidget);

    await tester.tap(find.byKey(const Key('install-confirm')));
    await tester.pumpAndSettle();

    expect(runner.calls.where((call) => call[1] == 'install').single, [
      'winget',
      'install',
      'M2Team.NanaZip',
      '--exact',
      '--source',
      'winget',
      '--silent',
      '--accept-package-agreements',
      ...quiet,
    ]);
    expect(find.text('装好了'), findsOneWidget);

    await tester.tap(find.byKey(const Key('install-close')));
    await tester.pumpAndSettle();

    expect(runner.calls.where((call) => call[1] == 'list').length, 2);
    expect(find.text('装好了'), findsNothing);
  });

  testWidgets('escape cancels the confirmation without installing', (
    tester,
  ) async {
    final runner = await pumpDiscover(tester);
    await submit(tester, '7zip');

    await tester.tap(find.byKey(const Key('install-M2Team.NanaZip')));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('安装 NanaZip？'), findsNothing);
    expect(runner.calls.where((call) => call[1] == 'install'), isEmpty);
  });

  testWidgets('keeps the failure message from winget', (tester) async {
    final runner = await pumpDiscover(tester);
    await submit(tester, '7zip');

    await tester.tap(find.byKey(const Key('install-M2Team.NanaZip')));
    await tester.pumpAndSettle();

    runner.byCommand['install'] = const CommandResult(
      exitCode: -1978335175,
      stdoutText: 'Found 1 package\nNo applicable installer\n',
    );
    await tester.tap(find.byKey(const Key('install-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('安装失败'), findsOneWidget);
    expect(find.textContaining('No applicable installer'), findsOneWidget);
    expect(runner.calls.where((call) => call[1] == 'list').length, 1);

    await tester.tap(find.byKey(const Key('install-close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('page-discover')), findsOneWidget);
  });
}
