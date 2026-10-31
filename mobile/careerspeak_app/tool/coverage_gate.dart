import 'dart:io';

void main(List<String> args) {
  final threshold = args.isEmpty ? 90.0 : double.parse(args.first);
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln('coverage/lcov.info is missing. Run flutter test --coverage first.');
    exitCode = 2;
    return;
  }

  final files = <_CoverageFile>[];
  String? currentPath;
  var found = 0;
  var hit = 0;

  void flush() {
    final path = currentPath;
    if (path == null) return;
    if (!_excluded(path)) {
      files.add(_CoverageFile(path, found, hit));
    }
    currentPath = null;
    found = 0;
    hit = 0;
  }

  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      flush();
      currentPath = line.substring(3).replaceAll('\\', '/');
      continue;
    }
    if (line.startsWith('LF:')) {
      found = int.parse(line.substring(3));
      continue;
    }
    if (line.startsWith('LH:')) {
      hit = int.parse(line.substring(3));
      continue;
    }
    if (line == 'end_of_record') flush();
  }
  flush();

  final totalFound = files.fold<int>(0, (sum, item) => sum + item.found);
  final totalHit = files.fold<int>(0, (sum, item) => sum + item.hit);
  final percent = totalFound == 0 ? 0.0 : totalHit * 100 / totalFound;

  files.sort((a, b) {
    final byPercent = a.percent.compareTo(b.percent);
    return byPercent != 0 ? byPercent : a.path.compareTo(b.path);
  });

  stdout.writeln(
    'Production line coverage: ${percent.toStringAsFixed(2)}% '
    '($totalHit/$totalFound), threshold ${threshold.toStringAsFixed(2)}%',
  );
  stdout.writeln('Lowest-covered production files:');
  for (final item in files.take(25)) {
    stdout.writeln(
      '  ${item.percent.toStringAsFixed(2).padLeft(6)}% '
      '${item.hit}/${item.found} ${_relative(item.path)}',
    );
  }

  if (percent + 1e-9 < threshold) {
    stderr.writeln(
      'Coverage gate failed: ${percent.toStringAsFixed(2)}% < '
      '${threshold.toStringAsFixed(2)}%.',
    );
    exitCode = 1;
  }
}

bool _excluded(String path) {
  final normalized = path.replaceAll('\\', '/');
  return !normalized.contains('/lib/') ||
      normalized.endsWith('.g.dart') ||
      normalized.endsWith('.freezed.dart') ||
      normalized.contains('/generated/');
}

String _relative(String path) {
  final marker = '/lib/';
  final index = path.indexOf(marker);
  return index < 0 ? path : 'lib/${path.substring(index + marker.length)}';
}

final class _CoverageFile {
  const _CoverageFile(this.path, this.found, this.hit);

  final String path;
  final int found;
  final int hit;

  double get percent => found == 0 ? 100 : hit * 100 / found;
}
