import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/models.dart';
import '../shared/process_runner.dart';
import '../shared/winget_service.dart';

final processRunnerProvider = Provider<ProcessRunner>(
  (ref) => const SystemProcessRunner(),
);

final wingetProvider = Provider<WingetService>(
  (ref) => WingetService(runner: ref.watch(processRunnerProvider)),
);

final installedAppsProvider = FutureProvider<List<InstalledApp>>(
  (ref) => ref.watch(wingetProvider).installedApps(),
  // A winget failure is deterministic, so never respawn the process on a timer.
  retry: (_, _) => null,
);
