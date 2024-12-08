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


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:haveno_app/providers/haveno_client_providers/version_provider.dart';
import 'package:haveno_app/services/mobile_manager_service.dart';
import 'package:haveno_app/views/drawer/node_manager_screen.dart';
import 'package:haveno_app/views/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/views/drawer/link_to_mobile_screen.dart';
import 'package:haveno_app/views/drawer/payment_accounts_screen.dart';
import 'package:haveno_app/views/drawer/settings_screen.dart';
import 'package:haveno_app/views/drawer/wallet_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  _MainDrawerState createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  String _appVersion = 'Loading...';
  String? _daemonVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _fetchDaemonVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      print('Failed to load app version: $e'); // Log the error
      setState(() {
        _appVersion = 'Failed to load version';
      });
    }
  }


  Future<void> _fetchDaemonVersion() async {
    final versionProvider = Provider.of<GetVersionProvider>(context, listen: false);
    await versionProvider.fetchVersion();
    setState(() {
      _daemonVersion = versionProvider.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color(0xFF303030), // Header background color
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/haveno-logo.png',
                      height: 60,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet, color: Colors.white),
                  title: const Text('Wallet', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WalletScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_circle, color: Colors.white),
                  title: const Text('Payment Accounts', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PaymentAccountsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const FaIcon(
                    FontAwesomeIcons.monero,
                    color: Colors.white,
                    size: 18.0,  // Adjust icon size to fit within the height
                  ),
                  title: const Text('Nodes', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NodeManagerScreen()), // Make sure you replace this with your Nodes screen
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.white),
                  title: const Text('Settings', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                  },
                ),
                if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
                  ListTile(
                    leading: const Icon(Icons.sync, color: Colors.white),
                    title: const Text('Link to Mobile Device', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LinkToMobileScreen()),
                      );
                    },
                  ),
                if (Platform.isIOS || Platform.isAndroid)
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white),
                    title: const Text('Logout', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      _showLogoutConfirmation(context);
                    },
                  ),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Daemon Version: ${_daemonVersion ?? "Loading..."}',
            style: TextStyle(color: Colors.white.withOpacity(0.66)), // Adjust opacity
          ),
          Text(
            'App Version: $_appVersion',
            style: TextStyle(color: Colors.white.withOpacity(0.66)), // Adjust opacity
          ),
          const SizedBox(height: 8.0),
          _buildStatusRow('Tor Status', true), // Assume true is online, false is offline
          _buildStatusRow('Daemon Status', true),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isOnline) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: TextStyle(color: Colors.white.withOpacity(0.7)), // Adjust opacity
        ),
        Icon(
          Icons.circle,
          color: isOnline ? Colors.green : Colors.red,
          size: 12.0,
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('If you logout you will lose connection to your Haveno daemon which will require setup again, are you sure?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes, Logout'),
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) {
    final mobileManagerService = MobileManagerService();
    mobileManagerService.logout();
    // Navigate back to the initial setup screen or login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => OnboardingScreen()), // Replace with your initial setup screen
    );
  }
}
