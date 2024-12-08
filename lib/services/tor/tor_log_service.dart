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
import 'package:haveno_app/models/schema.dart';

class TorLogService {
  static final TorLogService _instance = TorLogService._internal();

  final List<String> _stdOutLogs = [];
  final List<String> _stdErrLogs = [];

  final StreamController<void> _stdOutStreamController = StreamController<void>.broadcast();
  final StreamController<void> _stdErrStreamController = StreamController<void>.broadcast();

  static const int _logLimit = 200;  // Limit the number of logs kept

  factory TorLogService() {
    return _instance;
  }

  TorLogService._internal();

  // Start listening for Tor log events
  void startListening(EventDispatcher dispatcher) {
    dispatcher.subscribe(BackgroundEventType.torStdOutLog, _onStdOutLogReceived);
    dispatcher.subscribe(BackgroundEventType.torStdErrLog, _onStdErrLogReceived);
  }

  void _onStdOutLogReceived(Map<String, dynamic> data) {
    final log = data['details'] ?? 'No details available';
    _addLog(_stdOutLogs, log);

      // Debug print stderr logs
      print("[Tor StdOut] $log");

    _stdOutStreamController.add(null);
  }

  void _onStdErrLogReceived(Map<String, dynamic> data) {
    final log = data['details'] ?? 'No details available';
    _addLog(_stdErrLogs, log);

    // Debug print stderr logs
    print("[Tor StdErr] $log");

    _stdErrStreamController.add(null);
  }

  void _addLog(List<String> logList, String log) {
    logList.add(log);
    if (logList.length > _logLimit) {
      logList.removeAt(0);  // Remove the oldest log to stay within the limit
    }
  }

  // Expose logs and streams for external listeners
  List<String> get stdOutLogs => List.unmodifiable(_stdOutLogs);
  List<String> get stdErrLogs => List.unmodifiable(_stdErrLogs);

  Stream<void> get stdOutStream => _stdOutStreamController.stream;
  Stream<void> get stdErrStream => _stdErrStreamController.stream;
}
 */