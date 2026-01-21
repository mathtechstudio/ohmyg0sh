import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'errors.dart';

/// Lightweight regex-based scanner for detecting secrets and sensitive data.
///
/// This scanner can be used independently of the APK scanning workflow to
/// scan individual files or directories for hardcoded secrets, API keys,
/// tokens, and other sensitive information using configurable regex patterns.
///
/// ## Use Cases
///
/// - Scan source code files for secrets
/// - Audit configuration files
/// - Check documentation for leaked credentials
/// - Integrate into CI/CD pipelines
/// - Standalone security audits
///
/// ## Pattern Configuration
///
/// Patterns are loaded from a JSON file with the following structure:
/// ```json
/// {
///   "AWS_Access_Key": "AKIA[0-9A-Z]{16}",
///   "Google_API_Key": "AIza[0-9A-Za-z\\-_]{35}",
///   "Generic_Secret": "(?i)(secret|password|token)\\s*[:=]\\s*['\"]([^'\"]+)['\"]"
/// }
/// ```
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:ohmyg0sh/ohmyg0sh.dart';
///
/// // Scan a single file
/// final scanner = RegexScanner();
/// final results = await scanner.scanFile('config.json');
///
/// if (results.isNotEmpty) {
///   print('Found secrets:');
///   results.forEach((pattern, matches) {
///     print('  $pattern: ${matches.length} matches');
///   });
/// }
/// ```
///
/// ## Advanced Usage
///
/// ```dart
/// // Use custom patterns file
/// final scanner = RegexScanner(regexFile: 'custom-patterns.json');
///
/// // Scan entire directory
/// final results = await scanner.scanDirectory('src/');
///
/// // Process results
/// for (final entry in results.entries) {
///   final filePath = entry.key;
///   final patterns = entry.value;
///   print('$filePath: found ${patterns.join(", ")}');
/// }
/// ```
///
/// ## Error Handling
///
/// ```dart
/// try {
///   final scanner = RegexScanner(regexFile: 'patterns.json');
///   final results = await scanner.scanFile('secrets.txt');
/// } on ConfigurationError catch (e) {
///   print('Configuration error: $e');
/// } on ScanError catch (e) {
///   print('Scan error: $e');
/// }
/// ```
///
/// ## Performance Considerations
///
/// - Patterns are compiled once during initialization
/// - Files are read asynchronously
/// - Invalid patterns are silently skipped
/// - Unreadable files are silently skipped during directory scans
/// - Results are deduplicated automatically
///
/// See also:
/// - [OhMyG0sh] for full APK scanning with decompilation
class RegexScanner {
  /// Loaded regex patterns mapping identifier to pattern string.
  late final Map<String, String> _patterns;

  /// Creates a new regex scanner with the specified pattern file.
  ///
  /// ## Parameters
  ///
  /// - [regexFile] - Path to the regex patterns JSON file (optional).
  ///   - If `null`, defaults to `config/regexes.json`
  ///   - Must be valid JSON with pattern definitions
  ///   - Patterns should be valid regex strings
  ///
  /// ## Pattern File Format
  ///
  /// The JSON file should contain a map of pattern names to regex strings:
  /// ```json
  /// {
  ///   "Pattern_Name": "regex_pattern",
  ///   "AWS_Key": "AKIA[0-9A-Z]{16}",
  ///   "API_Token": "(?i)token\\s*[:=]\\s*['\"]([^'\"]+)['\"]"
  /// }
  /// ```
  ///
  /// ## Throws
  ///
  /// - [ConfigurationError] if the patterns file is not found
  /// - [ConfigurationError] if the file contains invalid JSON
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // Use default patterns
  /// final scanner = RegexScanner();
  ///
  /// // Use custom patterns
  /// final scanner = RegexScanner(regexFile: 'my-patterns.json');
  ///
  /// // Handle errors
  /// try {
  ///   final scanner = RegexScanner(regexFile: 'patterns.json');
  /// } on ConfigurationError catch (e) {
  ///   print('Failed to load patterns: $e');
  /// }
  /// ```
  RegexScanner({String? regexFile}) {
    final path = regexFile ?? p.join('config', 'regexes.json');
    final file = File(path);
    if (!file.existsSync()) {
      throw ConfigurationError(
        'Regex patterns file not found',
        path,
        'Ensure the file exists or provide a valid path',
      );
    }
    try {
      final content = json.decode(file.readAsStringSync());
      _patterns = {for (var k in content.keys) k: content[k].toString()};
    } catch (e) {
      throw ConfigurationError(
        'Failed to parse regex patterns file',
        path,
        'Invalid JSON: $e',
      );
    }
  }

  /// Scans a single file for potential secrets and sensitive data.
  ///
  /// Reads the file content and applies all configured regex patterns
  /// to detect matches. Results are deduplicated automatically.
  ///
  /// ## Parameters
  ///
  /// - [filePath] - Path to the file to scan (relative or absolute)
  ///
  /// ## Returns
  ///
  /// A map where:
  /// - Keys are pattern names that matched
  /// - Values are lists of unique matched strings
  ///
  /// Returns an empty map if no patterns match.
  ///
  /// ## Throws
  ///
  /// - [FileSystemException] if the file cannot be read
  /// - [PathNotFoundException] if the file doesn't exist
  ///
  /// ## Examples
  ///
  /// ```dart
  /// final scanner = RegexScanner();
  ///
  /// // Scan a file
  /// final results = await scanner.scanFile('config.json');
  ///
  /// // Process results
  /// if (results.isEmpty) {
  ///   print('No secrets found');
  /// } else {
  ///   print('Found secrets:');
  ///   results.forEach((pattern, matches) {
  ///     print('  $pattern:');
  ///     for (final match in matches) {
  ///       print('    - $match');
  ///     }
  ///   });
  /// }
  ///
  /// // Check for specific pattern
  /// if (results.containsKey('AWS_Access_Key')) {
  ///   print('WARNING: AWS keys detected!');
  /// }
  /// ```
  Future<Map<String, List<String>>> scanFile(String filePath) async {
    final content = await File(filePath).readAsString();
    return _scanContent(content);
  }

  /// Recursively scans a directory for potential secrets and sensitive data.
  ///
  /// Walks through all files in the directory (recursively) and scans each
  /// file for pattern matches. Hidden files (starting with '.') are skipped.
  /// Files that cannot be read are silently ignored.
  ///
  /// ## Parameters
  ///
  /// - [dirPath] - Path to the directory to scan (relative or absolute)
  ///
  /// ## Returns
  ///
  /// A map where:
  /// - Keys are file paths (relative to [dirPath])
  /// - Values are lists of pattern names that matched in that file
  ///
  /// Returns an empty map if no patterns match in any file.
  ///
  /// ## Throws
  ///
  /// - [ScanError] if the directory doesn't exist
  ///
  /// ## Examples
  ///
  /// ```dart
  /// final scanner = RegexScanner();
  ///
  /// // Scan entire directory
  /// final results = await scanner.scanDirectory('src/');
  ///
  /// // Process results
  /// if (results.isEmpty) {
  ///   print('No secrets found in any files');
  /// } else {
  ///   print('Files with secrets:');
  ///   results.forEach((filePath, patterns) {
  ///     print('  $filePath:');
  ///     print('    Patterns: ${patterns.join(", ")}');
  ///   });
  /// }
  ///
  /// // Count affected files
  /// print('Total files with secrets: ${results.length}');
  ///
  /// // Find files with specific pattern
  /// final awsFiles = results.entries
  ///     .where((e) => e.value.contains('AWS_Access_Key'))
  ///     .map((e) => e.key)
  ///     .toList();
  /// if (awsFiles.isNotEmpty) {
  ///   print('AWS keys found in: ${awsFiles.join(", ")}');
  /// }
  /// ```
  ///
  /// ## Performance Notes
  ///
  /// - Files are scanned sequentially (not in parallel)
  /// - Hidden files are automatically skipped
  /// - Unreadable files are silently ignored
  /// - Large directories may take significant time
  Future<Map<String, List<String>>> scanDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      throw ScanError(
        'Directory not found',
        dirPath,
        'Verify the directory path is correct',
      );
    }

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
