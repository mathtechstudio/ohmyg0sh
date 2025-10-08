# Changelog

All notable changes to this project will be documented in this file.

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
