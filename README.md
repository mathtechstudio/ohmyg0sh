# 0hmyg0sh

Lightweight Dart package for scanning Android APKs to detect possible API key or secret leaks using regex signatures. It decompiles the APK with jadx, crawls source/resources, and reports matches.

## Features

- Decompile APK with jadx and scan Java/Kotlin/Smali/XML/JS/TXT files
- Regex-driven detection via configurable signatures (config/regexes.json)
- Optional false-positive filters via config/notkeyhacks.json
- JSON output with grouped results and timestamps
- Continue-on-error mode when jadx exits non-zero but still produces artifacts

## Requirements

- Java 11+ (tested with Java 17)
- jadx installed and available in PATH, or specify --jadx
- Dart SDK ^3.5.4

## Installation

### Option 1: Docker (Recommended)

Pull from Docker Hub:

```bash
docker pull mathtechstudio/ohmyg0sh:latest
```

Or build locally:

```bash
git clone https://github.com/mathtechstudio/ohmyg0sh.git
cd ohmyg0sh
docker build -t ohmyg0sh:latest .
```

### Option 2: From Source

Requires Dart SDK, Java 17, and jadx installed:

```bash
git clone https://github.com/username/ohmyg0sh.git
cd ohmyg0sh
dart pub get
dart run bin/ohmyg0sh.dart -f file.apk
```

## Usage

### With Docker

Basic scan:

```bash
docker run -it --rm -v "$PWD":/work -w /work mathtechstudio/ohmyg0sh:latest -f /work/file.apk
```

With custom output:

```bash
docker run -it --rm -v "$PWD":/work -w /work mathtechstudio/ohmyg0sh:latest \
  -f /work/file.apk -o /work/results.json --json
```

With custom patterns:

```bash
docker run -it --rm \
  -v "$PWD":/work \
  -v "$PWD/custom-rules.json":/custom-rules.json \
  -w /work \
  mathtechstudio/ohmyg0sh:latest \
  -f /work/file.apk -p /custom-rules.json
```

### Create CLI Alias (Optional)

#### macOS/Linux

Temporary:

```bash
alias ohmyg0sh='docker run --rm -it -v "$PWD":/work -w /work mathtechstudio/ohmyg0sh:latest'
```

Persistent (zsh):

```bash
echo 'alias ohmyg0sh="docker run --rm -it -v \"\$PWD\":/work -w /work mathtechstudio/ohmyg0sh:latest"' >> ~/.zshrc
source ~/.zshrc
```

Persistent (bash):

```bash
echo 'alias ohmyg0sh="docker run --rm -it -v \"\$PWD\":/work -w /work mathtechstudio/ohmyg0sh:latest"' >> ~/.bashrc
source ~/.bashrc
```

#### Windows PowerShell

Add to $PROFILE:

```powershell
function ohmyg0sh { docker run --rm -it -v ${PWD}:/work -w /work mathtechstudio/ohmyg0sh:latest $args }
```

Make persistent:

```powershell
if (!(Test-Path $PROFILE)) { New-Item -Path $PROFILE -ItemType File -Force }
Add-Content $PROFILE 'function ohmyg0sh { docker run --rm -it -v ${PWD}:/work -w /work mathtechstudio/ohmyg0sh:latest $args }'
```

After setup:

```bash
ohmyg0sh -f file.apk
ohmyg0sh -f file.apk -o results.json --json
```

### From Source

Basic usage:

```bash
dart run bin/ohmyg0sh.dart -f ~/path/to/file.apk
```

With custom output:

```bash
dart run bin/ohmyg0sh.dart -f file.apk -o results.json --json
```

With custom patterns:

```bash
dart run bin/ohmyg0sh.dart -f file.apk -p custom-rules.json
```

## Options

| Argument      | Description                             | Example                                             |
| ------------- | --------------------------------------- | --------------------------------------------------- |
| -f, --file    | APK file to scan                        | ohmyg0sh -f file.apk                                |
| -o, --output  | Output file (auto-generated if not set) | ohmyg0sh -f file.apk -o results.txt                 |
| -p, --pattern | Path to custom patterns JSON            | ohmyg0sh -f file.apk -p custom-rules.json           |
| -a, --args    | Disassembler arguments                  | ohmyg0sh -f file.apk -a "--deobf --log-level DEBUG" |
| --json        | Save as JSON format                     | ohmyg0sh -f file.apk --json                         |
| --jadx        | Path to jadx binary                     | ohmyg0sh -f file.apk --jadx /usr/bin/jadx           |
| -n, --notkeys | Path to notkeyhacks.json                | ohmyg0sh -f file.apk -n custom-filters.json         |
| -h, --help    | Show help message                       | ohmyg0sh --help                                     |

## Configuration

### Regex Patterns (config/regexes.json)

Define detection patterns for various API keys and secrets:

```json
{
  "Google_API_Key": "AIza[0-9A-Za-z\\-_]{35}",
  "AWS_Access_Key": "AKIA[0-9A-Z]{16}",
  "GitHub": "[g|G][i|I][t|T][h|H][u|U][b|B].*['|\"][0-9a-zA-Z]{35,40}['|\"]",
  "Generic_Secret": "[s|S][e|E][c|C][r|R][e|E][t|T].*['|\"][0-9a-zA-Z]{32,45}['|\"]"
}
```

The package includes a comprehensive set of default patterns for:

- AWS keys and S3 buckets
- Google API keys and OAuth tokens
- GitHub tokens
- Firebase URLs
- Social media API keys (Facebook, Twitter, Slack)
- Payment service tokens (Stripe, PayPal, Square)
- And many more...

### False Positive Filters (config/notkeyhacks.json)

Reduce noise by filtering out known false positives:

```json
{
  "patterns": [
    "\\.with(?:AccountId|BeaconKey)\\([\"'].*[\"']\\)"
  ],
  "contains": [
    "example.com",
    "test_key",
    "YOUR_API_KEY"
  ],
  "Google_API_Key": [
    "AIzaGRAPHIC_DESIGN_TOOL"
  ]
}
```

Supported filter types:

- patterns: List of regex patterns to ignore (matches against found string or file content)
- contains: List of substrings to ignore
- per-key filters: Key name maps to regex list to ignore for that specific signature

### Custom Patterns Example

Create your own pattern file:

```json
{
  "Custom_API_Key": "myapp_[0-9a-f]{32}",
  "Internal_Token": "internal_token_[A-Z0-9]{20}"
}
```

Use it:

```bash
ohmyg0sh -f file.apk -p ./my-custom-patterns.json
```

## Programmatic API

You can use OhMyG0sh as a library in your Dart projects:

```dart
import 'package:ohmyg0sh/ohmyg0sh.dart';

Future<void> main() async {
  final scanner = OhMyG0sh(
    apkPath: './app-release.apk',
    outputJson: true,
    outputFile: 'results.json',
    patternPath: './config/regexes.json',
    notKeyHacksPath: './config/notkeyhacks.json',
    continueOnJadxError: true,
  );

  try {
    await scanner.run(jadxExtraArgs: ['--show-bad-code', '--deobf']);
  } catch (e, st) {
    print('Error: $e');
    print(st);
    await scanner.cleanup();
  }
}
```

## Output

### Text Format (default)

```bash
** Decompiling APK...
** Scanning files...
** Scanning against 'com.example.app'

[Google_API_Key]
- AIzaSyD...
- AIzaSyE...

[AWS_Access_Key]
- AKIAIOSFODNN7EXAMPLE

[Facebook_Access_Token]
- EAACEdEose0cBA...

** Results saved into 'results_1696598400000.txt'.
```

### JSON Format (--json)

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
    },
    {
      "name": "Facebook_Access_Token",
      "matches": ["EAACEdEose0cBA..."]
    }
  ],
  "generated_at": "2025-10-06T14:00:00Z"
}
```

Output file naming:

- Default: results_{timestamp}.txt or results_{timestamp}.json
- Custom: Use -o flag to specify your own filename

## Scanning Details

### File Types Scanned

- .java - Java source files
- .kt - Kotlin source files
- .smali - Smali bytecode
- .xml - XML resources (layouts, manifests, configs)
- .js - JavaScript files
- .txt - Text files

### Detection Process

- Decompilation: APK is decompiled using jadx to extract source code and resources
- Package Extraction: Package name is extracted from AndroidManifest.xml
- File Scanning: All relevant file types are scanned recursively
- Pattern Matching: Regex patterns are applied to file contents
- Filtering: Results are filtered using notkeyhacks.json rules
- Reporting: Findings are grouped by signature type and saved

### Temporary Files

- Decompiled output is stored in system temp directory
- Temp files are automatically cleaned up after scanning
- Logs are preserved in temp directory for troubleshooting:
  - jadx_stdout.log
  - jadx_stderr.log
  - jadx_exit_code.txt

## Troubleshooting

### JADX not found in PATH (Docker)

Not applicable when using Docker - jadx is pre-installed in the image.

### JADX not found in PATH (Source installation)

The CLI will prompt for installation:

```bash
jadx not found in PATH. Do you want to install jadx now? [Y/n]:
```

On macOS with Homebrew:

```bash
brew install jadx
```

Manual installation:

- Download from: <https://github.com/skylot/jadx/releases>
- Extract and add to PATH
- Verify: which jadx or jadx --version

Or specify custom path:

```bash
ohmyg0sh -f file.apk --jadx /path/to/jadx
```

### JADX exit code 1

The tool continues if decompiled artifacts exist. Check logs in temp directory:

Warning:

```bash
jadx exited with code 1, but decompiled artifacts were found under /tmp/ohmyg0sh-xyz.
Continuing. See logs: /tmp/ohmyg0sh-xyz/jadx_stdout.log, /tmp/ohmyg0sh-xyz/jadx_stderr.log
```

Try additional arguments:

```bash
# Enable deobfuscation
ohmyg0sh -f file.apk -a "--deobf"

# Increase logging
ohmyg0sh -f file.apk -a "--log-level DEBUG"

# Multiple arguments
ohmyg0sh -f file.apk -a "--deobf --show-bad-code --log-level DEBUG"
```

Common jadx arguments:

- --deobf - Enable deobfuscation
- --show-bad-code - Show inconsistent code
- --threads-count N - Use N threads for decompilation
- --log-level LEVEL - Set log level (QUIET, PROGRESS, ERROR, WARN, INFO, DEBUG)

### Regex file not found

Ensure config/regexes.json exists or provide custom path:

```bash
ohmyg0sh -f file.apk -p /path/to/custom-rules.json
```

The tool searches in order:

1. Path specified by -p flag
2. /app/config/regexes.json (Docker environment)
3. ./config/regexes.json (current directory)
4. Relative to script location

### Docker volume mounting issues (Windows)

Use absolute paths:

PowerShell:

```powershell
docker run -it --rm -v C:\Users\You\apks:/work -w /work mathtechstudio/ohmyg0sh:latest -f /work/file.apk
```

Command Prompt:

```cmd
docker run -it --rm -v C:\Users\You\apks:/work -w /work mathtechstudio/ohmyg0sh:latest -f /work/file.apk
```

Or use WSL2:

From WSL:

```bash
docker run -it --rm -v "$PWD":/work -w /work mathtechstudio/ohmyg0sh:latest -f /work/file.apk
```

### Permission denied errors

On Linux/macOS, ensure Docker has permission to mount volumes:

```bash
# Run with proper permissions
docker run -it --rm -v "$PWD":/work -w /work --user $(id -u):$(id -g) mathtechstudio/ohmyg0sh:latest -f /work/file.apk
```

### APK file not found

Ensure correct path and file exists:

```bash
# Check file exists
ls -lh /path/to/file.apk
```

Use absolute path:

```bash
docker run -it --rm -v /absolute/path:/work -w /work mathtechstudio/ohmyg0sh:latest -f /work/file.apk
```

## Development

### Setup

```bash
# Clone repository
git clone https://github.com/mathtechstudio/ohmyg0sh.git
cd ohmyg0sh

# Install dependencies
dart pub get

# Run tests
dart test

# Format code
dart format .

# Analyze
dart analyze
```

### Build Docker Image

```bash
# Build
docker build -t ohmyg0sh:dev .

# Test
docker run -it --rm ohmyg0sh:dev --help

# Tag for release
docker tag ohmyg0sh:dev mathtechstudio/ohmyg0sh:1.0.0
docker tag ohmyg0sh:dev mathtechstudio/ohmyg0sh:latest

# Push to Docker Hub
docker push mathtechstudio/ohmyg0sh:1.0.0
docker push mathtechstudio/ohmyg0sh:latest
```

## Contributing

Contributions are welcome! Please follow these guidelines:

- Fork the repository
- Create a feature branch: git checkout -b feature/my-feature
- Commit your changes: git commit -am 'Add new feature'
- Push to the branch: git push origin feature/my-feature
- Submit a pull request

## Adding New Patterns

To add new detection patterns:

- Edit config/regexes.json
- Add your pattern with descriptive name
- Test with sample APKs
- Add corresponding filters to config/notkeyhacks.json if needed
- Submit PR with examples

Example:

```json
{
  "My_Custom_Service_Key": "myservice_[a-f0-9]{32}"
}
```

## Security Notes

- This tool is for security research and auditing purposes
- Always obtain proper authorization before scanning APKs
- Results may include false positives - verify findings manually
- Leaked keys should be rotated immediately
- Report findings responsibly to app developers
