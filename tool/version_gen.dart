import 'dart:io';
import 'package:yaml/yaml.dart';

void main() {
  try {
    // Read pubspec.yaml
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      print('Error: pubspec.yaml not found');
      exit(1);
    }

    final pubspec = pubspecFile.readAsStringSync();
    final yaml = loadYaml(pubspec);
    final version = yaml['version'];

    if (version == null) {
      print('Version not found in pubspec.yaml');
      exit(1);
    }

    // Generate version.dart
    final versionFile = File('lib/src/version.dart');
    versionFile.writeAsStringSync('''
// Auto-generated - DO NOT EDIT
// Generated from pubspec.yaml version: $version
const String packageVersion = '$version';
''');

    print('Success: Generated lib/src/version.dart with version: $version');
  } catch (e) {
    print('Error: Error generating version: $e');
    exit(1);
  }
}
