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
import 'package:haveno/haveno_client.dart';
import 'package:haveno/haveno_service.dart';
import 'package:haveno/profobuf_models.dart';
import 'package:haveno_app/utils/database_helper.dart';

class TradeStatisticsProvider with ChangeNotifier {
  final HavenoChannel _havenoChannel;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<TradeStatistics3> _tradeStatistics = [];

  TradeStatisticsProvider(this._havenoChannel);

  List<TradeStatistics3>? get tradeStatisticsList => _tradeStatistics;

  Future<void> getTradeStatistics() async {
    try {
      await _havenoChannel.onConnected;

      if (_tradeStatistics.isEmpty) {
        _tradeStatistics = await _databaseHelper.getTradeStatistics(null);
      }

      TradeStatisticsService? tradeStatisticsService = TradeStatisticsService();
      List<TradeStatistics3>? tradeStatistics3 = await tradeStatisticsService.getTradeStatistics();

      if (tradeStatistics3 != null && tradeStatistics3.isNotEmpty) {
        _tradeStatistics = tradeStatistics3;
        try {
          for (var tradeStatistic in _tradeStatistics) {
            _databaseHelper.insertTradeStatistic(tradeStatistic);
          }
        } catch (e) {
          print(
              "Error adding one ore more trade statistic records to the database: ${e.toString()}");
          return;
        }
      }

      notifyListeners();
    } catch (e) {
      print("Failed to get trade statistics: $e");
    }
  }
}
