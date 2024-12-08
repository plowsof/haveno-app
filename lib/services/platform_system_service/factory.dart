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
import 'package:haveno_app/services/platform_system_service/android_platform_service.dart';
import 'package:haveno_app/services/platform_system_service/linux_platform_service.dart';
import 'package:haveno_app/services/platform_system_service/schema.dart';

Future<PlatformService> getPlatformService() async {
  
  late PlatformService platformService;
  
  if (Platform.isAndroid) {
    platformService = AndroidPlatformService();
  } else if (Platform.isLinux) {
    platformService = LinuxPlatformService();
  } else {
    throw UnsupportedError('Unsupported platform');
  }

  await platformService.init(); // Ensure init is called
  return platformService;
}
