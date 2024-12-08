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
import 'package:haveno/haveno_client.dart';
import 'package:haveno/haveno_service.dart';

class AccountProvider with ChangeNotifier {
  final HavenoChannel _havenoChannel = HavenoChannel();

  bool? _accountExists;
  DateTime? _lastCreatedAccount;

  AccountProvider();

  bool? get accountExists => _accountExists;
  DateTime? get lastCreatedAccount => _lastCreatedAccount;

  Future<void> requestAccountExists() async {
    await _havenoChannel.onConnected;
    try {
      _accountExists = await AccountService().accountExists();
      _lastCreatedAccount = DateTime.now();
      notifyListeners();
    } catch (e) {
      print("Failed to check if account exists: $e");
    }
  }

  Future<void> sendCreateAccount(password) async {
    await _havenoChannel.onConnected;
    try {
      await AccountService().createAccount(password);
    } catch (e) {
      print("Error while creating account: $e");
      rethrow;
    }
  }
}

class PasswordProvider with ChangeNotifier {
  final HavenoChannel _havenoChannel;
  DateTime? _lastPasswordChange = DateTime.now();

  PasswordProvider(this._havenoChannel);

  DateTime? get lastPasswordChange => _lastPasswordChange;

  Future<void> sendChangePassword(oldPassword, newPassword) async {  
    await _havenoChannel.onConnected;
    try {
      await AccountService().changePassword(oldPassword, newPassword);
      _lastPasswordChange = DateTime.now();
      notifyListeners();
    } catch (e) {
      print("Error changing account password: $e");
      rethrow;
    }   
  }
}
