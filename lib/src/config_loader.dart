/// Configuration file loading utilities for OhMyG0sh.
///
/// This module provides utilities for locating and loading configuration
/// files from various standard locations (Docker, current directory,
/// package installation, script-relative paths).
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;

import 'errors.dart';

/// Utility class for loading configuration files.
///
/// Provides methods to locate and load JSON configuration files from
/// standard locations with a well-defined resolution order.
class ConfigLoader {
  /// Load a configuration file with standard resolution order.
  ///
  /// Resolution order when [explicitPath] is null:
  /// 1. /app/config/{filename} (Docker)
  /// 2. ./config/{filename} (current directory)
  /// 3. package:ohmyg0sh/config/{filename} (pub global / package install)
  /// 4. script-relative ../../config/{filename}
  ///
  /// Parameters:
  /// - [filename]: Name of the configuration file (e.g., 'regexes.json')
  /// - [explicitPath]: Optional explicit path to the file
  /// - [required]: Whether the file is required (default: true)
  ///
  /// Returns:
  /// - Parsed JSON as Map<String, dynamic>
  /// - Empty map if file not found and [required] is false
  ///
  /// Throws:
  /// - [ConfigurationError] if file not found and [required] is true
  /// - [ConfigurationError] if file contains invalid JSON
  static Future<Map<String, dynamic>> loadConfig(
    String filename, {
    String? explicitPath,
    bool required = true,
  }) async {
    if (explicitPath != null) {
      return _loadFromPath(explicitPath, filename, required: required);
    }

    final candidates = _buildCandidatePaths(filename);

    for (final candidate in candidates) {
      final file = File(candidate);
      if (file.existsSync()) {
        try {
          final content = await file.readAsString();
          return jsonDecode(content) as Map<String, dynamic>;
        } catch (e) {
          throw ConfigurationError(
            'Failed to parse configuration file',
            candidate,
            'Invalid JSON: $e',
          );
        }
      }
    }

    if (!required) {
      return {};
    }

    throw ConfigurationError(
      '$filename not found in any standard location',
      filename,
      'Searched paths:\n${candidates.map((p) => '  - $p').join('\n')}\n\n'
          'Solutions:\n'
          '  1. Provide explicit path with appropriate option\n'
          '  2. Place $filename in ./config/ directory\n'
          '  3. Ensure package installation is complete',
    );
  }

  /// Load configuration from an explicit path.
  static Future<Map<String, dynamic>> _loadFromPath(
    String path,
    String filename, {
    required bool required,
  }) async {
    final file = File(path);
    if (!file.existsSync()) {
      if (!required) return {};

      throw ConfigurationError(
        'Configuration file not found',
        path,
        'Verify the file exists and is accessible',
      );
    }

    try {
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      throw ConfigurationError(
        'Failed to parse configuration file',
        path,
        'Invalid JSON: $e',
      );
    }
  }

  /// Build list of candidate paths for configuration file.
  ///
  /// Returns paths in resolution order:
  /// 1. Docker path (/app/config/)
  /// 2. Current directory (./config/)
  /// 3. Package URI resolution
  /// 4. Script-relative path
  static List<String> _buildCandidatePaths(String filename) {
    final candidates = <String>[
      '/app/config/$filename',
      p.join(Directory.current.path, 'config', filename),
    ];

    // Try package: URI resolution (works for pub global and direct runs)
    try {
      final pkgUri = Isolate.resolvePackageUriSync(
        Uri.parse('package:ohmyg0sh/config/$filename'),
      );
      if (pkgUri != null && pkgUri.scheme == 'file') {
        candidates.add(p.normalize(pkgUri.toFilePath()));
      }
    } catch (_) {
      // Ignore resolution errors
    }

    // Try script-relative path
    try {
      final scriptDir = File(Platform.script.toFilePath()).parent;
      candidates.add(
        p.normalize(p.join(scriptDir.path, '..', '..', 'config', filename)),
      );
    } catch (_) {
      // Ignore path resolution errors
    }

    return candidates;
  }

  /// Check if a configuration file exists at any standard location.
  ///
  /// Parameters:
  /// - [filename]: Name of the configuration file
  /// - [explicitPath]: Optional explicit path to check
  ///
  /// Returns:
  /// - true if file exists, false otherwise
  static bool configExists(String filename, {String? explicitPath}) {
    if (explicitPath != null) {
      return File(explicitPath).existsSync();
    }

    final candidates = _buildCandidatePaths(filename);
    return candidates.any((path) => File(path).existsSync());
  }

  /// Get the actual path where a configuration file is located.
  ///
  /// Parameters:
  /// - [filename]: Name of the configuration file
  /// - [explicitPath]: Optional explicit path
  ///
  /// Returns:
  /// - Actual file path if found, null otherwise
  static String? getConfigPath(String filename, {String? explicitPath}) {
    if (explicitPath != null) {
      return File(explicitPath).existsSync() ? explicitPath : null;
    }

    final candidates = _buildCandidatePaths(filename);
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }

    return null;
  }
}
