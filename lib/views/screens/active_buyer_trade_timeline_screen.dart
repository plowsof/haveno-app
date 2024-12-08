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
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:haveno/grpc_models.dart';
import 'package:haveno_app/views/screens/trade_timeline/buyer_phases/phase_deposits_confirmed_buyer.dart';
import 'package:haveno_app/views/screens/trade_timeline/buyer_phases/phase_deposits_published_buyer.dart';
import 'package:haveno_app/views/screens/trade_timeline/buyer_phases/phase_deposits_unlocked_buyer.dart';
import 'package:haveno_app/views/screens/trade_timeline/buyer_phases/phase_init_buyer.dart';
import 'package:haveno_app/views/screens/trade_timeline/buyer_phases/phase_payment_received_buyer.dart';
import 'package:haveno_app/views/screens/trade_timeline/buyer_phases/phase_payment_sent_buyer.dart';
import 'package:haveno_app/utils/payment_utils.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/trades_provider.dart';

class ActiveBuyerTradeTimelineScreen extends StatefulWidget {
  final TradeInfo trade;

  const ActiveBuyerTradeTimelineScreen({super.key, required this.trade});

  @override
  _ActiveBuyerTradeTimelineScreenState createState() =>
      _ActiveBuyerTradeTimelineScreenState();
}

class _ActiveBuyerTradeTimelineScreenState
    extends State<ActiveBuyerTradeTimelineScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _countdownTimer;
  late TradesProvider tradesProvider;

  late final tradesProviderListener;

  @override
  void initState() {
    super.initState();
    tradesProvider = Provider.of<TradesProvider>(context, listen: false);
    _initializePage();
    _listenToPhaseUpdates();
  }

  void _initializePage() {
    if (mounted) {
      setState(() {
        _currentPage = _getPhaseIndex(widget.trade.phase);
        _pageController = PageController(initialPage: _currentPage);
      });
    }
  }

  void _listenToPhaseUpdates() {
    tradesProviderListener = () {
      final updatedTrade = tradesProvider.trades
          .firstWhere((trade) => trade.tradeId == widget.trade.tradeId);
      if (updatedTrade.phase != widget.trade.phase) {
        if (mounted) {
          setState(() {
            widget.trade.phase = updatedTrade.phase;
            _currentPage = _getPhaseIndex(updatedTrade.phase);
            _pageController.animateToPage(
              _currentPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        }
      }
    };
    tradesProvider.addListener(tradesProviderListener);
  }

  void _listenToDisputeStateUpdates() {
    tradesProviderListener = () {
      final updatedTrade = tradesProvider.trades
          .firstWhere((trade) => trade.tradeId == widget.trade.tradeId);
      if (updatedTrade.phase != widget.trade.phase) {
        if (mounted) {
          setState(() {
            widget.trade.phase = updatedTrade.phase;
            _currentPage = _getPhaseIndex(updatedTrade.phase);
            _pageController.animateToPage(
              _currentPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        }
      }
    };
    tradesProvider.addListener(tradesProviderListener);
  }

  int _getPhaseIndex(String phase) {
    switch (phase) {
      case 'INIT':
        return 0;
      case 'DEPOSITS_PUBLISHED':
        return 1;
      case 'DEPOSITS_CONFIRMED':
        return 2;
      case 'DEPOSITS_UNLOCKED':
        return 3;
      case 'PAYMENT_SENT':
        return 4;
      case 'PAYMENT_RECEIVED':
        return 5;
      default:
        return 0;
    }
  }

  Widget _getPhaseWidget(int index) {
    switch (index) {
      case 0:
        return const PhaseInitBuyer();
      case 1:
        return const PhaseDepositsPublishedBuyer();
      case 2:
        return const PhaseDepositsConfirmedBuyer();
      case 3:
        return PhaseDepositsUnlockedBuyer(
          takerPaymentAccountPayload: _extractAccountPayload(
              jsonDecode(jsonEncode(widget.trade.contract.takerPaymentAccountPayload.toProto3Json()))),
          makerPaymentAccountPayload: _extractAccountPayload(
              jsonDecode(jsonEncode(widget.trade.contract.makerPaymentAccountPayload.toProto3Json()))),
          trade: widget.trade,
          onPaidInFull: _onPaidInFull,
        );
      case 4:
        return PhasePaymentSentBuyer(trade: widget.trade);
      case 5:
        return const PhasePaymentReceivedBuyer();
      default:
        return const PhaseInitBuyer(); // Fallback to an initial phase
    }
  }

  Map<String, dynamic> _extractAccountPayload(Map<String, dynamic> json) {
    return json.entries
        .firstWhere((entry) => entry.key.contains('AccountPayload'))
        .value as Map<String, dynamic>;
  }

  String formatFiat(double amount, String currencyCode) {
    return isFiatCurrency(currencyCode)
        ? '${amount.toStringAsFixed(2)} $currencyCode'
        : amount.toString();
  }

  Future<void> _onPaidInFull() async {
    try {
      // Confirm the payment
      await tradesProvider.confirmPaymentSent(widget.trade.tradeId);
      
      // Move to the next phase screen, which is index 4 (PAYMENT_SENT phase)
      setState(() {
        _currentPage = 4;
      });
      
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (error) {
      // Handle error and notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to confirm payment, please try again in a moment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const int totalPages = 6; // Number of phases

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buying XMR'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalPages,
              itemBuilder: (context, index) {
                return _getPhaseWidget(index);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalPages, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 12.0,
                  height: 12.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index <= _currentPage ? Colors.green : Colors.grey,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pageController.dispose();
    tradesProvider.removeListener(tradesProviderListener);
    super.dispose();
  }
}
