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
import 'package:haveno_app/utils/file_utils.dart';
import 'package:tray_manager/tray_manager.dart';

Future<void> intializeSystemTray() async {
  final trayManager = TrayManager.instance;
  await trayManager.setIcon(
    (Platform.isWindows
      ? await extractAssetToTemp('assets/icon/app_icon.ico')
      : await extractAssetToTemp('assets/icon/app_icon.png'))
  );
  Menu menu = Menu(
    items: [
      MenuItem(
        key: 'tor_status',
        label: 'Tor Daemon',
        sublabel: 'Running'
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'haveno_daemon',
        label: 'Haveno Daemon',
        sublabel: 'Running'
      ),
    ],
  );
  await trayManager.setContextMenu(menu);
}