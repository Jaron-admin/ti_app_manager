import 'package:ti_app_manager/shared/snapshot_store.dart';

/// Stands in for the file store: a widget test must never read or write the
/// real user profile.
class MemoryInstalledSnapshotStore implements InstalledSnapshotStore {
  MemoryInstalledSnapshotStore([this.snapshot]);

  InstalledSnapshot? snapshot;
  int readCount = 0;

  @override
  InstalledSnapshot? read() {
    readCount++;
    return snapshot;
  }

  @override
  void write(InstalledSnapshot snapshot) => this.snapshot = snapshot;
}
