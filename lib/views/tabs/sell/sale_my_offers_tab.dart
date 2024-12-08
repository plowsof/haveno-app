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
import 'package:haveno_app/views/widgets/offer_card_widget.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/offers_provider.dart';

class SaleMyOffersTab extends StatelessWidget {
  const SaleMyOffersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final offersProvider = Provider.of<OffersProvider>(context, listen: false);

    Future<void> fetchData() async {
      if (offersProvider.offers == null || offersProvider.offers == []) {
        await offersProvider.getMyOffers();
      }
    }

    return FutureBuilder<void>(
      future: fetchData(), // Fetch offers
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final offers = offersProvider.mySellOffers;
          if (offers == null || offers.isEmpty) {
            return const Center(child: Text('No offers available'));
          } else {
            return Padding(
              padding: const EdgeInsets.only(
                  top: 2.0), // Add 2 pixels of padding at the top
              child: ListView.builder(
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  return OfferCard(offer: offer);
                },
              ),
            );
          }
        }
      },
    );
  }
}
