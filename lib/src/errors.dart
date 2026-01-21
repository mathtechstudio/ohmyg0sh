/// Error types for OhMyG0sh scanner.
///
/// This module defines a hierarchy of error types that provide detailed
/// context about failures during APK scanning operations.
library;

/// Base class for all OhMyG0sh errors.
///
/// This is a sealed class, meaning all subclasses must be defined in this file.
/// This allows for exhaustive pattern matching on error types.
sealed class OhMyG0shError implements Exception {
  /// Human-readable error message.
  final String message;

  /// Optional context providing additional details about the error.
  final String? context;

  /// Creates a new OhMyG0sh error.
  const OhMyG0shError(this.message, [this.context]);

  @override
  String toString() {
    if (context != null) {
      return '$message\nContext: $context';
    }
    return message;
  }
}

/// Error related to configuration file loading or validation.
///
/// Thrown when:
/// - Configuration files are missing or inaccessible
/// - Configuration files contain invalid JSON
/// - Configuration values are out of valid ranges
///
/// Example:
/// ```dart
/// try {
///   final config = await loadConfig('config.json');
/// } catch (e) {
///   if (e is ConfigurationError) {
///     print('Config error in ${e.filePath}: ${e.message}');
///   }
/// }
/// ```
final class ConfigurationError extends OhMyG0shError {
  /// Path to the configuration file that caused the error.
  final String filePath;

  /// Creates a configuration error.
  ///
  /// Parameters:
  /// - [message]: Description of what went wrong
  /// - [filePath]: Path to the problematic configuration file
  /// - [context]: Optional additional context (e.g., JSON parse error details)
  const ConfigurationError(super.message, this.filePath, [super.context]);

  @override
  String toString() {
    final buffer = StringBuffer('Configuration Error: $message\n');
    buffer.writeln('File: $filePath');
    if (context != null) {
      buffer.writeln('Details: $context');
    }
    return buffer.toString();
  }
}

/// Error related to JADX decompilation process.
///
/// Thrown when:
/// - JADX binary is not found
/// - JADX exits with an error code
/// - Decompilation produces no usable artifacts
///
/// The [isRecoverable] flag indicates whether scanning can continue despite
/// the error (e.g., partial decompilation succeeded).
///
/// Example:
/// ```dart
/// try {
///   await decompileApk('app.apk');
/// } catch (e) {
///   if (e is JadxError && e.isRecoverable) {
///     print('Warning: ${e.message}');
///     // Continue with partial results
///   } else {
///     rethrow;
///   }
/// }
/// ```
final class JadxError extends OhMyG0shError {
  /// Exit code returned by JADX process.
  final int exitCode;

  /// Whether the error is recoverable (partial decompilation succeeded).
  final bool isRecoverable;

  /// Creates a JADX error.
  ///
  /// Parameters:
  /// - [message]: Description of the JADX failure
  /// - [exitCode]: Exit code from JADX process
  /// - [isRecoverable]: Whether scanning can continue with partial results
  /// - [context]: Optional additional context (e.g., stderr output)
  const JadxError(
    super.message,
    this.exitCode,
    this.isRecoverable, [
    super.context,
  ]);

  @override
  String toString() {
    final buffer = StringBuffer('JADX Error: $message\n');
    buffer.writeln('Exit Code: $exitCode');
    buffer.writeln('Recoverable: ${isRecoverable ? "Yes" : "No"}');
    if (context != null) {
      buffer.writeln('Details: $context');
    }
    return buffer.toString();
  }
}

/// Error related to file scanning operations.
///
/// Thrown when:
/// - Files cannot be read or accessed
/// - Regex patterns fail to compile
/// - File system operations fail
///
/// Example:
/// ```dart
/// try {
///   await scanFile('source.java');
/// } catch (e) {
///   if (e is ScanError) {
///     print('Failed to scan ${e.filePath}: ${e.message}');
///   }
/// }
/// ```
final class ScanError extends OhMyG0shError {
  /// Path to the file that caused the error.
  final String filePath;

  /// Creates a scan error.
  ///
  /// Parameters:
  /// - [message]: Description of what went wrong during scanning
  /// - [filePath]: Path to the file that caused the error
  /// - [context]: Optional additional context (e.g., regex compilation error)
  const ScanError(super.message, this.filePath, [super.context]);

  @override
  String toString() {
    final buffer = StringBuffer('Scan Error: $message\n');
    buffer.writeln('File: $filePath');
    if (context != null) {
      buffer.writeln('Details: $context');
    }
    return buffer.toString();
  }
}

/// Error related to APK file validation.
///
/// Thrown when:
/// - APK file does not exist
/// - APK file is not readable
/// - APK file is corrupted or invalid format
///
/// Example:
/// ```dart
/// try {
///   validateApk('app.apk');
/// } catch (e) {
///   if (e is ApkError) {
///     print('Invalid APK: ${e.message}');
///   }
/// }
/// ```
final class ApkError extends OhMyG0shError {
  /// Path to the APK file.
  final String apkPath;

  /// Creates an APK error.
  ///
  /// Parameters:
  /// - [message]: Description of the APK validation failure
  /// - [apkPath]: Path to the problematic APK file
  /// - [context]: Optional additional context
  const ApkError(super.message, this.apkPath, [super.context]);

  @override
  String toString() {
    final buffer = StringBuffer('APK Error: $message\n');
    buffer.writeln('APK: $apkPath');
    if (context != null) {
      buffer.writeln('Details: $context');
    }
    return buffer.toString();
  }
}

/// Error related to pattern matching operations.
///
/// Thrown when:
/// - Regex patterns are invalid or malformed
/// - Pattern compilation fails
/// - Pattern matching encounters unexpected errors
///
/// Example:
/// ```dart
/// try {
///   applyPattern('Invalid[regex', content);
/// } catch (e) {
///   if (e is PatternError) {
///     print('Pattern "${e.patternName}" failed: ${e.message}');
///   }
/// }
/// ```
final class PatternError extends OhMyG0shError {
  /// Name/identifier of the pattern that failed.
  final String patternName;

  /// The regex pattern string that caused the error.
  final String pattern;

  /// Creates a pattern error.
  ///
  /// Parameters:
  /// - [message]: Description of the pattern failure
  /// - [patternName]: Name of the pattern (e.g., "Google_API_Key")
  /// - [pattern]: The actual regex pattern string
  /// - [context]: Optional additional context (e.g., regex compilation error)
  const PatternError(
    super.message,
    this.patternName,
    this.pattern, [
    super.context,
  ]);

  @override
  String toString() {
    final buffer = StringBuffer('Pattern Error: $message\n');
    buffer.writeln('Pattern Name: $patternName');
    buffer.writeln('Pattern: $pattern');
    if (context != null) {
      buffer.writeln('Details: $context');
    }
    return buffer.toString();
  }
}
