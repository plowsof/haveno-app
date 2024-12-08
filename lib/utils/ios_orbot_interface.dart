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


/* import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OrbotApi {
  // Base URLs
  static const String _baseHttpsUrl = 'https://orbot.app/rc';
  static const String _baseSchemeUrl = 'orbot';

  // Launch a URL using the orbot scheme
  Future<void> _launchOrbotUri(String path, {String? query}) async {
    final uri = Uri(
      scheme: _baseSchemeUrl,
      path: path,
      query: query,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print("Could not launch Orbot URI: $uri");
    }
  }

  // Launch a URL using HTTPS as a fallback
  Future<void> _launchOrbotHttps(String path, {String? query}) async {
    final uri = Uri(
      scheme: 'https',
      host: 'orbot.app',
      path: '/rc/$path',
      query: query,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print("Could not launch Orbot HTTPS URL: $uri");
    }
  }

  // Shows the Orbot app
  Future<void> showOrbot() async {
    await _launchOrbotUri('show');
  }

  // Starts the Tor Network Extension via Orbot
  Future<void> startOrbot() async {
    await _launchOrbotUri('start');
  }

  // Shows the Orbot settings
  Future<void> showSettings() async {
    await _launchOrbotUri('show/settings');
  }

  // Shows the bridge configuration screen in Orbot
  Future<void> showBridges() async {
    await _launchOrbotUri('show/bridges');
  }

  // Shows the v3 Onion service authentication tokens in Orbot
  Future<void> showAuth() async {
    await _launchOrbotUri('show/auth');
  }

  // Adds a v3 Onion service authentication token in Orbot
  Future<void> addAuth({required String url, required String key}) async {
    final query = 'url=$url&key=$key';
    await _launchOrbotUri('add/auth', query: query);
  }

  // A fallback method that attempts to use HTTPS URLs instead of the Orbot scheme
  Future<void> showOrbotFallback() async {
    await _launchOrbotHttps('show');
  }

  Future<void> startOrbotFallback() async {
    await _launchOrbotHttps('start');
  }

  Future<void> showSettingsFallback() async {
    await _launchOrbotHttps('show/settings');
  }

  Future<void> showBridgesFallback() async {
    await _launchOrbotHttps('show/bridges');
  }

  Future<void> showAuthFallback() async {
    await _launchOrbotHttps('show/auth');
  }

  Future<void> addAuthFallback({required String url, required String key}) async {
    final query = 'url=$url&key=$key';
    await _launchOrbotHttps('add/auth', query: query);
  }
}
 */