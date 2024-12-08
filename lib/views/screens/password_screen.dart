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
import 'package:haveno_app/services/security.dart';
import 'package:haveno_app/views/screens/establish_connection_screen.dart';
import 'package:haveno_app/views/screens/link_to_desktop_screen.dart';
import 'package:haveno_app/views/screens/onboarding_screen.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen>
    with SingleTickerProviderStateMixin {
  final SecureStorageService _secureStorage = SecureStorageService();
  final TextEditingController _passwordController = TextEditingController();
  final SecurityService _securityService = SecurityService();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordSet = false;
  bool _isSettingPassword = false;
  bool _isObscured = true;
  bool _isHovered = false;
  bool _isUnlocked = false;
  Color _lockColor = Colors.white;
  IconData _lockIcon = Icons.lock;

  // Animation controller for shaking the padlock
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _checkPasswordStatus();

    // Initialize shake animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).chain(
      CurveTween(curve: Curves.elasticIn),
    ).animate(_shakeController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reverse();
        }
      });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkPasswordStatus() async {
    String? storedPassword = await _secureStorage.readUserPassword();
    setState(() {
      _isPasswordSet = storedPassword != null;
      _isSettingPassword = storedPassword == null;
    });
  }

  Future<void> _setPassword(String password) async {
    await _securityService.setupUserPassword(password);
    setState(() {
      _isPasswordSet = true;
      _isSettingPassword = false;
    });
  }

  Future<void> _verifyPassword(String password) async {
    if (await _securityService.authenticateUserPassword(password)) {
      setState(() {
        _lockColor = Colors.green;
        _lockIcon = Icons.lock_open;
        _isUnlocked = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      _decideNextScreen();
    } else {
      _shakeController.forward(from: 0); // Start the shake animation
      setState(() {
        _lockColor = Colors.red;
        _lockIcon = Icons.lock;
      });

      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _lockColor = Colors.white;
      });
    }
  }

  void _toggleObscured() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  void _decideNextScreen() {
    // Check if the user is new and still part of the onboarding process and send him to monero screen
    print("Navigating to the next screen...");
    if (Platform.isIOS || Platform.isAndroid) {
      _secureStorage.readHavenoDaemonConfig().then((config) => {
        if (config == null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LinkToDesktopScreen(),
            ),
          )       
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => EstablishConnectionScreen(),
            ),
          )
        }
      });
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EstablishConnectionScreen(),
        ),
      );
    }
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isResetting = false;
            bool resetComplete = false;
            String? errorMessage;

            Future<void> startReset() async {
              setState(() {
                isResetting = true;
              });

              try {
                await _securityService.resetAppData();

                setState(() {
                  resetComplete = true;
                });

                await Future.delayed(const Duration(seconds: 1)); // Wait for the tick to show

                Navigator.of(context).pop(); // Close the dialog box

                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) => OnboardingScreen(),
                    transitionsBuilder: (context, animation1, animation2, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(-1, 0), // Start from left
                          end: Offset.zero,
                        ).animate(animation1),
                        child: child,
                      );
                    },
                  ),
                );
              } catch (e) {
                setState(() {
                  isResetting = false;
                  errorMessage = "Failed to reset app data. Please try again.";
                });
                print("Reset error: $e");
              }
            }

            return AlertDialog(
              title: isResetting
                  ? null
                  : const Text('Confirm Reset'),
              content: isResetting
                  ? resetComplete
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 64)
                      : const SizedBox(
                          height: 64,
                          width: 64,
                          child: CircularProgressIndicator(),
                        )
                  : errorMessage != null
                      ? Text(errorMessage!)
                      : const Text('Are you sure you want to reset the device? This action cannot be undone.'),
              actions: isResetting || resetComplete
                  ? null
                  : [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          startReset();
                        },
                        child: const Text('Reset'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Image.asset(
                        'assets/haveno-logo.png',
                        height: 100,
                      ),
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: Icon(
                              _lockIcon,
                              size: 48,
                              color: _lockColor,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                  Text(
                    _isSettingPassword ? 'Set Your Password' : 'Enter Your Password',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _isObscured,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscured ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: _toggleObscured,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (_isSettingPassword && value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              if (_isSettingPassword) {
                                _setPassword(_passwordController.text);
                              } else {
                                _verifyPassword(_passwordController.text);
                              }
                            }
                          },
                          child: Text(
                            _isSettingPassword ? 'Set Password' : 'Verify Password',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) {
                setState(() {
                  _isHovered = true;
                });
              },
              onExit: (_) {
                setState(() {
                  _isHovered = false;
                });
              },
              child: GestureDetector(
                onTap: _showResetConfirmation,
                child: Tooltip(
                  message: 'This will reset the device to its factory settings.',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: _isHovered ? Colors.orange : Colors.grey.withOpacity(0.46),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 20,
                        child: Stack(
                          children: [
                            Text(
                              'Reset Device',
                              style: TextStyle(
                                color: _isHovered ? Colors.white : Colors.grey.withOpacity(0.46),
                                fontSize: 14,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 2,
                                color: _isHovered ? Colors.orange : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
