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
import 'dart:io';

import 'package:socks5_proxy/socks_client.dart';

class HttpService {
  final HttpClient _client;

  HttpService({String proxyHost = '127.0.0.1', int proxyPort = 8118})
      : _client = HttpClient() {
    SocksTCPClient.assignToHttpClient(_client, [
      ProxySettings(InternetAddress(proxyHost), proxyPort),
    ]);
  }

  Future<HttpClientResponse> request(String method, String url,
      {Map<String, String>? headers, dynamic body}) async {
    final request = await _client.openUrl(method, Uri.parse(url));

    headers?.forEach((key, value) {
      request.headers.set(key, value);
    });

    if (body != null) {
      request.add(utf8.encode(json.encode(body)));
    }

    return await request.close();
  }

  void close() {
    _client.close();
  }
}
