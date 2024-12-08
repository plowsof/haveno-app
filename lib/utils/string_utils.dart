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


String convertCamelCaseToSnakeCase(String input) {
  // Use a regular expression to find capital letters
  final RegExp exp = RegExp(r'(?<!^)([A-Z])');

  // Replace capital letters with _ followed by the lowercase equivalent
  String snakeCase = input.replaceAllMapped(exp, (Match match) => '_${match.group(0)}');

  // Convert the final string to uppercase
  return snakeCase.toUpperCase();
}


Map<String, String?> parseNodeUrl(String url) {
  String? host;
  String? port;
  bool hasPort = false;

  // Check if the URL contains an .onion address
  if (url.contains('.onion')) {
    // If it's an .onion link, handle manually since Uri.parse won't work for .onion
    if (url.contains('https://') || url.contains('http://')) {
      // Strip the protocol
      var hostnameAndBeyond = url.split('://').last;
      hasPort = hostnameAndBeyond.contains(':'); // Check if there is a port

      if (hasPort) {
        // Separate host and port
        host = hostnameAndBeyond.split(':').first;
        port = hostnameAndBeyond.split(':').last;
      } else {
        host = hostnameAndBeyond;
        port = null;
      }
    } else if (url.endsWith('.onion')) {
      // If the onion address does not have a protocol, treat the whole thing as the host
      host = url;
      port = null; // Default port can be set later if needed
    }
  } else {
    // For regular domains and IPs, we can rely on Uri.parse
    try {
      final uri = Uri.parse(url);
      host = uri.host.isNotEmpty ? uri.host : null;

      if (uri.hasPort) {
        port = uri.port.toString();
      } else {
        port = null;
      }
    } catch (e) {
      // In case of any parsing errors, log or handle accordingly
      print('Invalid URL format: $url');
      return {
        'host': null,
        'port': null,
      };
    }
  }

  // Set default port if not provided
  //port ??= '18081'; // Default port for Monero nodes

  return {
    'host': host,
    'port': port,
  };
}
