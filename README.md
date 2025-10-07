# ohmyg0.sh

APK security scanner that detects hardcoded API keys and credentials before they reach production. Decompiles APKs with jadx and scans for exposed secrets using configurable regex patterns.

## Features

- Scan Android APKs for hardcoded credentials
- 50+ built-in patterns for common API keys and secrets
- Configurable detection rules and false-positive filters
- JSON and text output formats
- CLI tool or programmatic API
- Docker🐳 support for easy deployment

## Installation

### Option 1: Global CLI Tool (Recommended)

Activate globally to use `ohmyg0sh` command anywhere:

```bash
dart pub global activate ohmyg0sh
```

After activation, run directly:

```bash
ohmyg0sh -f file.apk
ohmyg0sh -f file.apk --json -o results.json
```

### Option 2: As Dependency

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ohmyg0sh: ^1.69.777
```

Then install:

```bash
dart pub get
```

### Option 3: Docker

Pull from Docker Hub:

```bash
docker pull mathtechstudio/ohmyg0sh:latest
```

Run:

```bash
docker run -it --rm -v "$PWD":/work -w /work mathtechstudio/ohmyg0sh:latest -f /work/file.apk
```

## Requirements

- **Dart SDK**: ^3.5.4
- **Java**: 11+ (for jadx decompiler)
- **jadx**: Must be installed and in PATH (or specify `--jadx` flag)

### Installing jadx

**macOS (Homebrew):**

```bash
brew install jadx
```

**Linux/Windows:**
Download from [jadx releases](https://github.com/skylot/jadx/releases) and add to PATH.

## Quick Start

### CLI Usage

Basic scan:

```bash
ohmyg0sh -f file.apk
```

JSON output:

```bash
ohmyg0sh -f file.apk --json -o results.json
```

Note:

- If your output file name begins with a dash (-), ensure it is not parsed as an option by using either form:

```bash
ohmyg0sh -f file.apk --json --output=-results.json
ohmyg0sh -f file.apk --json -o ./-results.json
```

Custom patterns:

```bash
ohmyg0sh -f file.apk -p custom-patterns.json
```

With jadx options:

```bash
ohmyg0sh -f file.apk -a "--deobf --log-level DEBUG"
```

### Programmatic API

Use as a library in your Dart projects:

```dart
import 'package:ohmyg0sh/ohmyg0sh.dart';

Future<void> main() async {
  final scanner = OhMyG0sh(
    apkPath: './app-release.apk',
    outputJson: true,
    outputFile: 'results.json',
  );

  try {
    await scanner.run();
  } catch (e) {
    print('Scan failed: $e');
    await scanner.cleanup();
  }
}
```

Advanced usage with custom configuration:

```dart
final scanner = OhMyG0sh(
  apkPath: './app.apk',
  outputJson: true,
  outputFile: 'scan-results.json',
  patternPath: './custom-patterns.json',
  notKeyHacksPath: './custom-filters.json',
  jadxPath: '/usr/local/bin/jadx',
  continueOnJadxError: true,
);

await scanner.run(jadxExtraArgs: ['--deobf', '--show-bad-code']);
```

## CLI Options

| Option      | Short | Description                                  |
| ----------- | ----- | -------------------------------------------- |
| `--file`    | `-f`  | APK file to scan (required)                  |
| `--output`  | `-o`  | Output file path (auto-generated if not set) |
| `--json`    |       | Save results as JSON                         |
| `--pattern` | `-p`  | Custom regex patterns JSON file              |
| `--notkeys` | `-n`  | False-positive filters JSON file             |
| `--jadx`    |       | Path to jadx binary                          |
| `--args`    | `-a`  | Additional jadx arguments (quoted)           |
| `--help`    | `-h`  | Show help message                            |

## Configuration

### Custom Patterns

Create a JSON file with your detection patterns:

```json
{
  "Google_API_Key": "AIza[0-9A-Za-z\\-_]{35}",
  "AWS_Access_Key": "AKIA[0-9A-Z]{16}",
  "Custom_Token": "myapp_[a-f0-9]{32}"
}
```

Use with:

```bash
ohmyg0sh -f file.apk -p my-patterns.json
```

### False Positive Filters

Create `notkeyhacks.json` to filter out known false positives:

```json
{
  "patterns": ["example\\.com", "test_key"],
  "contains": ["YOUR_API_KEY", "PLACEHOLDER"],
  "Google_API_Key": ["AIzaGRAPHIC_DESIGN"]
}
```

## Built-in Patterns

The package includes 50+ detection patterns for:

- **Cloud Services**: AWS, Google Cloud, Azure, DigitalOcean
- **Social Media**: Facebook, Twitter, LinkedIn, Slack
- **Payment**: Stripe, PayPal, Square, Braintree
- **Development**: GitHub, GitLab, NPM, PyPI
- **Databases**: MongoDB, PostgreSQL, MySQL
- **And many more...**

See [config/regexes.json](https://github.com/mathtechstudio/ohmyg0sh/blob/main/config/regexes.json) for the complete list.

## Output Examples

### Text Format

```bash
** Scanning against 'com.example.app'

[Google_API_Key]
- AIzaSyD...
- AIzaSyE...

[AWS_Access_Key]
- AKIAIOSFODNN7EXAMPLE

** Results saved into 'results_1234567890.txt'.
```

### JSON Format

```json
{
  "package": "com.example.app",
  "results": [
    {
      "name": "Google_API_Key",
      "matches": ["AIzaSyD...", "AIzaSyE..."]
    },
    {
      "name": "AWS_Access_Key",
      "matches": ["AKIAIOSFODNN7EXAMPLE"]
    }
  ],
  "generated_at": "2025-10-07T14:00:00Z"
}
```

## How It Works

1. **Decompile**: APK is decompiled using jadx
2. **Extract**: Package name from AndroidManifest.xml
3. **Scan**: Java, Kotlin, Smali, XML, JS, and TXT files
4. **Match**: Apply regex patterns to file contents
5. **Filter**: Remove false positives using notkeyhacks rules
6. **Report**: Group findings and save results

## Troubleshooting

### jadx not found

Install jadx and ensure it's in your PATH:

```bash
# macOS
brew install jadx

# Verify
which jadx
jadx --version
```

Or specify custom path:

```bash
ohmyg0sh -f file.apk --jadx /path/to/jadx
```

### jadx exits with error

The tool continues if artifacts are found. Enable detailed logging:

```bash
ohmyg0sh -f file.apk -a "--log-level DEBUG"
```

### Pattern file not found

The tool searches for patterns in:

1. Custom path (if `-p` specified)
2. `/app/config/regexes.json` (Docker image)
3. `package:ohmyg0sh/config/regexes.json` (bundled with the package)
4. `./config/regexes.json` (current working directory)
5. Script-relative fallback near the executable

## Docker Usage

Create alias for convenience:

```bash
# macOS/Linux
alias ohmyg0sh='docker run --rm -it -v "$PWD":/work -w /work mathtechstudio/ohmyg0sh:latest'

# Then use like:
ohmyg0sh -f file.apk
```

With custom patterns:

```bash
docker run -it --rm \
  -v "$PWD":/work \
  -v "$PWD/patterns.json":/patterns.json \
  -w /work \
  mathtechstudio/ohmyg0sh:latest \
  -f /work/file.apk -p /patterns.json
```

## Development

Clone and setup:

```bash
git clone https://github.com/mathtechstudio/ohmyg0sh.git
cd ohmyg0sh
dart pub get
```

Run locally:

```bash
dart run bin/ohmyg0sh.dart -f test.apk
```

Run tests:

```bash
dart test
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Security Notes

- For security research and auditing only
- Always obtain authorization before scanning
- Verify findings manually (false positives possible)
- Rotate exposed credentials immediately
- Report vulnerabilities responsibly

## License

See [LICENSE](LICENSE) file for details.

## Links

- [GitHub Repository](https://github.com/mathtechstudio/ohmyg0sh)
- [Docker Hub](https://hub.docker.com/r/mathtechstudio/ohmyg0sh)
- [Issue Tracker](https://github.com/mathtechstudio/ohmyg0sh/issues)
- [pub.dev](https://pub.dev/packages/ohmyg0sh)
