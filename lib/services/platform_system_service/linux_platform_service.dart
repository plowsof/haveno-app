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


import 'dart:convert';
import 'dart:io';
import 'package:haveno_app/services/platform_system_service/schema.dart';
import 'package:haveno_app/services/secure_storage_service.dart';
import 'package:haveno_app/utils/kill.dart';
import 'package:haveno_app/utils/dependancy_helper.dart';
import 'package:haveno_app/versions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LinuxPlatformService implements PlatformService {
  final SecureStorageService secureStorageService = SecureStorageService();
  List<String> executionArgs = [
    '--baseCurrencyNetwork=XMR_MAINNET',
    '--useLocalhostForP2P=false',
    '--useDevPrivilegeKeys=false',
    '--nodePort=9999',
    '--apiPort=3201',
    '--appName=haveno_app_mainnet',
    '--useNativeXmrWallet=false',
    '--torControlHost=127.0.0.1',
    '--torControlPort=9077',
    '--torControlPassword=boner',
    '--seedNodes=5i6blbmuflq4s4im6zby26a7g22oef6kyp7vbwyru6oq5e36akzo3ayd.onion:2001,dx4ktxyiemjc354imehuaswbhqlidhy62b4ifzigk5p2rb37lxqbveqd.onion:2002'
  ];
  late Directory? applicationSupportDirectory;
  late File? torBinaryFile;
  late File? javaBinaryFile;
  late File? havenoJarFile;
  late String? daemonPassword;
  late String moneroWalletDir;
  Process? torDaemonProcess;
  Process? havenoDaemonProcess;
  List<Process>? allProcesses = [];

  @override
  Future<void> init() async {
    applicationSupportDirectory = await getApplicationSupportDirectory();
    //daemonPassword = await secureStorageService.readHavenoDaemonPassword();
    await checkShouldDownloadTor('Tor');
    await checkShouldDownloadJava('Java');
    await checkShouldDownloadHavenoDaemon('Haveno Daemon');
    await checkShouldDownloadMonero('Haveno Daemon/data');
    torBinaryFile = await _getTorBinaryFile();
    javaBinaryFile = await _getJavaBinaryFile();
    havenoJarFile = await _getHavenoDaemonJarFile();
    moneroWalletDir = await _getMoneroWalletDir();
    _killProcesses();
  }

  @override
  Future<bool> setupTorDaemon() async {
    torDaemonProcess = await _startTorService();
    if (torDaemonProcess != null) {
      allProcesses?.add(torDaemonProcess!);
      await _updateStoredPids();

      // Monitor STDOUT
      torDaemonProcess!.stdout.transform(utf8.decoder).listen((data) {
        if (data.contains("Bootstrapped 100% (done)")) {
          print('Tor stdout: $data');
        }
        print('Tor stdout: $data');
      });

      // Monitor STDERR
      torDaemonProcess!.stderr.transform(utf8.decoder).listen((data) {
        print('Proc(Tor): $data');
      });

      return true;
    }
    return false;
  }

  @override
  Future<bool> setupHavenoDaemon(String? password) async {
    daemonPassword = password;

    await _startHavenoService();

    if (havenoDaemonProcess != null) {
      allProcesses?.add(torDaemonProcess!);
      await _updateStoredPids();
      havenoDaemonProcess!.stdout.transform(utf8.decoder).listen((data) {
        print('Haveno Daemon stdout: $data');
      });

      havenoDaemonProcess!.stderr.transform(utf8.decoder).listen((data) {
        print('Haveno Daemon stderr: $data');
      });

      return true;
    }
    return false;
  }

  Future<void> _killProcesses() async {
    try {
      // Kill existing PIDs for the same process
      List<int> pids = await secureStorageService.readPids();
      killPids(pids);
    } catch (e) {
      print("No processes to kill, probable already dead...");
    }
  }

  Future<void> _updateStoredPids() async {
    List<int> pids = allProcesses!.map((process) => process.pid).toList();
    await secureStorageService.writePids(pids);
  }

  Future<File?> _getHavenoDaemonJarFile() async {
    Directory appSupportDirectory = await getApplicationSupportDirectory();
    String havenoJarFile =
        path.join(appSupportDirectory.path, 'Haveno Daemon', 'daemon-all.jar');
    File file = File(havenoJarFile);
    print("Haveno Jar: ${file.path}");
    return await file.exists() ? file : null;
  }

  Future<String> _getMoneroWalletDir() async {
    Directory appSupportDirectory = await getApplicationSupportDirectory();
    moneroWalletDir = path.join(appSupportDirectory.path, 'Monero Wallet RPC', 'wallets');
    print("Monero Wallet Dir: $moneroWalletDir");
    return moneroWalletDir;
  }

  Future<File?> _getJavaBinaryFile() async {
    File javaBinaryFile = File(path.join(applicationSupportDirectory!.path,
        'Java', '21.0.4+7', 'bin', 'java'));
    print("Java Binary: ${javaBinaryFile.path}");
    return await javaBinaryFile.exists() ? javaBinaryFile : null;
  }

  Future<File?> _getTorBinaryFile() async {
    File torBinary =
        File(path.join(applicationSupportDirectory!.path, 'Tor', Versions().getVersion('tor'), 'tor'));
    print("Tor Binary: ${torBinary.path}");
    return torBinary;
  }

  Future<Process> _startHavenoService() async {
    if (daemonPassword != null) {
      executionArgs.add('--apiPassword=$daemonPassword');
    }
    String havenoAppDirectory =
        path.join(applicationSupportDirectory!.path, 'Haveno Daemon', 'data');
    executionArgs.add('--appDataDir=$havenoAppDirectory');

    Map<String, String> environment = {
      'JAVA_HOME': path.join(applicationSupportDirectory!.path, 'Java',
          '21.0.4+7')
    };

    return await Process.start(
      javaBinaryFile!.path,
      ['-jar', havenoJarFile!.path, ...executionArgs],
      mode: ProcessStartMode.normal,
      workingDirectory:
          path.join(applicationSupportDirectory!.path, 'Haveno Daemon'),
      environment: environment,
    );
  }

  Future<Process> _startTorService() async {
    return await Process.start(
      torBinaryFile!.path,
      ['-f', '../torrc'],
      mode: ProcessStartMode.normal,
      workingDirectory: path.join(applicationSupportDirectory!.path, 'Tor', Versions().getVersion("tor")),
      //environment: environment,
    );
  }
}
