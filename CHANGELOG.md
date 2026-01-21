# Changelog

All notable changes to this project will be documented in this file.

## [1.71.1] - 2026-01-22

### Fixed

- JSON_Web_Token regex pattern compilation error that caused repeated warnings during scans
- Updated pattern to use standard JWT format detection: `eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*`

## [1.71.0] - 2026-01-22

### Added

- **Enhanced Error Handling System**
  - Structured error types: `ApkError`, `JadxError`, `ConfigurationError`, `ScanError`, `PatternError`
  - Detailed error context with actionable messages
  - Comprehensive error scenarios documentation ([ERROR_SCENARIOS.md](ERROR_SCENARIOS.md))

- **Performance Optimizations**
  - Configurable concurrency control via `scanConcurrency` parameter (default: 16)
  - `Semaphore` class for bounded concurrent operations
  - Progress reporting with `ScanProgress` class
  - Efficient memory management for large APKs
  - Streaming file reading for large files

- **Modern Dart Features**
  - Enhanced enums: `ScanStatus`, `OutputFormat`
  - Type-safe data models: `ScanResult`, `ScanStatistics`
  - Records and pattern matching for cleaner code
  - Improved type system throughout

- **Code Organization**
  - `JadxLogHandler` class for log management
  - `ConfigLoader` utility for configuration file resolution
  - `FileUtils` utility for file type detection and handling
  - Modular architecture with clear separation of concerns

### Changed

- **Refactored Core Engine**
  - Extracted large functions into smaller, focused methods
  - Improved pattern matching logic organization
  - Better separation of concerns in scanning workflow
  - Cleaner decompile method with extracted log handling

- **Configuration Loading**
  - Centralized configuration file resolution
  - Consistent error messages across all config operations
  - Better handling of optional configuration files

- **File Scanning**
  - Modular file enumeration with BFS approach
  - Extracted file type checking into utilities
  - Improved artifact detection logic

### Fixed

- Removed duplicate configuration loading code
- Eliminated redundant file extension checking
- Improved error message consistency
- Fixed unused imports

### Documentation

- Enhanced dartdoc comments for all public APIs
- Added comprehensive usage examples
- Created error scenarios guide
- Updated README with new features
- Generated API documentation with zero warnings

## [1.70.0] - 2025-10-08

### Added

- Detect Mapbox public/secret tokens and Supabase publishable/secret keys via bundled patterns ([config/regexes.json](https://github.com/mathtechstudio/ohmyg0sh/blob/main/config/regexes.json), [lib/config/regexes.json](https://github.com/mathtechstudio/ohmyg0sh/blob/main/lib/config/regexes.json))

### Changed

- Stamp generated reports with generator metadata and upstream repository links ([OhMyG0sh.generateReport](https://github.com/mathtechstudio/ohmyg0sh/blob/main/lib/src/ohmyg0sh_base.dart))
- Stream JAXB suppression improvements to hide noisy `ERROR - finished with errors` lines while preserving progress output ([OhMyG0sh.decompile](https://github.com/mathtechstudio/ohmyg0sh/blob/main/lib/src/ohmyg0sh_base.dart))

## [1.69.777+69] - 2025-10-07

### Fixed

- Resolve bundled configs via package: URIs for pub global installs ([OhMyG0sh._loadPatterns()](https://github.com/mathtechstudio/ohmyg0sh/blob/main/lib/src/ohmyg0sh_base.dart), [OhMyG0sh._loadNotKeyHacks()](https://github.com/mathtechstudio/ohmyg0sh/blob/main/lib/src/ohmyg0sh_base.dart))
- Ship default patterns/filters with the package for global CLI ([lib/config/regexes.json](https://github.com/mathtechstudio/ohmyg0sh/blob/main/lib/config/regexes.json), [lib/config/notkeyhacks.json](https://github.com/mathtechstudio/ohmyg0sh/blob/main/lib/config/notkeyhacks.json))
- README notes for output file naming and config resolution ([README.md](https://github.com/mathtechstudio/ohmyg0sh/blob/main/README.md))

### Chore

- Bump version to 1.69.777+69 ([pubspec.yaml](https://github.com/mathtechstudio/ohmyg0sh/blob/main/pubspec.yaml))
- Add .pubignore and ensure CHANGELOG.md is included ([.pubignore](https://github.com/mathtechstudio/ohmyg0sh/blob/main/.pubignore))
- Ignore RELEASE_STEP.md in VCS ([.gitignore](https://github.com/mathtechstudio/ohmyg0sh/blob/main/.gitignore))

### Docs

- Standardize doc comments across library, CLI, core engine, scanner, example, and tests

## [1.69.777] - 2025-10-07

### Added

- Initial release of ohmyg0sh APK security scanner
- APK decompilation using jadx 1.5.3
- Regex-based detection for 50+ API key and secret patterns
- Configurable detection rules via `config/regexes.json`
- False-positive filtering via `config/notkeyhacks.json`
- JSON and text output formats
- Docker image for easy deployment
- Continue-on-error mode for jadx failures
- Comprehensive pattern library including:
  - AWS, Google Cloud, Azure credentials
  - Social media API keys (Facebook, Twitter, Slack)
  - Payment services (Stripe, PayPal, Square)
  - Database connection strings
  - Private keys and certificates
- Automatic cleanup of temporary files
- Detailed logging for troubleshooting

### Security

- Scans Java, Kotlin, Smali, XML, JavaScript, and text files
- Package name extraction from AndroidManifest.xml
- Pattern matching with context-aware filtering

### Documentation

- Complete README with installation and usage examples
- Docker Hub deployment guide
- Troubleshooting section
- Contributing guidelines
