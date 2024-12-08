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
import 'package:haveno_app/services/secure_storage_service.dart';
import 'package:haveno_app/views/screens/password_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  late final List<Widget> _onboardingPages;

  @override
  void initState() {
    super.initState();

    String description;

    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      description = "We'll get through some basic steps to getr your account setup and connected to the network.";
    } else {
      description = "If you would like to use Haveno on your mobile you can do so by first downloading the client from Haveno.com/dekstop, once you have done that, come back here to scan the QR that will be displayed on your computer screen with your phone to make the connection.";
    }

    _onboardingPages = [
      const OnboardingPage(
        title: "Haveno",
        description: "A P2P decentralized trading platform for Monero.",
        imagePath: "assets/haveno-logo.png",
      ),
      const OnboardingPage(
        title: "Privacy by Tor",
        description: "Track your task progress with ease.",
        imagePath: "assets/tor-logo.png",
      ),
      const OnboardingPage(
        title: "Arbitration",
        description: "A distributed network of arbitrators will provide security in your transactions.",
        imagePath: "assets/arbitration-logo.png",
      ),
      OnboardingPage(
        title: "Get Started",
        description: description,
        imagePath: "assets/getting-started-logo.png",
        isLastPage: true,
        onFinish: _onFinish,
      ),
    ];
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onFinish() async {
    SecureStorageService secureStorageService = SecureStorageService();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      secureStorageService.writeOnboardingStatus(true);
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PasswordScreen(),
      ),
    );  
  }

  void _nextPage() {
    if (_currentIndex < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _onboardingPages.length,
            itemBuilder: (context, index) {
              return _onboardingPages[index];
            },
          ),
          Positioned(
            top: 40,
            left: 16,
            child: Visibility(
              visible: _currentIndex > 0,
              child: TextButton(
                onPressed: _previousPage,
                child: const Row(
                  children: [
                    Icon(Icons.chevron_left, size: 32),
                    SizedBox(width: 4),
                    Text("Previous"),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: Visibility(
              visible: _currentIndex < _onboardingPages.length - 1,
              child: TextButton(
                onPressed: _nextPage,
                child: Row(
                  children: [
                    const Text("Next"),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 32),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingPages.length,
                (index) => _buildDot(index, context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8,
      width: _currentIndex == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentIndex == index
            ? Theme.of(context).primaryColor.withOpacity(0.23)
            : Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final bool isLastPage;
  final VoidCallback? onFinish;

  const OnboardingPage({super.key, 
    required this.title,
    required this.description,
    required this.imagePath,
    this.isLastPage = false,
    this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 150),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (isLastPage) ...[
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onFinish,
              child: const Text("Begin Setup"),
            ),
          ],
        ],
      ),
    );
  }
}
