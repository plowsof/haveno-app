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


import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:haveno/grpc_models.dart';
import 'package:haveno/profobuf_models.dart';
import 'package:haveno_app/providers/haveno_client_providers/price_provider.dart';
import 'package:haveno_app/views/screens/home_screen.dart';
import 'package:haveno_app/utils/payment_utils.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/trades_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/payment_accounts_provider.dart';
import 'package:haveno_app/views/widgets/loading_button.dart';

class OfferDetailScreen extends StatefulWidget {
  final OfferInfo offer;

  const OfferDetailScreen({super.key, required this.offer});

  @override
  _OfferDetailScreenState createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _payController = TextEditingController();
  final TextEditingController _receiveController = TextEditingController();
  final TextEditingController _marketPriceController = TextEditingController(); // Controller for market price display
  bool _isLoading = true;
  bool _isWithinLimits = true;
  OfferInfo? _offer;
  String? _selectedPaymentAccountId;
  List<PaymentAccount> _paymentAccounts = [];
  double _currentMarketPrice = 0.0; // Variable to store the market price

  @override
  void initState() {
    super.initState();
    _offer = widget.offer;
    _loadPaymentAccounts();
    _loadMarketPrices();
    _initializeReceiveAmount();
    _payController.addListener(_updateReceiveAmount);
    _receiveController.addListener(_updatePayAmount);
  }

  // Determine if the trade is selling XMR or buying XMR
  bool get isSellingXMR => !_offer!.isMyOffer && _offer!.direction == 'BUY';

  // Initialize the receive/pay amounts based on the minimum offer amount
  void _initializeReceiveAmount() {
    if (_offer != null) {
      final minAmountXMR = _offer!.minAmount.toDouble() / 1e12; // Convert from atomic units
      if (isSellingXMR) {
        // Selling XMR: Prefill "I will pay" with min XMR
        _payController.text = minAmountXMR.toStringAsFixed(12);
        _updateReceiveAmount();
      } else {
        // Buying XMR: Prefill "I will receive" with min XMR
        _receiveController.text = minAmountXMR.toStringAsFixed(12);
        _updatePayAmount();
      }
    }
  }

  void _loadMarketPrices() async {
    final pricesProvider = Provider.of<PricesProvider>(context, listen: false);
    final marketPrice = pricesProvider.prices.firstWhere(
      (price) => price.currencyCode == _offer?.counterCurrencyCode,
      orElse: () => MarketPriceInfo(currencyCode: 'USD', price: 0),
    );

    setState(() {
      _currentMarketPrice = marketPrice.price;
      _marketPriceController.text = _calculateMarketValue().toStringAsFixed(2);
    });
  }

  // Updates the receive amount based on the pay amount
  void _updateReceiveAmount() {
    if (_offer != null && _payController.text.isNotEmpty) {
      final payAmount = double.tryParse(_payController.text) ?? 0;
      final offerPrice = double.parse(_offer!.price);

      _receiveController.removeListener(_updatePayAmount);

      if (isSellingXMR) {
        // Selling XMR: Calculate receive amount in fiat
        _receiveController.text = (payAmount * offerPrice).toStringAsFixed(2);
      } else {
        // Buying XMR: Calculate receive amount in XMR
        _receiveController.text = (payAmount / offerPrice).toStringAsFixed(12);
      }

      _receiveController.addListener(_updatePayAmount);
      _checkLimits();
      _marketPriceController.text = _calculateMarketValue().toStringAsFixed(2);
    }
  }

  // Updates the pay amount based on the receive amount
  void _updatePayAmount() {
    if (_offer != null && _receiveController.text.isNotEmpty) {
      final receiveAmount = double.tryParse(_receiveController.text) ?? 0;
      final offerPrice = double.parse(_offer!.price);

      _payController.removeListener(_updateReceiveAmount);

      if (isSellingXMR) {
        // Selling XMR: Calculate pay amount in XMR
        _payController.text = (receiveAmount / offerPrice).toStringAsFixed(12);
      } else {
        // Buying XMR: Calculate pay amount in fiat
        _payController.text = (receiveAmount * offerPrice).toStringAsFixed(2);
      }

      _payController.addListener(_updateReceiveAmount);
      _checkLimits();
      _marketPriceController.text = _calculateMarketValue().toStringAsFixed(2);
    }
  }

  double _calculateMarketValue() {
    // Get the XMR amount based on whether it's a buy or sell trade
    final xmrAmount = double.tryParse(isSellingXMR ? _payController.text : _receiveController.text) ?? 0;
    
    // Calculate the equivalent fiat value of the XMR
    return xmrAmount * _currentMarketPrice;
  }

  void _loadPaymentAccounts() async {
    final paymentAccountsProvider =
        Provider.of<PaymentAccountsProvider>(context, listen: false);
    await paymentAccountsProvider.getPaymentAccounts();
    setState(() {
      _paymentAccounts = paymentAccountsProvider.paymentAccounts
              .where((account) =>
                  account.paymentMethod.id == _offer?.paymentMethodId)
              .toList() ??
          [];
      _isLoading = false;
    });
  }

  // Ensures the pay/receive amounts are within the offer limits
  void _checkLimits() {
    final minAmountXMR = _offer!.minAmount.toDouble() / 1e12;
    final maxAmountXMR = _offer!.amount.toDouble() / 1e12;
    final xmrAmount = double.tryParse(isSellingXMR ? _payController.text : _receiveController.text) ?? 0;

    setState(() {
      _isWithinLimits = xmrAmount >= minAmountXMR && xmrAmount <= maxAmountXMR;
    });
  }

Future<void> _confirmOrder() async {
  if (_formKey.currentState?.validate() ?? false) {
    final tradesProvider =
        Provider.of<TradesProvider>(context, listen: false);
    
    try {
      // Declare variables for handling amounts
      BigInt amountBigInt;

      // Check if user is selling or buying
      if (!isSellingXMR) {
        // User is buying XMR: use receiveAmount
        final receiveAmountDouble = double.parse(_receiveController.text);
        amountBigInt = BigInt.from((receiveAmountDouble * 1e12).round());
      } else {
        // User is selling XMR: use payAmount
        final payAmountDouble = double.parse(_payController.text);
        amountBigInt = BigInt.from((payAmountDouble * 1e12).round());
      }

      // Call the takeOffer function with the correct amount
      await tradesProvider.takeOffer(
        widget.offer.id,
        _selectedPaymentAccountId, // Use selected payment account ID
        fixnum.Int64(amountBigInt.toInt()), // Use the calculated BigInt as Int64
      );

      // Navigate to HomeScreen after successful order confirmation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(initialIndex: 3),
        ),
      );
    } on GrpcError catch (e) {
      // Handle error: Navigate to a different screen and show error message
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(initialIndex: 1),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Unknown server error'),
        ),
      );
    }
  }
}


  @override
  void dispose() {
    _payController.dispose();
    _receiveController.dispose();
    _marketPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSellingXMR ? "Sell Your Monero" : "Buy Monero"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offer == null
              ? const Center(child: Text('Offer not found'))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Offer Details',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16.0),

                                  // Render the text fields based on the trade direction
                                  if (isSellingXMR) ...[
                                    TextFormField(
                                      controller: _payController,
                                      decoration: const InputDecoration(
                                        labelText: 'I will pay',
                                        suffixText: 'XMR',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter the amount to pay';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16.0),
                                    TextFormField(
                                      controller: _receiveController,
                                      decoration: InputDecoration(
                                        labelText: 'I will receive',
                                        suffixText: _offer?.counterCurrencyCode,
                                        border: const OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter the amount to receive';
                                        }
                                        return null;
                                      },
                                    ),
                                  ] else ...[
                                    TextFormField(
                                      controller: _payController,
                                      decoration: InputDecoration(
                                        labelText: 'I will pay',
                                        suffixText: _offer?.counterCurrencyCode,
                                        border: const OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter the amount to pay';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16.0),
                                    TextFormField(
                                      controller: _receiveController,
                                      decoration: const InputDecoration(
                                        labelText: 'I will receive',
                                        suffixText: 'XMR',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter the amount to receive';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],

                                  const SizedBox(height: 16.0),

                                  // Market value approximation
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Center(
                                        child: Text(
                                          _marketPriceController.text.isEmpty
                                              ? 'Calculating...'
                                              : 'XMR is ~${_marketPriceController.text} ${_offer?.counterCurrencyCode} in Market Value',
                                          style: TextStyle(
                                              fontSize: 16.0,
                                              color: Colors.grey[600]),
                                        ),
                                      )
                                    ],
                                  ),
                                  if (!_isWithinLimits)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Amount is out of the buy limits',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${(!_offer!.isMyOffer && _offer!.direction == 'BUY') ? "Paid" : "Pay"} via ${_offer?.paymentMethodShortName}',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16.0),
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: (!_offer!.isMyOffer && _offer!.direction == 'BUY') ? "You'll receive to" : "You'll pay with",
                                      border: const OutlineInputBorder(),
                                    ),
                                    items: _paymentAccounts.map((account) {
                                      return DropdownMenuItem<String>(
                                        value: account.id,
                                        child: Text(account.accountName),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPaymentAccountId = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select a payment account';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('About this Offer',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16.0),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text((!_offer!.isMyOffer && _offer!.direction == 'BUY') ? "Buyer's Rate" : "Seller's Rate", style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(isFiatCurrency(
                                              _offer!.counterCurrencyCode)
                                          ? '${double.parse(_offer!.price).toStringAsFixed(2)} ${_offer!.counterCurrencyCode}/${_offer!.baseCurrencyCode}'
                                          : _offer!.price),
                                    ],
                                  ),
                                  const SizedBox(height: 16.0),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Minimum Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(
                                          '${_offer!.minVolume} ${_offer!.counterCurrencyCode}'),
                                    ],
                                  ),
                                  const SizedBox(height: 16.0),
                                  Row(
                                    mainAxisAlignment: 
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Maximum Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(
                                          '${_offer!.volume} ${_offer!.counterCurrencyCode}'),
                                    ],
                                  ),
                                  const SizedBox(height: 16.0),
                                  const Text('Offer ID', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(_offer!.id),
                                  const SizedBox(height: 16.0),
                                  const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(_offer!.paymentMethodShortName),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LoadingButton(
          onPressed: _confirmOrder,
          child: const Text('Confirm Trade'),
        ),
      ),
    );
  }
}
