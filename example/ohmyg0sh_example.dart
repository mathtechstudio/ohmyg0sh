/// Example: OhMyG0sh library usage entrypoint.
///
/// Run with:
///   dart run example/ohmyg0sh_example.dart <path_to_apk>
///
/// Exit codes:
/// - 1 when no APK path is provided
/// - 2 for runtime failures
///
/// Tip:
/// Un-comment pattern/notKeyHacks/jadx options below to customize behavior.
library;
import 'dart:io';
import 'package:ohmyg0sh/ohmyg0sh.dart';

/// Demonstration entrypoint that constructs and runs OhMyG0sh.
///
/// Validates arguments, creates the scanner with JSON output, and
/// ensures cleanup on error.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run example/ohmyg0sh_example.dart <path_to_apk>');
    exit(1);
  }

  final apk = args.first;
  final scanner = OhMyG0sh(
    apkPath: apk,
    outputJson: true,
    // patternPath: 'config/regexes.json', // optional
    // notKeyHacksPath: 'config/notkeyhacks.json', // optional
    // jadxPath: '/usr/local/bin/jadx', // optional
  );

  try {
    await scanner.run();
  } catch (e) {
    stderr.writeln('Error: $e');
    await scanner.cleanup();
    exit(2);
  }
}
