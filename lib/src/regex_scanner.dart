import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// A lightweight regex-based scanner to detect possible leaks or sensitive keys.
///
/// Example:
/// ```dart
/// final scanner = RegexScanner();
/// final results = await scanner.scanFile('example.txt');
/// print(results);
/// ```
class RegexScanner {
  late final Map<String, String> _patterns;

  RegexScanner({String? regexFile}) {
    final path = regexFile ?? p.join('config', 'regexes.json');
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('Regex patterns file not found: $path');
    }
    final content = json.decode(file.readAsStringSync());
    _patterns = {for (var k in content.keys) k: content[k].toString()};
  }

  /// Scan a single file for potential leaks.
  Future<Map<String, List<String>>> scanFile(String filePath) async {
    final content = await File(filePath).readAsString();
    return _scanContent(content);
  }

  /// Recursively scan a directory for potential leaks.
  Future<Map<String, List<String>>> scanDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) throw Exception('Directory not found: $dirPath');

    final result = <String, List<String>>{};
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => !p.basename(f.path).startsWith('.'));

    for (final file in files) {
      final content = await file.readAsString();
      final found = _scanContent(content);
      if (found.isNotEmpty) result[file.path] = found.keys.toList();
    }

    return result;
  }

  Map<String, List<String>> _scanContent(String content) {
    final results = <String, List<String>>{};
    for (final entry in _patterns.entries) {
      final matches = RegExp(entry.value, multiLine: true).allMatches(content);
      if (matches.isNotEmpty) {
        results[entry.key] =
            matches.map((m) => m.group(0) ?? '').toSet().toList();
      }
    }
    return results;
  }
}
