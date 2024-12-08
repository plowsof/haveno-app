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


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:haveno/grpc_models.dart';
import 'package:haveno_app/providers/haveno_client_providers/trades_provider.dart';
import 'package:haveno_app/utils/payment_utils.dart';
import 'package:haveno_app/views/screens/trade_chat_screen.dart';
import 'package:haveno_app/views/screens/trade_timeline/phase_base.dart';
import 'package:provider/provider.dart';

class PhasePaymentSentSeller extends PhaseBase {
  final TradeInfo trade;

  const PhasePaymentSentSeller({required this.trade, super.key}) 
      : super(phaseText: 'Confirm Payment Received');

  Map<String, dynamic> _extractAccountPayload(Map<String, dynamic> json) {
    return json.entries
        .firstWhere((entry) => entry.key.contains('AccountPayload'))
        .value as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    final price = double.parse(trade.price);
    final amount = formatXmr(trade.amount, returnString: false) as double;
    final totalAmount = amount * price;
    final totalAmountFormatted = "${formatFiat(totalAmount)} ${trade.offer.counterCurrencyCode}";

    final takerPaymentAccountJson = trade.contract.takerPaymentAccountPayload.toProto3Json();
    final makerPaymentAccountJson = trade.contract.makerPaymentAccountPayload.toProto3Json();

    final takerPaymentAccountPayload = _extractAccountPayload(jsonDecode(jsonEncode(takerPaymentAccountJson)));
    final makerPaymentAccountPayload = _extractAccountPayload(jsonDecode(jsonEncode(makerPaymentAccountJson)));

    return Stack(
      children: [
        // Scrollable content
        Padding(
          padding: const EdgeInsets.only(bottom: 100.0), // Adjusted padding for button space
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text(
                  'Confirm Payment Received',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 20),
                Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'You should have received a total of $totalAmountFormatted from the following account:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                _buildPaymentDetails('From account...', takerPaymentAccountPayload),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        // Static button at the bottom with a solid background
        Positioned(
          bottom: 0.0,
          left: 8.0,
          right: 8.0,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor, // Same background as the scaffold
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _onConfirmPaymentReceived(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48), // Set the height
                    ),
                    child: const Text('Confirm Payment Received'),
                  ),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TradeChatScreen(tradeId: trade.tradeId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(48, 48), // Match the height of the main button
                    padding: EdgeInsets.zero, // Remove extra padding
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Icon(Icons.chat_bubble_outline),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails(String title, Map<String, dynamic> payload) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ...payload.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  initialValue: entry.value,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _onConfirmPaymentReceived(BuildContext context) {
    final tradesProvider = Provider.of<TradesProvider>(context, listen: false);
    tradesProvider
        .confirmPaymentReceived(trade.tradeId)
        .catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Failed to confirm payment received, please try again in a moment.')),
      );
    });
  }
}
