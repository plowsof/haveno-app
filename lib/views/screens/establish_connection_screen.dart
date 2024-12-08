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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:haveno_app/providers/haveno_client_providers/disputes_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/offers_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/payment_accounts_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/price_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/trades_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/wallets_provider.dart';
import 'package:haveno_app/services/connection_checker_service.dart';
import 'package:haveno_app/views/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class EstablishConnectionScreen extends StatefulWidget {
  const EstablishConnectionScreen({super.key});

  @override
  _EstablishConnectionScreenState createState() =>
      _EstablishConnectionScreenState();
}

class _EstablishConnectionScreenState
    extends State<EstablishConnectionScreen> {
  bool orbotMessageShown = false;
  String message = "Connecting to Tor...";
  double progress = 0.0; // Progress value
  bool _isTorConnected = false; // Track whether Tor is connected
  int failedAttempts = 0;
  Timer? connectionTimer; 
  bool isCheckingConnection = false; // To ensure only one connection check at a time
  final _connectionCheckerService = ConnectionCheckerService();

  @override
  void initState() {
    super.initState();
    _checkTorConnection();
  }



  Future<void> _checkTorConnection() async {
    connectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (isCheckingConnection) return; // Skip if a check is already in progress

      isCheckingConnection = true; // Mark as checking connection
      try {
        _isTorConnected = await _connectionCheckerService.isTorConnected();
        if (_isTorConnected) {
          setState(() {
            message = "Connecting to Daemon...";
            _isTorConnected = true; // Mark Tor as connected
          });
          timer.cancel(); // Stop further attempts
          await _initializeProvidersSequentially();
        } else {
          failedAttempts++;
          if (failedAttempts >= 10 && !orbotMessageShown) {
            _showOrbotDownloadMessage();
            orbotMessageShown = true;
          }
        }
      } catch (e) {
        print("Error checking Tor connection: $e");
      } finally {
        isCheckingConnection = false; // Reset the flag after check
      }
    });
  }

  Future<void> _initializeProvidersSequentially() async {
    if (_isTorConnected) {
      while (!await _connectionCheckerService.isHavenoDaemonConnected()) {
        await Future.delayed(const Duration(seconds: 1));
      }

      await Future.delayed(const Duration(seconds: 10));

      // Total steps
      const int totalSteps = 9;
      int currentStep = 0;

      // Initialize each provider sequentially with retry logic
      await _initializeProviderWithRetry(_initializePaymentMethods, "Fetching Payment Methods...", totalSteps, ++currentStep);
      await _initializeProviderWithRetry(_initializeOffers, "Fetching Offers...", totalSteps, ++currentStep);
      await _initializeProviderWithRetry(_initializeDisputes, "Fetching Integrity Profile...", totalSteps, ++currentStep);
      await _initializeProviderWithRetry(_initializeTrades, "Fetching Trades...", totalSteps, ++currentStep);
      _initializeProviderWithRetry(_initializePrices, "Fetching Market Prices...", totalSteps, ++currentStep);
      await _initializeProviderWithRetry(_initializePaymentAccounts, "Fetching Payment Accounts...", totalSteps, ++currentStep);
      await _initializeProviderWithRetry(_initializePaymentAccountForms, "Fetching Payment Accounts...", totalSteps, ++currentStep);
      await _initializeProviderWithRetry(_initializeWallets, "Wallet Initializing...", totalSteps, ++currentStep);
      await _initializeProviderWithRetry(_initializePrimaryWalletAddress, 'Retrieving Primary Wallet Address...', totalSteps, ++currentStep);

      _navigateToHomeScreen();

    } else {
      setState(() {
        message = "Tor connection failed.";
      });
      print("Tor connection failed.");
    }
  }

    Future<void> _initializeProviderWithRetry(
      Future<void> Function() initializeFunction, String initializationMessage, int totalSteps, int currentStep) async {
    bool success = false;
    while (!success) {
      try {
        setState(() {
          message = initializationMessage;
          progress = currentStep / totalSteps; // Update progress
        });

        // Add a delay before each initialization
        await Future.delayed(const Duration(seconds: 2));

        await initializeFunction();
        success = true; // If successful, exit the loop
      } on GrpcError catch (e) {
        final errorString = e.toString();
        if (errorString.contains("wallet and network is not yet") || errorString.contains("wallet is not yet")) {
          setState(() {
            message = "Wallet Initializing...";
          });
          print("Wallet not initialized. Retrying...");
        } else if (errorString.contains("Connection refused") || errorString.contains("the maximum allowed number")) {
          setState(() {
            message = "Connecting to Daemon...";
          });
          print("Connection refused. Retrying...");
        } else {
          setState(() {
            message = "Error: ${e.toString()}";
          });
          print("${e.message}");
        }
        await Future.delayed(const Duration(seconds: 5));
      } catch (e) {
        setState(() {
          message = "Unexpected Error: ${e.toString()}";
        });
        print(e.toString());
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }


  Future<void> _initializeWallets() async {
    await Provider.of<WalletsProvider>(context, listen: false).getBalances();
  }

  Future<void> _initializePrimaryWalletAddress() async {
    await Provider.of<WalletsProvider>(context, listen: false).getXmrPrimaryAddress();
  }

  Future<void> _initializeOffers() async {
    await Provider.of<OffersProvider>(context, listen: false).getAllOffers();
  }

  Future<void> _initializeDisputes() async {
    await Provider.of<DisputesProvider>(context, listen: false).getDisputes();
  }

  Future<void> _initializeTrades() async {
    await Provider.of<TradesProvider>(context, listen: false).getTrades();
  }

  Future<void> _initializePrices() async {
    await Provider.of<PricesProvider>(context, listen: false).getXmrMarketPrices();
  }

  Future<void> _initializePaymentMethods() async {
    await Provider.of<PaymentAccountsProvider>(context, listen: false).getPaymentMethods();
  }

  Future<void> _initializePaymentAccounts() async {
    await Provider.of<PaymentAccountsProvider>(context, listen: false).getPaymentAccounts();
  }

  Future<void> _initializePaymentAccountForms() async {
    await Provider.of<PaymentAccountsProvider>(context, listen: false).getAllPaymentAccountForms();
  }

  void _showOrbotDownloadMessage() {
    setState(() {
      if (Platform.isAndroid) {
        message =
            "You must download the Orbot app to use Haveno Mobile. This ensures there are no leaks from your connection. You can click here to download it from the Play Store, otherwise make sure it's switched on in the app.";
      } else if (Platform.isIOS) {
        message =
            "You must download the Orbot app to use Haveno Mobile. This ensures there are no leaks from your connection. You can click here to download it from the App Store, otherwise make sure it's switched on in the app.";
      }
    });
  }

  void _launchStore() async {
    String url = '';
    if (Platform.isAndroid) {
      url =
          'https://play.google.com/store/apps/details?id=org.torproject.android';
    } else if (Platform.isIOS) {
      url = 'https://apps.apple.com/us/app/orbot/id1456634573';
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildLoadingScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              _isTorConnected ? 'assets/haveno-logo.png' : 'assets/tor-logo.png',
              height: 100,
            ), // Tor logo until connected, then Haveno logo
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            if (message.contains("download it from the"))
              TextButton(
                onPressed: _launchStore,
                child: Text(
                  "Download from the ${Platform.isAndroid ? 'Play Store' : 'App Store'}",
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToHomeScreen() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    });
  }
}
