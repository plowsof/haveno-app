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
import 'package:haveno/grpc_models.dart';
import 'package:haveno/haveno_client.dart';

class PricesProvider with ChangeNotifier {
  final HavenoChannel _havenoChannel;
  List<MarketPriceInfo> _marketPrices = [];
  Timer? _timer;

  PricesProvider(this._havenoChannel);

  List<MarketPriceInfo> get prices => _marketPrices;

  Future<void> getXmrMarketPrices() async {
    await _havenoChannel.onConnected;
    try {
      final getMarketPricesReply = await _havenoChannel.priceClient
          !.getMarketPrices(MarketPricesRequest());
      _marketPrices = getMarketPricesReply.marketPrice;
      notifyListeners();
    } catch (e) {
      print("Failed to get prices: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
