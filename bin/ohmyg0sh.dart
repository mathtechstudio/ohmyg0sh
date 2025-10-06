/// OhMyG0sh CLI entrypoint.
///
/// Provides a command-line interface to scan Android APKs for hardcoded secrets.
///
/// Usage:
///   ohmyg0sh -f <apk> [options]
///
/// Flags:
///   -h, --help          Show help and usage
///   -v, --version       Show version banner
///       --no-banner     Hide ASCII banner on startup
///   -f, --file         Path to the target APK (or pass as positional arg)
///   -o, --output       Output file path (random name if not set)
///   -p, --pattern      Path to custom regexes.json
///   -a, --args         Extra arguments forwarded to JADX
///       --jadx         Path to jadx binary
///       --json         Save report as JSON (otherwise plaintext)
///   -n, --notkeys      Path to notkeyhacks.json filters
///
/// Exit codes:
///   0  Success
///   2  Failure during setup/run (e.g., missing JADX)
///  64  Invalid CLI usage/arguments
library;
import 'dart:io';
import 'package:args/args.dart';
import 'package:ohmyg0sh/ohmyg0sh.dart';
import 'package:ohmyg0sh/src/cli_header.dart';
import 'package:ohmyg0sh/src/version.dart';

/// Locate a command in PATH using platform-specific resolver.
///
/// On Windows uses 'where', on Unix-like systems uses 'which'.
/// Returns the first resolved path or null if not found.
Future<String?> _whichCmd(String cmd) async {
  try {
    final result = await Process.run(
      Platform.isWindows ? 'where' : 'which',
      [cmd],
      runInShell: true,
    );
    if (result.exitCode == 0) {
      final out = (result.stdout as String).trim();
      if (out.isNotEmpty) return out.split('\n').first;
    }
  } catch (_) {}
  return null;
}

/// Ensure JADX is available. If a custom path is provided and exists, returns.
/// Otherwise checks PATH; if missing, prompts for installation.
/// On macOS/Linux, attempts Homebrew install when available.
/// On failure or user decline, prints instructions and terminates with exit(2).
Future<void> _ensureJadxInstalledOrPrompt(String? customJadxPath) async {
  // If user provided a path, accept it if exists
  if (customJadxPath != null && customJadxPath.isNotEmpty) {
    if (File(customJadxPath).existsSync()) return;
    stderr.writeln("Provided --jadx path not found: $customJadxPath");
  }

  // Check PATH for jadx
  final found = await _whichCmd('jadx');
  if (found != null) return;

  // Prompt to install
  stdout.write(
      'jadx not found in PATH. Do you want to install jadx now? [Y/n]: ');
  final resp = stdin.readLineSync()?.trim().toLowerCase();
  final yes = resp == null || resp.isEmpty || resp == 'y' || resp == 'yes';
  if (!yes) {
    stderr.writeln(
        "jadx is required to decompile APKs. Install it and re-run, or provide --jadx with a valid path.");
    stderr.writeln(
        "Install instructions: https://github.com/skylot/jadx#installation");
    exit(2);
  }

  // Attempt installation via Homebrew on macOS (best-effort)
  if (!Platform.isWindows) {
    final brew = await _whichCmd('brew');
    if (brew != null) {
      print('Installing jadx via Homebrew...');
      final proc = await Process.start(
        'brew',
        ['install', 'jadx'],
        runInShell: true,
        mode: ProcessStartMode.inheritStdio,
      );
      final code = await proc.exitCode;
      if (code != 0) {
        stderr.writeln(
            'Homebrew installation failed (exit code $code). Please install manually: https://github.com/skylot/jadx#installation');
        exit(2);
      }
      // Verify installation
      final verify = await _whichCmd('jadx');
      if (verify == null) {
        stderr.writeln(
            'jadx not found after installation. Ensure it is in PATH or re-run with --jadx=/path/to/jadx');
        exit(2);
      }
      return;
    }
  }

  // Fallback: manual instructions
  stderr.writeln(
      'Automatic installation not available. Please install jadx manually: https://github.com/skylot/jadx#installation');
  exit(2);
}

/// Program entrypoint for the OhMyG0sh CLI.
///
/// Parses CLI arguments, renders the version/banner, resolves configuration,
/// verifies/installs JADX if necessary, and runs the scan workflow.
/// Produces a JSON or text report depending on --json flag.
///
/// This function may terminate the process with exit codes:
/// - 0 on success (when showing version/help)
/// - 64 for invalid arguments
/// - 2 for runtime failures
Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Show help', negatable: false)
    ..addFlag('version', abbr: 'v', help: 'Show version', negatable: false)
    ..addFlag('no-banner', help: 'Hide banner on startup', negatable: false)
    ..addOption('file', abbr: 'f', help: 'APK file to scanning')
    ..addOption('output',
        abbr: 'o', help: 'Write results to file (random if not set)')
    ..addOption('pattern', abbr: 'p', help: 'Path to custom patterns JSON')
    ..addOption('args',
        abbr: 'a', help: 'Disassembler arguments (quoted, space-separated)')
    ..addOption('jadx', help: 'Path to jadx binary')
    ..addFlag('json', help: 'Save as JSON format', negatable: false)
    ..addOption('notkeys', abbr: 'n', help: 'Path to notkeyhacks.json');

  ArgResults args;
  try {
    args = parser.parse(argv);
  } catch (e) {
    print('Error parsing args: $e');
    print('Usage: ohmyg0sh -f <apk> [options]');
    exit(64);
  }

  // Show version
  if (args['version'] as bool) {
    displayHeader('v$packageVersion');
    exit(0);
  }

  // Show help
  if (args['help'] as bool) {
    displayHeader('v$packageVersion');
    print('\nUsage: ohmyg0sh -f <apk> [options]\n');
    print(parser.usage);
    exit(0);
  }

  // Display header for normal operation (unless --no-banner)
  if (!(args['no-banner'] as bool)) {
    displayHeader('v$packageVersion');
  }

  String? apk = args['file'] as String?;
  if ((apk == null || apk.isEmpty) && args.rest.isEmpty) {
    stderr
        .writeln('Error: APK path required. Provide -f <apk> or positionally.');
    print('\nUsage: ohmyg0sh -f <apk> [options]\n');
    print(parser.usage);
    exit(64);
  }
  apk ??= args.rest.isNotEmpty ? args.rest.first : null;

  // Derived options
  final String apkStr = apk!;
  final bool outputJson =
      (args['json'] as bool); // default false when not provided
  final String? outArg = args['output'] as String?;
  final String outPath = (outArg == null || outArg.isEmpty)
      ? 'results_${DateTime.now().millisecondsSinceEpoch}.${outputJson ? 'json' : 'txt'}'
      : outArg;

  final String? pattern = args['pattern'] as String?;
  final String? notkeys = args['notkeys'] as String?;
  final String? customJadx = args['jadx'] as String?;

  // Prompt-install if missing
  await _ensureJadxInstalledOrPrompt(customJadx);

  // Disassembler args
  final String? disasmArgsStr = args['args'] as String?;
  final List<String>? disasmArgs =
      (disasmArgsStr == null || disasmArgsStr.trim().isEmpty)
          ? null
          : disasmArgsStr.trim().split(RegExp(r'\s+'));

  final scanner = OhMyG0sh(
    apkPath: apkStr,
    outputJson: outputJson,
    outputFile: outPath,
    patternPath: pattern,
    notKeyHacksPath: notkeys,
    jadxPath: customJadx,
    // continueOnJadxError defaults to true in _base
  );

  try {
    await scanner.run(jadxExtraArgs: disasmArgs);
  } catch (e, st) {
    stderr.writeln('Error: $e');
    stderr.writeln(st);
    await scanner.cleanup();
    exit(2);
  }
}
