/// APK security scanner that detects hardcoded API keys and credentials.
///
/// Example usage:
/// ```dart
/// import 'package:ohmyg0sh/ohmyg0sh.dart';
///
/// final scanner = OhMyG0sh(
///   apkPath: 'app.apk',
///   outputJson: true,
/// );
/// await scanner.run();
/// ```
library;

export 'src/ohmyg0sh_base.dart';
export 'src/regex_scanner.dart';