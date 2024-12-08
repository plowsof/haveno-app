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


class HavenoDaemonConfig {
  final String host;
  final int port;
  final String clientAuthPassword;
  final Uri fullUri;
  bool isVerified; // Has had at least one successful GRPC call

  HavenoDaemonConfig({
    required this.fullUri,
    String? clientAuthPassword,
  })  : clientAuthPassword = clientAuthPassword ?? _parsePassword(fullUri),
        host = _parseHost(fullUri),
        port = _parsePort(fullUri),
        isVerified = false {
    _validateOnionAddress(fullUri);
  }

  static String _parseHost(Uri uri) {
    return uri.host;
  }

  static int _parsePort(Uri uri) {
    return uri.hasPort ? uri.port : 80;
  }

  static String _parsePassword(Uri uri) {
    final password = uri.queryParameters['password'];
    if (password == null) {
      throw const FormatException('Missing password query parameter');
    }
    return password;
  }

  static void _validateOnionAddress(Uri uri) {
    final pattern = RegExp(r'^[a-zA-Z0-9]{56}\.onion$');
    if (!pattern.hasMatch(uri.host)) {
      throw const FormatException('Invalid v3 onion address');
    }
  }

  void setVerified(bool verified) {
    isVerified = verified;
  }

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'fullUri': fullUri.toString(),
      'clientAuthPassword': clientAuthPassword,
      'isVerified': isVerified
    };
  }

  factory HavenoDaemonConfig.fromJson(Map<String, dynamic> json) {
    return HavenoDaemonConfig(
      fullUri: Uri.parse(json['fullUri']),
      clientAuthPassword: json['clientAuthPassword'],
    );
  }
}