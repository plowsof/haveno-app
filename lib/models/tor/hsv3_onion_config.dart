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

import 'package:cryptography/cryptography.dart';

class HSV3OnionConfig {
  final List<int> privateKeyBytes;
  final SimplePublicKey publicKey;
  final int internalPort;
  final int externalPort;

  HSV3OnionConfig(
      {required this.privateKeyBytes,
      required this.publicKey,
      required this.internalPort,
      required this.externalPort});

  get privateKey => null;

  Map<String, dynamic> toJson() {
    return {
      'privateKeyBytes': privateKeyBytes,
      'publicKey': publicKey,
      'internalPort': internalPort,
      'externalPort': externalPort
    };
  }

  factory HSV3OnionConfig.fromJson(Map<String, dynamic> json) {
    return HSV3OnionConfig(
        privateKeyBytes: json['privateKeyBytes'],
        publicKey: json['publicKey'],
        internalPort: json['internalPort'],
        externalPort: json['externalPortal']);
  }
}
