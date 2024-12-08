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
import 'package:provider/provider.dart';
import 'package:haveno_app/providers/haveno_providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            return ListView(
              children: [
                Card(
                  color: Theme.of(context).cardTheme.color,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preferences',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Language',
                            border: OutlineInputBorder(),
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          value: settingsProvider.preferredLanguage,
                          items: ['English', 'Spanish', 'French']
                              .map((language) => DropdownMenuItem(
                                    value: language,
                                    child: Text(language),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              settingsProvider.setPreferredLanguage(value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            border: OutlineInputBorder(),
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          value: settingsProvider.country,
                          items: ['USA', 'Canada', 'UK']
                              .map((country) => DropdownMenuItem(
                                    value: country,
                                    child: Text(country),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              settingsProvider.setCountry(value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Preferred Currency',
                            border: OutlineInputBorder(),
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          value: settingsProvider.preferredCurrency,
                          items: (settingsProvider.supportedCurrencies..sort())
                              .map((currency) => DropdownMenuItem(
                                    value: currency,
                                    child: Text(currency),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              settingsProvider.setPreferredCurrency(value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Blockchain Explorer',
                            border: OutlineInputBorder(),
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          value: settingsProvider.blockchainExplorer,
                          items: ['Haveno.com', 'MoneroExplorer.com']
                              .map((explorer) => DropdownMenuItem(
                                    value: explorer,
                                    child: Text(explorer),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              settingsProvider.setBlockchainExplorer(value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Max Deviation from Market Price',
                            border: OutlineInputBorder(),
                            labelStyle: TextStyle(color: Colors.white),
                            suffixText: '%',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            settingsProvider.setMaxDeviationFromMarketPrice(value);
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text(
                            'Trade Payout Automatically Withdraws to New Stealth Address',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: settingsProvider.autoWithdrawToNewStealthAddress,
                          onChanged: (value) {
                            settingsProvider.setAutoWithdrawToNewStealthAddress(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Card(
                  color: Theme.of(context).cardTheme.color,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Display Options',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text(
                            'Hide Non-Supported Payment Methods',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: settingsProvider.hideNonSupportedPaymentMethods,
                          onChanged: (value) {
                            settingsProvider.setHideNonSupportedPaymentMethods(value);
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text(
                            'Sort Market Lists by Number of Offers/Trades',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: settingsProvider.sortMarketListsByNumberOfOffersTrades,
                          onChanged: (value) {
                            settingsProvider.setSortMarketListsByNumberOfOffersTrades(value);
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text(
                            'Use Dark Mode',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: settingsProvider.useDarkMode,
                          onChanged: (value) {
                            settingsProvider.setUseDarkMode(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
