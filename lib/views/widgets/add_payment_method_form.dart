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
import 'package:haveno_app/utils/payment_utils.dart';
import 'package:haveno_app/views/widgets/add_payment_account_form.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/payment_accounts_provider.dart';// Import the utils file

class PaymentMethodSelectionForm extends StatefulWidget {
  final String accountType;

  const PaymentMethodSelectionForm({super.key, required this.accountType});

  @override
  _PaymentMethodSelectionFormState createState() =>
      _PaymentMethodSelectionFormState();
}

class _PaymentMethodSelectionFormState
    extends State<PaymentMethodSelectionForm> {
  String? _selectedPaymentMethod;

  @override
  Widget build(BuildContext context) {
    final paymentAccountsProvider =
        Provider.of<PaymentAccountsProvider>(context);
    final paymentMethods = widget.accountType == 'FIAT'
        ? paymentAccountsProvider.paymentMethods
        : paymentAccountsProvider.cryptoCurrencyPaymentMethods;

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Payment Method', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              items: paymentMethods.map((method) {
                return DropdownMenuItem<String>(
                  value: method.id,
                  child: Text(getPaymentMethodLabel(method.id)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value;
                });

                if (value != null) {
                  paymentAccountsProvider
                      .getPaymentAccountForm(value)
                      .then((form) {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return DynamicPaymentAccountForm(
                            paymentAccountForm: form!,
                            paymentMethodLabel: getPaymentMethodLabel(value),
                            paymentMethodId: value);
                      },
                    );
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a payment method';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
