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

class SystemdManager {
  final String serviceName;

  SystemdManager({required this.serviceName});

  /// Starts the service with optional environment variables.
  Future<void> startService({Map<String, String>? environment}) async {
    await _runSystemctlCommand('start', environment: environment);
  }

  /// Stops the service.
  Future<void> stopService() async {
    await _runSystemctlCommand('stop');
  }

  /// Restarts the service with optional environment variables.
  Future<void> restartService({Map<String, String>? environment}) async {
    await _runSystemctlCommand('restart', environment: environment);
  }

  /// Checks the status of the service.
  Future<void> statusService() async {
    await _runSystemctlCommand('status');
  }

  /// Runs a systemctl command for the service with optional environment variables.
  Future<void> _runSystemctlCommand(String command, {Map<String, String>? environment}) async {
    final result = await Process.run(
      'systemctl',
      ['--user', command, serviceName],
      environment: environment,
    );

    if (result.exitCode == 0) {
      print('Service $serviceName $command successfully.');
    } else {
      print('Failed to $command $serviceName: ${result.stderr}');
    }
  }
}