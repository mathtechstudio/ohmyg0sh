/// Progress reporting utilities for OhMyG0sh scanner.
///
/// This module provides tools to track and report scanning progress,
/// giving users feedback during long-running operations.
library;

import 'dart:io';

/// Tracks and reports progress during file scanning operations.
///
/// Provides real-time feedback to users about scanning progress,
/// including file counts, percentages, and match statistics.
///
/// Example:
/// ```dart
/// final progress = ScanProgress(totalFiles: 1000);
///
/// for (final file in files) {
///   await scanFile(file);
///   progress.increment();
///   if (hasMatches) {
///     progress.incrementMatches();
///   }
/// }
///
/// progress.complete();
/// ```
class ScanProgress {
  /// Total number of files to scan.
  final int totalFiles;

  /// Number of files scanned so far.
  int scannedFiles = 0;

  /// Number of files with matches found.
  int matchedFiles = 0;

  /// Whether progress reporting is enabled.
  final bool enabled;

  /// Update frequency (report every N files).
  final int updateFrequency;

  /// Creates a progress tracker.
  ///
  /// Parameters:
  /// - [totalFiles]: Total number of files to scan
  /// - [enabled]: Whether to display progress (default: true)
  /// - [updateFrequency]: Report progress every N files (default: 100)
  ScanProgress({
    required this.totalFiles,
    this.enabled = true,
    this.updateFrequency = 100,
  });

  /// Calculate completion percentage.
  double get percentage =>
      totalFiles > 0 ? (scannedFiles / totalFiles) * 100 : 0;

  /// Increment the scanned file count and optionally report progress.
  void increment() {
    scannedFiles++;
    if (enabled && _shouldReport()) {
      _report();
    }
  }

  /// Increment the matched file count.
  void incrementMatches() {
    matchedFiles++;
  }

  /// Check if progress should be reported based on frequency.
  bool _shouldReport() {
    return scannedFiles % updateFrequency == 0 || scannedFiles == totalFiles;
  }

  /// Report current progress to stderr.
  void _report() {
    stderr.write(
      '\rScanning: $scannedFiles/$totalFiles files '
      '(${percentage.toStringAsFixed(1)}%)',
    );
  }

  /// Report completion with final statistics.
  void complete() {
    if (!enabled) return;

    stderr.writeln(
      '\rScan complete: $scannedFiles files scanned, '
      '$matchedFiles files with matches',
    );
  }

  /// Clear the current progress line.
  void clear() {
    if (!enabled) return;
    stderr.write('\r${' ' * 80}\r');
  }
}

/// A simple spinner for indicating ongoing operations.
///
/// Displays an animated spinner to show that work is in progress.
///
/// Example:
/// ```dart
/// final spinner = Spinner(message: 'Decompiling APK');
/// spinner.start();
/// await decompileApk();
/// spinner.stop();
/// ```
class Spinner {
  /// Message to display alongside the spinner.
  final String message;

  /// Spinner animation frames.
  static const List<String> _frames = [
    '⠋',
    '⠙',
    '⠹',
    '⠸',
    '⠼',
    '⠴',
    '⠦',
    '⠧',
    '⠇',
    '⠏'
  ];

  /// Current frame index.
  int _frameIndex = 0;

  /// Whether the spinner is currently running.
  bool _running = false;

  /// Creates a spinner with the given message.
  Spinner({required this.message});

  /// Start the spinner animation.
  void start() {
    if (_running) return;
    _running = true;
    _animate();
  }

  /// Stop the spinner and clear the line.
  void stop({String? finalMessage}) {
    _running = false;
    stderr.write('\r${' ' * 80}\r');
    if (finalMessage != null) {
      stderr.writeln(finalMessage);
    }
  }

  /// Animate the spinner.
  Future<void> _animate() async {
    while (_running) {
      stderr.write('\r${_frames[_frameIndex]} $message');
      _frameIndex = (_frameIndex + 1) % _frames.length;
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }
}

/// Progress bar for visual progress indication.
///
/// Displays a progress bar with percentage and optional message.
///
/// Example:
/// ```dart
/// final bar = ProgressBar(total: 100, width: 40);
/// for (int i = 0; i <= 100; i++) {
///   bar.update(i);
///   await Future.delayed(Duration(milliseconds: 50));
/// }
/// bar.complete();
/// ```
class ProgressBar {
  /// Total value (100% completion).
  final int total;

  /// Width of the progress bar in characters.
  final int width;

  /// Whether the progress bar is enabled.
  final bool enabled;

  /// Creates a progress bar.
  ///
  /// Parameters:
  /// - [total]: Total value representing 100% completion
  /// - [width]: Width of the bar in characters (default: 40)
  /// - [enabled]: Whether to display the bar (default: true)
  ProgressBar({
    required this.total,
    this.width = 40,
    this.enabled = true,
  });

  /// Update the progress bar with current value.
  void update(int current, {String? message}) {
    if (!enabled) return;

    final percentage = (current / total * 100).clamp(0, 100);
    final filled = (width * current / total).round().clamp(0, width);
    final empty = width - filled;

    final bar = '[${'=' * filled}${' ' * empty}]';
    final msg = message != null ? ' $message' : '';

    stderr.write('\r$bar ${percentage.toStringAsFixed(1)}%$msg');
  }

  /// Mark the progress bar as complete.
  void complete({String? message}) {
    if (!enabled) return;

    final bar = '[${'=' * width}]';
    final msg = message != null ? ' $message' : '';

    stderr.writeln('\r$bar 100.0%$msg');
  }

  /// Clear the progress bar line.
  void clear() {
    if (!enabled) return;
    stderr.write('\r${' ' * (width + 20)}\r');
  }
}
