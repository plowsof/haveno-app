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
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:haveno/profobuf_models.dart';
import 'package:haveno_app/providers/haveno_client_providers/payment_accounts_provider.dart';
import 'package:haveno_app/utils/human_readable_helpers.dart';
import 'package:haveno_app/utils/payment_utils.dart';
import 'package:haveno_app/utils/time_utils.dart';
import 'package:provider/provider.dart';

class PaymentAccountDetailScreen extends StatefulWidget {
  final PaymentAccount paymentAccount;

  const PaymentAccountDetailScreen({super.key, required this.paymentAccount});

  @override
  _PaymentAccountDetailScreenState createState() =>
      _PaymentAccountDetailScreenState();
}

class _PaymentAccountDetailScreenState extends State<PaymentAccountDetailScreen> with SingleTickerProviderStateMixin {
  late Future<List<PaymentAccountFormField>> _futurePaymentAccountFormFields;
  late TextEditingController _accountNameController;
  bool _isNameChanged = false;
  bool _isSaving = false;
  bool _showCheckmark = false;
  bool _showError = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _accountNameController = TextEditingController(text: widget.paymentAccount.accountName);
    _accountNameController.addListener(() {
      setState(() {
        _isNameChanged = _accountNameController.text != widget.paymentAccount.accountName;
      });
    });
    _futurePaymentAccountFormFields = fetchData();

    // Initialize the animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _animationController.dispose(); // Dispose the animation controller
    super.dispose();
  }

  Future<List<PaymentAccountFormField>> fetchData() async {
    final paymentAccountsProvider = Provider.of<PaymentAccountsProvider>(context, listen: false);
    await paymentAccountsProvider.getPaymentMethods();
    var paymentAccountForm = await paymentAccountsProvider.getPaymentAccountForm(widget.paymentAccount.paymentAccountPayload.paymentMethodId);
    return paymentAccountForm!.fields;
  }

  Future<void> _saveAccountName() async {
    setState(() {
      _isSaving = true;
      _showError = false;
      _showCheckmark = false;
    });

    // Simulate a save operation
    await Future.delayed(const Duration(seconds: 2));

    final isSuccess = true; // Simulate success or failure
    setState(() {
      _isSaving = false;
      if (isSuccess) {
        _showCheckmark = true;
        _animationController.forward(from: 0.0); // Start the fade-out animation
      } else {
        _showError = true;
        _animationController.forward(from: 0.0); // Start the fade-out animation
      }
    });

    // Show the checkmark or error for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _showCheckmark = false;
      _showError = false;
      _isNameChanged = false;
    });
  }

  Animation<double> _fadeOutAnimation() {
    return Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

    @override
  Widget build(BuildContext context) {
    final paymentAccountPayloadJson = widget.paymentAccount.paymentAccountPayload.toProto3Json();
    final paymentAccountPayload = _extractAccountPayload(jsonDecode(jsonEncode(paymentAccountPayloadJson)));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Payment Account'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 80.0),
            child: FutureBuilder<List<PaymentAccountFormField>>(
              future: _futurePaymentAccountFormFields,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (snapshot.hasData) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAccountInfoCard(
                          context,
                          widget.paymentAccount,
                        ),
                        const SizedBox(height: 8),
                        _buildPaymentDetails(
                          context,
                          'Payment Details',
                          paymentAccountPayload,
                          snapshot.requireData,
                          widget.paymentAccount.tradeCurrencies,
                        ),
                        //const SizedBox(height: 8),
                      ],
                    ),
                  );
                } else {
                  return const Center(child: Text('No details available'));
                }
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Logic for exporting the account
                      },
                      child: const Text('Export Account'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Logic for deleting the account
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Delete Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _extractAccountPayload(Map<String, dynamic> json) {
    return json.entries
        .firstWhere((entry) => entry.key.contains('AccountPayload'))
        .value as Map<String, dynamic>;
  }

  Widget _buildAccountInfoCard(BuildContext context, PaymentAccount account) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // Editable Account Name Field with Save Suffix
            TextFormField(
              controller: _accountNameController,
              decoration: InputDecoration(
                labelText: 'Label',
                border: const OutlineInputBorder(),
                suffixIcon: _isNameChanged
                    ? MouseRegion(
                        onEnter: (_) => setState(() {}),
                        onExit: (_) => setState(() {}),
                        child: GestureDetector(
                          onTap: _isSaving ? null : _saveAccountName,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: _isSaving
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.7),
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                : _showCheckmark
                                    ? FadeTransition(
                                        opacity: _fadeOutAnimation(),
                                        child: const Icon(
                                          Icons.check,
                                          key: ValueKey('checkmark'),
                                          color: Colors.green,
                                        ),
                                      )
                                    : _showError
                                        ? FadeTransition(
                                            opacity: _fadeOutAnimation(),
                                            child: const Icon(
                                              Icons.close,
                                              key: ValueKey('error'),
                                              color: Colors.red,
                                            ),
                                          )
                                        : Icon(
                                            Icons.save,
                                            key: const ValueKey('save'),
                                            color: _isNameChanged
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                                    .withOpacity(0.23),
                                          ),
                          ),
                        ),
                      )
                    : null,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // Account Info Grid
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                childAspectRatio: 4, // Adjust as needed
              ),
              children: [
                _buildGridTile('Account Type', account.paymentMethod.id),
                _buildGridTile('Account Age', '${calculateFormattedTimeSince(account.creationDate)} old'),
                _buildGridTile('Max Sell Limit', "${formatXmr(account.paymentMethod.maxTradeLimit)} XMR"),
                _buildGridTile('Max Buy Limit', "${formatXmr(account.paymentMethod.maxTradeLimit)} XMR"),
                _buildGridTile('Max Trade Period', _formatTradePeriod(account.paymentMethod.maxTradePeriod)),
                _buildGridTile('Status', 'Not Signed'),
                _buildGridTile('Total Trades', '4'),
                _buildGridTile('Total Disputes', '5')
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridTile(String title, String value) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTradePeriod(Int64 maxTradePeriod) {
    final periodInSeconds = maxTradePeriod.toInt();
    if (periodInSeconds < 60) {
      return '$periodInSeconds seconds';
    } else if (periodInSeconds < 3600) {
      final minutes = (periodInSeconds / 60).floor();
      return '$minutes minutes';
    } else if (periodInSeconds < 86400) {
      final hours = (periodInSeconds / 3600).floor();
      return '$hours hours';
    } else {
      final days = (periodInSeconds / 86400).floor();
      return '$days days';
    }
  }

    Widget _buildPaymentDetails(
    BuildContext context,
    String title,
    Map<String, dynamic> payload,
    List<PaymentAccountFormField?> fields,
    List<TradeCurrency> tradeCurrencies,
  ) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            ...payload.entries.map((entry) {
              String label = getHumanReadablePaymentMethodFormFieldLabel(entry, fields);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  initialValue: entry.value.toString(),
                  readOnly: true,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }),
            const SizedBox(height: 10),
            const Text(
              'Accepted Currencies',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 100.0, // Maximum width for each item
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                childAspectRatio: 3, // Adjust the aspect ratio as needed
              ),
              itemCount: tradeCurrencies.length,
              itemBuilder: (context, index) {
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.23),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    tradeCurrencies[index].code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
