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
import 'package:haveno_app/views/tabs/trades/trades_active_tab.dart';
import 'package:haveno_app/views/tabs/trades/trades_completed_tab.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/trades_provider.dart';

class TradesTab extends StatefulWidget {
  const TradesTab({super.key});

  @override
  _TradesTabState createState() => _TradesTabState();
}

class _TradesTabState extends State<TradesTab>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Call getTrades when the widget is initialized
    final tradesProvider = Provider.of<TradesProvider>(context, listen: false);
    tradesProvider.getTrades();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tradesProvider = Provider.of<TradesProvider>(context);
    final totalTrades = tradesProvider.trades.length;
    final activeTrades = tradesProvider.activeTrades.length ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Trades'),
            Center(
              child: Text(
                '$activeTrades active out of $totalTrades total trades',
                style: TextStyle(
                  fontSize: 14.0, // Reduced font size
                  color: Colors.white.withOpacity(0.23), // Reduced opacity
                ),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TradesActiveTab(),
          TradesCompletedTab(),
        ],
      ),
    );
  }
}
