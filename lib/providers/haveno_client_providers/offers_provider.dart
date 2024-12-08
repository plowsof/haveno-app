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


import 'dart:async';  // Import the async library for Timer
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:haveno/grpc_models.dart';
import 'package:haveno/haveno_client.dart';
import 'package:haveno_app/models/schema.dart';
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:haveno_app/utils/database_helper.dart';

class OffersProvider with ChangeNotifier, CooldownMixin {
  final HavenoChannel _havenoChannel;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<OfferInfo> _offers = [];
  OfferInfo? _lastCreatedOffer;
  String? _lastCancelledOfferId;
  List<OfferInfo> _myOffers = []; // Timer to periodically call getOffers

  OffersProvider(this._havenoChannel) {
    setCooldownDurations({
      'getOffers': const Duration(minutes: 1), // 2 minutes cooldown for getOffers
      'getMyOffers': const Duration(minutes: 2), // 2 minutes seconds cooldown for getMyOffers
    });
  }

  List<OfferInfo>? get offers => _offers;
  List<OfferInfo>? get marketBuyOffers =>
      _offers.where((offer) => offer.direction == 'SELL' && !offer.isMyOffer).toList();
  List<OfferInfo>? get marketSellOffers =>
      _offers.where((offer) => offer.direction == 'BUY' && !offer.isMyOffer).toList();
  OfferInfo? get lastCreatedOffer => _lastCreatedOffer;
  String? get lastCancelledOffer => _lastCancelledOfferId;
  List<OfferInfo>? get myOffers => _myOffers;
  List<OfferInfo>? get mySellOffers =>
      _myOffers.where((offer) => offer.direction == 'SELL' && offer.isMyOffer).toList(); // It's reversed because if an offer is your own, then it's not a sell offer to you
  List<OfferInfo>? get myBuyOffers =>
      _myOffers.where((offer) => offer.direction == 'BUY' && offer.isMyOffer).toList(); // It's reversed because if an offer is your own, then it's not a buy offer to you


  Future<void> getAllOffers() async {
    await _havenoChannel.onConnected;
    await getOffers();
    await Future.delayed(const Duration(seconds: 3));
    await getMyOffers();
  }

Future<List<OfferInfo>> getOffers() async {
  await _havenoChannel.onConnected;

  // Check if the cooldown has expired, if so, fetch from server
  if (!await isCooldownValid('getOffers')) {
    try {
      // Fetch from the server
      final getOffersReply = await _havenoChannel.offersClient!.getOffers(GetOffersRequest());
      final fetchedOffers = getOffersReply.offers;

      if (fetchedOffers.isEmpty) {
        await _databaseHelper.deleteOffers(null, isMyOffer: false);
        return [];
      }
        
      // Save to local database and update the local cache
      _offers = fetchedOffers;
      List<OfferInfo> peerTradeOffers = [];
      for (var offer in fetchedOffers) {
        if (offer.hasIsMyOffer() && offer.isMyOffer != true) {
          offer.isMyOffer = false;
        }
        peerTradeOffers.add(offer);
      }
      print("Returning ${fetchedOffers.length} offers from peers found on the daemon");

      await _databaseHelper.deleteOffers(null, isMyOffer: false);
      await _databaseHelper.insertOffers(peerTradeOffers);

      updateCooldown('getOffers'); // Update the cooldown after fetching
      notifyListeners(); // Notify listeners if applicable
      return _offers;
    } catch (e) {
      updateCooldown('getOffers');
      print("Failed to fetch peer offers from server: $e");
    }
  }

  // If cooldown is active or no offers were fetched, return offers from the database or cache
  if (_offers.isEmpty) {
    _offers = await _databaseHelper.getOffers();
    print("Returning ${_offers.length} of my own offers from the local database.");
  } else {
    print("Returning ${_offers.length} of my own offers from cache due to cooldown.");
  }

  notifyListeners(); // Notify listeners if applicable
  return _offers;
}

  Future<List<OfferInfo>> getMyOffers() async {
    await _havenoChannel.onConnected;

    // Check if cooldown has expired, if so, fetch from server
    if (!await isCooldownValid('getMyOffers')) {
      // Fetch from the server
      final getMyOffersReply = await _havenoChannel.offersClient!.getMyOffers(GetMyOffersRequest());
      _myOffers = getMyOffersReply.offers;
      updateCooldown('getMyOffers');

      if (_myOffers.isNotEmpty) {
        // Save to local database
        List<OfferInfo> myTradeOffers = [];
        try {
          for (var myOffer in _myOffers) {
            myOffer.isMyOffer = true;
            myTradeOffers.add(myOffer);
          }
        print("Returning ${_myOffers.length} of my own offers requested from the daemon.");

          await _databaseHelper.deleteOffers(null, isMyOffer: true);
          await _databaseHelper.insertOffers(myTradeOffers);
        } catch (e) {
          updateCooldown('getMyOffers');
          print("Failed to save one or more of my own offers from the daemon locally to DB: ${e.toString()}");
        }
      } else {
        print("None of my own offers found on daemon...");
      }
    } else {
      print("Returning ${_myOffers.length} my own offers from the database or cache due to cooldown");
    }

    // Return the offers, whether fetched or from the cache
    return _myOffers;
  }

  Future<void> postOffer({
    required String currencyCode,
    required String direction,
    required String price,
    required bool useMarketBasedPrice,
    double? marketPriceMarginPct,
    required fixnum.Int64 amount,
    required fixnum.Int64 minAmount,
    required double buyerSecurityDepositPct,
    String? triggerPrice,
    required bool reserveExactAmount,
    required String paymentAccountId,
  }) async {
    try {
      final postOfferResponse = await _havenoChannel.offersClient!.postOffer(
        PostOfferRequest(
          currencyCode: currencyCode,
          direction: direction,
          price: price,
          useMarketBasedPrice: useMarketBasedPrice,
          marketPriceMarginPct: marketPriceMarginPct,
          amount: amount,
          minAmount: minAmount,
          buyerSecurityDepositPct: buyerSecurityDepositPct,
          triggerPrice: triggerPrice,
          reserveExactAmount: reserveExactAmount,
          paymentAccountId: paymentAccountId,
        ),
      );
      final postedOffer = postOfferResponse.offer;
      postedOffer.isMyOffer = true;
      debugPrint(postedOffer.state);
      debugPrint("IsActive = postedOffer.isActivated");
      _lastCreatedOffer = postedOffer;
      _myOffers.add(postedOffer);
      await _databaseHelper.insertOffer(postedOffer);
      notifyListeners();
    } on GrpcError catch (e) {
      print("Failed to post offer: $e");
      rethrow;
    }
  }

  Future<void> cancelOffer(String offerId) async {
    try {
      await _havenoChannel.onConnected;

      await _havenoChannel.offersClient
          !.cancelOffer(CancelOfferRequest(id: offerId));
      _lastCancelledOfferId = offerId;
      _myOffers.removeWhere((offer) => offer.id == offerId);
      notifyListeners();
    } catch (e) {
      print("Failed to cancel offer: $e");
      rethrow;
    }
  }

  Future<void> editOffer({required String offerId, double? marketPriceMarginPct, String? triggerPrice}) async {
    await _havenoChannel.onConnected;
    try {
      //not implemented at daemon
    } catch(e) {
      //not implemented at daemon
    }
  }

  String offerToString(OfferInfo offer) {
    return 'Offer(id: ${offer.id}, direction: ${offer.direction}, price: ${offer.price}, amount: ${offer.amount}, minAmount: ${offer.minAmount}, volume: ${offer.volume}, minVolume: ${offer.minVolume}, baseCurrencyCode: ${offer.baseCurrencyCode}, date: ${offer.date}, state: ${offer.state}, paymentAccountId: ${offer.paymentAccountId}, paymentMethodId: ${offer.paymentMethodId})';
  }
}
