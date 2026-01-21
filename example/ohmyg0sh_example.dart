/// Example: OhMyG0sh library usage with enhanced error handling.
///
/// This example demonstrates:
/// - Basic APK scanning
/// - Specific error type handling
/// - Performance tuning options
/// - Progress reporting
///
/// Run with:
///   dart run example/ohmyg0sh_example.dart <path_to_apk>
///
/// Exit codes:
/// - 0: Success
/// - 1: Invalid arguments
/// - 2: APK or configuration error
/// - 3: JADX error
/// - 4: Scan error
/// - 5: Unexpected error
library;

import 'dart:io';
import 'package:ohmyg0sh/ohmyg0sh.dart';

/// Demonstration entrypoint showcasing OhMyG0sh with enhanced error handling.
///
/// Features demonstrated:
/// - Specific error type handling (ApkError, JadxError, etc.)
/// - Performance tuning with scanConcurrency
/// - Progress reporting
/// - Proper cleanup on errors
/// - Informative exit codes
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run example/ohmyg0sh_example.dart <path_to_apk>');
    print('');
    print('Options:');
    print('  --concurrency=N    Set scan concurrency (default: 16)');
    print('  --no-progress      Disable progress reporting');
    print('  --fail-fast        Fail immediately on JADX errors');
    exit(1);
  }

  // Parse arguments
  final apk = args.first;
  int concurrency = 16;
  bool showProgress = true;
  bool continueOnError = true;

  for (final arg in args.skip(1)) {
    if (arg.startsWith('--concurrency=')) {
      concurrency = int.tryParse(arg.split('=')[1]) ?? 16;
    } else if (arg == '--no-progress') {
      showProgress = false;
    } else if (arg == '--fail-fast') {
      continueOnError = false;
    }
  }

  // Create scanner with enhanced options
  final scanner = OhMyG0sh(
    apkPath: apk,
    outputJson: true,
    scanConcurrency: concurrency,
    showProgress: showProgress,
    continueOnJadxError: continueOnError,
    // Optional customizations:
    // patternPath: 'config/regexes.json',
    // notKeyHacksPath: 'config/notkeyhacks.json',
    // jadxPath: '/usr/local/bin/jadx',
  );

  try {
    print('🔍 Starting APK security scan...');
    print('   APK: $apk');
    print('   Concurrency: $concurrency');
    print('   Progress: ${showProgress ? "enabled" : "disabled"}');
    print('');

    await scanner.run();

    print('');
    print('✅ Scan completed successfully!');
    exit(0);
  } on ApkError catch (e) {
    stderr.writeln('');
    stderr.writeln('❌ APK Error: ${e.message}');
    stderr.writeln('   File: ${e.apkPath}');
    if (e.context != null) {
      stderr.writeln('   ${e.context}');
    }
    await scanner.cleanup();
    exit(2);
  } on JadxError catch (e) {
    stderr.writeln('');
    stderr.writeln('❌ JADX Error: ${e.message}');
    stderr.writeln('   Exit Code: ${e.exitCode}');
    stderr.writeln('   Recoverable: ${e.isRecoverable}');
    if (e.context != null) {
      stderr.writeln('   ${e.context}');
    }
    await scanner.cleanup();
    exit(3);
  } on ConfigurationError catch (e) {
    stderr.writeln('');
    stderr.writeln('❌ Configuration Error: ${e.message}');
    stderr.writeln('   File: ${e.filePath}');
    if (e.context != null) {
      stderr.writeln('   ${e.context}');
    }
    await scanner.cleanup();
    exit(2);
  } on ScanError catch (e) {
    stderr.writeln('');
    stderr.writeln('❌ Scan Error: ${e.message}');
    stderr.writeln('   File: ${e.filePath}');
    if (e.context != null) {
      stderr.writeln('   ${e.context}');
    }
    await scanner.cleanup();
    exit(4);
  } catch (e, stackTrace) {
    stderr.writeln('');
    stderr.writeln('❌ Unexpected Error: $e');
    stderr.writeln('   Stack Trace:');
    stderr.writeln('   $stackTrace');
    await scanner.cleanup();
    exit(5);
  }
}
