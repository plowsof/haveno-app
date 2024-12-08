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
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:haveno_app/main.dart';
import 'package:haveno_app/services/secure_storage_service.dart';
import 'package:haveno_app/views/desktop_lifecycle.dart';
import 'package:haveno_app/views/mobile_lifecycle.dart';
import 'package:haveno_app/views/screens/onboarding_screen.dart';
import 'package:haveno_app/views/screens/seednode_setup_screen.dart';

class HavenoApp extends StatefulWidget {
  const HavenoApp({super.key});

  @override
  _HavenoAppState createState() => _HavenoAppState();
}

class _HavenoAppState extends State<HavenoApp> with WidgetsBindingObserver {
  bool? _onboardingComplete; // Nullable

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load the onboarding status asynchronously and update the state
    SecureStorageService().readOnboardingStatus().then((onboardingComplete) {
      setState(() {
        _onboardingComplete = onboardingComplete ?? false;
      });
    });
  }

  Widget _buildAppContent() {
    // Check if _onboardingComplete is null (while loading)
    if (_onboardingComplete == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          primary: const Color(0xFFF4511E),
          seedColor: const Color(0xFFF4511E),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF303030),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF303030),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF303030),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF303030).withOpacity(0.5),
          indicatorShape: const StadiumBorder(),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF4511E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        cardTheme: const CardTheme(
          color: Color(0xFF424242),
        ),
      ),
      // Use _onboardingComplete to decide the home widget
      home: _onboardingComplete == true ? SeedNodeSetupScreen() : OnboardingScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return MobileLifecycleWidget(
        child: _buildAppContent(),
        builder: (context, child) => child,
      );
    } else if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return DesktopLifecycleWidget(
        child: _buildAppContent(),
        builder: (context, child) => child,
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    
    switch (state) {
      case AppLifecycleState.resumed:
        if (Platform.isAndroid || Platform.isIOS) {
          final service = FlutterBackgroundService();
          bool isRunning = await service.isRunning();
          if (!isRunning) {
            service.startService();
          }
        }
        print("App resumed");
        break;
      case AppLifecycleState.paused:
        print("App paused");
        break;
      case AppLifecycleState.inactive:
        print("App inactive");
        break;
      case AppLifecycleState.detached:
        print("App detached");
        break;
      case AppLifecycleState.hidden:
        print("App hidden");
        break;
    }
    
    // Ensure the method always returns a Future
    return Future.value();
  }
}
