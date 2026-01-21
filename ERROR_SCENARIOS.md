# Common Error Scenarios and Solutions

This document describes common errors you may encounter when using OhMyG0sh and how to resolve them.

## Table of Contents

- [APK Errors](#apk-errors)
- [JADX Errors](#jadx-errors)
- [Configuration Errors](#configuration-errors)
- [Scan Errors](#scan-errors)
- [Pattern Errors](#pattern-errors)
- [System Errors](#system-errors)

---

## APK Errors

### APK File Not Found

**Error Message:**

```bash
APK Error: APK file doesn't exist or is not accessible
APK: /path/to/app.apk
Context: Verify the file path and permissions
```

**Causes:**

- File path is incorrect
- File doesn't exist
- Insufficient read permissions
- File is on unmounted drive

**Solutions:**

1. Verify the file exists: `ls -la /path/to/app.apk`
2. Check file permissions: `chmod 644 /path/to/app.apk`
3. Use absolute path instead of relative path
4. Ensure the file extension is `.apk`

**Example:**

```dart
// ❌ Wrong - relative path might be incorrect
final scanner = OhMyG0sh(apkPath: '../app.apk');

// ✅ Correct - use absolute path
final scanner = OhMyG0sh(apkPath: '/home/user/apps/app.apk');
```

---

## JADX Errors

### JADX Not Found

**Error Message:**

```bash
JADX Error: jadx binary not found in PATH
Exit Code: -1
Context: Install jadx using:
  macOS: brew install jadx
  Linux/Windows: https://github.com/skylot/jadx/releases
Or provide explicit path with --jadx option
```

**Causes:**

- JADX is not installed
- JADX is not in system PATH
- Wrong JADX path provided

**Solutions:**

1. **Install JADX:**

   ```bash
   # macOS
   brew install jadx
   
   # Linux (using apt)
   sudo apt install jadx
   
   # Manual installation
   # Download from https://github.com/skylot/jadx/releases
   # Extract and add to PATH
   ```

2. **Provide explicit path:**

   ```dart
   final scanner = OhMyG0sh(
     apkPath: 'app.apk',
     jadxPath: '/usr/local/bin/jadx',
   );
   ```

3. **Verify installation:**

   ```bash
   which jadx
   jadx --version
   ```

### JADX Decompilation Failed

**Error Message:**

```bash
JADX Error: jadx decompilation failed
Exit Code: 1
Context: JADX exited with code 1. Check logs:
  stdout: /tmp/ohmyg0sh-xyz/jadx_stdout.log
  stderr: /tmp/ohmyg0sh-xyz/jadx_stderr.log
Try running with --args "--log-level DEBUG" for more details
```

**Causes:**

- Corrupted APK file
- Unsupported APK format
- Obfuscated or protected APK
- Insufficient memory
- JADX version incompatibility

**Solutions:**

1. **Check APK integrity:**

   ```bash
   unzip -t app.apk
   ```

2. **Enable debug logging:**

   ```dart
   await scanner.run(jadxExtraArgs: ['--log-level', 'DEBUG']);
   ```

3. **Continue on errors (if partial results acceptable):**

   ```dart
   final scanner = OhMyG0sh(
     apkPath: 'app.apk',
     continueOnJadxError: true,  // Default is true
   );
   ```

4. **Increase memory for large APKs:**

   ```bash
   export JAVA_OPTS="-Xmx4g"
   ```

5. **Try different JADX options:**

   ```dart
   await scanner.run(jadxExtraArgs: [
     '--no-res',        // Skip resources
     '--no-imports',    // Don't add imports
     '--deobf',         // Enable deobfuscation
   ]);
   ```

---

## Configuration Errors

### Pattern File Not Found

**Error Message:**

```bash
Configuration Error: regexes.json not found in any standard location
File: regexes.json
Searched paths:
  - /app/config/regexes.json
  - /current/dir/config/regexes.json
  - /package/install/config/regexes.json

Solutions:
  1. Provide explicit path with --pattern option
  2. Place regexes.json in ./config/ directory
  3. Ensure package installation is complete
```

**Causes:**

- Configuration file missing
- Wrong working directory
- Incomplete package installation
- Custom path not provided

**Solutions:**

1. **Create config directory and file:**

   ```bash
   mkdir -p config
   cp node_modules/ohmyg0sh/config/regexes.json config/
   ```

2. **Provide explicit path:**

   ```dart
   final scanner = OhMyG0sh(
     apkPath: 'app.apk',
     patternPath: '/path/to/custom-patterns.json',
   );
   ```

3. **Verify package installation:**

   ```bash
   dart pub get
   # or
   flutter pub get
   ```

### Invalid JSON in Configuration

**Error Message:**

```bash
Configuration Error: Failed to parse configuration file
File: /path/to/regexes.json
Context: Invalid JSON: FormatException: Unexpected character...
```

**Causes:**

- Malformed JSON syntax
- Missing commas or brackets
- Invalid escape sequences
- UTF-8 encoding issues

**Solutions:**

1. **Validate JSON:**

   ```bash
   # Using jq
   jq . config/regexes.json
   
   # Using Python
   python -m json.tool config/regexes.json
   ```

2. **Check common issues:**
   - Trailing commas (not allowed in JSON)
   - Unescaped backslashes in regex patterns
   - Missing quotes around keys/values
   - Unclosed brackets or braces

3. **Example valid format:**

   ```json
   {
     "AWS_Key": "AKIA[0-9A-Z]{16}",
     "API_Token": "(?i)token\\s*[:=]\\s*['\"]([^'\"]+)['\"]"
   }
   ```

---

## Scan Errors

### Too Many Open Files

**Error Message:**

```bash
Scan Error: Too many open files
File: /tmp/ohmyg0sh-xyz/sources/com/example/File.java
```

**Causes:**

- System file descriptor limit reached
- Too high concurrency setting
- Large APK with many files

**Solutions:**

1. **Reduce concurrency:**

   ```dart
   final scanner = OhMyG0sh(
     apkPath: 'app.apk',
     scanConcurrency: 8,  // Lower value
   );
   ```

2. **Increase system limits (Unix/Linux):**

   ```bash
   # Temporary
   ulimit -n 4096
   
   # Permanent (add to ~/.bashrc or ~/.zshrc)
   echo "ulimit -n 4096" >> ~/.bashrc
   ```

3. **Check current limits:**

   ```bash
   ulimit -n
   ```

### File Read Permission Denied

**Error Message:**

```bash
Scan Error: Permission denied
File: /tmp/ohmyg0sh-xyz/sources/protected.java
```

**Causes:**

- Insufficient permissions on temp directory
- SELinux or AppArmor restrictions
- Antivirus interference

**Solutions:**

1. **Check temp directory permissions:**

   ```bash
   ls -la /tmp/ohmyg0sh-*
   ```

2. **Set proper permissions:**

   ```bash
   chmod -R 755 /tmp/ohmyg0sh-*
   ```

3. **Use custom temp directory:**

   ```bash
   export TMPDIR=/path/to/writable/temp
   ```

---

## Pattern Errors

### Invalid Regex Pattern

**Error Message:**

```bash
Pattern Error: Invalid regular expression
Pattern Name: Custom_Pattern
Pattern: [invalid(regex
Context: Unterminated character class
```

**Causes:**

- Malformed regex syntax
- Unescaped special characters
- Unclosed groups or brackets
- Invalid escape sequences

**Solutions:**

1. **Test regex patterns:**

   ```dart
   // Test pattern before adding to config
   try {
     final regex = RegExp(r'your_pattern_here');
     print('Pattern is valid');
   } catch (e) {
     print('Pattern error: $e');
   }
   ```

2. **Common regex issues:**

   ```json
   {
     "❌ Wrong": "[unclosed",
     "✅ Correct": "[a-z]+",
     
     "❌ Wrong": "(unclosed",
     "✅ Correct": "(group)",
     
     "❌ Wrong": "\\invalid",
     "✅ Correct": "\\\\valid"
   }
   ```

3. **Use online regex testers:**
   - <https://regex101.com/>
   - <https://regexr.com/>

---

## System Errors

### Out of Memory

**Error Message:**

```bash
Out of memory
```

**Causes:**

- Large APK file
- Insufficient system memory
- Memory leak
- Too many concurrent operations

**Solutions:**

1. **Increase Dart VM memory:**

   ```bash
   dart --old_gen_heap_size=4096 bin/ohmyg0sh.dart -f app.apk
   ```

2. **Reduce concurrency:**

   ```dart
   final scanner = OhMyG0sh(
     apkPath: 'app.apk',
     scanConcurrency: 4,
   );
   ```

3. **Process in batches:**
   - Split large APKs if possible
   - Scan specific directories only

### Disk Space Full

**Error Message:**

```bash
No space left on device
```

**Causes:**

- Insufficient disk space for decompilation
- Temp directory on small partition
- Previous temp files not cleaned up

**Solutions:**

1. **Check disk space:**

   ```bash
   df -h /tmp
   ```

2. **Clean up old temp files:**

   ```bash
   rm -rf /tmp/ohmyg0sh-*
   ```

3. **Use different temp directory:**

   ```bash
   export TMPDIR=/path/to/larger/partition/tmp
   ```

4. **Ensure cleanup runs:**

   ```dart
   try {
     await scanner.run();
   } finally {
     await scanner.cleanup();  // Always cleanup
   }
   ```

---

## Best Practices

### Error Handling Pattern

```dart
import 'package:ohmyg0sh/ohmyg0sh.dart';

Future<void> scanWithErrorHandling(String apkPath) async {
  final scanner = OhMyG0sh(apkPath: apkPath);
  
  try {
    // Pre-flight checks
    await scanner.integrityCheck();
    print('✓ Pre-flight checks passed');
    
    // Decompile
    await scanner.decompile();
    print('✓ Decompilation complete');
    
    // Scan
    await scanner.scanning();
    print('✓ Scanning complete');
    
    // Generate report
    await scanner.generateReport();
    print('✓ Report generated');
    
  } on ApkError catch (e) {
    print('❌ APK Error: ${e.message}');
    print('   File: ${e.apkPath}');
    if (e.context != null) print('   ${e.context}');
    
  } on JadxError catch (e) {
    print('❌ JADX Error: ${e.message}');
    print('   Exit Code: ${e.exitCode}');
    print('   Recoverable: ${e.isRecoverable}');
    if (e.context != null) print('   ${e.context}');
    
  } on ConfigurationError catch (e) {
    print('❌ Configuration Error: ${e.message}');
    print('   File: ${e.filePath}');
    if (e.context != null) print('   ${e.context}');
    
  } on ScanError catch (e) {
    print('❌ Scan Error: ${e.message}');
    print('   File: ${e.filePath}');
    if (e.context != null) print('   ${e.context}');
    
  } catch (e, stackTrace) {
    print('❌ Unexpected Error: $e');
    print('   Stack Trace: $stackTrace');
    
  } finally {
    // Always cleanup temp files
    await scanner.cleanup();
    print('✓ Cleanup complete');
  }
}
```

### Logging and Debugging

```dart
// Enable verbose output
final scanner = OhMyG0sh(
  apkPath: 'app.apk',
  showProgress: true,
);

// Use JADX debug logging
await scanner.run(jadxExtraArgs: ['--log-level', 'DEBUG']);

// Check JADX logs after failure
// Logs are in: /tmp/ohmyg0sh-*/jadx_stdout.log
//              /tmp/ohmyg0sh-*/jadx_stderr.log
```

### CI/CD Configuration

```dart
// Fail-fast mode for CI/CD
final scanner = OhMyG0sh(
  apkPath: 'app.apk',
  continueOnJadxError: false,  // Fail on any JADX error
  showProgress: false,          // Silent mode
);

try {
  await scanner.run();
  exit(0);  // Success
} catch (e) {
  print('Scan failed: $e');
  exit(1);  // Failure
}
```

---

## Getting Help

If you encounter an error not covered here:

1. **Check the logs:**
   - JADX logs: `/tmp/ohmyg0sh-*/jadx_stdout.log`
   - JADX errors: `/tmp/ohmyg0sh-*/jadx_stderr.log`

2. **Enable debug mode:**

   ```dart
   await scanner.run(jadxExtraArgs: ['--log-level', 'DEBUG']);
   ```

3. **Report issues:**
   - GitHub: <https://github.com/mathtechstudio/ohmyg0sh/issues>
   - Include: Error message, APK size, JADX version, OS version

4. **Community support:**
   - Check existing issues on GitHub
   - Search for similar problems
   - Provide minimal reproduction example
