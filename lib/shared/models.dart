class InstalledApp {
  const InstalledApp({
    required this.name,
    required this.id,
    required this.version,
    this.availableVersion,
    this.source = '',
  });

  final String name;
  final String id;
  final String version;
  final String? availableVersion;
  final String source;

  bool get updateAvailable =>
      availableVersion != null && availableVersion! != version;
}

class UpdateEntry {
  const UpdateEntry({
    required this.name,
    required this.id,
    required this.currentVersion,
    required this.availableVersion,
    this.source = '',
  });

  final String name;
  final String id;
  final String currentVersion;
  final String availableVersion;
  final String source;
}

class SearchResult {
  const SearchResult({
    required this.name,
    required this.id,
    required this.version,
    this.match = '',
    this.source = '',
  });

  final String name;
  final String id;
  final String version;
  final String match;
  final String source;
}
