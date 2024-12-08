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


import 'dart:async';
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flutter/material.dart';
import 'package:haveno/grpc_models.dart';
import 'package:haveno/haveno_client.dart';
import 'package:haveno/haveno_service.dart';
import 'package:haveno/profobuf_models.dart';
import 'package:haveno_app/models/schema.dart';
import 'package:haveno_app/utils/database_helper.dart';
import 'package:collection/collection.dart';

class TradesProvider with ChangeNotifier, CooldownMixin {
  final HavenoChannel _havenoChannel;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  TradeUpdateCallback? onTradeUpdate;
  NewChatMessageCallback? onNewChatMessage;
  List<TradeInfo> _trades = [];
  TradeInfo? _currentTrade;
  final Map<String, List<ChatMessage>> _chatMessages = {};
  final Map<String, DateTime> _estimatedConfirmationTimes = {};

  TradesProvider(this._havenoChannel) {
    setCooldownDurations({
      'getTrades':
          const Duration(seconds: 10), // 10 seconds cooldown for getTrades
      'getTrade': const Duration(seconds: 10)
    });
  }

  List<TradeInfo>? _newUnreadTrades;

  // Getters
  List<TradeInfo>? get newUnreadTrades => _newUnreadTrades;

  List<TradeInfo> get trades => _trades;
  List<TradeInfo> get activeTrades => _trades
      .where((trade) =>
          trade.state != 'SELLER_SENT_PAYMENT_RECEIVED_MSG' &&
          trade.state != 'SELLER_SAW_ARRIVED_PAYMENT_RECEIVED_MSG')
      .toList();
  List<TradeInfo>? get completedTrades => _trades
      .where((trade) =>
          trade.state == 'SELLER_SENT_PAYMENT_RECEIVED_MSG' ||
          trade.state == 'SELLER_SAW_ARRIVED_PAYMENT_RECEIVED_MSG')
      .toList();
  List<TradeInfo>? get cancelledTrades => _trades;
  List<TradeInfo>? get expiredTrades =>
      _trades.where((trade) => trade.disputeState == 'something').toList();
  List<TradeInfo>? get disputedTrades =>
      _trades.where((trade) => trade.disputeState != 'NO_DISPUTE').toList();
  TradeInfo? get currentTrade => _currentTrade;
  Map<String, List<ChatMessage>> get chatMessages => _chatMessages;
  Map<String, DateTime> get estimatedConfirmationTimes =>
      _estimatedConfirmationTimes;

  Future<void> getTrades() async {
    await _havenoChannel.onConnected;
    if (!await isCooldownValid('getTrades')) {
      await updateCooldown('getTrades');
      try {
        final tradesClient = TradesService();
        final fetchedTrades = await tradesClient.getTrades();

        // Deep compare the list of trades
        final tradesAreEqual =
            const DeepCollectionEquality().equals(_trades, fetchedTrades);

        if (!tradesAreEqual) {
          _trades = fetchedTrades!;

          // Insert or update trades in the database
          await _databaseHelper.insertTrades(
              fetchedTrades); // Assuming this handles insert or update
          notifyListeners();
        }
      } catch (e) {
        print("Failed to get trades: $e");
        rethrow;
      }
    } else {
      var tradesBefore = _trades;
      _trades = await _databaseHelper.getAllTrades();

      final tradesAreEqual =
          const DeepCollectionEquality().equals(tradesBefore, _trades);

      if (!tradesAreEqual) {
        notifyListeners();
      }
      print(
          "Returned ${_trades.length} trades from the server since cooldown is active");
    }
  }

  Future<void> getTrade(String tradeId) async {
    await _havenoChannel.onConnected;

    TradeInfo? existingTrade;

    // Check if the cooldown is valid
    if (!await isCooldownValid('getTrade')) {
      await updateCooldown('getTrade');
      try {
        final getTradeReply = await _havenoChannel.tradesClient!
            .getTrade(GetTradeRequest(tradeId: tradeId));
        final fetchedTrade = getTradeReply.trade;

        // Find the corresponding trade in the current list of trades
        try {
          existingTrade =
              _trades.firstWhere((trade) => trade.tradeId == tradeId);
        } catch (e) {
          print(
              "No existing trade for $tradeId, very odd we're fetching it? $e");
          existingTrade = null;
        }

        // Compare the existing trade with the fetched one
        if (!const DeepCollectionEquality()
            .equals(existingTrade, fetchedTrade)) {
          // Update the trade in the _trades list
          _trades = _trades
              .map((trade) => trade.tradeId == tradeId ? fetchedTrade : trade)
              .toList();

          // Update the trade in the database
          await _databaseHelper.insertTrade(
              fetchedTrade); // Assuming this handles insert or update
          onTradeUpdate?.call(fetchedTrade, false);
          // Update cooldown and notify listeners
          notifyListeners();
        }
      } catch (e) {
        print("Failed to get trade: $e");
      }
    } else {
      // If cooldown is active, fetch the trade from the database
      final tradeFromDb = await _databaseHelper.getTradeById(tradeId);

      if (tradeFromDb != null) {
        // Find the corresponding trade in the current list of trades
        try {
          existingTrade =
              _trades.firstWhere((trade) => trade.tradeId == tradeId);
        } catch (e) {
          existingTrade = null;
        }

        if (!const DeepCollectionEquality()
            .equals(existingTrade, tradeFromDb)) {
          // Update the _trades list and notify listeners if there's a change
          _trades = _trades.map((trade) {
            return trade.tradeId == tradeId ? tradeFromDb : trade;
          }).toList();

          notifyListeners();
        }
      }

      print(
          "Returned trade $tradeId from the database since cooldown is active");
    }
  }

  Future<TradeInfo?> takeOffer(
      String? offerId, String? paymentAccountId, fixnum.Int64 amount) async {
    await _havenoChannel.onConnected;
    try {
      final takeOfferReply = await _havenoChannel.tradesClient!.takeOffer(
          TakeOfferRequest(
              offerId: offerId,
              paymentAccountId: paymentAccountId,
              amount: amount));
      _currentTrade = takeOfferReply.trade;
      notifyListeners();
      return _currentTrade;
    } catch (e) {
      print("Failed to take offer: $e");
      rethrow;
    }
  }

  Future<void> sendChatMessage(String? tradeId, String? message) async {
    await _havenoChannel.onConnected;
    try {
      await _havenoChannel.tradesClient!.sendChatMessage(
          SendChatMessageRequest(tradeId: tradeId, message: message));
    } catch (e) {
      print("Failed to send trade chat message: $e");
      rethrow;
    }
  }

  Future<void> getChatMessages(String tradeId) async {
    await _havenoChannel.onConnected;
    try {
      final getChatMessagesReply = await _havenoChannel.tradesClient!
          .getChatMessages(GetChatMessagesRequest(tradeId: tradeId));
      _chatMessages[tradeId] = getChatMessagesReply.message;
      notifyListeners();
    } catch (e) {
      print("Failed to get trade chat messages: $e");
    }
  }

  Future<void> confirmPaymentSent(String tradeId) async {
    await _havenoChannel.onConnected;
    try {
      await _havenoChannel.tradesClient!
          .confirmPaymentSent(ConfirmPaymentSentRequest(tradeId: tradeId));
      await getTrade(tradeId);
      notifyListeners();
    } catch (e) {
      print("Failed to confirm payment sent: $e");
      rethrow;
    }
  }

  Future<void> confirmPaymentReceived(String tradeId) async {
    await _havenoChannel.onConnected;
    try {
      await _havenoChannel.tradesClient!.confirmPaymentReceived(
          ConfirmPaymentReceivedRequest(tradeId: tradeId));
      await getTrade(tradeId);
      notifyListeners();
    } catch (e) {
      print("Failed to confirm payment received: $e");
      rethrow;
    }
  }

  Future<void> completeTrade(String? tradeId) async {
    await _havenoChannel.onConnected;
    try {
      await _havenoChannel.tradesClient!
          .completeTrade(CompleteTradeRequest(tradeId: tradeId));
    } catch (e) {
      print("Failed to complete trade: $e");
      rethrow;
    }
  }

  Future<void> withdrawFunds(
      String? tradeId, String? address, String? memo) async {
    await _havenoChannel.onConnected;
    try {
      await _havenoChannel.tradesClient!.withdrawFunds(
          WithdrawFundsRequest(tradeId: tradeId, address: address, memo: memo));
    } catch (e) {
      print("Failed to withdraw funds from trade: $e");
      rethrow;
    }
  }

  // Used by the listener to add remote messages, dont use to post message to network
  void addChatMessage(ChatMessage chatMessage) {
    // Ensure the tradeId exists in the _chatMessages map
    if (_chatMessages.containsKey(chatMessage.tradeId)) {
      // Check if a message with the same UID already exists
      bool messageExists = _chatMessages[chatMessage.tradeId]!
          .any((msg) => msg.uid == chatMessage.uid);

      // If the message does not exist, add it to the list
      if (!messageExists) {
        _chatMessages[chatMessage.tradeId]!.add(chatMessage);
        onNewChatMessage?.call(chatMessage);
        notifyListeners();
      }
    } else {
      // If the tradeId does not exist, create a new entry
      _chatMessages[chatMessage.tradeId] = [chatMessage];
      onNewChatMessage?.call(chatMessage);
      notifyListeners();
    }
  }

  // Used by the listener
  void createOrUpdateTrade(TradeInfo trade) {
    // Find the index of the trade with the same tradeId in the _trades list
    final index = _trades
        .indexWhere((existingTrade) => existingTrade.tradeId == trade.tradeId);

    if (index != -1) {
      // If the trade exists, update it
      _trades[index] = trade;
    } else {
      // If the trade does not exist, add it to the list
      _trades.add(trade);
    }

    // Update the trade in the database
    _databaseHelper.insertTrade(trade);

    // Get deep trade
    getTrade(trade.tradeId);

    // Trigger the callback
    onTradeUpdate?.call(trade, !(index != -1));

    // Notify listeners that the trade list has been updated
    notifyListeners();
  }
}
