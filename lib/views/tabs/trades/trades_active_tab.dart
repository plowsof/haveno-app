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
import 'package:haveno_app/providers/haveno_client_providers/disputes_provider.dart';
import 'package:haveno_app/utils/payment_utils.dart';
import 'package:haveno_app/views/screens/active_buyer_trade_timeline_screen.dart';
import 'package:haveno_app/views/screens/active_seller_trade_timeline_screen.dart';
import 'package:haveno_app/views/screens/dispute_chat_screen.dart';
import 'package:haveno_app/utils/human_readable_helpers.dart';
import 'package:haveno_app/utils/time_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/trades_provider.dart';

class TradesActiveTab extends StatelessWidget {
  const TradesActiveTab({super.key});

  @override
  Widget build(BuildContext context) {
    final tradesProvider = Provider.of<TradesProvider>(context);
    final activeTrades = tradesProvider.activeTrades;
    final disputesProvider = Provider.of<DisputesProvider>(context, listen: false);

    return activeTrades == null
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: activeTrades.length,
            itemBuilder: (context, index) {
              final trade = activeTrades[index];
              final tradeAmount = trade.amount;
              final tradePrice = trade.price;
              final currencyCode = trade.offer.counterCurrencyCode;
              final paymentMethod = trade.offer.paymentMethodShortName;
              final tradeRole = trade.role;

              final price = double.parse(tradePrice);
              final amount =
                  formatXmr(tradeAmount, returnString: false) as double;
              final total = amount * price;

              final directionString = tradeRole.contains('seller') ? 'selling' : 'buying';
              final isDisputed = trade.disputeState != 'NO_DISPUTE';
              String tradeStatus = humanReadablePhaseAs(trade.phase, trade.role.contains('buyer'), trade.role.contains('buyer'));
              late Dispute? dispute;
              if (isDisputed) {
                dispute = disputesProvider.getDisputeByTradeId(trade.tradeId);
                if (dispute != null) {
                  tradeStatus = humanReadableDisputeStateAs(trade.disputeState, tradeRole.contains('buyer'), dispute.isOpener);
                } else {
                  throw Exception("Dispute discovered by could not resolve the dispute object");
                }
              }

              // Determine badge text and color based on trade role
              String badgeText;
              Color badgeColor;

              if (tradeRole == 'XMR buyer as maker' || tradeRole == 'XMR seller as maker') {
                badgeText = 'Maker';
                badgeColor = Colors.green;
              } else {
                badgeText = 'Taker';
                badgeColor = Colors.red;
              }

              return GestureDetector(
                onTap: () {
                  if (isDisputed) {
                    if (dispute != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DisputeChatScreen(tradeId: trade.tradeId),
                        ),
                      );
                    }                 
                  }
                  if (directionString == 'buying') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ActiveBuyerTradeTimelineScreen(trade: trade),
                      ),
                    );
                  } else if (directionString == 'selling') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ActiveSellerTradeTimelineScreen(trade: trade),
                      ),
                    );
                  }
                },
                child: Stack(
                  children: [
                    Card(
                      margin: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                      color: Theme.of(context).cardTheme.color,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Trade #${trade.shortId}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'You are $directionString ${formatXmr(tradeAmount)} ${trade.offer.baseCurrencyCode} for a total ${formatFiat(total)} $currencyCode at the rate of ${formatFiat(price)} $currencyCode/${trade.offer.baseCurrencyCode} via $paymentMethod',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: isDisputed ? Colors.red : Colors.blue,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    tradeStatus,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Opened ${calculateFormattedTimeSince(trade.date)} ago',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Maker/Taker Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.zero,
                            bottomRight: Radius.zero,
                            bottomLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }

  String formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final dateFormat = DateFormat('HH:mm dd-MM-yyyy');
    return dateFormat.format(date);
  }
}