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
import 'package:flutter/material.dart';
import 'package:haveno_app/services/secure_storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SecureStorageService _secureStorageService;

  // Preferences
  String? _preferredLanguage;
  String? _country;
  String? _preferredCurrency;
  String? _blockchainExplorer;
  String? _maxDeviationFromMarketPrice;

  // Display Options
  bool _hideNonSupportedPaymentMethods = false;
  bool _sortMarketListsByNumberOfOffersTrades = false;
  bool _useDarkMode = false;
  bool _autoWithdrawToNewStealthAddress = false;

  // Supported currencies
  final List<String> _supportedCurrencies = [
    'CHF', 'MXN', 'CLP', 'ZAR', 'VND', 'AUD', 'ILS', 'IDR', 'TRY', 'AED', 'HKD', 'TWD', 'EUR', 'DKK',
    'BCH', 'CAD', 'MYR', 'MMK', 'NOK', 'GEL', 'BTC', 'LKR', 'NGN', 'CZK', 'PKR', 'SEK', 'LTC', 'UAH',
    'BHD', 'ARS', 'SAR', 'INR', 'CNY', 'THB', 'KRW', 'JPY', 'BDT', 'PLN', 'GBP', 'BMD', 'HUF', 'KWD',
    'PHP', 'RUB', 'USD', 'SGD', 'ETH', 'NZD', 'BRL'
  ];

  // Getters
  String? get preferredLanguage => _preferredLanguage;
  String? get country => _country;
  String? get preferredCurrency => _preferredCurrency;
  String? get blockchainExplorer => _blockchainExplorer;
  String? get maxDeviationFromMarketPrice => _maxDeviationFromMarketPrice;
  List<String> get supportedCurrencies => _supportedCurrencies;

  bool get hideNonSupportedPaymentMethods => _hideNonSupportedPaymentMethods;
  bool get sortMarketListsByNumberOfOffersTrades => _sortMarketListsByNumberOfOffersTrades;
  bool get useDarkMode => _useDarkMode;
  bool get autoWithdrawToNewStealthAddress => _autoWithdrawToNewStealthAddress;

  SettingsProvider(this._secureStorageService) {
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _preferredLanguage = await _secureStorageService.readSettingsPreferredLanguage();
    _country = await _secureStorageService.readSettingsCountry();
    _preferredCurrency = await _secureStorageService.readSettingsPreferredCurrency() ?? 'USD';
    _blockchainExplorer = await _secureStorageService.readSettingsBlockchainExplorer();
    _maxDeviationFromMarketPrice = await _secureStorageService.readSettingsMaxDeviationFromMarketPrice();

    _hideNonSupportedPaymentMethods = await _secureStorageService.readSettingsHideNonSupportedPaymentMethods() ?? false;
    _sortMarketListsByNumberOfOffersTrades = await _secureStorageService.readSettingsSortMarketListsByNumberOfOffersTrades() ?? false;
    _useDarkMode = await _secureStorageService.readSettingsUseDarkMode() ?? false;
    _autoWithdrawToNewStealthAddress = await _secureStorageService.readSettingsAutoWithdrawToNewStealthAddress() ?? false;

    notifyListeners();
  }

  // Setters
  Future<void> setPreferredLanguage(String languageCode) async {
    await _secureStorageService.writeSettingsPreferredLanguage(languageCode);
    _preferredLanguage = languageCode;
    notifyListeners();
  }

  Future<void> setCountry(String country) async {
    await _secureStorageService.writeSettingsCountry(country);
    _country = country;
    notifyListeners();
  }

  Future<void> setPreferredCurrency(String currencyCode) async {
    await _secureStorageService.writeSettingsPreferredCurrency(currencyCode);
    _preferredCurrency = currencyCode;
    notifyListeners();
  }

  Future<void> setBlockchainExplorer(String explorer) async {
    await _secureStorageService.writeSettingsBlockchainExplorer(explorer);
    _blockchainExplorer = explorer;
    notifyListeners();
  }

  Future<void> setMaxDeviationFromMarketPrice(String deviation) async {
    await _secureStorageService.writeSettingsMaxDeviationFromMarketPrice(deviation);
    _maxDeviationFromMarketPrice = deviation;
    notifyListeners();
  }

  Future<void> setHideNonSupportedPaymentMethods(bool value) async {
    await _secureStorageService.writeSettingsHideNonSupportedPaymentMethods(value);
    _hideNonSupportedPaymentMethods = value;
    notifyListeners();
  }

  Future<void> setSortMarketListsByNumberOfOffersTrades(bool value) async {
    await _secureStorageService.writeSettingsSortMarketListsByNumberOfOffersTrades(value);
    _sortMarketListsByNumberOfOffersTrades = value;
    notifyListeners();
  }

  Future<void> setUseDarkMode(bool value) async {
    await _secureStorageService.writeSettingsUseDarkMode(value);
    _useDarkMode = value;
    notifyListeners();
  }

  Future<void> setAutoWithdrawToNewStealthAddress(bool value) async {
    await _secureStorageService.writeSettingsAutoWithdrawToNewStealthAddress(value);
    _autoWithdrawToNewStealthAddress = value;
    notifyListeners();
  }
}