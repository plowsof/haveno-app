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
import 'package:haveno_app/utils/payment_utils.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/offers_provider.dart';

class EditTradeOfferForm extends StatefulWidget {
  final OfferInfo offer;

  const EditTradeOfferForm({super.key, required this.offer});

  @override
  _EditTradeOfferFormState createState() => _EditTradeOfferFormState();
}

class _EditTradeOfferFormState extends State<EditTradeOfferForm> {
  final TextEditingController _deviationController = TextEditingController();
  final TextEditingController _triggerPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with current offer data
    _deviationController.text = widget.offer.marketPriceMarginPct.toString();
    _triggerPriceController.text = autoFormatCurrency(widget.offer.triggerPrice.toString(), widget.offer.counterCurrencyCode, includeCurrencyCode: false);
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = widget.offer.direction == 'BUY';
    final useMarketBasedPrice = widget.offer.useMarketBasedPrice;

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Edit ${isBuy ? 'Buy' : 'Sell'} Offer',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16.0),
                if (useMarketBasedPrice)
                  TextFormField(
                    controller: _deviationController,
                    decoration: const InputDecoration(
                      labelText: 'Maximum Deviation from Market Price',
                      border: OutlineInputBorder(),
                      suffixText: '%',  // Suffix text to indicate percentage
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the maximum deviation percentage';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _triggerPriceController,
                  decoration: InputDecoration(
                    labelText: isBuy
                        ? 'Delist if Market Price goes above'
                        : 'Delist if Market Price goes below',
                    border: const OutlineInputBorder(),
                    suffixText: widget.offer.counterCurrencyCode, // Suffix is the currency code
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a trigger price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Validate and update offer details
                          if (Form.of(context).validate()) {
                            final offersProvider =
                                Provider.of<OffersProvider>(context, listen: false);
                            await offersProvider.editOffer(
                              offerId: widget.offer.id,
                              marketPriceMarginPct: double.tryParse(_deviationController.text),
                              triggerPrice: _triggerPriceController.text,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Offer updated successfully!')),
                            );
                          }
                        },
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Cancel offer action
                          final offersProvider =
                              Provider.of<OffersProvider>(context, listen: false);
                          await offersProvider.cancelOffer(widget.offer.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Offer canceled')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.8), // Red color with opacity
                        ),
                        child: const Text('Cancel Offer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
