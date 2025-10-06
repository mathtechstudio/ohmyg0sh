import 'package:test/test.dart';
import 'package:ohmyg0sh/ohmyg0sh.dart';
import 'dart:io';

void main() {
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

    test('detects Google API Key', () async {
      await tempFile
          .writeAsString('My key = AIzaSyD9A3Y9ZEXAMPLE12345678901234567');
      final results = await scanner.scanFile(tempFile.path);
      expect(results.isNotEmpty, true);
      expect(results.containsKey('Google_API_Key'), true);
    });

    test('returns empty for safe content', () async {
      await tempFile.writeAsString('No secrets here!');
      final results = await scanner.scanFile(tempFile.path);
      expect(results.isEmpty, true);
    });
  });
}
