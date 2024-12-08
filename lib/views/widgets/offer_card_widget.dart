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
import 'package:haveno_app/views/widgets/edit_trade_offer_form.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/views/screens/taker_offer_detail_screen.dart';
import 'package:haveno_app/providers/haveno_client_providers/offers_provider.dart';
 
class OfferCard extends StatelessWidget {
  final OfferInfo offer;

  const OfferCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return Consumer<OffersProvider>(
      builder: (context, offersProvider, child) {
        final bool isMyOffer =
            offersProvider.myOffers?.any((myOffer) => myOffer.id == offer.id) ?? false;
        final bool isBuy = offer.direction == 'SELL';

        String fromCurrencyDisplay;
        String toCurrencyDisplay;

        if (isMyOffer) {
          fromCurrencyDisplay = isBuy ? offer.baseCurrencyCode : offer.counterCurrencyCode;
          toCurrencyDisplay = isBuy ? offer.counterCurrencyCode : offer.baseCurrencyCode;
        } else {
          fromCurrencyDisplay = isBuy ? offer.counterCurrencyCode : offer.baseCurrencyCode;
          toCurrencyDisplay = isBuy ? offer.baseCurrencyCode : offer.counterCurrencyCode;
        }

        // Determine badge color and text based on offer status
        String badgeText;
        Color badgeColor;

        if (isMyOffer) {
          badgeText = offer.state == 'PENDING' ? 'Pending' : 'Active';
          badgeColor = offer.state == 'PENDING' ? Colors.blue : Colors.green;
        } else {
          badgeText = '';
          badgeColor = Colors.transparent; // No badge if it's not the user's offer
        }

        return GestureDetector(
          onTap: () {
            if (isMyOffer) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => EditTradeOfferForm(offer: offer),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OfferDetailScreen(offer: offer),
                ),
              );
            }
          },
          child: Stack(
            children: [
              Card(
                margin: const EdgeInsets.only(top: 1.0),
                color: Theme.of(context).cardTheme.color,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // No border radius
                ),
                elevation: 0, // No elevation
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              fromCurrencyDisplay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: Text(
                              offer.paymentMethodShortName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Text(
                              toCurrencyDisplay,
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          isFiatCurrency(offer.counterCurrencyCode)
                              ? '${double.parse(offer.price).toStringAsFixed(2)} ${offer.counterCurrencyCode}'
                              : offer.price,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: Text(
                          'Order limit: ${offer.minVolume} - ${offer.volume}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMyOffer)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(8)),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
}