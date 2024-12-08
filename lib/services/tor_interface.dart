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


import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';
import 'package:haveno_app/models/tor/tor_daemon_config.dart';
import 'package:haveno_app/models/tor/hsv3_onion_config.dart';
// import 'package:haveno_app/services/tor/tor_status_service.dart';
import 'package:http/io_client.dart';
//import 'package:tor/socks_socket.dart';

class TorService {
  final StreamController<String> _statusController = StreamController<String>.broadcast();
  final StreamController<String> _controlPortStatusController = StreamController<String>.broadcast();
  late final TorDaemonConfig _torDaemonConfig;

  Stream<String> get statusStream => _statusController.stream;
  Stream<String> get controlPortStatusStream => _controlPortStatusController.stream;

  TorService();

  static Future<bool> isTorConnected() async {
    //final torStatusService = TorStatusService();
    int socksPort = 9066;
    bool socks5Open = false;
    bool i2pOpen = false;
    //if (Platform.isAndroid || Platform.isIOS) {
    //  if (torStatusService.torPort == null) {
    //    return false;
    //  } else {
    //    socksPort = torStatusService.torPort!;
    //  }
    //}

    try {
      if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
        socksPort = 9066; // Example port, adjust as needed
        socks5Open = await checkSocks5Proxy(testHost: '127.0.0.1', testPort: socksPort);
        if (!socks5Open) {
          print("SOCKS5 proxy port $socksPort is not open at 127.0.0.1 (It should be, start the daemon...)");
          return false; // If the SOCKS5 proxy port is closed, return false
        } else {
          print("The socks5 port is open at $socksPort");
          return await checkTorViaApiStandardBinary();
        }
      } else if (Platform.isAndroid) {
        socks5Open = await checkSocks5Proxy(testHost: '127.0.0.1', testPort: 9050);
        i2pOpen = await checkI2pTunnel();
        if (!socks5Open && !i2pOpen) {
          return false;
        } else {
          print("I2P: $i2pOpen TOR: $socks5Open");
          if (i2pOpen) {
            return true;
          }
        }
      } else if (Platform.isIOS) {
        // Skip the SOCKS5 proxy check since we don't know the port, proceed directly to checking Tor connection via .onion
        // We can find the port using OrbotKit implementation later
        return await checkTorOnionLink();
      }
    } catch (e) {
      print("Error when Tor via both Onion and Clearnet links: $e");
      return false;
    }

    // If the SOCKS5 port is open, proceed with the actual request
    try {
      return await checkTorViaApiStandardBinary();
    } catch (e) {
      print("Error during the Tor connection check: $e");
      return false;
    }
  }


  // Function to check Tor connection via .onion link on iOS
  static Future<bool> checkTorOnionLink() async {
    final httpClient = HttpClient();
    try {
      final request = await httpClient.headUrl(Uri.parse('http://2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion/robots.txt'));
      final response = await request.close();
      
      return response.statusCode == 200;
    } catch (e) {
      print("Error during .onion connection check: $e");
      try {
        print('Attempting to check Tor connection via non-onion URL');
        final request = await httpClient.headUrl(Uri.parse('https://check.torproject.org/api/ip'));
        final response = await request.close();
        
        return response.statusCode == 200;    
      } catch (e) {
        throw Exception('No connection to tor what soever, even through clearnet link');
      }
    }
  }

  // Function to check Tor connection via Tor Project API
  // Make a proxied HTTP request using IOClient
  static Future<bool> checkTorViaApiStandardBinary() async {
    // Wrap the HttpClient in an IOClient for modern HTTP API
    final ioClient = IOClient(createTorHttpClient());

    try {
      // Perform the HTTP GET request
      final response = await ioClient.get(Uri.parse('https://check.torproject.org/api/ip'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Response from Tor website: $data");
        return data['IsTor'] == true; // Return true if IsTor is true
      } else {
        return false; // Return false if the API didn't return 200 OK
      }
    } catch (e) {
      print("Error during Tor Project API check: $e");
      return false;
    } finally {
      ioClient.close(); // Always close the client
    }
  }

  static Future<bool> checkI2pTunnel({String testHost = '127.0.0.1', int? testPort}) async {
    try {
      final socket = await Socket.connect(testHost, testPort ?? 3201, timeout: const Duration(seconds: 7));
      socket.destroy(); // Close the socket as soon as the connection is established
      return true; // If connected, the SOCKS5 proxy is available
    } catch (e) {
      print("Error connecting to an I2P tunnel: $e");
      return false; // Connection failed, proxy is not available
    }
  }

/*   static Future<bool> checkTorViaApiWithRustSocks5() async {
   final torStatusService = TorStatusService();
    if (torStatusService.torPort == null) {
      print("Tor port is not available.");
      return false;
    }

    try {
      // Step 1: Create and connect to SOCKSSocket with SSL enabled
      final socksSocket = await SOCKSSocket.create(
        proxyHost: InternetAddress.loopbackIPv4.address,
        proxyPort: torStatusService.torPort!,
        sslEnabled: true, // Enable SSL for secure communication
      );

      // Connect to the Tor Project API through the SOCKS5 proxy
      await socksSocket.connect();
      await socksSocket.connectTo('check.torproject.org', 443); // HTTPS port

      // Step 2: Send the HTTPS request manually
      const request = 'GET /api/ip HTTP/1.1\r\n'
          'Host: check.torproject.org\r\n'
          'Connection: close\r\n\r\n';
      socksSocket.write(request);

      // Step 3: Collect the entire response
      StringBuffer responseBuffer = StringBuffer();
      await for (var data in socksSocket.responseController.stream) {
        responseBuffer.write(utf8.decode(data));
      }

      // Step 4: Extract and debug the response
      final responseString = responseBuffer.toString();
      print('Full response from Tor Project API: $responseString');

      // Step 5: Split the response into headers and body
      final responseParts = responseString.split('\r\n\r\n');
      if (responseParts.length < 2) {
        print('Invalid response format');
        return false;
      }

      final body = responseParts[1]; // Extract the body (JSON content)
      print('Extracted body: $body');

      // Step 6: Parse the JSON body and check the IsTor field
      final data = jsonDecode(body);
      print('Parsed JSON: $data');

      // Step 7: Close the SOCKSSocket
      if (data['IsTor'] == true) {
        socksSocket.close();
        print("Tor is 100% connected.");
        return true;
      } else {
        socksSocket.close();
        print("IsTor contained ${data['IsTor']} and failed!");
        return false;
      }
    } catch (e) {
      print("Error during Tor Project API check: $e");
      return false;
    }
  } */


  Future<HSV3OnionConfig?> createHiddenServiceV3KeyPair(String identifier) async {
    try {
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
      final publicKey = await keyPair.extractPublicKey();
      return HSV3OnionConfig(
          privateKeyBytes: privateKeyBytes,
          publicKey: publicKey,
          internalPort: 3201,
          externalPort: 45256);
    } catch (e) {
      print("Failed to create Hidden Service key pair: $e");
      return null;
    }
  }

  Future<bool> publishOnionViaControlPort(HSV3OnionConfig onionConfig) async {
    try {
      final socket = await Socket.connect(_torDaemonConfig.host, _torDaemonConfig.controlPort);
      final controlPortStream = socket.transform(utf8.decoder as StreamTransformer<Uint8List, dynamic>).transform(const LineSplitter());

      // Authenticate with the control port
      final authenticateCommand = 'AUTHENTICATE "${_torDaemonConfig.hashedPassword}"\r\n';
      socket.write(authenticateCommand);

      await for (var line in controlPortStream) {
        if (line.startsWith('250')) {
          print('Authentication successful');

          // Add the hidden service using the private key
          final addOnionCommand = 'ADD_ONION ${onionConfig.privateKey} Port=${onionConfig.externalPort},127.0.0.1:${onionConfig.internalPort}\r\n';
          socket.write(addOnionCommand);

          await for (var response in controlPortStream) {
            if (response.startsWith('250')) {
              print('Hidden service created successfully');
              socket.destroy();
              return true;
            } else if (response.startsWith('551')) {
              print('Error creating hidden service: $response');
              socket.destroy();
              return false;
            }
          }
        } else if (line.startsWith('515')) {
          print('Authentication failed: $line');
          socket.destroy();
          return false;
        }
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
    return false;
  }

  static Future<bool> checkControlPort({String? password}) async {
    try {
      final socket = await Socket.connect('127.0.0.1', 9051, timeout: Duration(seconds: 5));
      if (password != null) {
        socket.write('AUTHENTICATE "$password"\r\n');
        await socket.flush();
        final response = await socket.transform(utf8.decoder as StreamTransformer<Uint8List, dynamic>).join();
        socket.destroy();
        return response.contains('250 OK');
      } else {
        socket.destroy();
        return true;
      }
    } catch (e) {
      return false;
    }
  }


  static Future<bool> checkSocks5Proxy({String testHost = '127.0.0.1', int? testPort}) async {
    try {
      final socket = await Socket.connect(testHost, testPort ?? 9050, timeout: const Duration(seconds: 5));
      socket.destroy(); // Close the socket as soon as the connection is established
      return true; // If connected, the SOCKS5 proxy is available
    } catch (e) {
      print("Error connecting to SOCKS5 proxy: $e");
      return false; // Connection failed, proxy is not available
    }
  }
  
  static HttpClient createTorHttpClient() {
    final httpClient = HttpClient();
    String proxy;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      proxy = "PROXY 127.0.0.1:8888"; // Set your proxy for desktop platforms
    } else if (Platform.isAndroid) {
      proxy = 'PROXY 127.0.0.1:8118'; // Orbot's default HTTP proxy for Android
    } else if (Platform.isIOS) {
      proxy = ''; // iOS-specific handling can be implemented here
    } else {
      proxy = 'PROXY 127.0.0.1:8118'; // Fallback
    }

    if (proxy.isNotEmpty) {
      httpClient.findProxy = (uri) {
        return proxy; // This sets the proxy for HttpClient
      };
    }

    return httpClient;
  }

}