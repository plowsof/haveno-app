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


import 'dart:convert';
import 'dart:math';
import '../services/http_service.dart';

class MoneroService {
  final List<String> nodes = [
    'http://xmr-node-uk.cakewallet.com:18081',
    'http://xmr-node.cakewallet.com:18081'
  ];

  final Random _random = Random();
  final HttpService _httpService;

  MoneroService({String proxyHost = '127.0.0.1', int proxyPort = 9050})
      : _httpService = HttpService(proxyHost: proxyHost, proxyPort: proxyPort);

  String _getRandomNode() {
    return nodes[_random.nextInt(nodes.length)];
  }

  Future<Map<String, dynamic>> getInfo() async {
    final node = _getRandomNode();
    final response = await _httpService.request(
      'GET',
      '$node/getinfo',
      headers: null,
      body: null,
    );

    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      return jsonDecode(responseBody);
    } else {
      throw Exception('Failed to communicate with node');
    }
  }

  void close() {
    _httpService.close();
  }
}
