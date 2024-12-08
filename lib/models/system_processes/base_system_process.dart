// Haveno App extends the features of Haveno, supporting mobile devices and more.
// Copyright (C) 2024 Kewbit (https://kewbit.org)
// Source Code: https://git.haveno.com/haveno/haveno-app.git
//
// Author: Kewbit
//    Website: https://kewbit.org
//    Contact Email: me@kewbit.org
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import 'dart:async';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

abstract class SystemProcess {
  final String key;
  final String displayName;
  final String? bundleAssetKey;
  final String? windowsInstallationPath;
  final String? linuxInstallationPath;
  final String? macOsInstallationPath;
  final bool useInstallationPathAsWorkingDirectory;
  final String? windowsExecutableName;
  final String? linuxExecutableName;
  final String? macOsExecutableName;
  final bool startOnLaunch;
  final String versionMinor;
  final String versionMajor;
  List<String>? executionArgs = [''];
  final Uri downloadUrl;
  final bool runAsDaemon;
  final int? internalPort;
  final int? externalPort;
  final bool installedByDistribution;
  final String? pidFilePath;
  Process? process;
  String? processStartPath;

  SystemProcess(
      {required this.key,
      required this.displayName,
      required this.bundleAssetKey,
      required this.windowsInstallationPath,
      required this.linuxInstallationPath,
      required this.macOsInstallationPath,
      required this.useInstallationPathAsWorkingDirectory,
      required this.windowsExecutableName,
      required this.linuxExecutableName,
      required this.macOsExecutableName,
      required this.startOnLaunch,
      required this.versionMinor,
      required this.versionMajor,
      required this.executionArgs,
      required this.downloadUrl,
      required this.runAsDaemon,
      required this.internalPort,
      required this.externalPort,
      required this.installedByDistribution,
      required this.pidFilePath});

  Future<Directory> getApplicationDirectory() async {
    Directory appDir = await getApplicationSupportDirectory();
    if (Platform.isWindows) {
      appDir = Directory('${appDir.path}\\$key');
    } else if (Platform.isMacOS) {
      appDir = Directory('${appDir.path}/$key');
    } else if (Platform.isLinux) {
      appDir = Directory('${appDir.path}/$key');
    }

    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  String? get executableName {
    if (Platform.isWindows) {
      return windowsExecutableName;
    } else if (Platform.isLinux) {
      return linuxExecutableName;
    } else if (Platform.isMacOS) {
      return macOsExecutableName;
    } else {
      throw Exception("Operating system not supported for this service.");
    }
  }

  String? get installationPath {
    if (Platform.isWindows) {
      return windowsInstallationPath;
    } else if (Platform.isLinux) {
      return linuxInstallationPath;
    } else if (Platform.isMacOS) {
      return macOsInstallationPath;
    } else {
      throw Exception("Operating system not supported for this service.");
    }
  }

  Future<bool> isInstalled() async {
    print("Is installed was called");
    final directory = await getApplicationDirectory();
    final defaultSystemProcessDirectory = path.join(directory.path, key);

    String executablePath;
    if (Platform.isWindows) {
      executablePath = windowsInstallationPath != null &&
              windowsInstallationPath!.isNotEmpty
          ? path.join(windowsInstallationPath!, windowsExecutableName!)
          : path.join(defaultSystemProcessDirectory, windowsExecutableName!);
    } else if (Platform.isLinux) {
      executablePath =
          linuxInstallationPath != null && linuxInstallationPath!.isNotEmpty
              ? path.join(linuxInstallationPath!, linuxExecutableName!)
              : path.join(defaultSystemProcessDirectory, linuxExecutableName!);
    } else if (Platform.isMacOS) {
      executablePath =
          macOsInstallationPath != null && macOsInstallationPath!.isNotEmpty
              ? path.join(macOsInstallationPath!, macOsExecutableName!)
              : path.join(defaultSystemProcessDirectory, macOsExecutableName!);
    } else {
      throw Exception("Operating system not supported for this service.");
    }
    print("Path to system process $executablePath");
    return File(executablePath).existsSync();
  }

  Future<bool> install() async {
    if (installedByDistribution) {
      throw Exception(
          "Installation is not supported where installed by distribution, you may try to upgrade.");
    }

    if (downloadUrl.toString().isNotEmpty ||
        (bundleAssetKey != null && bundleAssetKey!.isNotEmpty)) {
      String? specifiedInstallPath;
      if (Platform.isWindows) {
        if (windowsInstallationPath != null &&
            windowsInstallationPath!.isNotEmpty) {
          specifiedInstallPath = windowsInstallationPath;
        }
      } else if (Platform.isMacOS) {
        if (macOsInstallationPath != null &&
            macOsInstallationPath!.isNotEmpty) {
          specifiedInstallPath = macOsInstallationPath;
        }
      } else if (Platform.isLinux) {
        if (linuxInstallationPath != null &&
            linuxInstallationPath!.isNotEmpty) {
          specifiedInstallPath = linuxInstallationPath;
        }
      }

      final Directory installPath;
      if (specifiedInstallPath == null || specifiedInstallPath.isEmpty) {
        final directory = await getApplicationDirectory();
        final defaultInstallPath = path.join(directory.path, key);
        installPath = Directory(defaultInstallPath);
      } else {
        installPath = Directory(specifiedInstallPath);
      }

      final filePath = path.join(installPath.path, executableName!);

      // Check if the main executable already exists
      final file = File(filePath);
      if (file.existsSync()) {
        print('$displayName is already installed.');
        print('Main executable was found at $filePath');
        throw Exception("Already installed");
      } else {
        // Either download or extract from rootBundle
        if (downloadUrl.isScheme('HTTP') || downloadUrl.isScheme('HTTPS')) {
          // Handle file download (you need to implement this part)
          await _downloadAndExtractFile(downloadUrl, installPath);
        } else if (bundleAssetKey != null && bundleAssetKey!.isNotEmpty) {
          await _extractAssetBundle(bundleAssetKey!, installPath);
        }
      }
    } else {
      throw Exception("No source or remote file defined for install");
    }

    return true;
  }

  Future<void> _downloadAndExtractFile(
      Uri downloadUrl, Directory installPath) async {
    // Implement the download and extraction logic
  }

  Future<void> _extractAssetBundle(
      String assetKey, Directory installPath) async {
    ByteData byteData;
    try {
      byteData = await rootBundle.load(assetKey);
    } catch (e) {
      throw Exception(
          "Invalid bundle asset key supplied, the file could not be found. $e");
    }

    String? archiveType;
    if (assetKey.endsWith('.zip')) {
      archiveType = 'ZIP';
    } else if (assetKey.endsWith('.7z')) {
      throw Exception("The installer cannot support .7z files currently");
    } else if (assetKey.endsWith('.tar.gz')) {
      archiveType = 'TARGZ';
    }

    if (archiveType != null) {
      await _extractArchive(byteData, archiveType, installPath);
    } else {
      await _writeSingleFile(byteData, installPath, path.basename(assetKey));
    }
  }

  Future<void> _extractArchive(
      ByteData byteData, String archiveType, Directory installPath) async {
    if (archiveType == 'ZIP') {
      final archive = ZipDecoder().decodeBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      extractArchiveToDisk(archive, installPath.absolute.path);
    } else if (archiveType == 'TARGZ') {
      final tarBytes = GZipDecoder().decodeBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      final archive = TarDecoder().decodeBytes(tarBytes);
      extractArchiveToDisk(archive, installPath.absolute.path);
    } else {
      throw Exception("Unsupported archive type: $archiveType");
    }
  }

  Future<void> _writeSingleFile(
      ByteData byteData, Directory installPath, String fileName) async {
    final file = File(path.join(installPath.path, fileName));
    try {
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      print("Successfully installed ${file.absolute.path}");
    } catch (e) {
      print(
          "Failed to write a single binary file as bytes to the installation path ${file.absolute.path}");
      rethrow;
    }
  }

  Future<void> update() async {
    // #TODO
  }

  Future<Process?> start() async {
    print("$displayName service is starting...");
    final defaultApplicationDirectory = await getApplicationDirectory();
    final defaultSystemProcessDirectory = defaultApplicationDirectory.path;
    process = null;
    File pidFile;

    if (Platform.isWindows) {
      if (windowsInstallationPath != null &&
          windowsInstallationPath!.isNotEmpty &&
          windowsExecutableName != null) {
        processStartPath =
            path.join(windowsInstallationPath!, windowsExecutableName!);
        if (useInstallationPathAsWorkingDirectory) {
          process = await Process.start(processStartPath!, executionArgs!,
              mode: ProcessStartMode.detachedWithStdio,
              workingDirectory: windowsInstallationPath);
        } else {
          process = await Process.start(processStartPath!, executionArgs!,
              mode: ProcessStartMode.detachedWithStdio);
        }
        pidFile = File(path.join(windowsInstallationPath!, "$key.pid"));
        await pidFile.writeAsString(process!.pid.toString());
      } else {
        processStartPath =
            path.join(defaultSystemProcessDirectory, windowsExecutableName!);
        if (useInstallationPathAsWorkingDirectory) {
          process = await Process.start(processStartPath!, executionArgs!,
              mode: ProcessStartMode.detachedWithStdio,
              workingDirectory: defaultSystemProcessDirectory);
        } else {
          process = await Process.start(processStartPath!, executionArgs!,
              mode: ProcessStartMode.detachedWithStdio);
        }
        pidFile = File(path.join(defaultSystemProcessDirectory, "$key.pid"));
        await pidFile.writeAsString(process!.pid.toString());
      }
    } else if (Platform.isLinux) {
      if (linuxInstallationPath != null &&
          linuxInstallationPath!.isNotEmpty &&
          linuxExecutableName != null) {
        processStartPath =
            path.join(linuxInstallationPath!, linuxExecutableName!);
        if (useInstallationPathAsWorkingDirectory) {
          process = await Process.start(processStartPath!, executionArgs!,
              mode: ProcessStartMode.detachedWithStdio,
              workingDirectory: linuxInstallationPath);
        } else {
          process = await Process.start(processStartPath!, executionArgs!,
              mode: ProcessStartMode.detachedWithStdio);
        }
        pidFile = File(path.join(linuxInstallationPath!, "$key.pid"));
        await pidFile.writeAsString(process!.pid.toString());
      } else {
        processStartPath =
            path.join(defaultSystemProcessDirectory, linuxExecutableName!);
        if (useInstallationPathAsWorkingDirectory) {
          process = await Process.start(processStartPath!, executionArgs!,
              mode: ProcessStartMode.detachedWithStdio,
              workingDirectory: defaultSystemProcessDirectory);
        } else {
          process = await Process.start(processStartPath!, executionArgs!,
              mode: ProcessStartMode.detachedWithStdio);
        }
        pidFile = File(path.join(defaultSystemProcessDirectory, "$key.pid"));
        await pidFile.writeAsString(process!.pid.toString());
      }
    } else if (Platform.isMacOS) {
      if (macOsInstallationPath != null &&
          macOsInstallationPath!.isNotEmpty &&
          macOsExecutableName != null) {
        processStartPath =
            path.join(macOsInstallationPath!, macOsExecutableName!);
        if (useInstallationPathAsWorkingDirectory) {
          process = await Process.start(processStartPath!, executionArgs!,
              mode: ProcessStartMode.detachedWithStdio,
              workingDirectory: macOsInstallationPath);
        } else {
          process = await Process.start(processStartPath!, executionArgs!,
              mode: ProcessStartMode.detachedWithStdio);
        }
        pidFile = File(path.join(macOsInstallationPath!, "$key.pid"));
        await pidFile.writeAsString(process!.pid.toString());
      } else {
        processStartPath =
            path.join(defaultSystemProcessDirectory, macOsExecutableName!);
        if (useInstallationPathAsWorkingDirectory) {
          process = await Process.start(processStartPath!, executionArgs!,
              mode: ProcessStartMode.normal,
              workingDirectory: defaultSystemProcessDirectory);
        } else {
          process = await Process.start(processStartPath!, executionArgs!,
              mode: ProcessStartMode.normal);
        }
        pidFile = File(path.join(defaultSystemProcessDirectory, "$key.pid"));
        await pidFile.writeAsString(process!.pid.toString());
      }
    } else {
      throw Exception(
          "Operating system not supported for running this service, desktops only.");
    }
    if (process != null) {
      print(
          "The start script for $displayName was created with PID ${process?.pid.toString()} using command '$processStartPath ${executionArgs!.join(' ').trimRight()}'");
      return process;
    } else {
      print("The process for $displayName was not created");
      return null;
    }
  }
}
