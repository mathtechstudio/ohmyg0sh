import 'dart:io';

/// ANSI color codes for terminal output
class CliColors {
  static const String header = '\x1B[95m'; // Magenta
  static const String blue = '\x1B[94m';
  static const String green = '\x1B[92m';
  static const String yellow = '\x1B[93m';
  static const String red = '\x1B[91m';
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String underline = '\x1B[4m';
}

/// Display CLI banner with version
void displayHeader(String version) {
  final banner = '''
${CliColors.header}
 ██████╗ ██╗  ██╗███╗   ███╗██╗   ██╗ ██████╗  ██████╗ ███████╗██╗  ██╗   
██╔═══██╗██║  ██║████╗ ████║╚██╗ ██╔╝██╔════╝ ██╔═████╗██╔════╝██║  ██║   
██║   ██║███████║██╔████╔██║ ╚████╔╝ ██║  ███╗██║██╔██║███████╗███████║   
██║   ██║██╔══██║██║╚██╔╝██║  ╚██╔╝  ██║   ██║████╔╝██║╚════██║██╔══██║   
╚██████╔╝██║  ██║██║ ╚═╝ ██║   ██║   ╚██████╔╝╚██████╔╝███████║██║  ██║██╗
 ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝
                                                                          
 $version
 --${CliColors.reset}
 ${CliColors.bold}APK security scanner file for URIs, endpoints & secrets for detecting hardcoded credentials${CliColors.reset}
 ${CliColors.green}(c) 2025, Iqbal Fauzi - https://github.com/mathtechstudio/ohmyg0sh${CliColors.reset}
''';

  stderr.writeln(banner);
}
