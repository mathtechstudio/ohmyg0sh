// example/ohmyg0sh_example.dart
import 'dart:io';
import 'package:ohmyg0sh/ohmyg0sh.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run example/ohmyg0sh_example.dart <path_to_apk>');
    exit(1);
  }

  final apk = args.first;
  final scanner = OhMyG0sh(
    apkPath: apk,
    outputJson: true,
    // patternPath: 'config/regexes.json', // optional
    // notKeyHacksPath: 'config/notkeyhacks.json', // optional
    // jadxPath: '/usr/local/bin/jadx', // optional
  );

  try {
    await scanner.run();
  } catch (e) {
    stderr.writeln('Error: $e');
    await scanner.cleanup();
    exit(2);
  }
}
