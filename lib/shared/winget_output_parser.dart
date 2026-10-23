import 'models.dart';

List<InstalledApp> parseInstalledList(String output) {
  return _table(output, _installedHeaders).map((row) {
    return InstalledApp(
      name: row[0],
      id: row[1],
      version: row[2],
      availableVersion: row[3].isEmpty ? null : row[3],
      source: row[4],
    );
  }).toList();
}

List<UpdateEntry> parseUpgradeList(String output) {
  return _table(output, _upgradeHeaders).map((row) {
    return UpdateEntry(
      name: row[0],
      id: row[1],
      currentVersion: row[2],
      availableVersion: row[3],
      source: row[4],
    );
  }).toList();
}

List<SearchResult> parseSearchResults(String output) {
  return _table(output, _searchHeaders).map((row) {
    return SearchResult(
      name: row[0],
      id: row[1],
      version: row[2],
      match: row[3],
      source: row[4],
    );
  }).toList();
}

const _installedHeaders = ['Name', 'Id', 'Version', 'Available', 'Source'];
const _upgradeHeaders = ['Name', 'Id', 'Version', 'Available', 'Source'];
const _searchHeaders = ['Name', 'Id', 'Version', 'Match', 'Source'];

final _lineBreak = RegExp(r'\r\n|\r|\n');
final _separatorLine = RegExp(r'^[-\s]+$');

List<List<String>> _table(String output, List<String> headers) {
  final lines = output.split(_lineBreak);
  var columns = const <int>[];
  final rows = <List<String>>[];

  for (final line in lines) {
    final layout = _headerColumns(line, headers);
    if (layout != null) {
      columns = layout;
      continue;
    }
    if (columns.isEmpty ||
        line.trim().isEmpty ||
        _separatorLine.hasMatch(line)) {
      continue;
    }
    final cells = _cells(line, columns);
    // A row without the two leading columns is prose printed around the table.
    if (cells[0].isEmpty || cells[1].isEmpty) continue;
    rows.add(cells);
  }
  return rows;
}

List<int>? _headerColumns(String line, List<String> headers) {
  final labels = <String>[];
  final starts = <int>[];
  var column = 0;
  var index = 0;

  while (index < line.length) {
    while (index < line.length && line[index] == ' ') {
      column += _displayWidth(line.codeUnitAt(index));
      index++;
    }
    if (index >= line.length) break;
    final tokenStart = index;
    starts.add(column);
    labels.add(_readToken(line, tokenStart));
    column += _displayWidthOf(labels.last);
    index = tokenStart + labels.last.length;
  }

  if (labels.length != headers.length) return null;
  for (var i = 0; i < labels.length; i++) {
    if (labels[i] != headers[i]) return null;
  }
  return starts;
}

String _readToken(String line, int from) {
  var end = from;
  while (end < line.length && line[end] != ' ') {
    end++;
  }
  return line.substring(from, end);
}

List<String> _cells(String line, List<int> columns) {
  final runes = line.runes.toList();
  final starts = List<int>.filled(runes.length + 1, 0);
  final widths = List<int>.filled(runes.length + 1, 0);
  for (var i = 0; i < runes.length; i++) {
    starts[i + 1] = starts[i] + (runes[i] > 0xFFFF ? 2 : 1);
    widths[i + 1] = widths[i] + _displayWidth(runes[i]);
  }

  final cuts = <int>[];
  var rune = 0;
  for (final column in columns) {
    while (rune < runes.length && widths[rune] < column) {
      rune++;
    }
    cuts.add(starts[rune]);
  }
  cuts.add(line.length);

  return [
    for (var i = 0; i < columns.length; i++) //
      line.substring(cuts[i], cuts[i + 1]).trim(),
  ];
}

/// winget pads each cell to the console column width, where an ideograph fills
/// two columns, so rows must be sliced by display width instead of index.
int _displayWidth(int rune) {
  const wideRanges = [
    (0x1100, 0x115F),
    (0x2E80, 0x303E),
    (0x3041, 0x33FF),
    (0x3400, 0x4DBF),
    (0x4E00, 0x9FFF),
    (0xA000, 0xA4CF),
    (0xAC00, 0xD7A3),
    (0xF900, 0xFAFF),
    (0xFE10, 0xFE19),
    (0xFE30, 0xFE6F),
    (0xFF00, 0xFF60),
    (0xFFE0, 0xFFE6),
    (0x1F300, 0x1F9FF),
    (0x20000, 0x3FFFD),
  ];
  for (final range in wideRanges) {
    if (rune >= range.$1 && rune <= range.$2) return 2;
  }
  return 1;
}

int _displayWidthOf(String value) {
  var width = 0;
  for (final rune in value.runes) {
    width += _displayWidth(rune);
  }
  return width;
}
