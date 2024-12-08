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
import 'package:grpc/grpc.dart';
import 'package:haveno/profobuf_models.dart';
import 'package:haveno_app/utils/payment_utils.dart';
import 'package:haveno_app/views/tabs/buy_tab.dart';
import 'package:haveno_app/views/widgets/loading_button.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/offers_provider.dart';
import 'package:fixnum/fixnum.dart' as fixnum;
import 'dart:convert'; // Import the dart:convert library

class NewTradeOfferForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final List<PaymentAccount> paymentAccounts;
  final String direction; // New argument for direction ('BUY' or 'SELL')

  const NewTradeOfferForm({super.key, 
    required this.formKey,
    required this.paymentAccounts,
    required this.direction,
  });

  @override
  __NewTradeOfferFormState createState() => __NewTradeOfferFormState();
}

class __NewTradeOfferFormState extends State<NewTradeOfferForm> {
  PaymentAccount? _selectedPaymentAccount;
  TradeCurrency? _selectedTradeCurrency;
  int _selectedPricingTypeIndex = 0; // 0 for Fixed, 1 for Dynamic
  bool _reserveExactAmount = false;

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _depositController =
      TextEditingController(text: '15');
  final TextEditingController _marginController =
      TextEditingController(text: '0');
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _triggerPriceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isBuy = widget.direction == 'BUY';

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: widget.formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Open a New XMR ${isBuy ? 'Buy' : 'Sell'} Offer',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16.0),
                ToggleButtons(
                  isSelected: [
                    _selectedPricingTypeIndex == 0,
                    _selectedPricingTypeIndex == 1
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedPricingTypeIndex = index;
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Fixed'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Dynamic'),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<PaymentAccount>(
                  decoration: InputDecoration(
                    labelText: 'Your ${isBuy ? 'Sender' : 'Receiver'} Account',
                    border: const OutlineInputBorder(),
                  ),
                  value: _selectedPaymentAccount,
                  items: widget.paymentAccounts.map((account) {
                    return DropdownMenuItem<PaymentAccount>(
                      value: account,
                      child: Text("${getPaymentMethodLabel(account.paymentMethod.id)} (${account.accountName})"),
                    );
                  }).toList(),
                  onChanged: (account) {
                    setState(() {
                      _selectedPaymentAccount = account;
                      _selectedTradeCurrency = null; // Reset currency code
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a payment account';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<TradeCurrency>(
                  decoration: const InputDecoration(
                    labelText: 'Currency Code',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedTradeCurrency,
                  items: _selectedPaymentAccount?.tradeCurrencies
                          .map((tradeCurrency) {
                        return DropdownMenuItem<TradeCurrency>(
                          value: tradeCurrency,
                          child: Text(tradeCurrency.name),
                        );
                      }).toList() ??
                      [],
                  onChanged: (value) {
                    setState(() {
                      _selectedTradeCurrency = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a currency code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                if (_selectedPricingTypeIndex == 0)
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      suffixText: _selectedTradeCurrency?.code ?? '',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the price';
                      }
                      return null;
                    },
                  ),
                if (_selectedPricingTypeIndex == 1)
                  TextFormField(
                    controller: _marginController,
                    decoration: InputDecoration(
                      labelText: isBuy
                          ? 'Market Price Below Margin'
                          : 'Market Price Above Margin',
                      suffixText: '%',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the market price margin';
                      }
                      final margin = double.tryParse(value);
                      if (margin == null || margin < 1 || margin > 90) {
                        return 'Please enter a value between 1 and 90';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount to ${isBuy ? 'Buy' : 'Sell'}',
                    suffixText: 'XMR',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the maximum amount you wish to ${isBuy ? 'buy' : 'sell'}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _minAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Transaction Amount',
                    suffixText: 'XMR',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the minimum transaction amount in XMR';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _depositController,
                  decoration: const InputDecoration(
                    labelText: 'Mutual Security Deposit',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the mutual security deposit';
                    }
                    final deposit = double.tryParse(value);
                    if (deposit == null || deposit < 0 || deposit > 50) {
                      return 'Please enter a value between 0 and 50';
                    }
                    return null;
                  },
                ),
                if (_selectedPricingTypeIndex == 1)
                  const SizedBox(height: 16.0),
                if (_selectedPricingTypeIndex == 1)
                  TextFormField(
                    controller: _triggerPriceController,
                    decoration: InputDecoration(
                      labelText:
                          'Delist If Market Price Goes Above',
                      suffixText: _selectedTradeCurrency?.code ?? '',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the trigger price to suspend your offer';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Row(
                          children: [
                            Text('Reserve only the funds needed'),
                            SizedBox(width: 4),
                            Tooltip(
                              message:
                                  'If selected, only the exact amount of funds needed for this trade will be reserved. This may also incur a mining fee and will require 10 confirmations therefore it will take ~20 minutes longer to post your trade.',
                              child: Icon(
                                Icons.info_outline,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        value: _reserveExactAmount,
                        onChanged: (value) {
                          setState(() {
                            _reserveExactAmount = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                LoadingButton(
                  child: const Text('Post Offer'),
                  onPressed: () async {
                    if (widget.formKey.currentState?.validate() ?? false) {
                      // Prepare the data to be sent
                      final offerData = {
                        'currencyCode': _selectedTradeCurrency?.code ?? '',
                        'direction': widget.direction,
                        'price': _selectedPricingTypeIndex == 0 ? _priceController.text : '',
                        'useMarketBasedPrice': _selectedPricingTypeIndex == 1,
                        'marketPriceMarginPct': double.parse(
                            _marginController.text.isNotEmpty ? _marginController.text : '0'),
                        'amount': fixnum.Int64(
                            ((double.tryParse(_amountController.text) ?? 0) * 1000000000000)
                                .toInt()).toString(),
                        'minAmount': fixnum.Int64(
                            ((double.tryParse(_minAmountController.text) ?? 0) * 1000000000000)
                                .toInt()).toString(),
                        'buyerSecurityDepositPct': double.parse(_depositController.text) / 100,
                        'triggerPrice': _selectedPricingTypeIndex == 1 ? _triggerPriceController.text : '',
                        'reserveExactAmount': _reserveExactAmount,
                        'paymentAccountId': _selectedPaymentAccount?.id ?? '',
                      };

                      // Print the JSON representation of the offer
                      print(jsonEncode(offerData));

                      // Call the postOffer method
                      try {
                        final offersProvider = Provider.of<OffersProvider>(context, listen: false);
                        await offersProvider.postOffer(
                          currencyCode: _selectedTradeCurrency?.code ?? '',
                          direction: widget.direction,
                          price: _selectedPricingTypeIndex == 0 ? _priceController.text : '',
                          useMarketBasedPrice: _selectedPricingTypeIndex == 1,
                          marketPriceMarginPct: double.parse(
                              _marginController.text.isNotEmpty ? _marginController.text : '0'),
                          amount: fixnum.Int64(
                              ((double.tryParse(_amountController.text) ?? 0) * 1000000000000)
                                  .toInt()),
                          minAmount: fixnum.Int64(
                              ((double.tryParse(_minAmountController.text) ?? 0) * 1000000000000)
                                  .toInt()),
                          buyerSecurityDepositPct: double.parse(_depositController.text) / 100,
                          triggerPrice: _selectedPricingTypeIndex == 1 ? _triggerPriceController.text : '',
                          reserveExactAmount: _reserveExactAmount,
                          paymentAccountId: _selectedPaymentAccount?.id ?? '',
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Successfully posted offer!'),
                            ),
                          );
                          await offersProvider.getMyOffers();
                          if (widget.direction == 'BUY') {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BuyTab(),  /// there is a way to just animate to the next tab dot aht
                            ),
                          );
                          } else {

                          }
                        }             
                      } on GrpcError catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.message ?? 'Unknown server error'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
