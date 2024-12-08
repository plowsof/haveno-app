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
import 'package:haveno/grpc_models.dart';
import 'package:haveno/haveno_client.dart';
import 'package:haveno_app/models/haveno_daemon_config.dart';
import 'package:haveno_app/services/platform_system_service/schema.dart';
import 'package:haveno_app/services/secure_storage_service.dart';
import 'package:haveno_app/services/security.dart';

class MobileManagerService {
  final SecureStorageService secureStorageService = SecureStorageService();
  final HavenoChannel havenoChannel = HavenoChannel();
  HavenoDaemonConfig? _remoteHavenoDaemonNodeConfig;
  bool _hasHavenoDaemonNodeConfig = false;
  late PlatformService platformService;

  MobileManagerService();

  Future<HavenoDaemonConfig?> getRemoteHavenoDaemonNode() async {
    try {
      _remoteHavenoDaemonNodeConfig = await secureStorageService.readHavenoDaemonConfig();
      return _remoteHavenoDaemonNodeConfig;
    } catch (e) {
      print("Failed to read Haveno Daemon config: $e");
      return null;
    }
  }

  Future<HavenoDaemonConfig?> setHavenoDaemonNodeConfig(Uri onionUri) async {
    HavenoDaemonConfig havenoDaemonConfig = HavenoDaemonConfig(fullUri: onionUri);
    print(jsonEncode(havenoDaemonConfig.toJson()));
    try {
      havenoChannel.connect(havenoDaemonConfig.host, havenoDaemonConfig.port, havenoDaemonConfig.clientAuthPassword);
    } catch (e) {
      print("Couldn't connect to the URI provided ${e.toString()}");
      return null;
    }
    try {
      await havenoChannel.versionClient?.getVersion(GetVersionRequest());
      havenoDaemonConfig.setVerified(true);
    } catch (e) {
      print('Error fetching version ${e.toString()}');
      return null;
    }
    try {
      await secureStorageService.writeHavenoDaemonConfig(havenoDaemonConfig);
      _hasHavenoDaemonNodeConfig = true;
      return havenoDaemonConfig;
    } catch (e) {
      print("Couldn't set the new haveno daemon config: $e");
      rethrow;
    }
  }

  Future<bool> logout() async {
    try {
      await SecurityService().resetAppData();
      _hasHavenoDaemonNodeConfig = false;
      return true;
    } catch (e) {
      print("Failed to logout: $e");
      _hasHavenoDaemonNodeConfig = false;
      return false;
    }
  }

}
