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
import 'package:haveno/haveno_client.dart';
import 'package:haveno/profobuf_models.dart';
import 'package:haveno_app/models/schema.dart';
import 'package:haveno_app/utils/database_helper.dart';

class PaymentAccountsProvider with ChangeNotifier, CooldownMixin {
  final HavenoChannel _havenoChannel;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<PaymentMethod> _paymentMethods = [];
  List<PaymentMethod> _cryptoCurrencyPaymentMethods = [];
  List<PaymentAccount> _paymentAccounts = [];
  final List<PaymentAccountForm> _paymentAccountForms = [];
  final Map<String, PaymentAccountForm_FormId> _paymentMethodIdToPaymentAccountFormIdMap = {};
  final Map<PaymentAccountForm_FormId, PaymentAccountForm> _paymentAccountFormIdToPaymentAccountFormMap = {};
  PaymentAccountsProvider(this._havenoChannel) {
    setCooldownDurations({
      'getPaymentAccounts': const Duration(minutes: 1), // 2 minutes cooldown for getOffers
    });
  }

  List<PaymentMethod> get paymentMethods => _paymentMethods;
  List<PaymentMethod> get cryptoCurrencyPaymentMethods => _cryptoCurrencyPaymentMethods;
  List<PaymentAccount> get paymentAccounts => _paymentAccounts;
  
  List<PaymentAccountForm>? get paymentAccountForms => _paymentAccountForms.isNotEmpty ? _paymentAccountForms : null;

  Future<List<PaymentMethod>?> getPaymentMethods() async {
    await _havenoChannel.onConnected;

    try {
      // Attempt to load payment methods from the local database
      _paymentMethods = await _databaseHelper.getAllPaymentMethods();
      
      if (_paymentMethods.isNotEmpty) {
        return _paymentMethods;
      }
    } catch (e) {
      print("Failed to load payment methods from the local database: $e");
    }

    // If the local database does not have the data, fetch it from the remote service
    try {
      final getPaymentMethodsReply = await _havenoChannel.paymentAccountsClient!
          .getPaymentMethods(GetPaymentMethodsRequest());
      _paymentMethods = getPaymentMethodsReply.paymentMethods;
      
      // Optionally, save the retrieved payment methods to the local database
      if (_paymentMethods.isNotEmpty) {
        for (var paymentMethod in _paymentMethods) {
          await _databaseHelper.insertPaymentMethod(paymentMethod);
        }
      }
    } catch (e) {
      print("Failed to get payment methods from the remote service: $e");
      rethrow;
    }

    return _paymentMethods;
  }

  Future<List<PaymentAccount>> getPaymentAccounts() async {
    await _havenoChannel.onConnected;
    if (await isCooldownValid('getPaymentAccounts')) {
      try {
        // Attempt to load payment accounts from the local database
        _paymentAccounts = await _databaseHelper.getAllPaymentAccounts();
        if (_paymentAccounts.isNotEmpty) {
          return _paymentAccounts;
        }
      } catch (e) {
        print("Failed to load payment accounts from the local database: $e");
      }
    } else {

      try {
        final getPaymentAccountsReply = await _havenoChannel
            .paymentAccountsClient!
            .getPaymentAccounts(GetPaymentAccountsRequest());
        _paymentAccounts = getPaymentAccountsReply.paymentAccounts;
        print("Found ${_paymentAccounts.length} payment accounts on the daemon, will try caching them...");
        updateCooldown('getPaymentAccounts');
      } catch (e) {
        updateCooldown('getPaymentAccounts');
        print("Failed to get payment accounts from daemon: $e");
        rethrow;
      }

      try {
        for (var paymentAccount in _paymentAccounts) {
          await _databaseHelper.insertPaymentAccount(paymentAccount);
        }
        print("Successfully synced ${_paymentAccounts.length} payment accounts from the daemon to local storage");
      } catch (e) {
        print("Could not add the payment accounts from the daemon to the local database: ${e.toString()}");
      }
      return _paymentAccounts;
    }
    return [];
  }
  

  Future<List<PaymentMethod>?> getCryptoCurrencyPaymentMethods() async {
    await _havenoChannel.onConnected;
    try {
      final getCryptoCurrencyPaymentMethodsReply = await _havenoChannel
          .paymentAccountsClient!
          .getCryptoCurrencyPaymentMethods(
              GetCryptoCurrencyPaymentMethodsRequest());
      _cryptoCurrencyPaymentMethods = getCryptoCurrencyPaymentMethodsReply.paymentMethods;
    } catch (e) {
      print("Failed to get payment accounts: $e");
    }
    return paymentMethods;
  }

  Future<PaymentAccountForm?> getPaymentAccountForm(String paymentMethodId) async {
    await _havenoChannel.onConnected;
    PaymentAccountForm? paymentAccountForm;
    bool didLoadFromDb = false;

    try {
      // Attempt to load payment account form from the local database
      paymentAccountForm = await _databaseHelper.getPaymentAccountFormByPaymentMethodId(paymentMethodId);
      if (paymentAccountForm != null) {
        didLoadFromDb = true;
        print("Loaded payment account form from local database for paymentMethod ID: $paymentMethodId.");
        return paymentAccountForm;
      }
    } catch (e) {
      print("Failed to load payment account form from the local database: $e");
    }

    if (!didLoadFromDb) {
      try {
        // Fetch from the remote service if not found locally
        final paymentAccountFormReply = await _havenoChannel.paymentAccountsClient!.getPaymentAccountForm(
          GetPaymentAccountFormRequest(paymentMethodId: paymentMethodId),
        );

        if (paymentAccountFormReply.hasPaymentAccountForm()) {
          paymentAccountForm = paymentAccountFormReply.paymentAccountForm;
          print("Loaded payment account form from remote service for paymentMethod ID: $paymentMethodId.");
          
          // Store the fetched form in the local database for future use
          await _databaseHelper.insertPaymentAccountForm(paymentMethodId, paymentAccountForm);

          // Add a delay to respect network cooldown limitations, but this needs improving #TODO CooldownManager, or
          // EVEN BETTER, remove cooldowns from the daemon completely, I'mm a
          await Future.delayed(const Duration(seconds: 4));
        } else {
          return null;
        }
      } catch (e) {
        print("Failed to get the payment form from remote service: $e");
        rethrow;
      }
    }

    return paymentAccountForm;
  }

  Future<List<PaymentAccountForm>?> getAllPaymentAccountForms() async {
    await _havenoChannel.onConnected;
    if (_paymentMethods.isEmpty) {
      _paymentMethods = (await getPaymentMethods())!;
    }

    for (var paymentMethod in _paymentMethods) {
      var paymentAccountForm = await getPaymentAccountForm(paymentMethod.id);
      if (paymentAccountForm == null) continue;

      if (!_paymentAccountForms.contains(paymentAccountForm)) {
        _paymentAccountForms.add(paymentAccountForm);
      }
    }

    print("There are currently ${(await _databaseHelper.getAllPaymentAccountForms())?.length ?? 'an unknown number of'} payment account forms in the database.");
    return _paymentAccountForms;
  }

  Future<PaymentAccount?> createPaymentAccount(String paymentMethodId, PaymentAccountForm form) async {
    await _havenoChannel.onConnected;
    try {
      notifyListeners();
      final createdPaymentAccount = await _havenoChannel.paymentAccountsClient!
          .createPaymentAccount(
              CreatePaymentAccountRequest(paymentAccountForm: form));
      var paymentAccount = createdPaymentAccount.paymentAccount;
      print("Created Payment Account: $paymentAccount");
      notifyListeners();
      return paymentAccount;
    } catch (e) {
      print("Failed to create payment account: $e");
      rethrow;
    }
  }
}

