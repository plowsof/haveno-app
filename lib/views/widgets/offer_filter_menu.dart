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
import 'package:dropdown_search/dropdown_search.dart';
import 'package:haveno_app/providers/haveno_client_providers/payment_accounts_provider.dart';
import 'package:haveno_app/utils/payment_utils.dart';
import 'package:provider/provider.dart';

class OfferFilterMenu extends StatefulWidget {
  final ValueChanged<List<String>>? onCurrenciesChanged;
  final ValueChanged<List<String>>? onPaymentMethodsChanged;

  const OfferFilterMenu({
    super.key,
    this.onCurrenciesChanged,
    this.onPaymentMethodsChanged,
  });

  @override
  _OfferFilterMenuState createState() => _OfferFilterMenuState();
}

class _OfferFilterMenuState extends State<OfferFilterMenu> {
  List<String> _selectedCurrencies = [];
  List<String> _selectedPaymentMethodIds = [];
  late Future<List<String>> _paymentMethodsFuture;

  @override
  void initState() {
    super.initState();
    _paymentMethodsFuture = _fetchPaymentMethods();
  }

  Future<List<String>> _fetchPaymentMethods() async {
    final paymentAccountsProvider = Provider.of<PaymentAccountsProvider>(context, listen: false);
    await paymentAccountsProvider.getPaymentMethods(); // Fetch payment methods
    return paymentAccountsProvider.paymentMethods.map((method) => method.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardTheme.color,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildDropdownSearchField(
            label: 'Currencies',
            items: getAllFiatCurrencies().toList(),
            selectedValues: _selectedCurrencies,
            onChanged: (values) {
              setState(() {
                _selectedCurrencies = values;
              });
              widget.onCurrenciesChanged?.call(values);
            },
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<String>>(
            future: _paymentMethodsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error loading payment methods');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('No payment methods available');
              } else {
                return _buildDropdownSearchField(
                  label: 'Payment Methods',
                  items: snapshot.data!,
                  selectedValues: _selectedPaymentMethodIds,
                  itemAsString: (String id) => getPaymentMethodLabel(id),
                  onChanged: (values) {
                    setState(() {
                      _selectedPaymentMethodIds = values;
                    });
                    widget.onPaymentMethodsChanged?.call(values);
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSearchField({
    required String label,
    required List<String> items,
    required List<String> selectedValues,
    required ValueChanged<List<String>> onChanged,
    String Function(String)? itemAsString,
  }) {
    return DropdownSearch<String>.multiSelection(
      key: Key(label), // Use a key to force rebuild
      items: items,
      selectedItems: selectedValues,
      itemAsString: itemAsString,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(6, 6, 3, 0),
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        ),
      ),
      dropdownBuilder: (context, selectedItems) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: selectedItems.map((item) {
              return DeletableChip(
                label: itemAsString?.call(item) ?? item,
                item: item,
                onDelete: () {
                  setState(() {
                    selectedItems.remove(item);
                  });
                  print(selectedItems.join(' '));
                  onChanged(List<String>.from(selectedValues));  // Trigger a UI rebuild
                },
              );
            }).toList(),
          ),
        );
      },
      dropdownButtonProps: const DropdownButtonProps(
        alignment: Alignment.center,
        color: Colors.white,
      ),
      popupProps: PopupPropsMultiSelection.modalBottomSheet(
        title: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        showSearchBox: true,
        modalBottomSheetProps: ModalBottomSheetProps(
          backgroundColor: Theme.of(context).primaryColor,
          barrierColor: Colors.black.withOpacity(0.5),
        ),
        searchFieldProps: TextFieldProps(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: InputDecoration(
            labelText: 'Search $label',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          ),
        ),
        listViewProps: const ListViewProps(
          padding: EdgeInsets.fromLTRB(0, 0, 8, 0),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class DeletableChip extends StatelessWidget {
  final String label;
  final String item;
  final VoidCallback onDelete;

  const DeletableChip({super.key, 
    required this.label,
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      padding: const EdgeInsets.all(0),
      backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.23),
      labelStyle: const TextStyle(color: Colors.white),
      deleteIconColor: Colors.white,
      onDeleted: onDelete,
    );
  }
}
