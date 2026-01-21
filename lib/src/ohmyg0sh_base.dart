// lib/src/ohmyg0sh_base.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'errors.dart';
import 'concurrency.dart';
import 'progress.dart';
import 'jadx_log_handler.dart';
import 'config_loader.dart';
import 'file_utils.dart';

/// OhMyG0sh core engine for APK security scanning.
///
/// Decompiles Android APK files using JADX and scans the decompiled source
/// code for hardcoded secrets, API keys, tokens, credentials, and other
/// potentially sensitive information using configurable regex patterns.
///
/// ## Workflow
///
/// The typical scanning workflow consists of five steps:
/// 1. [integrityCheck] - Validate inputs and environment
/// 2. [decompile] - Decompile APK using JADX
/// 3. [scanning] - Scan decompiled files for patterns
/// 4. [generateReport] - Generate results report
/// 5. [cleanup] - Remove temporary files
///
/// Alternatively, use [run] to execute all steps automatically.
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:ohmyg0sh/ohmyg0sh.dart';
///
/// // Simple scan with defaults
/// final scanner = OhMyG0sh(apkPath: 'app-release.apk');
/// await scanner.run();
/// ```
///
/// ## Advanced Usage
///
/// ```dart
/// // Customized scan with all options
/// final scanner = OhMyG0sh(
///   apkPath: 'app-release.apk',
///   outputJson: true,
///   outputFile: 'security-report.json',
///   patternPath: 'custom-patterns.json',
///   notKeyHacksPath: 'custom-filters.json',
///   jadxPath: '/usr/local/bin/jadx',
///   continueOnJadxError: true,
///   scanConcurrency: 32,
///   showProgress: true,
/// );
///
/// try {
///   await scanner.integrityCheck();
///   print('Pre-flight checks passed');
///
///   await scanner.decompile();
///   print('Decompilation complete');
///
///   await scanner.scanning();
///   print('Scanning complete');
///
///   await scanner.generateReport();
///   print('Report generated');
/// } catch (e) {
///   print('Scan failed: $e');
/// } finally {
///   await scanner.cleanup();
/// }
/// ```
///
/// ## Error Handling
///
/// The scanner can throw several types of errors:
/// - [ApkError] - APK file not found or inaccessible
/// - [JadxError] - JADX not found or decompilation failed
/// - [ConfigurationError] - Configuration files missing or invalid
/// - [ScanError] - File scanning errors
///
/// ## State Management
///
/// Each instance maintains temporary state including:
/// - Temporary decompilation directory
/// - Package name extracted from AndroidManifest.xml
/// - Aggregated scan results
/// - Loaded pattern and filter configurations
///
/// The temporary directory is automatically created during [decompile]
/// and should be cleaned up with [cleanup] when done.
///
/// ## Thread Safety
///
/// Instances are NOT thread-safe. Create separate instances for
/// concurrent scanning of multiple APKs.
///
/// See also:
/// - [RegexScanner] for standalone file scanning without APK decompilation
/// - [ConfigLoader] for configuration file resolution
class OhMyG0sh {
  final String apkPath;
  final bool outputJson;
  final String? outputFile;
  final String? patternPath;
  final String? notKeyHacksPath;
  final String? jadxPath;
  final bool continueOnJadxError;
  final int scanConcurrency;
  final bool showProgress;
  late final Directory _tmpDir;
  final Map<String, Set<String>> _results = {};
  String? _packageName;
  Map<String, dynamic>? _patterns;
  Map<String, dynamic>? _notkeyhacks;

  /// Creates a new APK scanner instance.
  ///
  /// ## Required Parameters
  ///
  /// - [apkPath] - Path to the target APK file to analyze. Must exist and be readable.
  ///
  /// ## Optional Parameters
  ///
  /// - [outputJson] - Output format (default: `true`).
  ///   - `true`: JSON format with structured data
  ///   - `false`: Plain text format with human-readable output
  ///
  /// - [outputFile] - Destination path for the report (default: auto-generated).
  ///   - If `null`, generates `results.json` or `results.txt` based on [outputJson]
  ///   - Can be absolute or relative path
  ///
  /// - [patternPath] - Path to custom regex patterns JSON file (default: auto-resolved).
  ///   - If `null`, searches standard locations (see [ConfigLoader])
  ///   - Must be valid JSON with pattern definitions
  ///
  /// - [notKeyHacksPath] - Path to false-positive filter JSON (default: auto-resolved).
  ///   - Optional file to reduce false positives
  ///   - If not found, no filtering is applied
  ///
  /// - [jadxPath] - Path to JADX binary (default: resolved from PATH).
  ///   - If `null`, searches system PATH for `jadx` command
  ///   - Must be executable JADX binary
  ///
  /// - [continueOnJadxError] - Continue on JADX errors (default: `true`).
  ///   - `true`: Continue if usable artifacts exist despite JADX errors
  ///   - `false`: Fail immediately on any JADX error
  ///
  /// - [scanConcurrency] - Maximum concurrent file scans (default: `16`).
  ///   - Controls parallelism to prevent "too many open files" errors
  ///   - Valid range: 1-256
  ///   - Higher values = faster but more resource usage
  ///
  /// - [showProgress] - Display progress during scanning (default: `true`).
  ///   - `true`: Show progress updates on stderr
  ///   - `false`: Silent mode (useful for CI/CD)
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // Minimal configuration
  /// final scanner = OhMyG0sh(apkPath: 'app.apk');
  ///
  /// // Custom output location
  /// final scanner = OhMyG0sh(
  ///   apkPath: 'app.apk',
  ///   outputFile: 'reports/security-scan.json',
  /// );
  ///
  /// // High-performance scanning
  /// final scanner = OhMyG0sh(
  ///   apkPath: 'large-app.apk',
  ///   scanConcurrency: 64,
  ///   showProgress: true,
  /// );
  ///
  /// // CI/CD mode (silent, fail-fast)
  /// final scanner = OhMyG0sh(
  ///   apkPath: 'app.apk',
  ///   continueOnJadxError: false,
  ///   showProgress: false,
  /// );
  /// ```
  OhMyG0sh({
    required this.apkPath,
    this.outputJson = true,
    this.outputFile,
    this.patternPath,
    this.notKeyHacksPath,
    this.jadxPath,
    this.continueOnJadxError = true,
    this.scanConcurrency = 16,
    this.showProgress = true,
  });

  /// Create a temporary working directory used for decompilation and scanning.
  Future<void> _createTemp() async {
    _tmpDir = await Directory.systemTemp.createTemp('ohmyg0sh-');
  }

  /// Validate inputs and environment prior to run.
  ///
  /// Ensures the APK file exists, locates the JADX binary, and loads the
  /// pattern and filter configurations.
  ///
  /// Throws:
  /// - [ApkError] when the APK file doesn't exist or is inaccessible
  /// - [JadxError] when JADX binary is not found
  /// - [ConfigurationError] when configuration files are missing or invalid
  Future<void> integrityCheck() async {
    final apkFile = File(apkPath);
    if (!apkFile.existsSync()) {
      throw ApkError(
        "APK file doesn't exist or is not accessible",
        apkPath,
        'Verify the file path and permissions',
      );
    }

    // check jadx
    if (jadxPath != null) {
      if (!File(jadxPath!).existsSync()) {
        throw JadxError(
          "jadx not found at provided path",
          -1,
          false,
          'Path: $jadxPath\nVerify the jadx binary exists at this location',
        );
      }
    } else {
      final which = await _which('jadx');
      if (which == null) {
        throw JadxError(
          "jadx binary not found in PATH",
          -1,
          false,
          'Install jadx using:\n'
              '  macOS: brew install jadx\n'
              '  Linux/Windows: https://github.com/skylot/jadx/releases\n'
              'Or provide explicit path with --jadx option',
        );
      }
    }

    // load patterns and notkeyhacks
    _patterns = await _loadPatterns();
    _notkeyhacks = await _loadNotKeyHacks();
  }

  /// Resolve the absolute path to [cmd] using 'which' (Unix) or 'where' (Windows).
  ///
  /// Returns the first resolved path or null if not found.
  Future<String?> _which(String cmd) async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        [cmd],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final stdout = (result.stdout as String).trim();
        if (stdout.isNotEmpty) return stdout.split('\n').first;
      }
    } catch (_) {}
    return null;
  }

  /// Decompile the APK using JADX into a temporary directory.
  ///
  /// Captures and persists stdout/stderr logs and the exit code under the
  /// temp directory. If [continueOnJadxError] is true and usable artifacts are
  /// detected, continues despite non-zero exit.
  ///
  /// Parameters:
  /// - [extraArgs] Extra arguments forwarded to JADX.
  ///
  /// Throws:
  /// - [JadxError] when JADX is not available or decompilation fails without usable artifacts.
  Future<void> decompile({List<String>? extraArgs}) async {
    await _createTemp();
    final outDir = _tmpDir.path;
    final jadx = jadxPath ?? (await _which('jadx'));
    if (jadx == null) {
      throw JadxError(
        'jadx not found',
        -1,
        false,
        'JADX binary could not be located. Install it or provide --jadx path',
      );
    }

    final args = [jadx, '-d', outDir, apkPath];
    if (extraArgs != null) args.addAll(extraArgs);

    final logHandler = JadxLogHandler();

    final proc = await Process.start(
      args.first,
      args.sublist(1),
      runInShell: true,
      mode: ProcessStartMode.normal,
    );

    proc.stdout.transform(utf8.decoder).listen(logHandler.handleStdout);
    proc.stderr.transform(utf8.decoder).listen(logHandler.handleStderr);

    final exitCode = await proc.exitCode;
    logHandler.flushAll();

    final sawFinishedErrorsLine =
        continueOnJadxError && logHandler.containsErrorMarker();

    // Persist logs for troubleshooting
    await logHandler.persistLogs(outDir, exitCode);

    if (exitCode != 0) {
      final hasArtifacts = await _detectJadxArtifacts(outDir);

      if (continueOnJadxError && hasArtifacts) {
        final prefix = sawFinishedErrorsLine
            ? 'JADX reported recoverable issues (error line suppressed).'
            : 'jadx exited with code $exitCode.';
        stderr.writeln(
            'Warning: $prefix Continuing because usable artifacts were produced in $outDir. See logs: $outDir/jadx_stdout.log, $outDir/jadx_stderr.log');
        return;
      }
      throw JadxError(
        'jadx decompilation failed',
        exitCode,
        false,
        'JADX exited with code $exitCode. Check logs:\n'
            '  stdout: $outDir/jadx_stdout.log\n'
            '  stderr: $outDir/jadx_stderr.log\n'
            'Try running with --args "--log-level DEBUG" for more details',
      );
    }
  }

  /// Detect if usable decompiled artifacts exist in the output directory.
  ///
  /// Returns true if the directory contains recognizable source files or
  /// standard JADX output directories (sources, resources).
  Future<bool> _detectJadxArtifacts(String outDir) async {
    try {
      final dir = Directory(outDir);
      if (!dir.existsSync()) return false;

      bool foundNonLogFile = false;
      bool foundKnownExt = false;
      bool foundSourcesOrResourcesDir = false;

      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is Directory) {
          if (FileUtils.isJadxOutputDir(entity)) {
            foundSourcesOrResourcesDir = true;
          }
        } else if (entity is File) {
          if (FileUtils.isLogFile(entity)) {
            continue;
          }
          foundNonLogFile = true;
          if (FileUtils.isScannablePath(entity.path)) {
            foundKnownExt = true;
          }
        }
      }

      return foundKnownExt || foundSourcesOrResourcesDir || foundNonLogFile;
    } catch (_) {
      return false;
    }
  }

  /// Load detection patterns from JSON.
  ///
  /// Uses ConfigLoader to resolve patterns from standard locations.
  ///
  /// Throws:
  /// - [ConfigurationError] if the pattern file is not found or contains invalid JSON.
  Future<Map<String, dynamic>> _loadPatterns() async {
    return ConfigLoader.loadConfig(
      'regexes.json',
      explicitPath: patternPath,
      required: true,
    );
  }

  /// Load optional false-positive filters ('notkeyhacks').
  ///
  /// Returns an empty map when the file is missing.
  /// Uses ConfigLoader to resolve from standard locations.
  Future<Map<String, dynamic>> _loadNotKeyHacks() async {
    return ConfigLoader.loadConfig(
      'notkeyhacks.json',
      explicitPath: notKeyHacksPath,
      required: false,
    );
  }

  /// Parse AndroidManifest.xml from the JADX output to establish package name.
  ///
  /// Sets [_packageName] when available.
  Future<void> _readPackageName() async {
    // try resources/AndroidManifest.xml (jadx output)
    final manifestPath =
        p.join(_tmpDir.path, 'resources', 'AndroidManifest.xml');
    final f = File(manifestPath);
    if (f.existsSync()) {
      final content = await f.readAsString();
      final match = RegExp(r'package="([^"]+)"').firstMatch(content);
      if (match != null) _packageName = match.group(1);
    }
  }

  /// Scan decompiled sources and aggregate matches.
  ///
  /// Walks the temp output directory and concurrently scans files with relevant
  /// extensions (.java, .kt, .xml, .smali, .js, .txt). Populates [_results].
  /// Prints target package if identified.
  ///
  /// Throws:
  /// - [ScanError] if critical scanning errors occur
  Future<void> scanning() async {
    await _readPackageName();
    if (_packageName != null) {
      print("Scanning against '${_packageName!}'");
    }
    if (_patterns == null) {
      throw ConfigurationError(
        'Patterns not loaded',
        'regexes.json',
        'Call integrityCheck() before scanning()',
      );
    }

    final files = await _enumerateScanFiles();
    await _scanFilesWithConcurrency(files);
  }

  /// Enumerate all scannable files in the temp directory.
  ///
  /// Uses breadth-first search with non-recursive listing to avoid
  /// file descriptor pressure. Returns files with relevant extensions.
  Future<List<File>> _enumerateScanFiles() async {
    final files = <File>[];
    final dirs = <Directory>[Directory(_tmpDir.path)];

    while (dirs.isNotEmpty) {
      final dir = dirs.removeLast();
      try {
        await for (final entity
            in dir.list(recursive: false, followLinks: false)) {
          if (entity is Directory) {
            dirs.add(entity);
          } else if (entity is File) {
            if (_isScannable(entity)) {
              files.add(entity);
            }
          }
        }
      } catch (_) {
        // Skip directories that can't be listed
      }
    }

    return files;
  }

  /// Check if a file should be scanned based on its extension.
  bool _isScannable(File file) {
    return FileUtils.isScannable(file);
  }

  /// Scan files with bounded concurrency using a semaphore.
  ///
  /// Processes files in parallel up to [scanConcurrency] limit and
  /// displays progress if enabled.
  Future<void> _scanFilesWithConcurrency(List<File> files) async {
    final int concurrency = scanConcurrency <= 0 ? 16 : scanConcurrency;
    final semaphore = Semaphore(concurrency);

    // Initialize progress tracking
    final progress = ScanProgress(
      totalFiles: files.length,
      enabled: showProgress,
    );

    await Future.wait(
      files.map((f) => semaphore.execute(() async {
            await _scanFile(f, _patterns!);
            progress.increment();
          })),
    );

    progress.complete();
  }

  /// Scan a single file's content using the loaded [patterns].
  ///
  /// Handles files that fail to read by skipping silently.
  Future<void> _scanFile(File file, Map<String, dynamic> patterns) async {
    String content;
    try {
      content = await file.readAsString();
    } catch (_) {
      return;
    }

    _scanContentWithPatterns(content, patterns);
  }

  /// Scan content against all patterns and aggregate results.
  ///
  /// Iterates through all patterns and applies them to the content,
  /// handling both single patterns and pattern arrays.
  void _scanContentWithPatterns(String content, Map<String, dynamic> patterns) {
    patterns.forEach((name, ptn) {
      if (ptn is List) {
        for (final p in ptn) {
          _applyPattern(name, p, content);
        }
      } else if (ptn is String) {
        _applyPattern(name, ptn, content);
      }
    });
  }

  /// Apply a single regex [patternString] for the given [name] group.
  ///
  /// Attempts compilation with multi-line and dot-all first, then falls back.
  /// Adds unique matches to [_results] unless excluded by [_isFiltered].
  /// Logs warnings for patterns that fail to compile.
  void _applyPattern(String name, String patternString, String content) {
    final re = _compilePattern(patternString);
    if (re == null) {
      stderr.writeln(
          'Warning: Failed to compile pattern "$name": $patternString');
      return;
    }

    _extractMatches(name, re, content);
  }

  /// Compile a regex pattern with fallback strategies.
  ///
  /// Tries multiple compilation strategies in order:
  /// 1. multiLine + caseSensitive
  /// 2. multiLine + dotAll
  /// 3. caseSensitive only
  /// 4. dotAll only
  ///
  /// Returns null if all strategies fail.
  RegExp? _compilePattern(String patternString) {
    RegExp? tryCompile({bool multiLine = true, bool dotAll = false}) {
      try {
        return RegExp(patternString, multiLine: multiLine, dotAll: dotAll);
      } catch (e) {
        return null;
      }
    }

    RegExp? re = tryCompile();
    re ??= tryCompile(dotAll: true);
    re ??= tryCompile(multiLine: false);
    re ??= tryCompile(multiLine: false, dotAll: true);

    return re;
  }

  /// Extract matches from content using a compiled regex.
  ///
  /// Filters matches using [_isFiltered] and adds unique matches
  /// to [_results]. Logs errors but continues processing.
  void _extractMatches(String name, RegExp regex, String content) {
    try {
      for (final m in regex.allMatches(content)) {
        final matchStr = m.group(0) ?? '';
        if (matchStr.isEmpty) continue;
        if (!_isFiltered(name, matchStr, content)) {
          _results.putIfAbsent(name, () => <String>{}).add(matchStr);
        }
      }
    } catch (e) {
      stderr.writeln('Warning: Error applying pattern "$name": $e');
    }
  }

  /// Determine whether a match should be filtered out based on notkeyhacks.
  ///
  /// Supports keys:
  /// - 'patterns': list of regex applied to the match or the file content
  /// - 'contains': list of substrings that, when present, exclude
  /// - per-key lists matching [name] with additional regex filters
  bool _isFiltered(String name, String matchStr, String fileContent) {
    if (_notkeyhacks == null || _notkeyhacks!.isEmpty) return false;

    try {
      if (_notkeyhacks!.containsKey('patterns')) {
        if (_matchesFilterRegex(
            _notkeyhacks!['patterns'], matchStr, fileContent)) {
          return true;
        }
      }
      if (_notkeyhacks!.containsKey('contains')) {
        if (_containsFilterSubstring(
            _notkeyhacks!['contains'], matchStr, fileContent)) {
          return true;
        }
      }
      if (_notkeyhacks!.containsKey(name)) {
        if (_matchesFilterRegex(_notkeyhacks![name], matchStr, fileContent)) {
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

  /// Check if match or content matches any filter regex patterns.
  bool _matchesFilterRegex(dynamic value, String matchStr, String fileContent) {
    if (value is List) {
      for (final item in value) {
        if (_matchesFilterRegex(item, matchStr, fileContent)) return true;
      }
      return false;
    }
    if (value is String) {
      try {
        final re = RegExp(value, multiLine: true);
        if (re.hasMatch(matchStr) || re.hasMatch(fileContent)) return true;
      } catch (_) {}
    }
    return false;
  }

  /// Check if match or content contains any filter substrings.
  bool _containsFilterSubstring(
      dynamic value, String matchStr, String fileContent) {
    if (value is List) {
      for (final item in value) {
        if (_containsFilterSubstring(item, matchStr, fileContent)) return true;
      }
      return false;
    }
    if (value is String) {
      if (matchStr.contains(value) || fileContent.contains(value)) return true;
    }
    return false;
  }

  /// Print a grouped summary of results to the console similar to apkleaks.
  void _printSummaryToConsole() {
    // Print groups similar to apkleaks
    final keys = _results.keys.toList()..sort();
    for (final name in keys) {
      print('');
      print('[$name]');
      final matches = _results[name]!.toList()..sort();
      for (final m in matches) {
        print('- $m');
      }
    }
  }

  /// Write scan results to a report file.
  ///
  /// When [outputJson] is true, writes a formatted JSON containing 'package',
  /// 'results', and 'generated_at'. Otherwise writes plaintext sections.
  ///
  /// Parameters:
  /// - [outPath] Optional explicit path; falls back to [outputFile] or defaults.
  ///
  /// Prints the final path to console.
  Future<void> generateReport({String? outPath}) async {
    final now = DateTime.now().toIso8601String();
    const generatedBy = 'ohmyg0sh';
    const repositoryUrl = 'https://github.com/mathtechstudio/ohmyg0sh';
    const pubDevUrl = 'https://pub.dev/packages/ohmyg0sh';

    final path =
        outPath ?? outputFile ?? (outputJson ? 'results.json' : 'results.txt');

    final file = File(path);

    if (outputJson) {
      final out = {
        'package': _packageName ?? '',
        'results': _results.entries
            .map((e) => {'name': e.key, 'matches': e.value.toList()})
            .toList(),
        'generated_at': now,
        'generated_by': generatedBy,
        'repository': repositoryUrl,
        'pub_dev': pubDevUrl,
      };
      await file.writeAsString(JsonEncoder.withIndent('  ').convert(out));
    } else {
      final buf = StringBuffer();
      buf.writeln('generate at :: $now');
      buf.writeln('generate by :: **$generatedBy**');
      buf.writeln('repository :: $repositoryUrl');
      buf.writeln('pub.dev :: $pubDevUrl');
      buf.writeln();
      buf.writeln("** Scanning against '${_packageName ?? ''}'");
      final keys = _results.keys.toList()..sort();
      for (final name in keys) {
        buf.writeln();
        buf.writeln('[$name]');
        final matches = _results[name]!.toList()..sort();
        for (final m in matches) {
          buf.writeln('- $m');
        }
      }
      await file.writeAsString(buf.toString());
    }

    print("** Results saved into '$path'.");
  }

  /// Remove the temporary working directory, ignoring errors.
  Future<void> cleanup() async {
    try {
      if (_tmpDir.existsSync()) await _tmpDir.delete(recursive: true);
    } catch (_) {}
  }

  /// Executes the complete APK security scan workflow.
  ///
  /// This is the main entry point that orchestrates all scanning steps:
  /// 1. Validates inputs and environment ([integrityCheck])
  /// 2. Decompiles the APK using JADX ([decompile])
  /// 3. Scans decompiled files for patterns ([scanning])
  /// 4. Prints results summary to console
  /// 5. Generates report file ([generateReport])
  /// 6. Cleans up temporary files ([cleanup])
  ///
  /// The cleanup step runs even if errors occur, ensuring temporary
  /// files are always removed.
  ///
  /// ## Parameters
  ///
  /// - [jadxExtraArgs] - Optional additional arguments to pass to JADX.
  ///   Common examples:
  ///   - `['--log-level', 'DEBUG']` - Enable debug logging
  ///   - `['--no-res']` - Skip resources decompilation
  ///   - `['--no-src']` - Skip source decompilation
  ///
  /// ## Throws
  ///
  /// - [ApkError] - APK file not found or inaccessible
  /// - [JadxError] - JADX not found or decompilation failed
  /// - [ConfigurationError] - Configuration files missing or invalid
  /// - [ScanError] - Critical scanning errors
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // Basic scan
  /// final scanner = OhMyG0sh(apkPath: 'app.apk');
  /// await scanner.run();
  ///
  /// // Scan with JADX debug logging
  /// await scanner.run(jadxExtraArgs: ['--log-level', 'DEBUG']);
  ///
  /// // Error handling
  /// try {
  ///   await scanner.run();
  ///   print('Scan completed successfully');
  /// } on ApkError catch (e) {
  ///   print('APK error: $e');
  /// } on JadxError catch (e) {
  ///   print('JADX error: $e');
  /// } on ConfigurationError catch (e) {
  ///   print('Configuration error: $e');
  /// } catch (e) {
  ///   print('Unexpected error: $e');
  /// }
  /// ```
  ///
  /// ## Output
  ///
  /// The method produces two types of output:
  /// 1. Console output (stdout/stderr):
  ///    - Progress messages
  ///    - JADX decompilation logs
  ///    - Scan progress (if [showProgress] is true)
  ///    - Results summary grouped by pattern
  /// 2. Report file:
  ///    - JSON or text format based on [outputJson]
  ///    - Contains all matches organized by pattern
  ///    - Includes metadata (package name, timestamp)
  ///
  /// See also:
  /// - [integrityCheck] for pre-flight validation
  /// - [decompile] for APK decompilation
  /// - [scanning] for file scanning
  /// - [generateReport] for report generation
  Future<void> run({List<String>? jadxExtraArgs}) async {
    try {
      await integrityCheck();
      print('** Decompiling APK...');
      await decompile(extraArgs: jadxExtraArgs);
      print('** Scanning files...');
      await scanning();
      _printSummaryToConsole();
      await generateReport(outPath: outputFile);
    } finally {
      await cleanup();
    }
  }
}
