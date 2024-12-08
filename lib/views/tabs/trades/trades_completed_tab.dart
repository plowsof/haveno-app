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
import 'package:haveno/grpc_models.dart';
import 'package:haveno_app/utils/human_readable_helpers.dart';
import 'package:haveno_app/utils/payment_utils.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/trades_provider.dart';
import 'package:intl/intl.dart';
import 'package:fixnum/fixnum.dart'; // Import the fixnum package for Int64
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome package

class TradesCompletedTab extends StatelessWidget {
  const TradesCompletedTab({super.key});

  @override
  Widget build(BuildContext context) {
    final tradesProvider = Provider.of<TradesProvider>(context);
    final completedTrades = tradesProvider.completedTrades;

    if (completedTrades == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Sort the completed trades by date in descending order
    completedTrades.sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      itemCount: completedTrades.length,
      itemBuilder: (context, index) {
        final trade = completedTrades[index];

        return Card(
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 2),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.monero, color: Color(0xFFFF6602)),
                        const SizedBox(width: 8.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              trade.role.contains('seller') ? 'Sell XMR' : 'Buy XMR',
                              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                            ),
                            //const SizedBox(height: 2.0), // Reduced space between the texts
                            Text(
                              'You were the ${trade.role.contains('maker') ? 'Maker' : 'Taker'}',
                              style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      _formatDate(trade.date),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(trade.offer.paymentMethodShortName),
                const SizedBox(height: 8.0),
                _buildAmountDisplay(trade),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Tooltip(
                      message: 'Trade ID: ${trade.shortId}\nTrade Peer: ${trade.tradePeerNodeAddress}\nYou have traded X times with this peer.',
                      child: const Icon(
                        Icons.info,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      humanReadablePayoutStateAs(trade.payoutState, trade.role.contains('buyer'), trade.role.contains('buyer')),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountDisplay(TradeInfo trade) {
    final price = double.tryParse(trade.offer.price) ?? 0.0;
    final amountAtomicUnits = trade.offer.amount.toDouble();
    final amountXMR = amountAtomicUnits / 1e12; // Convert atomic units to XMR
    final payAmount = trade.tradeVolume;
    final receiveAmount = double.parse(payAmount) / price;
    final isBuyingXmr = trade.role.contains('buyer');
    final payAmountDisplay = autoFormatCurrency(trade.tradeVolume, isBuyingXmr ? trade.offer.counterCurrencyCode : trade.offer.counterCurrencyCode, includeCurrencyCode: false);
    final receiveAmountDisplay = autoFormatCurrency(receiveAmount, isBuyingXmr ? trade.offer.baseCurrencyCode : trade.offer.counterCurrencyCode, includeCurrencyCode: false);
    print("$payAmountDisplay : $receiveAmountDisplay (${trade.offer.baseCurrencyCode} : ${trade.offer.counterCurrencyCode})");
    if (trade.role.contains('buyer')) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You pay'),
              Text(
                '$payAmountDisplay ${trade.offer.counterCurrencyCode}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Icon(Icons.arrow_forward),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('You receive'),
              Text(
                '$receiveAmountDisplay ${trade.offer.baseCurrencyCode}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You pay'),
              Text(
                '$receiveAmountDisplay ${trade.offer.baseCurrencyCode}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Icon(Icons.arrow_forward),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('You receive'),
              Text(
                '$payAmountDisplay ${trade.offer.counterCurrencyCode}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      );
    }
  }

  String _formatDate(Int64? dateInt64) {
    try {
      if (dateInt64 == null) return 'Unknown Date';
      final date = DateTime.fromMillisecondsSinceEpoch(dateInt64.toInt());
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      print('Error formatting date: $e');
      return 'Invalid Date';
    }
  }
}
