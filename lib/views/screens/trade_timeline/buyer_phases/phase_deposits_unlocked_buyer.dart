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
import 'package:flutter/services.dart';
import 'package:haveno/grpc_models.dart';
import 'package:haveno/profobuf_models.dart';
import 'package:haveno_app/providers/haveno_client_providers/payment_accounts_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/trades_provider.dart';
import 'package:haveno_app/utils/human_readable_helpers.dart';
import 'package:haveno_app/views/screens/trade_chat_screen.dart';
import 'package:haveno_app/views/screens/trade_timeline/phase_base.dart';
import 'package:haveno_app/utils/payment_utils.dart';
import 'package:haveno_app/views/widgets/loading_button.dart';
import 'package:provider/provider.dart';

class PhaseDepositsUnlockedBuyer extends PhaseBase {
  final Map<String, dynamic> takerPaymentAccountPayload;
  final Map<String, dynamic> makerPaymentAccountPayload;
  final TradeInfo trade;
  final VoidCallback onPaidInFull;

  const PhaseDepositsUnlockedBuyer({
    super.key,
    required this.takerPaymentAccountPayload,
    required this.makerPaymentAccountPayload,
    required this.trade,
    required this.onPaidInFull,
  }) : super(phaseText: "Awaiting Your Payment");

  Future<PaymentAccountForm?> _getPaymentAccountForm(context) async {
    final paymentAccountsProvider = Provider.of<PaymentAccountsProvider>(context, listen: false);
    await paymentAccountsProvider.getPaymentMethods();
    return paymentAccountsProvider.getPaymentAccountForm(trade.offer.paymentMethodId);
  }


  @override
Widget build(BuildContext context) {
  final tradeAmount = trade.amount;
  final tradePrice = trade.price;
  final currencyCode = trade.offer.counterCurrencyCode;
  final paymentMethod = trade.offer.paymentMethodShortName;

  final price = double.parse(tradePrice);
  final amount = formatXmr(tradeAmount, returnString: false) as double;
  final total = amount * price;

  final totalAmountFormatted = "${formatFiat(total)} $currencyCode";

  // Fetch the PaymentAccountForm using a FutureBuilder
 return FutureBuilder<PaymentAccountForm?>(
  future: _getPaymentAccountForm(context), // Fetch the form asynchronously
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    } else if (!snapshot.hasData) {
      return const Center(child: Text('No payment account form available'));
    }

    final paymentAccountForm = snapshot.data!;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.1, // Add padding equal to the height of the button container
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  phaseText,
                  style: const TextStyle(fontSize: 24),
                ),
                Card(
                  margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'You must pay a total of ',
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: totalAmountFormatted,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const TextSpan(
                              text: ' via ',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            TextSpan(
                              text: paymentMethod,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const TextSpan(
                              text: '. Please be sure the amount is exact.',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center, // Center the text
                      ),
                    ),
                  ),
                ),
                _buildPaymentDetails(
                  'You\'ll send from...',
                  takerPaymentAccountPayload,
                  paymentAccountForm
                ),
                _buildCopyablePaymentDetails(
                  context,
                  'To the seller\'s account...',
                  makerPaymentAccountPayload,
                  paymentAccountForm,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0.0,
          left: 8.0,
          right: 8.0,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor, // Same background as the scaffold
            padding: const EdgeInsets.symmetric(vertical: 8.0), // Reduced padding
            child: Row(
              children: [
                Expanded(
                  child: LoadingButton(
                    onPressed: () async {
                      try {
                        await Provider.of<TradesProvider>(context, listen: false)
                            .confirmPaymentSent(trade.tradeId);
                        onPaidInFull();
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to confirm payment, please try again in a moment.')),
                        );
                      }
                    },
                    child: const Text('I have paid in full'),
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
                  child: const Icon(Icons.chat),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  },
);

}


  Widget _buildPaymentDetails(String title, Map<String, dynamic> payload, PaymentAccountForm paymentAccountForm) {
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
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
                  enabled: false,
                  initialValue: entry.value,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: getHumanReadablePaymentMethodFormFieldLabel(entry, paymentAccountForm.fields),
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }),
            //const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyablePaymentDetails(
      BuildContext context, String title, Map<String, dynamic> payload, PaymentAccountForm paymentAccountForm) {
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
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
                  enabled: true,
                  initialValue: entry.value,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: getHumanReadablePaymentMethodFormFieldLabel(entry, paymentAccountForm.fields),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: entry.value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                    ),
                  ),
                ),
              );
            }),
            //const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

}
