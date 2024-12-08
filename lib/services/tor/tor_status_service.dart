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


/* import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:haveno_app/models/schema.dart';

class TorStatusService {
  static final TorStatusService _instance = TorStatusService._internal();

  String _torStatus = 'Unknown';
  String _torDetails = 'No details available';
  int? _torPort;

  // Completer to track initialization
  final Completer<void> _torInitializationCompleter = Completer<void>();

  final StreamController<void> _statusStreamController = StreamController<void>.broadcast();

  String get torStatus => _torStatus;
  String get torDetails => _torDetails;
  int? get torPort => _torPort;

  factory TorStatusService() {
    return _instance;
  }

  TorStatusService._internal();

  // Start listening to events before the UI is loaded
  void startListening(EventDispatcher dispatcher) {
    dispatcher.subscribe(BackgroundEventType.updateTorStatus, _onTorStatusUpdate);
  }

  void _onTorStatusUpdate(Map<String, dynamic> data) {
    _torStatus = data['status'] ?? 'Unknown';
    _torDetails = data['details'] ?? 'No details available';
    _torPort = data['port'];

    if (_torStatus == 'started') {
      print("Tor listening connected on port $_torPort");
    } else {
      print("Tor Status: $_torStatus ($_torDetails)");
    }

    if (_torStatus == 'started' && _torPort != null && !_torInitializationCompleter.isCompleted) {
      _torInitializationCompleter.complete();  // Mark initialization as completed
      //SocksProxy.initProxy(proxy: 'SOCKS5 127.0.0.1:$_torPort');
    }

    _statusStreamController.add(null);
  }

  // Expose a stream for external listeners to subscribe to status updates
  Stream<void> get torStatusStream => _statusStreamController.stream;

  // Method to await until Tor is fully initialized
  Future<void> waitForInitialization() {
    return _torInitializationCompleter.future;
  }
}
 */