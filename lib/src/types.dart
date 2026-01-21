/// Type definitions for OhMyG0sh scanner.
///
/// This module defines enhanced enums and data classes used throughout
/// the scanner for type safety and better code organization.
library;

/// Output format for scan results.
///
/// Determines how scan results are formatted and saved.
enum OutputFormat {
  /// JSON format with structured data.
  json('json', 'application/json'),

  /// Plain text format with human-readable output.
  text('txt', 'text/plain');

  /// File extension for this format.
  final String extension;

  /// MIME type for this format.
  final String mimeType;

  const OutputFormat(this.extension, this.mimeType);

  /// Get format from file extension.
  static OutputFormat fromExtension(String ext) {
    final normalized = ext.toLowerCase().replaceAll('.', '');
    return values.firstWhere(
      (f) => f.extension == normalized,
      orElse: () => OutputFormat.text,
    );
  }
}

/// Status of a scanning operation.
enum ScanStatus {
  /// Scan has not started yet.
  notStarted('Not Started'),

  /// Scan is currently in progress.
  inProgress('In Progress'),

  /// Scan completed successfully.
  completed('Completed'),

  /// Scan failed with an error.
  failed('Failed');

  /// Human-readable display name.
  final String displayName;

  const ScanStatus(this.displayName);
}

/// Statistics about a completed scan.
///
/// Provides metrics about the scanning operation including file counts,
/// match counts, and timing information.
class ScanStatistics {
  /// Total number of files found in the APK.
  final int totalFiles;

  /// Number of files actually scanned.
  final int scannedFiles;

  /// Number of files with at least one match.
  final int matchedFiles;

  /// Total number of matches found across all files.
  final int totalMatches;

  /// Duration of the scan operation.
  final Duration scanDuration;

  /// Creates scan statistics.
  const ScanStatistics({
    required this.totalFiles,
    required this.scannedFiles,
    required this.matchedFiles,
    required this.totalMatches,
    required this.scanDuration,
  });

  /// Convert to JSON representation.
  Map<String, dynamic> toJson() => {
        'total_files': totalFiles,
        'scanned_files': scannedFiles,
        'matched_files': matchedFiles,
        'total_matches': totalMatches,
        'scan_duration_ms': scanDuration.inMilliseconds,
      };

  @override
  String toString() {
    return 'ScanStatistics('
        'totalFiles: $totalFiles, '
        'scannedFiles: $scannedFiles, '
        'matchedFiles: $matchedFiles, '
        'totalMatches: $totalMatches, '
        'duration: ${scanDuration.inSeconds}s)';
  }
}

/// Result of a scan operation.
///
/// Contains all information about a completed scan including matches,
/// statistics, and metadata.
class ScanResult {
  /// Package name of the scanned APK.
  final String packageName;

  /// Matches grouped by pattern name.
  final Map<String, Set<String>> matches;

  /// Timestamp when the scan was performed.
  final DateTime timestamp;

  /// Statistics about the scan operation.
  final ScanStatistics statistics;

  /// Creates a scan result.
  const ScanResult({
    required this.packageName,
    required this.matches,
    required this.timestamp,
    required this.statistics,
  });

  /// Convert to JSON representation.
  Map<String, dynamic> toJson() => {
        'package': packageName,
        'results': matches.entries
            .map((e) => {'name': e.key, 'matches': e.value.toList()})
            .toList(),
        'generated_at': timestamp.toIso8601String(),
        'statistics': statistics.toJson(),
        'generated_by': 'ohmyg0sh',
        'repository': 'https://github.com/mathtechstudio/ohmyg0sh',
        'pub_dev': 'https://pub.dev/packages/ohmyg0sh',
      };

  @override
  String toString() {
    return 'ScanResult('
        'package: $packageName, '
        'matches: ${matches.length} patterns, '
        'timestamp: $timestamp)';
  }
}
