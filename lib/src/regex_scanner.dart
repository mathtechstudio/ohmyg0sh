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
/// Regex-based scanner utility that loads patterns from a JSON file
/// and scans text files or directory contents for potential secrets.
///
/// Patterns are defined as a map of identifiers to regex strings.
class RegexScanner {
  /// Loaded regex patterns mapping identifier to pattern string.
  late final Map<String, String> _patterns;

  /// Create a new RegexScanner.
  ///
  /// Parameters:
  /// - [regexFile] Optional path to the patterns JSON. Defaults to
  ///   "config/regexes.json".
  ///
  /// Throws:
  /// - [Exception] if the patterns file is not found.
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
      try {
        final content = await file.readAsString();
        final found = _scanContent(content);
        if (found.isNotEmpty) result[file.path] = found.keys.toList();
      } catch (_) {
        // Skip files that can't be read
      }
    }

    return result;
  }

  /// Internal: scan raw [content] against all configured patterns.
  ///
  /// Returns:
  /// - Map keyed by pattern name with unique match strings.
  ///
  /// Notes:
  /// - Tries case-sensitive first, then falls back to case-insensitive
  ///   when a pattern fails to compile.
  Map<String, List<String>> _scanContent(String content) {
    final results = <String, List<String>>{};
    for (final entry in _patterns.entries) {
      try {
        // Try with multiLine and caseSensitive first
        final matches = RegExp(
          entry.value,
          multiLine: true,
          caseSensitive: true,
        ).allMatches(content);

        if (matches.isNotEmpty) {
          results[entry.key] =
              matches.map((m) => m.group(0) ?? '').toSet().toList();
        }
      } catch (_) {
        // If pattern is invalid, try case-insensitive
        try {
          final matches = RegExp(
            entry.value,
            multiLine: true,
            caseSensitive: false,
          ).allMatches(content);

          if (matches.isNotEmpty) {
            results[entry.key] =
                matches.map((m) => m.group(0) ?? '').toSet().toList();
          }
        } catch (_) {
          // Skip invalid patterns silently
        }
      }
    }
    return results;
  }
}
