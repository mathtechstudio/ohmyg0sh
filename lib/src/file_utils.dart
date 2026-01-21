/// File handling utilities for OhMyG0sh scanner.
///
/// This module provides utilities for file type detection, filtering,
/// and other file-related operations.
library;

import 'dart:io';
import 'package:path/path.dart' as p;

/// Utility class for file operations.
class FileUtils {
  /// File extensions that should be scanned for secrets.
  ///
  /// These are common source file types found in decompiled APKs.
  static const List<String> scannableExtensions = [
    '.java',
    '.xml',
    '.smali',
    '.kt',
    '.txt',
    '.js',
  ];

  /// Log file names that should be excluded from artifact detection.
  static const List<String> logFileNames = [
    'jadx_stdout.log',
    'jadx_stderr.log',
    'jadx_exit_code.txt',
  ];

  /// Standard JADX output directory names.
  static const List<String> jadxOutputDirs = [
    'sources',
    'resources',
  ];

  /// Check if a file should be scanned based on its extension.
  ///
  /// Parameters:
  /// - [file]: File to check
  ///
  /// Returns:
  /// - true if the file has a scannable extension, false otherwise
  static bool isScannable(File file) {
    final ext = p.extension(file.path).toLowerCase();
    return scannableExtensions.contains(ext);
  }

  /// Check if a file path has a scannable extension.
  ///
  /// Parameters:
  /// - [path]: File path to check
  ///
  /// Returns:
  /// - true if the path has a scannable extension, false otherwise
  static bool isScannablePath(String path) {
    final ext = p.extension(path).toLowerCase();
    return scannableExtensions.contains(ext);
  }

  /// Check if a file is a log file that should be excluded.
  ///
  /// Parameters:
  /// - [file]: File to check
  ///
  /// Returns:
  /// - true if the file is a log file, false otherwise
  static bool isLogFile(File file) {
    final basename = p.basename(file.path).toLowerCase();
    return logFileNames.contains(basename);
  }

  /// Check if a file path is a log file.
  ///
  /// Parameters:
  /// - [path]: File path to check
  ///
  /// Returns:
  /// - true if the path is a log file, false otherwise
  static bool isLogFilePath(String path) {
    final basename = p.basename(path).toLowerCase();
    return logFileNames.contains(basename);
  }

  /// Check if a directory is a standard JADX output directory.
  ///
  /// Parameters:
  /// - [dir]: Directory to check
  ///
  /// Returns:
  /// - true if the directory is a JADX output directory, false otherwise
  static bool isJadxOutputDir(Directory dir) {
    final basename = p.basename(dir.path).toLowerCase();
    return jadxOutputDirs.contains(basename);
  }

  /// Check if a directory path is a standard JADX output directory.
  ///
  /// Parameters:
  /// - [path]: Directory path to check
  ///
  /// Returns:
  /// - true if the path is a JADX output directory, false otherwise
  static bool isJadxOutputDirPath(String path) {
    final basename = p.basename(path).toLowerCase();
    return jadxOutputDirs.contains(basename);
  }

  /// Get the file extension in lowercase.
  ///
  /// Parameters:
  /// - [path]: File path
  ///
  /// Returns:
  /// - Lowercase file extension (e.g., '.java')
  static String getExtension(String path) {
    return p.extension(path).toLowerCase();
  }

  /// Check if a file exists and is readable.
  ///
  /// Parameters:
  /// - [path]: File path to check
  ///
  /// Returns:
  /// - true if file exists and is readable, false otherwise
  static bool isReadable(String path) {
    try {
      final file = File(path);
      return file.existsSync() &&
          file.statSync().type == FileSystemEntityType.file;
    } catch (_) {
      return false;
    }
  }

  /// Safely read a file as string, returning null on error.
  ///
  /// Parameters:
  /// - [file]: File to read
  ///
  /// Returns:
  /// - File content as string, or null if read fails
  static Future<String?> safeReadAsString(File file) async {
    try {
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  /// Count files in a directory recursively.
  ///
  /// Parameters:
  /// - [dir]: Directory to count files in
  /// - [filter]: Optional filter function
  ///
  /// Returns:
  /// - Number of files matching the filter
  static Future<int> countFiles(
    Directory dir, {
    bool Function(File)? filter,
  }) async {
    int count = 0;
    try {
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          if (filter == null || filter(entity)) {
            count++;
          }
        }
      }
    } catch (_) {
      // Ignore errors
    }
    return count;
  }
}
