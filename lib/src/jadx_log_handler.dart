import 'dart:io';
import 'package:path/path.dart' as p;

/// Handles JADX stdout/stderr log capture, filtering, and persistence.
///
/// This class manages the buffering and streaming of JADX output during
/// decompilation, with special handling for error markers that should be
/// suppressed from console output while being preserved in log files.
class JadxLogHandler {
  /// Buffer for all stdout content (for log file persistence).
  final StringBuffer stdoutBuf = StringBuffer();

  /// Buffer for all stderr content (for log file persistence).
  final StringBuffer stderrBuf = StringBuffer();

  /// Regex pattern to detect and filter JADX error summary lines.
  static final RegExp errorRegex =
      RegExp(r'ERROR - finished with errors, count: \d+\r?\n?');

  /// Error marker string to detect in logs.
  static const String errorMarker = 'ERROR - finished with errors';

  /// Number of characters to retain as "carry" for chunk boundary handling.
  static const int carryLength = 64;

  /// Carry buffer for stdout to handle chunk boundaries.
  String _stdoutCarry = '';

  /// Carry buffer for stderr to handle chunk boundaries.
  String _stderrCarry = '';

  /// Process and emit a chunk of stdout data.
  ///
  /// Buffers the data for later persistence and emits sanitized output
  /// to the console, filtering out error markers.
  void handleStdout(String data) {
    stdoutBuf.write(data);
    _handleChunk(data, isStdout: true);
  }

  /// Process and emit a chunk of stderr data.
  ///
  /// Buffers the data for later persistence and emits sanitized output
  /// to the console, filtering out error markers.
  void handleStderr(String data) {
    stderrBuf.write(data);
    _handleChunk(data, isStdout: false);
  }

  /// Internal handler for processing data chunks with carry buffer logic.
  ///
  /// Maintains a carry buffer to handle error markers that might span
  /// chunk boundaries. Emits sanitized output to stdout or stderr.
  void _handleChunk(String data, {required bool isStdout}) {
    final carry = isStdout ? _stdoutCarry : _stderrCarry;
    final combined = carry + data;

    // Calculate how much to emit (leave carryLength for boundary handling)
    final emitLength =
        combined.length <= carryLength ? 0 : combined.length - carryLength;
    final emitPortion = combined.substring(0, emitLength);

    // Remove error markers from emitted portion
    final sanitized = emitPortion.replaceAll(errorRegex, '');
    if (sanitized.isNotEmpty) {
      if (isStdout) {
        stdout.write(sanitized);
      } else {
        stderr.write(sanitized);
      }
    }

    // Update carry buffer
    final newCarry = combined.substring(emitLength);
    if (isStdout) {
      _stdoutCarry = newCarry;
    } else {
      _stderrCarry = newCarry;
    }
  }

  /// Flush any remaining carry buffer content to console.
  ///
  /// Should be called after all data has been processed to ensure
  /// no buffered content is lost.
  void flushAll() {
    _flush(isStdout: true);
    _flush(isStdout: false);
  }

  /// Flush a specific carry buffer (stdout or stderr).
  void _flush({required bool isStdout}) {
    final carry = isStdout ? _stdoutCarry : _stderrCarry;
    if (carry.isNotEmpty) {
      final sanitized = carry.replaceAll(errorRegex, '');
      if (sanitized.isNotEmpty) {
        if (isStdout) {
          stdout.write(sanitized);
        } else {
          stderr.write(sanitized);
        }
      }
    }

    // Clear carry buffer
    if (isStdout) {
      _stdoutCarry = '';
    } else {
      _stderrCarry = '';
    }
  }

  /// Check if the captured logs contain the JADX error marker.
  ///
  /// Returns true if either stdout or stderr contains the error marker line.
  bool containsErrorMarker() {
    return stdoutBuf.toString().contains(errorMarker) ||
        stderrBuf.toString().contains(errorMarker);
  }

  /// Persist captured logs to files in the specified output directory.
  ///
  /// Creates three files:
  /// - jadx_stdout.log: Complete stdout content
  /// - jadx_stderr.log: Complete stderr content
  /// - jadx_exit_code.txt: JADX process exit code
  ///
  /// Silently ignores write errors to avoid disrupting the main workflow.
  Future<void> persistLogs(String outputDir, int exitCode) async {
    try {
      await File(p.join(outputDir, 'jadx_stdout.log'))
          .writeAsString(stdoutBuf.toString());
      await File(p.join(outputDir, 'jadx_stderr.log'))
          .writeAsString(stderrBuf.toString());
      await File(p.join(outputDir, 'jadx_exit_code.txt'))
          .writeAsString('$exitCode');
    } catch (_) {
      // Silently ignore log persistence errors
    }
  }
}
