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
import 'package:haveno_app/providers/haveno_client_providers/price_provider.dart';
import 'package:haveno_app/providers/haveno_providers/settings_provider.dart';

class ExchangeRateWidget extends StatelessWidget {
  const ExchangeRateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, PricesProvider>(
      builder: (context, settingsProvider, pricesProvider, child) {
        final preferredCurrency = settingsProvider.preferredCurrency ?? 'USD';
        final marketPrice = pricesProvider.prices.firstWhere(
          (price) => price.currencyCode == preferredCurrency,
          orElse: () => MarketPriceInfo(currencyCode: preferredCurrency, price: 0),
        );

        final currencyPair = 'XMR/$preferredCurrency';
        final value = "${formatFiat(marketPrice.price)} $preferredCurrency";

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: const Color(0xFF424242),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: const Color(0xFF2E2E2E),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 28.0,  // Match the height to the MoneroBalanceWidget height
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Center(
                  child: Text(
                    currencyPair,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6.0),
              Container(
                height: 28.0,  // Ensure consistent height
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A4A4A),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Center(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
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
