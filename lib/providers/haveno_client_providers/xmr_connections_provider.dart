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


import 'package:flutter/material.dart';
import 'package:haveno/grpc_models.dart';
import 'package:haveno/haveno_client.dart';
import 'package:haveno/haveno_service.dart';

class XmrConnectionsProvider with ChangeNotifier {
  final HavenoChannel _havenoChannel = HavenoChannel();

  List<UrlConnection> _xmrUrlConnections = [];
  UrlConnection? _xmrActiveConnection;

  XmrConnectionsProvider();

  // Expose the list of connections and the active node
  List<UrlConnection> get xmrNodeConnections => _xmrUrlConnections;
  UrlConnection? get xmrActiveConnection => _xmrActiveConnection;

  // Fetch connections from the server
  Future<void> getXmrConnectionSettings() async {
    await _havenoChannel.onConnected;
    try {
      final xmrConnectionsClient = XmrConnectionsService();
      final response = await xmrConnectionsClient.getXmrConnectionSettings();
      _xmrUrlConnections = response;
      notifyListeners();
    } catch (e) {
      print("Failed to fetch connections: $e");
    }
  }

  // Fetch connections from the server
  Future<void> checkConnections() async {
    await _havenoChannel.onConnected;
    try {
      final response = await _havenoChannel.xmrConnectionsClient!.checkConnections(CheckConnectionsRequest());
      _xmrUrlConnections = response.connections;
      notifyListeners();
    } catch (e) {
      print("Failed to check connections: $e");
    }
  }

  // Set the active node on the server and locally
  Future<void> setConnection(UrlConnection connection) async {
    await _havenoChannel.onConnected;
    try {
      await _havenoChannel.xmrConnectionsClient!.setConnection(SetConnectionRequest(connection: connection));
      _xmrActiveConnection = connection; // Set the new active node locally
      notifyListeners(); // Notify the UI to update
    } catch (e) {
      print("Failed to set active connection: $e");
    }
  }

  // Fetch the currently active connection from the server
  Future<void> getActiveConnection() async {
    await _havenoChannel.onConnected;
    try {
      final response = await _havenoChannel.xmrConnectionsClient!.getConnection(GetConnectionRequest());
      _xmrActiveConnection = response.connection;
      notifyListeners();
    } catch (e) {
      print("Failed to get active connection: $e");
    }
  }

  // Method to check if the selected connection is online (optional, if you need this)
  Future<bool> checkConnection() async {
    await _havenoChannel.onConnected;
    try {
      final response = await _havenoChannel.xmrConnectionsClient!.checkConnection(CheckConnectionRequest());
      return response.connection.onlineStatus == UrlConnection_OnlineStatus.ONLINE;
    } catch (e) {
      print("Failed to check connection status: $e");
      return false;
    }
  }


  // Add a connection to the list and notify
  Future<bool> addConnection(UrlConnection connection) async {
    await _havenoChannel.onConnected;
    try {
      await _havenoChannel.xmrConnectionsClient!.addConnection(AddConnectionRequest(connection: connection));
      _xmrUrlConnections.add(connection); // Add to local list
      notifyListeners(); // Notify listeners/UI
      return true;
    } catch (e) {
      print("Failed to add connection: $e");
      return false;
    }
  }

  // Remove a connection from the list and notify
  Future<bool> removeConnection(String url) async {
    await _havenoChannel.onConnected;
    try {
      await _havenoChannel.xmrConnectionsClient!.removeConnection(RemoveConnectionRequest(url: url));
      _xmrUrlConnections.removeWhere((connection) => connection.url == url); // Remove from local list
      notifyListeners(); // Notify listeners/UI
      return true;
    } catch (e) {
      print("Failed to remove connection: $e");
      return false;
    }
  }

  // Remove a connection from the list and notify
  Future<bool> setAutoSwitchBestConnection(bool autoSwitch) async {
    await _havenoChannel.onConnected;
    try {
      await _havenoChannel.xmrConnectionsClient!.setAutoSwitch(SetAutoSwitchRequest(autoSwitch: autoSwitch));
      notifyListeners();
      return true;
    } catch (e) {
      print("Failed to remove connection: $e");
      return false;
    }
  }

  // Remove a connection from the list and notify
  Future<bool> getAutoSwitchBestConnection() async {
    await _havenoChannel.onConnected;
    try {
      final getAutoSwitchReply = await _havenoChannel.xmrConnectionsClient!.getAutoSwitch(GetAutoSwitchRequest());
      return getAutoSwitchReply.autoSwitch;
    } catch (e) {
      print("Failed to remove connection: $e");
      return false;
    }
  }

}
