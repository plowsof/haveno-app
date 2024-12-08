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

import 'base_system_process.dart';

class JavaSystemProcess extends SystemProcess {
  JavaSystemProcess()
      : super(
          key: 'Java',
          displayName: 'Java',
          bundleAssetKey: null,
          windowsInstallationPath: '',
          linuxInstallationPath: '',
          macOsInstallationPath: '',
          useInstallationPathAsWorkingDirectory: false,
          windowsExecutableName: 'java.exe',
          linuxExecutableName: 'java',
          macOsExecutableName: 'java',
          startOnLaunch: false,
          versionMinor: '21.0.4+7',
          versionMajor: '21',
          executionArgs: [''],
          downloadUrl: Uri.parse(''), // Add the appropriate download URL if needed
          runAsDaemon: false,
          internalPort: null,
          externalPort: null,
          installedByDistribution: true,
          pidFilePath: null
        );
}