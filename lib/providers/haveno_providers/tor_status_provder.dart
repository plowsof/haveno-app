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


/* import 'package:flutter/material.dart';
import 'package:haveno_app/models/schema.dart';
import 'package:haveno_app/services/tor/tor_status_service.dart';

class TorStatusProvider with ChangeNotifier, StreamListenerProviderMixin {
  final TorStatusService _torStatusService;

  TorStatusProvider(this._torStatusService) {
    listenToStream(_torStatusService.torStatusStream, notifyListeners);
  }

  int? get port => _torStatusService.torPort;
  String get torStatus => _torStatusService.torStatus;
  String get torDetails => _torStatusService.torDetails;
}
 */