# ohmyg0sh

![Pub Version](https://img.shields.io/pub/v/ohmyg0sh)
![Release CI](https://github.com/mathtechstudio/ohmyg0sh/actions/workflows/release.yml/badge.svg?branch=main)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows-informational)

ohmyg0sh is an APK security scanner that decompiles packages with `jadx`, applies a curated library of credential and secret patterns, filters false positives, and produces text or JSON reports.

## Table of Contents

- [ohmyg0sh](#ohmyg0sh)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Installation](#installation)
    - [Global CLI (Recommended)](#global-cli-recommended)
    - [Project Dependency](#project-dependency)
    - [Docker](#docker)
  - [Requirements](#requirements)
    - [Installing jadx](#installing-jadx)
  - [Quick Start](#quick-start)
    - [CLI](#cli)
    - [Programmatic API](#programmatic-api)
  - [Configuration](#configuration)
    - [Custom Patterns (`regexes.json`)](#custom-patterns-regexesjson)
    - [False Positive Filters (`notkeyhacks.json`)](#false-positive-filters-notkeyhacksjson)
  - [Built-in Patterns](#built-in-patterns)
  - [Output Examples](#output-examples)
    - [Text](#text)
    - [JSON](#json)
  - [CLI Reference](#cli-reference)
  - [How It Works](#how-it-works)
  - [Troubleshooting](#troubleshooting)
    - [`jadx` Not Found](#jadx-not-found)
    - [`jadx` Exits with Errors](#jadx-exits-with-errors)
    - [Custom Pattern Resolution](#custom-pattern-resolution)
  - [Docker Usage](#docker-usage)
  - [Development](#development)
  - [Contributing](#contributing)
  - [Security Notes](#security-notes)
  - [Acknowledments](#acknowledments)
  - [License](#license)
  - [Links](#links)

## Features

- Scan Android APKs for hardcoded credentials before release
- 50+ bundled regex patterns covering major cloud, social, payment, and developer platforms
- Customizable detection rules and false-positive filters
- Human-readable text reports and machine-friendly JSON output
- Streamed CLI updates with noisy jadx error lines suppressed
- Programmatic API and Docker image for automation pipelines

## Installation

### Global CLI (Recommended)

```bash
dart pub global activate ohmyg0sh
ohmyg0sh -f app-release.apk
```

### Project Dependency

```yaml
dependencies:
  ohmyg0sh: ^1.70.0
```

```bash
dart pub get
```

### Docker

```bash
docker pull mathtechstudio/ohmyg0sh:latest
docker run -it --rm -v "$PWD":/work -w /work mathtechstudio/ohmyg0sh:latest -f /work/app-release.apk
```

## Requirements

- **Dart SDK** ^3.5
- **Java** 11 or newer (required by `jadx`)
- **jadx** installed and available on `PATH`, or passed with `--jadx`

### Installing jadx

```bash
# macOS
brew install jadx

# Linux / Windows
# Download from https://github.com/skylot/jadx/releases and add the binary to PATH
```

## Quick Start

### CLI

```bash
# Basic scan
ohmyg0sh -f app-release.apk

# JSON results
ohmyg0sh -f app-release.apk --json -o results.json

# Custom patterns & extra jadx flags
ohmyg0sh -f app-release.apk -p custom/regexes.json -a "--deobf --log-level INFO"
```

> [!TIP]
> If your output file name starts with `-`, provide the path as `--output=./-results.json` to avoid option parsing issues.

### Programmatic API

```dart
import 'package:ohmyg0sh/ohmyg0sh.dart';

Future<void> main() async {
  final scanner = OhMyG0sh(
    apkPath: './app-release.apk',
    outputJson: true,
    outputFile: 'results.json',
  );

  await scanner.run();
}
```

## Configuration

### Custom Patterns (`regexes.json`)

```json
// your-fucking-rules.json
{
  "Google_API_Key": "AIza[0-9A-Za-z\\-_]{35}",
  "AWS_Access_Key": "AKIA[0-9A-Z]{16}",
  "Custom_Token": "myapp_[a-f0-9]{32}"
  // ...
}
```

Use via `ohmyg0sh -f app.apk -p my-patterns.json`.

### False Positive Filters (`notkeyhacks.json`)

```json
{
  "patterns": ["example\\.com"],
  "contains": ["PLACEHOLDER"],
  "Google_API_Key": ["AIzaGRAPHIC_DESIGN"]
}
```

Use via `ohmyg0sh -f app.apk -n my-filters.json`.

## Built-in Patterns

Bundled rules detect secrets across:

- **Cloud**: AWS, Google Cloud, Azure, DigitalOcean
- **Social & Comms**: Facebook, Twitter, Slack, Discord
- **Payments**: Stripe, PayPal, Square, Braintree
- **Developer Services**: GitHub, GitLab, Mailgun, Cloudinary
- **Databases & Keys**: MongoDB, Postgres, private key blocks

Review the full list in [config/regexes.json](config/regexes.json).

## Output Examples

### Text

```bash
** Scanning against 'com.example.app'

[Google_API_Key]
- AIzaSyD...

** Results saved into 'results_1234567890.txt'.
```

### JSON

```json
{
  "package": "com.example.app",
  "results": [
    {
      "name": "Google_API_Key",
      "matches": ["AIzaSyD..."]
    }
  ],
  "generated_at": "2025-10-07T14:00:00Z",
  "generated_by": "ohmyg0sh",
  "repository": "https://github.com/mathtechstudio/ohmyg0sh",
  "pub_dev": "https://pub.dev/packages/ohmyg0sh"
}
```

## CLI Reference

| Option      | Short | Description                                  |
| ----------- | ----- | -------------------------------------------- |
| `--file`    | `-f`  | APK file to scan (required)                  |
| `--output`  | `-o`  | Output file path (auto-generated if missing) |
| `--json`    |       | Emit JSON instead of text                    |
| `--pattern` | `-p`  | Custom `regexes.json` file                   |
| `--notkeys` | `-n`  | Custom `notkeyhacks.json` file               |
| `--jadx`    |       | Explicit path to the `jadx` binary           |
| `--args`    | `-a`  | Additional `jadx` arguments (quoted)         |
| `--help`    | `-h`  | Show usage                                   |

## How It Works

1. **Decompile** APK with `jadx`
2. **Extract** package metadata
3. **Scan** Java, Kotlin, Smali, XML, JS, and TXT sources
4. **Match** regex patterns against file contents
5. **Filter** via `notkeyhacks` rules
6. **Report** grouped matches to disk in the requested format

## Troubleshooting

### `jadx` Not Found

```bash
brew install jadx       # macOS
which jadx && jadx --version
```

Or run with `--jadx /custom/path/to/jadx`.

### `jadx` Exits with Errors

OhMyG0sh continues when usable artifacts exist and suppresses the noisy `ERROR - finished with errors` line. For verbose logs use:

```bash
ohmyg0sh -f app.apk -a "--log-level DEBUG"
```

### Custom Pattern Resolution

Search order:

1. `--pattern` path (if provided)
2. `/app/config/regexes.json` (Docker image)
3. `package:ohmyg0sh/config/regexes.json` (pub install)
4. `./config/regexes.json`
5. Executable-relative fallback

## Docker Usage

```bash
alias ohmyg0sh='docker run --rm -it -v "$PWD":/work -w /work mathtechstudio/ohmyg0sh:latest'
ohmyg0sh -f app-release.apk
```

With custom patterns:

```bash
docker run -it --rm \
  -v "$PWD":/work \
  -v "$PWD/patterns.json":/patterns.json \
  -w /work \
  mathtechstudio/ohmyg0sh:latest \
  -f /work/app.apk -p /patterns.json
```

## Development

```bash
git clone https://github.com/mathtechstudio/ohmyg0sh.git
cd ohmyg0sh
dart pub get
dart run bin/ohmyg0sh.dart -f app-release.apk
dart test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement and test your changes
4. Submit a pull request

## Security Notes

- Use only on APKs you are authorized to assess
- Review findings manually to confirm leaks
- Rotate exposed credentials immediately
- Report vulnerabilities responsibly

## Acknowledments

Since this tool includes some contributions, and I'm not an asshole, I'll publically thank the following users for their helps and resources:

| Contributors                                                                                                                                |
| ------------------------------------------------------------------------------------------------------------------------------------------- |
| [![Contributors](https://contrib.rocks/image?repo=mathtechstudio/ohmyg0sh)](https://github.com/mathtechstudio/ohmyg0sh/graphs/contributors) |

## License

Released under the MIT License - see the [MIT License](LICENSE) file for details.

## Links

<h1 align="center" </h1>

- [GitHub](https://github.com/mathtechstudio/ohmyg0sh)
- [Docker](https://hub.docker.com/r/mathtechstudio/ohmyg0sh)
- [Issue Tracker](https://github.com/mathtechstudio/ohmyg0sh/issues)
- [pub.dev Package](https://pub.dev/packages/ohmyg0sh)

</div>
