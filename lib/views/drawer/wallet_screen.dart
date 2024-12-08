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
import 'package:flutter/services.dart';
import 'package:haveno/grpc_models.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/wallets_provider.dart';
import 'package:fixnum/fixnum.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletsScreenState createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletScreen> {

  @override
  void initState() {
    super.initState();
    final walletsProvider = context.read<WalletsProvider>();
    walletsProvider.getBalances();
    walletsProvider.getXmrPrimaryAddress();
    walletsProvider.getXmrTxs();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
      ),
      body: Center(
        child: Consumer<WalletsProvider>(
          builder: (context, walletsProvider, child) {
            if (walletsProvider.balances == null) {
              return const CircularProgressIndicator();
            } else {
              final balances = walletsProvider.balances!;
              return ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  if (balances.hasXmr()) _buildXmrBalanceCard('XMR', balances.xmr),
                  const SizedBox(height: 4.0),
                  _buildXmrAddressCard(walletsProvider.xmrPrimaryAddress),
                  const SizedBox(height: 4.0),
                  _buildXmrTransactionsList(walletsProvider.xmrTxs),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildXmrBalanceCard(String coin, XmrBalanceInfo balance) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Balances',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            Text('Available Balance: ${_formatXmr(balance.availableBalance)} XMR'),
            Text('Pending Balance: ${_formatXmr(balance.pendingBalance)} XMR'),
            const SizedBox(height: 10.0),
            Text('Reserved Offer Balance: ${_formatXmr(balance.reservedOfferBalance)} XMR'),
            Text('Reserved Trade Balance: ${_formatXmr(balance.reservedTradeBalance)} XMR'),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // handle deposit balance logic here
                    },
                    child: const Text('Send'),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // handle withdraw balance logic here
                    },
                    child: const Text('Receive'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXmrAddressCard(String? xmrAddress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: xmrAddress != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Addresses',
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          xmrAddress,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: xmrAddress));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Address copied to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You currently don\'t have an XMR address',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 10.0),
                  ElevatedButton(
                    onPressed: () {
                      // request a new XMR address here
                    },
                    child: const Text('Request a new address'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildXmrTransactionsList(List<XmrTx>? transactions) {
    if (transactions != null) {
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            transactions == null || transactions.isEmpty
                ? const Text('No transactions available')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final amounts = _getTransactionAmounts(tx);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _buildTransactionInfo(tx, amounts),
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                  Tooltip(
                                    message: _formatTimestamp(tx.timestamp.toInt()),
                                    child: Text(
                                      _formatDate(tx.timestamp.toInt()),
                                      style: const TextStyle(color: Colors.grey, fontSize: 14.0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: tx.hash));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Transaction ID copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  List<Int64> _getTransactionAmounts(XmrTx tx) {
    final List<Int64> amounts = <Int64>[];
    if (tx.hasOutgoingTransfer()) {
      amounts.add(Int64.parseInt(tx.outgoingTransfer.amount));
    }
    amounts.addAll(tx.incomingTransfers
        .map((transfer) => Int64.parseInt(transfer.amount)));
    return amounts;
  }

  String _buildTransactionInfo(XmrTx tx, List<Int64> amounts) {
    final amountString =
        amounts.map((amount) => '${_formatXmr(amount)} XMR').join(', ');
    final type = tx.hasOutgoingTransfer() ? 'Sent' : 'Received';
    return '$type $amountString';
  }

  String _formatXmr(Int64? atomicUnits) {
    if (atomicUnits == null) {
      return 'N/A';
    }
    return (atomicUnits.toInt() / 1e12).toStringAsFixed(5);
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(date);
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
