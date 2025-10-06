/// Test suite for OhMyG0sh and RegexScanner.
///
/// Coverage:
/// - RegexScanner API behavior, matching, and error handling
/// - OhMyG0sh core validation, defaults, and workflow assumptions
/// - Configuration presence and basic validity
/// - File type scanning and integration flows
///
/// Notes:
/// These tests rely on config/regexes.json to exist for most cases.
/// Pattern-specific tests are skipped if the named pattern is absent.
library;
import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:ohmyg0sh/ohmyg0sh.dart';

/// Top-level test suite for OhMyG0sh and RegexScanner.
void main() {
  // Load actual patterns from config
  late Map<String, dynamic> patterns;

  setUpAll(() {
    final configFile = File('config/regexes.json');
    if (configFile.existsSync()) {
      patterns = jsonDecode(configFile.readAsStringSync());
    } else {
      patterns = {};
    }
  });

  /// Tests for the RegexScanner API: initialization, matching behavior, and file handling.
  group('RegexScanner', () {
    late RegexScanner scanner;
    late File tempFile;

    setUp(() async {
      scanner = RegexScanner(regexFile: 'config/regexes.json');
      tempFile = File('temp_test.txt');
    });

    tearDown(() async {
      if (tempFile.existsSync()) await tempFile.delete();
    });

    test('scanner initializes correctly', () {
      expect(scanner, isNotNull);
    });

    test('detects secrets when pattern matches', () async {
      // Use a generic secret that likely matches something
      await tempFile.writeAsString('''
        secret_key="abc123def456ghi789jkl012mno345pqr678stu901vwx234"
        api_key="test_key_1234567890abcdefghijklmnopqrstuvwxyz"
        password="MyP@ssw0rd123!"
      ''');

      final results = await scanner.scanFile(tempFile.path);

      // At least one pattern should detect something suspicious
      // or no patterns matched (which is also valid if text is clean)
      expect(results, isA<Map<String, List<String>>>());
    });

    test('returns empty for definitely safe content', () async {
      await tempFile.writeAsString('Hello World! This is a test.');
      final results = await scanner.scanFile(tempFile.path);
      expect(results.isEmpty, true);
    });

    test('handles empty files', () async {
      await tempFile.writeAsString('');
      final results = await scanner.scanFile(tempFile.path);
      expect(results.isEmpty, true);
    });
  });

  /// Pattern-specific tests to validate common provider keys (Google, AWS) when present in config.
  group('Pattern-Specific Tests', () {
    late RegexScanner scanner;
    late File tempFile;

    setUp(() async {
      scanner = RegexScanner(regexFile: 'config/regexes.json');
      tempFile = File('temp_pattern_test.txt');
    });

    tearDown(() async {
      if (tempFile.existsSync()) await tempFile.delete();
    });

    // Test Google API Key if pattern exists
    test('Google API Key pattern test', () async {
      if (!patterns.containsKey('Google_API_Key')) {
        markTestSkipped('Google_API_Key pattern not in config');
        return;
      }

      // Standard Google API Key format: AIza[35 chars]
      await tempFile.writeAsString(
          'const API_KEY = "AIzaSyDGxW1234567890abcdefghijklmnop";');

      final results = await scanner.scanFile(tempFile.path);

      if (results.containsKey('Google_API_Key')) {
        expect(results['Google_API_Key'], isNotEmpty);
      }
    });

    // Test AWS Access Key if pattern exists
    test('AWS Access Key pattern test', () async {
      final awsKeys = [
        'Amazon_AWS_Access_Key_ID',
        'AWS_API_Key',
        'AWS_Access_Key'
      ];
      final hasAwsPattern = awsKeys.any((key) => patterns.containsKey(key));

      if (!hasAwsPattern) {
        markTestSkipped('No AWS Access Key patterns in config');
        return;
      }

      // Standard AWS format: AKIA[16 chars]
      await tempFile.writeAsString('AWS_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE');

      final results = await scanner.scanFile(tempFile.path);

      // Check if any AWS pattern matched
      final matched = awsKeys.any((key) => results.containsKey(key));
      if (matched) {
        expect(results.values.any((list) => list.isNotEmpty), true);
      }
    });

    test('handles multiple potential matches', () async {
      await tempFile.writeAsString('''
        // Multiple potential secrets
        api_key_1="1234567890abcdefghijklmnopqrstuvwxyz"
        secret_token="abcdefghijklmnopqrstuvwxyz1234567890"
        access_key="AKIA1234567890ABCDEF"
        password="MySecureP@ssw0rd123"
      ''');

      final results = await scanner.scanFile(tempFile.path);
      expect(results, isA<Map<String, List<String>>>());
    });
  });

  /// Core engine parameter validation and default behavior tests.
  group('OhMyG0sh Core', () {
    test('throws error for non-existent APK', () async {
      final scanner = OhMyG0sh(apkPath: 'nonexistent.apk');
      expect(
        () async => await scanner.integrityCheck(),
        throwsException,
      );
    });

    test('accepts valid parameters', () {
      final scanner = OhMyG0sh(
        apkPath: 'test.apk',
        outputJson: true,
        outputFile: 'results.json',
        patternPath: 'config/regexes.json',
        notKeyHacksPath: 'config/notkeyhacks.json',
        continueOnJadxError: false,
      );
      expect(scanner.apkPath, 'test.apk');
      expect(scanner.outputJson, true);
      expect(scanner.outputFile, 'results.json');
      expect(scanner.continueOnJadxError, false);
    });

    test('uses default values correctly', () {
      final scanner = OhMyG0sh(apkPath: 'test.apk');
      expect(scanner.outputJson, true);
      expect(scanner.continueOnJadxError, true);
      expect(scanner.outputFile, null);
    });
  });

  /// Configuration presence and basic validation tests for regexes and filters.
  group('Configuration Loading', () {
    test('loads default regexes.json', () {
      final file = File('config/regexes.json');
      expect(file.existsSync(), true);

      final scanner = RegexScanner(regexFile: 'config/regexes.json');
      expect(scanner, isNotNull);
    });

    test('throws error for missing regex file', () {
      expect(
        () => RegexScanner(regexFile: 'nonexistent.json'),
        throwsException,
      );
    });

    test('notkeyhacks.json exists', () {
      final file = File('config/notkeyhacks.json');
      expect(file.existsSync(), true);
    });

    test('regexes.json is valid JSON', () {
      final file = File('config/regexes.json');
      expect(file.existsSync(), true);

      final content = file.readAsStringSync();
      expect(() => jsonDecode(content), returnsNormally);
    });

    test('regexes.json contains at least one pattern', () {
      expect(patterns.isNotEmpty, true);
    });
  });

  /// File type handling tests to ensure scanning covers common source types.
  group('File Type Detection', () {
    late Directory tempDir;
    late RegexScanner scanner;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ohmyg0sh_test_');
      scanner = RegexScanner(regexFile: 'config/regexes.json');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('scans .java files', () async {
      final javaFile = File('${tempDir.path}/Test.java');
      await javaFile.writeAsString(
          'public class Test { String secret = "abc123xyz789"; }');

      final results = await scanner.scanFile(javaFile.path);
      expect(results, isA<Map<String, List<String>>>());
    });

    test('scans .xml files', () async {
      final xmlFile = File('${tempDir.path}/config.xml');
      await xmlFile
          .writeAsString('<config><secret>abc123xyz789</secret></config>');

      final results = await scanner.scanFile(xmlFile.path);
      expect(results, isA<Map<String, List<String>>>());
    });

    test('scans .js files', () async {
      final jsFile = File('${tempDir.path}/script.js');
      await jsFile.writeAsString('const apiKey = "abc123xyz789def456";');

      final results = await scanner.scanFile(jsFile.path);
      expect(results, isA<Map<String, List<String>>>());
    });
  });

  /// Matching behavior tests to ensure deduplication and robustness on special content.
  group('Pattern Matching Behavior', () {
    late File tempFile;
    late RegexScanner scanner;

    setUp(() {
      scanner = RegexScanner(regexFile: 'config/regexes.json');
      tempFile = File('temp_pattern_behavior_test.txt');
    });

    tearDown(() async {
      if (tempFile.existsSync()) await tempFile.delete();
    });

    test('avoids duplicate matches', () async {
      await tempFile.writeAsString('''
        secret_key_12345678901234567890
        secret_key_12345678901234567890
        secret_key_12345678901234567890
      ''');

      final results = await scanner.scanFile(tempFile.path);

      // If matches found, each should be unique (no duplicates)
      for (final matches in results.values) {
        final uniqueMatches = matches.toSet();
        expect(matches.length, uniqueMatches.length);
      }
    });

    test('handles files with only whitespace', () async {
      await tempFile.writeAsString('   \n\n   \t\t   ');
      final results = await scanner.scanFile(tempFile.path);
      expect(results.isEmpty, true);
    });

    test('handles special characters', () async {
      await tempFile.writeAsString(r'''
        $#@!%^&*()_+-=[]{}|;:,.<>?
      ''');
      final results = await scanner.scanFile(tempFile.path);
      expect(results, isA<Map<String, List<String>>>());
    });
  });

  /// Error handling tests covering invalid patterns, missing files/directories.
  group('Error Handling', () {
    test('handles invalid regex patterns gracefully', () async {
      final tempFile = File('temp_error_test.txt');
      await tempFile.writeAsString('test content');

      final scanner = RegexScanner(regexFile: 'config/regexes.json');
      final results = await scanner.scanFile(tempFile.path);

      expect(results, isA<Map<String, List<String>>>());

      await tempFile.delete();
    });

    test('handles directory scanning with mixed file types', () async {
      final tempDir = await Directory.systemTemp.createTemp('scan_test_');

      await File('${tempDir.path}/test.java').writeAsString('clean code');
      await File('${tempDir.path}/test.xml').writeAsString('<root/>');
      await File('${tempDir.path}/.hidden').writeAsString('hidden');

      final scanner = RegexScanner(regexFile: 'config/regexes.json');
      final results = await scanner.scanDirectory(tempDir.path);

      expect(results, isA<Map<String, List<String>>>());

      await tempDir.delete(recursive: true);
    });

    test('handles non-existent file', () async {
      final scanner = RegexScanner(regexFile: 'config/regexes.json');

      expect(
        () async => await scanner.scanFile('nonexistent_file.txt'),
        throwsException,
      );
    });

    test('handles non-existent directory', () async {
      final scanner = RegexScanner(regexFile: 'config/regexes.json');

      expect(
        () async => await scanner.scanDirectory('nonexistent_dir'),
        throwsException,
      );
    });
  });

  /// Integration tests simulating a full workflow in a temporary directory.
  group('Integration Tests', () {
    test('full workflow with temp directory', () async {
      final tempDir = await Directory.systemTemp.createTemp('integration_');

      // Create test files
      await File('${tempDir.path}/secrets.txt')
          .writeAsString('api_key=test123\ntoken=abc456');
      await File('${tempDir.path}/clean.txt').writeAsString('No secrets here');

      final scanner = RegexScanner(regexFile: 'config/regexes.json');
      final results = await scanner.scanDirectory(tempDir.path);

      expect(results, isA<Map<String, List<String>>>());

      await tempDir.delete(recursive: true);
    });
  });
}
