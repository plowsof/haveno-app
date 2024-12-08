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
import 'package:haveno/profobuf_models.dart';

class XmrNodeProvider with ChangeNotifier {
  final HavenoChannel _havenoChannel = HavenoChannel();

  XmrNodeSettings? _xmrNodeSettings;

  XmrNodeProvider();

  // Getters
  XmrNodeSettings? get xmrNodeSettings => _xmrNodeSettings;

  Future<void> getXmrNodeSettings() async {
    await _havenoChannel.onConnected;
    try {
      final getXmrNodeSettingsReply =
          await _havenoChannel.xmrNodeClient!.getXmrNodeSettings(GetXmrNodeSettingsRequest());
      _xmrNodeSettings = getXmrNodeSettingsReply.settings;
      print("Getting XMR node settings from daemon...");
      notifyListeners();
    } catch (e) {
      print("Failed to get XMR node settings: $e");
      rethrow;
    }
  }
}
