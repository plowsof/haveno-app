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
import 'package:haveno/profobuf_models.dart';
import 'package:haveno_app/views/screens/payment_account_detail_screen.dart';
import 'package:haveno_app/utils/payment_utils.dart';
import 'package:haveno_app/views/widgets/add_payment_method_form.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/payment_accounts_provider.dart';

class PaymentAccountsScreen extends StatefulWidget {
  const PaymentAccountsScreen({super.key});

  @override
  _PaymentAccountsScreenState createState() => _PaymentAccountsScreenState();
}

class _PaymentAccountsScreenState extends State<PaymentAccountsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Payment Accounts'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Fiat Accounts'),
            Tab(text: 'Crypto Accounts'),
          ],
        ),
      ),
      body: FutureBuilder<void>(
        future: fetchData(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildAccountList(context, PaymentMethodType.FIAT),
                _buildAccountList(context, PaymentMethodType.CRYPTO),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAccountForm(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> fetchData(BuildContext context) async {
    final paymentAccountsProvider = Provider.of<PaymentAccountsProvider>(context, listen: false);
    if (paymentAccountsProvider.paymentAccounts.isEmpty) {
      await paymentAccountsProvider.getPaymentAccounts();
    }
    if (paymentAccountsProvider.paymentMethods.isEmpty) {
      await paymentAccountsProvider.getPaymentMethods();
    }
    if (paymentAccountsProvider.cryptoCurrencyPaymentMethods.isEmpty) {
      await paymentAccountsProvider.getCryptoCurrencyPaymentMethods();
    }
  }

Widget _buildAccountList(BuildContext context, PaymentMethodType accountType) {
  final provider = Provider.of<PaymentAccountsProvider>(context, listen: false);

  if (provider.paymentAccounts.isEmpty) {
    return const Center(child: Text('No accounts available'));
  } else {
    final accounts = provider.paymentAccounts.where((account) {
      final methodType = getPaymentMethodType(account.paymentMethod.id);
      return methodType == accountType;
    }).toList();

    if (accounts.isEmpty) {
      return const Center(
        child: Text(
          'You do not currently have any accounts',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final account = accounts[index];
          var paymentMethodLabel = accountType.name == 'CRYPTO' 
              ? account.selectedTradeCurrency.name 
              : getPaymentMethodLabel(account.paymentMethod.id);
          print(accountType.name);
          return GestureDetector(
            onTap: () => _viewAccountDetails(account),
            child: Card(
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 2),
              color: Theme.of(context).cardTheme.color,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8), // Updated padding
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center, // Vertically center the row content
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '$paymentMethodLabel (${account.accountName})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.secondary.withOpacity(0.23)),
                      onPressed: () => _showDeleteConfirmationDialog(context, account),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }
}


  void _showCreateAccountForm(BuildContext context) {
    final isFiat = _tabController.index == 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return PaymentMethodSelectionForm(accountType: isFiat ? 'FIAT' : 'CRYPTO');
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, PaymentAccount account) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete this account?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                // Call the provider to delete the account
                //Provider.of<PaymentAccountsProvider>(context, listen: false).deletePaymentAccount(account.id);
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _viewAccountDetails(PaymentAccount account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentAccountDetailScreen(paymentAccount: account),
      ),
    );
  }
}
