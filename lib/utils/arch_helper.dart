import 'dart:io';

// Enum to represent CPU architectures
enum Architecture { x86, x86_64, arm, arm64, unknown }

void main() {
  print('Operating System: ${Platform.operatingSystem}');
  print('Architecture: ${getArchitecture()}');
}

Architecture getArchitecture() {
  if (Platform.isWindows) {
    return _getWindowsArchitecture();
  } else if (Platform.isLinux) {
    return _getLinuxArchitecture();
  } else if (Platform.isMacOS) {
    return _getMacOSArchitecture();
  }
  return Architecture.unknown;
}

Architecture _getWindowsArchitecture() {
  String arch = Platform.environment['PROCESSOR_ARCHITECTURE'] ?? '';
  if (arch.contains('AMD64') || arch.contains('x86_64')) {
    return Architecture.x86_64;
  } else if (arch.contains('x86')) {
    return Architecture.x86;
  } else if (arch.contains('ARM')) {
    return Architecture.arm;
  }
  return Architecture.unknown;
}

Architecture _getLinuxArchitecture() {
  if (Platform.isLinux) {
    try {
      var result = Process.runSync('uname', ['-m']);
      if (result.exitCode == 0) {
        String output = result.stdout.toString().trim();
        if (output == 'x86_64') {
          return Architecture.x86_64;
        } else if (output == 'x86') {
          return Architecture.x86;
        } else if (output == 'armv7l' || output == 'arm') {
          return Architecture.arm;
        } else if (output == 'aarch64') {
          return Architecture.arm64;
        }
      }
    } catch (e) {
      print('Error getting Linux architecture: $e');
    }
  }
  return Architecture.unknown;
}

Architecture _getMacOSArchitecture() {
  if (Platform.isMacOS) {
    try {
      var result = Process.runSync('uname', ['-m']);
      if (result.exitCode == 0) {
        String output = result.stdout.toString().trim();
        if (output == 'x86_64') {
          return Architecture.x86_64;
        } else if (output == 'x86') {
          return Architecture.x86;
        } else if (output == 'arm64') {
          return Architecture.arm64;
        }
      }
    } catch (e) {
      print('Error getting macOS architecture: $e');
    }
  }
  return Architecture.unknown;
}
