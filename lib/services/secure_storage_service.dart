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


import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:haveno_app/models/haveno/p2p/haveno_seednode.dart';
import 'package:haveno_app/models/haveno_daemon_config.dart';
import 'package:haveno_app/models/tor/hsv3_onion_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();

  // Factory constructor to return the same instance every time
  factory SecureStorageService() {
    return _instance;
  }

  SecureStorageService._internal(); // Private constructor for singleton

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // Should basically never used this, so dont... unless it's like temporary
  Future<void> init() async {
    // Initialize anything here if needed
  }

  Future<void> writeUserPassword(String userPassword) async {
    try {
      final prefs = await _prefs;
      await prefs.setString('user_password', userPassword);
    } catch (e) {
      print("Failed to set user password: $e");
      rethrow;
    }
  }

  Future<String?> readUserPassword() async {
    try {
      final prefs = await _prefs;
      return prefs.getString('user_password');
    } catch (e) {
      print("Failed to read user password: $e");
      rethrow;
    }
  }

  // Preferred Language
  Future<void> writeSettingsPreferredLanguage(String languageCode) async {
    try {
      final prefs = await _prefs;
      await prefs.setString('settings.preferred_language', languageCode);
    } catch (e) {
      print("Failed to set preferred language: $e");
      rethrow;
    }
  }

  Future<String?> readSettingsPreferredLanguage() async {
    try {
      final prefs = await _prefs;
      return prefs.getString('settings.preferred_language');
    } catch (e) {
      print("Failed to get preferred language: $e");
      rethrow;
    }
  }

  // Country
  Future<void> writeSettingsCountry(String country) async {
    try {
      final prefs = await _prefs;
      await prefs.setString('settings.country', country);
    } catch (e) {
      print("Failed to set country: $e");
      rethrow;
    }
  }

  Future<String?> readSettingsCountry() async {
    try {
      final prefs = await _prefs;
      return prefs.getString('settings.country');
    } catch (e) {
      print("Failed to get country: $e");
      rethrow;
    }
  }

  // Preferred Currency
  Future<void> writeSettingsPreferredCurrency(String currencyCode) async {
    try {
      final prefs = await _prefs;
      await prefs.setString('settings.preferred_currency', currencyCode);
    } catch (e) {
      print("Failed to set preferred currency: $e");
      rethrow;
    }
  }

  Future<String?> readSettingsPreferredCurrency() async {
    try {
      final prefs = await _prefs;
      return prefs.getString('settings.preferred_currency');
    } catch (e) {
      print("Failed to get preferred currency: $e");
      rethrow;
    }
  }

  // Blockchain Explorer
  Future<void> writeSettingsBlockchainExplorer(String explorer) async {
    try {
      final prefs = await _prefs;
      await prefs.setString('settings.blockchain_explorer', explorer);
    } catch (e) {
      print("Failed to set blockchain explorer: $e");
      rethrow;
    }
  }

  Future<String?> readSettingsBlockchainExplorer() async {
    try {
      final prefs = await _prefs;
      return prefs.getString('settings.blockchain_explorer');
    } catch (e) {
      print("Failed to get blockchain explorer: $e");
      rethrow;
    }
  }

  // Max Deviation from Market Price
  Future<void> writeSettingsMaxDeviationFromMarketPrice(
      String deviation) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(
          'settings.max_deviation_from_market_price', deviation);
    } catch (e) {
      print("Failed to set max deviation from market price: $e");
      rethrow;
    }
  }

  Future<String?> readSettingsMaxDeviationFromMarketPrice() async {
    try {
      final prefs = await _prefs;
      return prefs.getString('settings.max_deviation_from_market_price');
    } catch (e) {
      print("Failed to get max deviation from market price: $e");
      rethrow;
    }
  }

  // Hide Non-Supported Payment Methods
  Future<void> writeSettingsHideNonSupportedPaymentMethods(bool value) async {
    try {
      final prefs = await _prefs;
      await prefs.setBool('settings.hide_non_supported_payment_methods', value);
    } catch (e) {
      print("Failed to set hide non-supported payment methods: $e");
      rethrow;
    }
  }

  Future<bool?> readSettingsHideNonSupportedPaymentMethods() async {
    try {
      final prefs = await _prefs;
      return prefs.getBool('settings.hide_non_supported_payment_methods');
    } catch (e) {
      print("Failed to get hide non-supported payment methods: $e");
      rethrow;
    }
  }

  // Sort Market Lists by Number of Offers/Trades
  Future<void> writeSettingsSortMarketListsByNumberOfOffersTrades(
      bool value) async {
    try {
      final prefs = await _prefs;
      await prefs.setBool(
          'settings.sort_market_lists_by_number_of_offers_trades', value);
    } catch (e) {
      print("Failed to set sort market lists by number of offers/trades: $e");
      rethrow;
    }
  }

  Future<bool?> readSettingsSortMarketListsByNumberOfOffersTrades() async {
    try {
      final prefs = await _prefs;
      return prefs
          .getBool('settings.sort_market_lists_by_number_of_offers_trades');
    } catch (e) {
      print("Failed to get sort market lists by number of offers/trades: $e");
      rethrow;
    }
  }

  // Use Dark Mode
  Future<void> writeSettingsUseDarkMode(bool value) async {
    try {
      final prefs = await _prefs;
      await prefs.setBool('settings.use_dark_mode', value);
    } catch (e) {
      print("Failed to set use dark mode: $e");
      rethrow;
    }
  }

  Future<bool?> readSettingsUseDarkMode() async {
    try {
      final prefs = await _prefs;
      return prefs.getBool('settings.use_dark_mode');
    } catch (e) {
      print("Failed to get use dark mode: $e");
      rethrow;
    }
  }

  // Auto Withdraw to New Stealth Address
  Future<void> writeSettingsAutoWithdrawToNewStealthAddress(bool value) async {
    try {
      final prefs = await _prefs;
      await prefs.setBool(
          'settings.auto_withdraw_to_new_stealth_address', value);
    } catch (e) {
      print("Failed to set auto withdraw to new stealth address: $e");
      rethrow;
    }
  }

  Future<bool?> readSettingsAutoWithdrawToNewStealthAddress() async {
    try {
      final prefs = await _prefs;
      return prefs.getBool('settings.auto_withdraw_to_new_stealth_address');
    } catch (e) {
      print("Failed to get auto withdraw to new stealth address: $e");
      rethrow;
    }
  }

  Future<void> writeOnboardingStatus(bool completed) async {
    try {
      final prefs = await _prefs;
      await prefs.setBool('onboarding_completed', completed);
    } catch (e) {
      print("Failed to set onboarding status: $e");
      rethrow;
    }
  }

  Future<bool?> readOnboardingStatus() async {
    try {
      final prefs = await _prefs;
      return prefs.getBool('onboarding_completed');
    } catch (e) {
      print("Failed to get onboarding status: $e");
      rethrow;
    }
  }

  Future<void> writePids(List<int> pids) async {
    try {
      final prefs = await _prefs;
      await prefs.setString('pids', jsonEncode(pids));
    } catch (e) {
      print('Error writing pids: $e');
    }
  }

  Future<List<int>> readPids() async {
    try {
      final prefs = await _prefs;
      final pidsString = prefs.getString('pids');
      if (pidsString != null) {
        List<dynamic> pidsDynamic = jsonDecode(pidsString);
        List<int> pids = pidsDynamic.cast<int>();
        return pids;
      }
    } catch (e) {
      print('Error reading pids: $e');
    }
    return [];
  }

  // Desktop Only Methods
  Future<bool> writeDesktopClientHiddenServiceConfig(
      HSV3OnionConfig hiddenServiceConfig) async {
    if (!_isDesktopPlatform()) {
      print("This method is only available on desktop platforms.");
      return false;
    }
    try {
      final prefs = await _prefs;
      await prefs.setString('desktop_client_hidden_service_config',
          jsonEncode(hiddenServiceConfig.toJson()));
      return true;
    } catch (e) {
      print("Failed to write desktop client hidden service config: $e");
      rethrow;
    }
  }

  Future<HSV3OnionConfig?> readDesktopClientHiddenServiceConfig() async {
    if (!_isDesktopPlatform()) {
      final prefs = await _prefs;
      final jsonString =
          prefs.getString('desktop_client_hidden_service_config');
      if (jsonString == null) return null;
      final jsonMap = jsonDecode(jsonString);
      return HSV3OnionConfig.fromJson(jsonMap);
    }
    return null;
  }

  // Desktop Only Methods
  Future<String?> writeHavenoDaemonPassword(String password) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(
          'desktop_generated_haveno_daemon_password', password);
      return password;
    } catch (e) {
      print("Failed to write daemon password: $e");
      rethrow;
    }
  }

  Future<String?> readHavenoDaemonPassword() async {
    try {
      final prefs = await _prefs;
      var value = prefs.getString('desktop_generated_haveno_daemon_password');
      return (value != null && value.isNotEmpty) ? value : null;
    } catch (e) {
      print("Failed to read daemon password: $e");
      rethrow;
    }
  }

  // Mobile Only Methods
  Future<void> writeHavenoDaemonConfig(HavenoDaemonConfig config,
      {String? identifier}) async {
    try {
      final prefs = await _prefs;
      final key = identifier ?? 'default_haveno_daemon';
      await prefs.setString(key, jsonEncode(config.toJson()));
    } catch (e) {
      print("Failed to write daemon config: $e");
      rethrow;
    }
  }

  Future<HavenoDaemonConfig?> readHavenoDaemonConfig(
      {String? identifier}) async {
    try {
      final prefs = await _prefs;
      final key = identifier ?? 'default_haveno_daemon';
      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;
      final jsonMap = jsonDecode(jsonString);
      return HavenoDaemonConfig.fromJson(jsonMap);
    } catch (e) {
      print("Failed to read daemon config: $e");
      rethrow;
    }
  }

  Future<void> deleteHavenoDaemonConfig({String? identifier}) async {
    try {
      final prefs = await _prefs;
      final key = identifier ?? 'default_haveno_daemon';
      await prefs.remove(key);
    } catch (e) {
      print("Failed to delete daemon config: $e");
      rethrow;
    }
  }


  Future<List<HavenoSeedNode>> readHavenoSeedNodes() async {
    final prefs = await SharedPreferences.getInstance();
    final serializedNodes = prefs.getStringList('seed_nodes');

    if (serializedNodes == null) {
      return [];
    }

    return serializedNodes.map((node) {
      final jsonData = jsonDecode(node);
      return HavenoSeedNode.fromJson(jsonData);
    }).toList();
  }

  Future<void> writeHavenoSeedNodes(List<HavenoSeedNode> nodes) async {
    final prefs = await SharedPreferences.getInstance();
    final serializedNodes = nodes.map((node) => jsonEncode(node.toJson())).toList();
    await prefs.setStringList('seed_nodes', serializedNodes);
  }

  Future<List<String>> listDaemonOnionKeys() async {
    try {
      final prefs = await _prefs;
      final allKeys = prefs.getKeys();
      return allKeys.where((key) => key.contains('daemon_onion')).toList();
    } catch (e) {
      print("Failed to list daemon onion keys: $e");
      rethrow;
    }
  }

  Future<void> deleteDaemonOnion({String? identifier}) async {
    try {
      final prefs = await _prefs;
      final key = identifier ?? 'default_daemon_onion';
      await prefs.remove(key);
    } catch (e) {
      print("Failed to delete daemon onion: $e");
      rethrow;
    }
  }

  Future<void> writeConnectionStatus({String? identifier}) async {
    try {
      final prefs = await _prefs;
      final key = identifier ?? 'default_connection_status';
      await prefs.remove(key);
    } catch (e) {
      print("Failed to delete connection status: $e");
      rethrow;
    }
  }

  Future<void> readConnectionStatus() async {
    try {
      final prefs = await _prefs;
      const key = 'connection_status';
      prefs.getString(key);
    } catch (e) {
      print("Failed to read connection status: $e");
      rethrow;
    }
  }

  Future<void> deleteAll() async {
    try {
      final prefs = await _prefs;
      prefs.clear();
    } catch (e) {
      print("Failed to destory all shared preferences: $e");
    }
  }

  bool _isDesktopPlatform() {
    return kIsWeb ||
        [TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.macOS]
            .contains(defaultTargetPlatform);
  }
}
