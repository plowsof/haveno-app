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
import 'package:haveno_app/views/tabs/buy_tab.dart';
import 'package:haveno_app/views/tabs/market_statistics.dart';
import 'package:haveno_app/views/tabs/sell_tab.dart';
import 'package:haveno_app/views/tabs/trades_tab.dart';
import 'package:haveno_app/views/widgets/balance.dart';
import 'package:haveno_app/views/widgets/main_drawer.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  static final List<Widget> _widgetOptions = <Widget>[
    MarketStatistics(),
    BuyTab(),
    SellTab(),
    TradesTab(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end, // Aligns the widget to the right
          children: [
            MoneroBalanceWidget(),
          ],
        ),
      ),
      drawer: MainDrawer(),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.query_stats),
            label: 'Market Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Buy',
          ),
          NavigationDestination(
            icon: Icon(Icons.sell),
            label: 'Sell',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_vert),
            label: 'Trades',
          ),
        ],
      ),
    );
  }
}
