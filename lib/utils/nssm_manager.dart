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

class NSSMServiceManager {
  final String nssmPath;

  NSSMServiceManager(this.nssmPath);

  String get quotedNssmPath => '"$nssmPath"';

  Future<void> setServiceParameters(
      String serviceName, List<String> args) async {
    var arguments = [
      'set',
      serviceName,
      'AppParameters',
      args.join(' '),
    ];
    var result = await Process.run(quotedNssmPath, arguments);

    print("Ran command: $quotedNssmPath ${arguments.join(" ")}");
    print(result.stdout);
    print(result.stderr);
  }

  Future<void> serviceStart(String serviceName) async {
    print("Path: $quotedNssmPath");
    final ProcessResult result =
        await Process.run(quotedNssmPath, ['start', serviceName]);

    print(result.stdout);
    print(result.stderr);
  }

  Future<void> serviceStop(String serviceName) async {
    final ProcessResult result =
        await Process.run(quotedNssmPath, ['stop', serviceName]);

    print(result.stdout);
    print(result.stderr);
  }

  Future<void> serviceRestart(String serviceName) async {
    final ProcessResult result =
        await Process.run(quotedNssmPath, ['restart', serviceName]);
    print(result.stdout);
    print(result.stderr);
  }

  Future<void> serviceStatus(String serviceName) async {
    final ProcessResult result =
        await Process.run(quotedNssmPath, ['status', serviceName]);
    print(result.stdout);
    print(result.stderr);
  }
}
