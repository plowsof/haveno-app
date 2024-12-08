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
import 'package:haveno_app/data/mock_data.dart';
import 'package:haveno_app/providers/haveno_client_providers/trade_statistics_provider.dart';
import 'package:interactive_chart/interactive_chart.dart';
import 'package:provider/provider.dart';

class MarketStatistics extends StatefulWidget {
  const MarketStatistics({super.key});

  @override
  State<MarketStatistics> createState() => _MarketStatisticsState();
}

class _MarketStatisticsState extends State<MarketStatistics> {
  final List<CandleData> _data = MockDataTesla.candles;
  bool _showAverage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Access the provider here to initialize or fetch data
      Provider.of<TradeStatisticsProvider>(context, listen: false)
          .getTradeStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access the provider's state here
    final tradeStatisticsProvider =
        Provider.of<TradeStatisticsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("XMR/USDT"),
        actions: [
          IconButton(
            icon: Icon(
              _showAverage ? Icons.show_chart : Icons.bar_chart_outlined,
            ),
            onPressed: () {
              setState(() => _showAverage = !_showAverage);
              if (_showAverage) {
                _computeTrendLines();
              } else {
                _removeTrendLines();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: InteractiveChart(
          candles: _data,
          style: ChartStyle(
            volumeHeightFactor: 0.1,
            priceGainColor: Colors.green,
            priceLossColor: Colors.red,
            trendLineStyles: [
              Paint()
                ..strokeWidth = 2.0
                ..strokeCap = StrokeCap.round
                ..color = Colors.deepOrange,
            ],
          ),
        ),
      ),
    );
  }

  void _computeTrendLines() {
    final ma7 = CandleData.computeMA(_data, 7);
    final ma30 = CandleData.computeMA(_data, 30);
    final ma90 = CandleData.computeMA(_data, 90);

    for (int i = 0; i < _data.length; i++) {
      _data[i].trends = [ma7[i], ma30[i], ma90[i]];
    }
  }

  void _removeTrendLines() {
    for (final data in _data) {
      data.trends = [];
    }
  }
}
