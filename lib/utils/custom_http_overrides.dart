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

class MyHttpOverrides extends HttpOverrides {

  MyHttpOverrides();

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    HttpClient client = super.createHttpClient(context);
    client.findProxy = (Uri uri) {
      // Add your local network IP ranges here
      if (uri.host.startsWith('192.168.') ||
          uri.host.startsWith('10.') ||
          uri.host.startsWith('172.16.') ||
          uri.host.startsWith('172.17.') ||
          uri.host.startsWith('172.18.') ||
          uri.host.startsWith('172.19.') ||
          uri.host.startsWith('172.20.') ||
          uri.host.startsWith('172.21.') ||
          uri.host.startsWith('172.22.') ||
          uri.host.startsWith('172.23.') ||
          uri.host.startsWith('172.24.') ||
          uri.host.startsWith('172.25.') ||
          uri.host.startsWith('172.26.') ||
          uri.host.startsWith('172.27.') ||
          uri.host.startsWith('172.28.') ||
          uri.host.startsWith('172.29.') ||
          uri.host.startsWith('172.30.') ||
          uri.host.startsWith('172.31.')) {
        return 'DIRECT';
      }
      return "PROXY 127.0.0.1:8118";
    };
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  }
}
