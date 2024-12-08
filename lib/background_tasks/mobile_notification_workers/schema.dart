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

import 'package:haveno/haveno_client.dart';
import 'package:haveno_app/models/haveno_daemon_config.dart';
import 'package:haveno_app/services/connection_checker_service.dart';
import 'package:haveno_app/services/secure_storage_service.dart';
import 'package:haveno_app/services/local_notification_service.dart';
import 'package:haveno_app/utils/database_helper.dart';

abstract class AbstractMobileTask {
  late Duration minIntervalDuration;

  Future<void> run();
  Future<void> sendNotification({required int id, required String title, required String body});
  Future<void> updateState();
}

class MobileTask implements AbstractMobileTask {
  final SecureStorageService secureStorage = SecureStorageService();
  final HavenoChannel havenoChannel = HavenoChannel();
  late final DatabaseHelper db;
  HavenoDaemonConfig? havenoDaemonConfig;

  @override
  Duration minIntervalDuration;

  // Constructor with a default value for minIntervalDuration
  MobileTask({this.minIntervalDuration = const Duration(minutes: 5)}) {
    init();
  }

  // Common initialization logic
  Future<void> init() async {
    // Get remote daemon config
    havenoDaemonConfig = await secureStorage.readHavenoDaemonConfig();

    // Init database
    db = DatabaseHelper.instance;

    // Check if connected to Tor
    while (true) {
      try {
        if ((!await ConnectionCheckerService().isTorConnected())) {
          throw Exception("Not yet connected to Tor...");
        }
      } catch (e) {
        print(e.toString());
      }
      break;
    }
    while (true) {
      try {
        if ((!havenoChannel.isConnected)) {
          await havenoChannel.connect(
            havenoDaemonConfig!.host,
            havenoDaemonConfig!.port,
            havenoDaemonConfig!.clientAuthPassword,
          );
        }
      } catch (e) {
        print("Failed to connect to Haveno instance: $e");
      }
      break;
    }
  }

  @override
  Future<void> run() async {
    throw UnimplementedError("Subclasses should implement this method.");
  }

  @override
  Future<void> sendNotification({required int id, required String title, required String body}) async {
    // Default implementation of sendNotification
    LocalNotificationsService().showNotification(
      id: id,
      title: title,
      body: body,
    );
  }

  @override
  Future<void> updateState() async {
    // Default implementation of updateState
    // Can be overridden by subclasses if needed
  }
}
