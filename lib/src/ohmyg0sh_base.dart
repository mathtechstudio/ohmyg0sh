// lib/src/ohmyg0sh_base.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Core class untuk OhMyG0sh
class OhMyG0sh {
  final String apkPath;
  final bool outputJson;
  final String? outputFile;
  final String? patternPath;
  final String? notKeyHacksPath;
  final String? jadxPath;
  final bool continueOnJadxError;
  late final Directory _tmpDir;
  final Map<String, Set<String>> _results = {};
  String? _packageName;
  Map<String, dynamic>? _patterns;
  Map<String, dynamic>? _notkeyhacks;

  OhMyG0sh({
    required this.apkPath,
    this.outputJson = true,
    this.outputFile,
    this.patternPath,
    this.notKeyHacksPath,
    this.jadxPath,
    this.continueOnJadxError = true,
  });

  Future<void> _createTemp() async {
    _tmpDir = await Directory.systemTemp.createTemp('ohmyg0sh-');
  }

  Future<void> integrityCheck() async {
    final apkFile = File(apkPath);
    if (!apkFile.existsSync()) {
      throw Exception("APK file doesn't exist: $apkPath");
    }

    // check jadx
    if (jadxPath != null) {
      if (!File(jadxPath!).existsSync()) {
        throw Exception("jadx not found at provided path: $jadxPath");
      }
    } else {
      final which = await _which('jadx');
      if (which == null) {
        throw Exception("jadx binary not found in PATH. Please install jadx.");
      }
    }

    // load patterns and notkeyhacks
    _patterns = await _loadPatterns();
    _notkeyhacks = await _loadNotKeyHacks();
  }

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

  Future<void> decompile({List<String>? extraArgs}) async {
    await _createTemp();
    final outDir = _tmpDir.path;
    final jadx = jadxPath ?? (await _which('jadx'));
    if (jadx == null) throw Exception('jadx not found');

    final args = [jadx, '-d', outDir, apkPath];
    if (extraArgs != null) args.addAll(extraArgs);

    final stdoutBuf = StringBuffer();
    final stderrBuf = StringBuffer();

    final proc = await Process.start(
      args.first,
      args.sublist(1),
      runInShell: true,
      mode: ProcessStartMode.normal,
    );

    // Stream logs to console while also capturing to buffers
    proc.stdout.transform(utf8.decoder).listen((data) {
      stdout.write(data);
      stdoutBuf.write(data);
    });
    proc.stderr.transform(utf8.decoder).listen((data) {
      stderr.write(data);
      stderrBuf.write(data);
    });

    final exitCode = await proc.exitCode;

    // Persist logs for troubleshooting
    try {
      await File(p.join(outDir, 'jadx_stdout.log'))
          .writeAsString(stdoutBuf.toString());
      await File(p.join(outDir, 'jadx_stderr.log'))
          .writeAsString(stderrBuf.toString());
      await File(p.join(outDir, 'jadx_exit_code.txt'))
          .writeAsString('$exitCode');
    } catch (_) {}

    if (exitCode != 0) {
      // detect if usable decompiled artifacts exist (lenient)
      bool hasArtifacts = false;
      try {
        final dir = Directory(outDir);
        if (dir.existsSync()) {
          bool foundNonLogFile = false;
          bool foundKnownExt = false;
          bool foundSourcesOrResourcesDir = false;

          await for (final entity
              in dir.list(recursive: true, followLinks: false)) {
            if (entity is Directory) {
              final base = p.basename(entity.path).toLowerCase();
              if (base == 'sources' || base == 'resources') {
                foundSourcesOrResourcesDir = true;
              }
            } else if (entity is File) {
              final base = p.basename(entity.path).toLowerCase();
              if (base == 'jadx_stdout.log' ||
                  base == 'jadx_stderr.log' ||
                  base == 'jadx_exit_code.txt') {
                continue;
              }
              foundNonLogFile = true;
              final ext = p.extension(entity.path).toLowerCase();
              if (['.java', '.xml', '.smali', '.kt', '.txt', '.js']
                  .contains(ext)) {
                foundKnownExt = true;
              }
            }
          }

          hasArtifacts =
              foundKnownExt || foundSourcesOrResourcesDir || foundNonLogFile;
        }
      } catch (_) {}

      if (continueOnJadxError && hasArtifacts) {
        stderr.writeln(
            'Warning: jadx exited with code $exitCode, but decompiled artifacts were found under $outDir. Continuing. See logs: $outDir/jadx_stdout.log, $outDir/jadx_stderr.log');
        return;
      }
      throw Exception(
          'jadx failed with exit code $exitCode. See logs in $outDir/jadx_stdout.log and $outDir/jadx_stderr.log');
    }
  }

  Future<Map<String, dynamic>> _loadPatterns() async {
    if (patternPath != null) {
      final f = File(patternPath!);
      if (!f.existsSync()) {
        throw Exception('Pattern file not found: $patternPath');
      }
      return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    }

    // Priority order untuk Docker environment:
    // 1. /app/config/regexes.json (Docker internal)
    // 2. ./config/regexes.json (current directory)
    // 3. Relative to script location

    final candidates = [
      '/app/config/regexes.json', // Docker path
      p.join(Directory.current.path, 'config', 'regexes.json'), // Current dir
    ];

    // Try script-relative path
    try {
      final scriptDir = File(Platform.script.toFilePath()).parent;
      candidates.add(p.normalize(
          p.join(scriptDir.path, '..', '..', 'config', 'regexes.json')));
    } catch (_) {}

    for (final candidate in candidates) {
      final f = File(candidate);
      if (f.existsSync()) {
        return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      }
    }

    throw Exception(
        'regexes.json not found. Provide patternPath or ensure config/regexes.json exists.\n'
        'Searched paths: ${candidates.join(", ")}');
  }

  Future<Map<String, dynamic>> _loadNotKeyHacks() async {
    if (notKeyHacksPath != null) {
      final f = File(notKeyHacksPath!);
      if (f.existsSync()) {
        return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      }
      return {};
    }

    final candidates = [
      '/app/config/notkeyhacks.json', // Docker path
      p.join(
          Directory.current.path, 'config', 'notkeyhacks.json'), // Current dir
    ];

    try {
      final scriptDir = File(Platform.script.toFilePath()).parent;
      candidates.add(p.normalize(
          p.join(scriptDir.path, '..', '..', 'config', 'notkeyhacks.json')));
    } catch (_) {}

    for (final candidate in candidates) {
      final f = File(candidate);
      if (f.existsSync()) {
        return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      }
    }

    return {}; // Return empty if not found (optional filter)
  }

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

  Future<void> scanning() async {
    await _readPackageName();
    if (_packageName != null) {
      print("Scanning against '${_packageName!}'");
    }
    if (_patterns == null) throw Exception('Patterns not loaded');

    final outDir = Directory(_tmpDir.path);
    final futures = <Future>[];

    await for (final entity
        in outDir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase();
        if (!['.java', '.xml', '.smali', '.kt', '.txt', '.js'].contains(ext)) {
          continue;
        }
        futures.add(_scanFile(entity, _patterns!));
      }
    }

    await Future.wait(futures);
  }

  Future<void> _scanFile(File file, Map<String, dynamic> patterns) async {
    String content;
    try {
      content = await file.readAsString();
    } catch (_) {
      return;
    }

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

  void _applyPattern(String name, String patternString, String content) {
    RegExp re;
    try {
      re = RegExp(patternString, multiLine: true, dotAll: true);
    } catch (_) {
      try {
        re = RegExp(patternString);
      } catch (e) {
        // invalid pattern skip
        return;
      }
    }

    for (final m in re.allMatches(content)) {
      final matchStr = m.group(0) ?? '';
      if (matchStr.isEmpty) continue;
      if (!_isFiltered(name, matchStr, content)) {
        _results.putIfAbsent(name, () => <String>{}).add(matchStr);
      }
    }
  }

  bool _isFiltered(String name, String matchStr, String fileContent) {
    if (_notkeyhacks == null || _notkeyhacks!.isEmpty) return false;

    // common patterns in notkeyhacks: specific regexes or substrings to ignore
    // support two keys: "patterns" (list of regex) and "contains" (list of substrings)
    try {
      if (_notkeyhacks!.containsKey('patterns')) {
        final List patterns = _notkeyhacks!['patterns'] as List;
        for (final p in patterns) {
          try {
            final re = RegExp(p.toString(), multiLine: true);
            if (re.hasMatch(matchStr) || re.hasMatch(fileContent)) return true;
          } catch (_) {}
        }
      }
      if (_notkeyhacks!.containsKey('contains')) {
        final List contains = _notkeyhacks!['contains'] as List;
        for (final s in contains) {
          final sub = s.toString();
          if (matchStr.contains(sub) || fileContent.contains(sub)) return true;
        }
      }
      // also support per-key whitelist: key names mapping to list of patterns to ignore
      if (_notkeyhacks!.containsKey(name)) {
        final entry = _notkeyhacks![name];
        if (entry is List) {
          for (final p in entry) {
            try {
              final re = RegExp(p.toString(), multiLine: true);
              if (re.hasMatch(matchStr) || re.hasMatch(fileContent)) {
                return true;
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    return false;
  }

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

  Future<void> generateReport({String? outPath}) async {
    final now = DateTime.now().toIso8601String();

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
      };
      await file.writeAsString(JsonEncoder.withIndent('  ').convert(out));
    } else {
      final buf = StringBuffer();
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

  Future<void> cleanup() async {
    try {
      if (_tmpDir.existsSync()) await _tmpDir.delete(recursive: true);
    } catch (_) {}
  }

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
