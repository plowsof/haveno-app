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
import 'package:haveno/profobuf_models.dart';
import 'package:haveno_app/views/tabs/sell/sale_market_offers_tab.dart';
import 'package:haveno_app/views/tabs/sell/sale_my_offers_tab.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/offers_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/payment_accounts_provider.dart';
import 'package:haveno_app/views/widgets/new_trade_offer_form.dart';
import 'package:haveno_app/views/widgets/offer_filter_menu.dart';

class SellTab extends StatefulWidget {
  const SellTab({super.key});

  @override
  _SellTabState createState() => _SellTabState();
}

class _SellTabState extends State<SellTab> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  TabController? _tabController;
  bool _isLoadingPaymentMethods = true;
  List<PaymentAccount> _paymentAccounts = [];
  bool _isFilterVisible = false;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
    _initializeData();
  }

  Future<void> _initializeData() async {
    final paymentAccountsProvider =
        Provider.of<PaymentAccountsProvider>(context, listen: false);

    await paymentAccountsProvider.getPaymentAccounts();

    setState(() {
      _paymentAccounts = paymentAccountsProvider.paymentAccounts;
      _isLoadingPaymentMethods = false;
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  void _showNewTradeForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return NewTradeOfferForm(
          direction: 'SELL',
          paymentAccounts: _paymentAccounts,
          formKey: _formKey,
        );
      },
    ).then((value) {
      // After closing the modal, navigate to the "My Offers" tab
      if (_tabController != null) {
        _tabController?.animateTo(1); // Move to "My Offers" tab
      }
    });
  }

  void _toggleFilter() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
      if (_isFilterVisible) {
        _filterAnimationController.forward();
      } else {
        _filterAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final offersProvider = Provider.of<OffersProvider>(context);
    final totalOpenOffers = offersProvider.offers?.length ?? 'Loading';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Sell Monero'),
            Text(
              '$totalOpenOffers total open offers',
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.white.withOpacity(0.23),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _toggleFilter,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Market Offers'),
            Tab(text: 'My Offers'),
          ],
        ),
      ),
      body: Column(
        children: [
          SizeTransition(
            sizeFactor: _filterAnimation,
            axisAlignment: -1.0,
            child: OfferFilterMenu(
              onCurrenciesChanged: (value) {
                // Handle currency filter change
              },
              onPaymentMethodsChanged: (value) {
                // Handle payment method filter change
              },
            ),
          ),
          Expanded(
            child: _isLoadingPaymentMethods
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      SaleMarketOffersTab(),
                      SaleMyOffersTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewTradeForm,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
