import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ti_app_manager/app/app.dart';
import 'package:ti_app_manager/app/providers.dart';
import 'package:ti_app_manager/design/tokens.dart';
import 'package:ti_app_manager/shared/process_runner.dart';

import 'support/fake_process_runner.dart';
import 'support/fake_snapshot_store.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, {ProcessRunner? runner}) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          processRunnerProvider.overrideWithValue(
            runner ??
                FakeProcessRunner(
                  const CommandResult(exitCode: 0, stdoutText: installedTable),
                ),
          ),
          snapshotStoreProvider.overrideWithValue(
            MemoryInstalledSnapshotStore(),
          ),
        ],
        child: const TiApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('only the section on screen gets read', (tester) async {
    final runner = RoutingProcessRunner(const {
      'list': CommandResult(exitCode: 0, stdoutText: installedTable),
      'upgrade': CommandResult(exitCode: 0, stdoutText: upgradeTable),
    });
    await pumpApp(tester, runner: runner);

    // winget needs ~20s per call, so an offscreen page must not queue a second
    // one before the user has even asked for it.
    expect(runner.calls.map((call) => call[1]), ['list']);

    await tester.tap(find.byKey(const Key('nav-updates')));
    await tester.pumpAndSettle();

    expect(runner.calls.map((call) => call[1]), ['list', 'upgrade']);
  });

  testWidgets('a visited page keeps its state when coming back', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('nav-installed')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('installed-search')), 'blend');
    await tester.pump();

    await tester.tap(find.byKey(const Key('nav-about')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-installed')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('installed-search')))
          .controller
          ?.text,
      'blend',
    );
    expect(find.text('Blender'), findsOneWidget);
  });

  testWidgets('shell shows the four destinations', (tester) async {
    await pumpApp(tester);

    expect(find.byKey(const Key('nav-installed')), findsOneWidget);
    expect(find.byKey(const Key('nav-updates')), findsOneWidget);
    expect(find.byKey(const Key('nav-discover')), findsOneWidget);
    expect(find.byKey(const Key('nav-about')), findsOneWidget);
    expect(find.byKey(const Key('page-installed')), findsOneWidget);
    final rowRect = tester.getRect(find.text('7-Zip 26.03 (x64)'));
    expect(rowRect.height, greaterThan(0));
    expect(rowRect.top, greaterThan(0));
    expect(find.text('Ti 软件管家'), findsWidgets);
  });

  testWidgets('tapping a destination switches the page', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('nav-discover')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('page-discover')), findsOneWidget);
    expect(find.byKey(const Key('page-installed')), findsNothing);
  });

  testWidgets('system dark mode selects the dark Ti palette', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpApp(tester);

    final context = tester.element(find.byKey(const Key('page-installed')));
    expect(Theme.of(context).colorScheme.primary, TiColors.primaryDark);
    expect(Theme.of(context).scaffoldBackgroundColor, TiColors.paperDark);
  });

  testWidgets('shell stays usable at 200% text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('nav-about')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('page-about')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
