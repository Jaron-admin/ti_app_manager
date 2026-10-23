import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/bcu_locator.dart';
import '../shared/models.dart';
import '../shared/process_runner.dart';
import '../shared/registry_service.dart';
import '../shared/snapshot_store.dart';
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

final snapshotStoreProvider = Provider<InstalledSnapshotStore>(
  (ref) => FileInstalledSnapshotStore(
    directory: FileInstalledSnapshotStore.defaultDirectory(),
  ),
);

/// Read once per session, before winget has had time to answer.
final installedSnapshotProvider = Provider<InstalledSnapshot?>((ref) {
  final store = ref.watch(snapshotStoreProvider).read();
  return store == null || store.apps.isEmpty ? null : store;
});

final installedAppsProvider = FutureProvider<List<InstalledApp>>(
  (ref) async {
    final apps = await ref.watch(wingetProvider).installedApps();
    ref
        .watch(snapshotStoreProvider)
        .write(InstalledSnapshot(capturedAt: DateTime.now(), apps: apps));
    // Keep the cached value honest, so a later failed read falls back to these
    // rows rather than to the ones from before the last change.
    ref.invalidate(installedSnapshotProvider);
    return apps;
  },
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
