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

class TorSystemProcess extends SystemProcess {
  TorSystemProcess()
      : super(
          key: 'Tor',
          displayName: 'Tor Daemon',
          bundleAssetKey: '', // Specify the correct asset path here
          windowsInstallationPath: '',  // Define specific installation paths if required
          linuxInstallationPath: '',    // Define specific installation paths if required
          macOsInstallationPath: '',    // Define specific installation paths if required
          useInstallationPathAsWorkingDirectory: true,  // Assuming the working directory should be the installation path
          windowsExecutableName: 'tor.exe',
          linuxExecutableName: 'tor',
          macOsExecutableName: 'tor',
          startOnLaunch: true,
          versionMinor: '0.17.1.9',
          versionMajor: '0.17',
          executionArgs: ['-f', 'torrc'],
          downloadUrl: Uri.parse(''),  // Specify the download URL if required
          runAsDaemon: true,
          internalPort: 9050,
          externalPort: null,
          installedByDistribution: true,
          pidFilePath: 'tor.pid'
        );
}