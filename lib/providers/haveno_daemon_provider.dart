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
import 'package:flutter/material.dart';
import 'package:haveno_app/models/haveno_daemon_config.dart';
import 'package:haveno_app/services/secure_storage_service.dart';


class HavenoDaemonProvider with ChangeNotifier {
  final SecureStorageService _secureStorageService;
  
  HavenoDaemonConfig? _currentDaemon;
  // Getters
  HavenoDaemonConfig? get currentDaemon => _currentDaemon;
  bool get isPaired => _currentDaemon!.isVerified && _currentDaemon?.host != null;

  HavenoDaemonProvider(this._secureStorageService) {
    _initializeSettings();
  }

  get lastPing => null;

  Future<void> _initializeSettings() async {
    _currentDaemon = await _secureStorageService.readHavenoDaemonConfig();
    notifyListeners();
  }

  // Returns how many seconds ago the last ping to Haveno Daemon was
  Future<int?> ping() async {
    if (_currentDaemon != null) {
      try {
        var httpClient = HttpClient();
        var request = await httpClient.headUrl(Uri.http('${_currentDaemon!.host}:${_currentDaemon!.port}', '/'));
        var response = await request.close();
        httpClient.close();

        if (response.statusCode == HttpStatus.ok) {
          // If the response status is OK, the server is available
          _currentDaemon!.setVerified(true);
          _secureStorageService.writeHavenoDaemonConfig(_currentDaemon!);
          return DateTime.now().millisecondsSinceEpoch ~/ 1000;
        } else {
          // Handle non-OK response statuses if necessary
          return null;
        }
      } on SocketException catch (e) {
        // Handle socket exceptions (e.g., server not available)
        print('SocketException: $e');
        return null;
      } on HttpException catch (e) {
        // Handle HTTP exceptions
        print('HttpException: $e');
        return null;
      } catch (e) {
        // Handle any other exceptions
        print('Exception: $e');
        return null;
      }
    }
    return null;
  }

}
