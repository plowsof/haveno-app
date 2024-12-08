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

import 'dart:io';
import 'package:haveno_app/utils/nssm_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'base_system_process.dart';

class HavenoDaemonSystemProcess extends SystemProcess {
  final String? password;

  HavenoDaemonSystemProcess({this.password})
      : super(
            key: 'Haveno Daemon',
            displayName: 'Haveno Daemon',
            bundleAssetKey: '', // Specify the correct asset path here
            windowsInstallationPath:
                '', // Define specific installation paths if required
            linuxInstallationPath:
                '', // Define specific installation paths if required
            macOsInstallationPath:
                '', // Define specific installation paths if required
            useInstallationPathAsWorkingDirectory: true,
            windowsExecutableName: 'daemon-all.jar',
            linuxExecutableName: 'daemon-all.jar',
            macOsExecutableName: 'daemon-all.jar',
            startOnLaunch: true,
            versionMinor: '0.17.1.9',
            versionMajor: '0.17',
            executionArgs: [
              '--baseCurrencyNetwork=XMR_STAGENET',
              '--useLocalhostForP2P=false',
              '--useDevPrivilegeKeys=false',
              '--nodePort=9999',
              '--apiPort=3201',
              '--appName=haveno_app_stagenet',
              '--useNativeXmrWallet=false',
              '--torControlHost=127.0.0.1',
              '--torControlPort=9077',
              '--torControlPassword=boner',
              '--appDataDir=data/'
            ],
            downloadUrl: Uri.parse(''), // Specify the download URL if required
            runAsDaemon: true,
            internalPort: 9050,
            externalPort: null,
            installedByDistribution: false,
            pidFilePath: null) {
    if (password != null && password!.isNotEmpty) {
      executionArgs!.add('--apiPassword=$password');
      //executionArgs!.add('--passwordRequired=true');
    } else {
      //executionArgs!.add('--passwordRequired=false');
    }
  }

  @override
  Future<Process?> start() async {
    print("$displayName service is starting...");
    final defaultApplicationDirectory = await getApplicationDirectory();
    final defaultSystemProcessDirectory = defaultApplicationDirectory.path;
    process = null;
    File? javaBinaryFile = await getJavaBinaryDirectory();
    File? havenoDaemonJarFile = await getHavenoDaemonJarFile();

    if (javaBinaryFile == null) {
      print("The java binary file was not found, cannot start the daemon");
      return null;
    }
    if (havenoDaemonJarFile == null) {
      print(
          "The haveno daemon file was not found, cannot start the daemon.");
      return null;
    }

    // Get the paths
    String javaPath = javaBinaryFile.path;
    String jarPath = havenoDaemonJarFile.path;

    Map<String, String> environment = {
      'JAVA_HOME': path.dirname(path.dirname(javaPath)),
      'PATH': Platform.environment['PATH'] ?? '',
    };

    if (Platform.isWindows) {
      Directory appSupportDirectory = await getApplicationSupportDirectory();

      String nssmPath = path.join(appSupportDirectory.path, 'nssm.exe');

      print("We are trying to load NSSM from: $nssmPath");

      var nssmManager = NSSMServiceManager(nssmPath);
      try {
        await nssmManager.setServiceParameters('HavenoPlusDaemonService',
            ['-jar', '"$jarPath"', ...executionArgs!]);
        print("Set service parameters for HavenoPlusDaemonService");
        await Future.delayed(Duration(seconds: 2));
        await nssmManager.serviceStop('HavenoPlusDaemonService');
        // Wait 5 seconds
        await Future.delayed(Duration(seconds: 2)); // Added wait period
        await nssmManager.serviceStart('HavenoPlusDaemonService');
        print("Restarted HavenoPlusDaemonService");
      } catch (e) {
        print("Error setting service parameters or restarting: $e");
      }
      return null;
    }

    if (Platform.isLinux) {
      process = await Process.start(
        javaPath,
        ['-jar', jarPath, ...executionArgs!],
        mode: ProcessStartMode.normal,
        environment: environment,
      );
    } else if (Platform.isMacOS) {
      process = await Process.start(
        javaPath,
        ['-jar', jarPath, ...executionArgs!],
        mode: ProcessStartMode.normal,
        workingDirectory: defaultSystemProcessDirectory,
        environment: environment,
      );
    }
    return process;
  }

  Future<void> stop() async {
    if (Platform.isWindows) {
      Directory appSupportDirectory = await getApplicationSupportDirectory();
      String nssmPath = path.join(appSupportDirectory.path, 'nssm.exe');
      await NSSMServiceManager(nssmPath).serviceStop('HavenoPlusDaemonService');
    }
  }

  Future<File?> getJavaBinaryDirectory() async {
    Directory appSupportDirectory = await getApplicationSupportDirectory();
    File javaBinaryFile;

    if (Platform.isWindows) {
      javaBinaryFile = File(path.join(
          appSupportDirectory.path, 'Java', 'jdk-21.0.4', 'bin', 'java.exe'));
    } else if (Platform.isMacOS) {
      javaBinaryFile = File(path.join(appSupportDirectory.path, 'Java',
          '21.0.4+7', 'Contents', 'Home', 'bin', 'java'));
    } else if (Platform.isLinux) {
      return null;
    } else {
      return null;
    }

    return await javaBinaryFile.exists() ? javaBinaryFile : null;
  }

  Future<File?> getHavenoDaemonJarFile() async {
    Directory havenoHomeDirectory = await getApplicationDirectory();
    String havenoJarFile = path.join(havenoHomeDirectory.path, executableName);
    File file = File(havenoJarFile);
    return await file.exists() ? file : null;
  }
}
