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
import 'package:haveno/haveno_service.dart';
import 'package:haveno_app/models/schema.dart';

class WalletsProvider with ChangeNotifier, CooldownMixin {
  final HavenoChannel _havenoChannel;
  final WalletsService _walletsService = WalletsService();
  BalancesInfo? _balances;
  List<XmrTx> _xmrTxs = [];
  String? _xmrPrimaryAddress;
  List<XmrIncomingTransfer> _xmrIncomingTransfers = [];
  List<XmrOutgoingTransfer> _xmrOutgoingTransfers = [];

  WalletsProvider(this._havenoChannel) {
    setCooldownDurations({
      'getBalances': const Duration(seconds: 15),
    });
  }

  BalancesInfo? get balances => _balances;
  String? get xmrPrimaryAddress => _xmrPrimaryAddress;
  List<XmrTx>? get xmrTxs => _xmrTxs;
  List<XmrIncomingTransfer> get xmrIncomingTransfers => _xmrIncomingTransfers;
  List<XmrOutgoingTransfer> get xmrOutgoingTransfers => _xmrOutgoingTransfers;

  Future<void> getBalances() async {
    await _havenoChannel.onConnected;
    if (!await isCooldownValid('getBalances')) {
      try {
        _balances = await _walletsService.getBalances();
        updateCooldown('getBalances');
        print("Loaded balances...");
        notifyListeners();
        return;
      } catch (e) {
        print("Failed to get balances: $e");
      }
    } else {
      print("Tried to get getBalances when cooldown is active");
      return;
    }
  }

  Future<void> getXmrPrimaryAddress() async {
    await _havenoChannel.onConnected;
    try {
      final getXmrPrimaryAddressReply = await _havenoChannel.walletsClient!
          .getXmrPrimaryAddress(GetXmrPrimaryAddressRequest());
      _xmrPrimaryAddress = getXmrPrimaryAddressReply.primaryAddress;
      print("Primary Address: $_xmrPrimaryAddress");
      notifyListeners();
    } catch (e) {
      print("Failed to get primary address: $e");
    }
  }

  Future<void> getXmrTxs() async {
    await _havenoChannel.onConnected;
    try {
      final getXmrTxsReply =
          await _havenoChannel.walletsClient!.getXmrTxs(GetXmrTxsRequest());
      _xmrTxs = getXmrTxsReply.txs;
      _xmrIncomingTransfers = [];
      _xmrOutgoingTransfers = [];

      for (var xmrTx in _xmrTxs) {
        _xmrIncomingTransfers.addAll(xmrTx.incomingTransfers);
        if (xmrTx.hasOutgoingTransfer()) {
          _xmrOutgoingTransfers.add(xmrTx.outgoingTransfer);
        }
      }

      notifyListeners();
    } catch (e) {
      print("Failed to get XMR transactions: $e");
    }
  }

  Future<void> createXmrTx(Iterable<XmrDestination> destinations) async {
    await _havenoChannel.onConnected;
    try {
      final createXmrTxsReply = await _havenoChannel.walletsClient!
          .createXmrTx(CreateXmrTxRequest(destinations: destinations));
      var tx = createXmrTxsReply.tx;
      // Check if tx with the same hash already exists
      bool exists = _xmrTxs.any((existingTx) => existingTx.hash == tx.hash);
      if (!exists) {
        _xmrTxs.add(tx);
        notifyListeners();
      }
    } catch (e) {
      print("Failed to create an XMR transaction: $e");
    }
  }

  Future<void> relayXmrTx(String metadata) async {
    await _havenoChannel.onConnected;
    try {
      await _havenoChannel.walletsClient!
          .relayXmrTx(RelayXmrTxRequest(metadata: metadata));
    } catch (e) {
      print("Error relaying transaciton: $e");
    }
  }

  Future<String?> getXmrSeed() async {
    await _havenoChannel.onConnected;
    try {
      final getXmrSeedReply =
          await _havenoChannel.walletsClient!.getXmrSeed(GetXmrSeedRequest());
      return getXmrSeedReply.seed;
    } catch (e) {
      print("Error getting seed phrase: $e");
      return null;
    }
  }

  Future<void> setWalletPassword(String newPassword, String? password) async {
    await _havenoChannel.onConnected;
    try {
      await _havenoChannel.walletsClient!.setWalletPassword(
          SetWalletPasswordRequest(
              password: password, newPassword: newPassword));
    } catch (e) {
      print("Error setting wallet password: $e");
    }
  }

  Future<void> lockWallet(String password) async {
    await _havenoChannel.onConnected;
    try {
      await _havenoChannel.walletsClient!.lockWallet(LockWalletRequest());
    } catch (e) {
      print("Error setting wallet password: $e");
    }
  }

  Future<void> unlockWallet(String password) async {
    await _havenoChannel.onConnected;
    try {
      await _havenoChannel.walletsClient!.unlockWallet(UnlockWalletRequest());
    } catch (e) {
      print("Error setting wallet password: $e");
    }
  }

  Future<void> removeWalletPassword(String password) async {
    await _havenoChannel.onConnected;
    try {
      await _havenoChannel.walletsClient!.removeWalletPassword(
          RemoveWalletPasswordRequest(password: password));
    } catch (e) {
      print("Error removing wallet password: $e");
    }
  }
}
