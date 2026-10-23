import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/bcu_locator.dart';
import '../shared/models.dart';
import '../shared/process_runner.dart';
import '../shared/registry_service.dart';
import '../shared/winget_service.dart';

final processRunnerProvider = Provider<ProcessRunner>(
  (ref) => const SystemProcessRunner(),
);

final wingetProvider = Provider<WingetService>(
  (ref) => WingetService(runner: ref.watch(processRunnerProvider)),
);

final registryProvider = Provider<RegistryService>(
  (ref) => RegistryService(runner: ref.watch(processRunnerProvider)),
);

final installedAppsProvider = FutureProvider<List<InstalledApp>>(
  (ref) => ref.watch(wingetProvider).installedApps(),
  // A winget failure is deterministic, so never respawn the process on a timer.
  retry: (_, _) => null,
);

final availableUpdatesProvider = FutureProvider<List<UpdateEntry>>(
  (ref) => ref.watch(wingetProvider).availableUpdates(),
  retry: (_, _) => null,
);

final discoverSearchProvider =
    FutureProvider.family<List<SearchResult>, String>(
      (ref, query) => ref.watch(wingetProvider).search(query),
      retry: (_, _) => null,
    );

final bcuLocatorProvider = Provider<BcuLocator>((ref) => BcuLocator.system());

/// Null when the user never installed BCUninstaller: the engine stays a
/// suggestion, so we ask for the deep clean instead of shipping it.
final bcuInstallProvider = Provider<BcuInstall?>(
  (ref) => ref.watch(bcuLocatorProvider).find(),
);

/// One powershell call per app, so it runs when a row is opened rather than
/// for all 200 rows of the list.
final uninstallerProvider = FutureProvider.family<RegistryUninstall?, String>(
  (ref, id) => ref.watch(registryProvider).uninstaller(id),
  retry: (_, _) => null,
);
