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

class TorDaemonConfig {
  final String host;
  final int controlPort;
  final List<int> socks5ProxyPorts;
  final List<int> httpProxyPorts;
  final String? hashedPassword;

  TorDaemonConfig({
    required this.host,
    required this.controlPort,
    this.socks5ProxyPorts = const [9050],
    this.httpProxyPorts = const [8118],
    this.hashedPassword,
  }) {
    _validateOnionAddress(host);
  }

  static void _validateOnionAddress(String host) {
    print(host);
    final pattern = RegExp(r'^[a-zA-Z0-9]{56}\.onion$');
    if (!pattern.hasMatch(host)) {
      throw const FormatException('Invalid v3 onion address');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'controlPort': controlPort,
      'socks5ProxyPorts': socks5ProxyPorts,
      'httpProxyPorts': httpProxyPorts,
      'hashedPassword': hashedPassword,
    };
  }

  factory TorDaemonConfig.fromJson(Map<String, dynamic> json) {
    return TorDaemonConfig(
      host: json['host'],
      controlPort: json['controlPort'],
      socks5ProxyPorts: List<int>.from(json['socks5ProxyPorts'] ?? [9050]),
      httpProxyPorts: List<int>.from(json['httpProxyPorts'] ?? [8118]),
      hashedPassword: json['hashedPassword'],
    );
  }

  factory TorDaemonConfig.getDefault() {
    return TorDaemonConfig(
      host: '127.0.0.1',
      controlPort: 9051,
      socks5ProxyPorts: [9050],
      httpProxyPorts: [8118],
    );
  }
}