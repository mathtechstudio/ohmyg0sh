/// OhMyG0sh — Android APK security scanner.
///
/// Scans decompiled sources for hardcoded API keys, tokens, credentials,
/// endpoints, and other potentially sensitive artifacts using configurable
/// regular-expression patterns.
///
/// Features:
/// - Decompiles APKs with JADX (external dependency)
/// - Scans .java, .kt, .xml, .smali, .js, and .txt files
/// - Configurable detection patterns via config/regexes.json
/// - Optional false-positive filters via config/notkeyhacks.json
/// - JSON or plaintext report output
///
/// Quick CLI usage:
///   ohmyg0sh -f app.apk [-o results.json] [--json] [-p config/regexes.json]
///
/// Library usage:
/// ```dart
/// import 'package:ohmyg0sh/ohmyg0sh.dart';
///
/// final scanner = OhMyG0sh(
///   apkPath: 'app.apk',
///   outputJson: true,
/// );
/// await scanner.run();
/// ```
///
/// See also:
/// - bin/ohmyg0sh.dart — CLI entrypoint and flags
/// - lib/src/ohmyg0sh_base.dart — core engine
/// - lib/src/regex_scanner.dart — standalone regex scanner utility
/// - config/regexes.json — detection patterns
/// - config/notkeyhacks.json — optional filters for non-keys
library;

export 'src/ohmyg0sh_base.dart';
export 'src/regex_scanner.dart';