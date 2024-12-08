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
import 'package:haveno/haveno_client.dart';
import 'package:haveno_app/models/haveno/p2p/haveno_seednode.dart';
import 'package:haveno_app/services/platform_system_service/schema.dart';
import 'package:haveno_app/services/secure_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class DesktopManagerService {
  final SecureStorageService secureStorageService = SecureStorageService();
  final HavenoChannel havenoService = HavenoChannel();
  Uri? _desktopDaemonNodeUri;
  late PlatformService platformService;
  late String daemonPassword;

  DesktopManagerService();

  Future<Uri?> getDesktopDaemonNodeUri() async {
    String? daemonPassword =
        await secureStorageService.readHavenoDaemonPassword();
    try {
      Directory applicationSupportDirectory =
          await getApplicationSupportDirectory();
      String torPath = path.join(applicationSupportDirectory.path, 'Tor',
          'daemon_service', 'hostname');
      File hiddenServiceHostnameFile = File(torPath);
      if (await hiddenServiceHostnameFile.exists()) {
        List<String> hostnameFileLines =
            await hiddenServiceHostnameFile.readAsLines();
        String? hostname = hostnameFileLines.first;
        _desktopDaemonNodeUri = Uri.parse(hostname);

        if (daemonPassword != null && daemonPassword.isNotEmpty) {
          _desktopDaemonNodeUri =
              _desktopDaemonNodeUri!.replace(queryParameters: {
            ..._desktopDaemonNodeUri!.queryParameters,
            'password': daemonPassword,
          });
        }

        return _desktopDaemonNodeUri;
      } else {
        return null;
      }
    } catch (e) {
      print("Error getting daemon node address: $e");
      return null;
    }
  }

  Future<bool?> isSeednodeConfigured() async {
    List<HavenoSeedNode> storedSeedNodes = await secureStorageService.readHavenoSeedNodes();
    if (storedSeedNodes.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> setInitialSeednode(HavenoSeedNode seedNode) async {
      await secureStorageService.writeHavenoSeedNodes([seedNode]);
  }

}
