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
import 'package:flutter/material.dart';
import 'package:haveno/haveno_client.dart';
import 'package:haveno/haveno_service.dart';

class DisputeAgentsProvider with ChangeNotifier {
  final HavenoChannel _havenoChannel = HavenoChannel();

  DisputeAgentsProvider();

  Future<void> registerDisputeAgent(String disputeAgentType, String registrationKey) async {
    try {
      await _havenoChannel.onConnected;

      await DisputeAgentService().registerDisputeAgent(
        disputeAgentType,
        registrationKey
      );

    } catch (e) {
      print("Failed to register dispute agent: $e");
    }
  }

  Future<void> unregisterDisputeAgent(String disputeAgentType) async {
    try {
      await _havenoChannel.onConnected;

      await DisputeAgentService().unregisterDisputeAgent(
        disputeAgentType
      );

    } catch (e) {
      print("Failed to unregister dispute agent: $e");
    }
  }

}