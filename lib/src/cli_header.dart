import 'dart:io';

/// ANSI color codes for terminal output.
///
/// Provides escape sequences for colored and styled text in terminals.
/// Intended for rendering the startup banner and other messages.
/// Color support depends on the terminal emulator.
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

/// Render the colored ASCII banner with the provided version string.
///
/// Behavior:
/// - Writes to stderr to keep stdout clean for machine-readable output.
/// - Uses ANSI color codes defined in CliColors.
///
/// Parameters:
/// - [version] Version string to render inside the banner.
void displayHeader(String version) {
  final banner = '''
${CliColors.header}
 ██████╗ ██╗  ██╗███╗   ███╗██╗   ██╗ ██████╗  ██████╗    ███████╗██╗  ██╗   
██╔═══██╗██║  ██║████╗ ████║╚██╗ ██╔╝██╔════╝ ██╔═████╗   ██╔════╝██║  ██║   
██║   ██║███████║██╔████╔██║ ╚████╔╝ ██║  ███╗██║██╔██║   ███████╗███████║   
██║   ██║██╔══██║██║╚██╔╝██║  ╚██╔╝  ██║   ██║████╔╝██║   ╚════██║██╔══██║   
╚██████╔╝██║  ██║██║ ╚═╝ ██║   ██║   ╚██████╔╝╚██████╔╝██╗███████║██║  ██║██╗
 ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝    ╚═════╝  ╚═════╝ ╚═╝╚══════╝╚═╝  ╚═╝╚═╝
                                                                             
 $version
 --${CliColors.reset}
 ${CliColors.bold}APK security scanner file for URIs, endpoints & secrets for detecting hardcoded credentials${CliColors.reset}
 ${CliColors.green}(c) 2025, Iqbal Fauzi - https://github.com/mathtechstudio/ohmyg0sh${CliColors.reset}
''';

  stderr.writeln(banner);
}
