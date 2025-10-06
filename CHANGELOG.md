# Changelog

All notable changes to this project will be documented in this file.

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
