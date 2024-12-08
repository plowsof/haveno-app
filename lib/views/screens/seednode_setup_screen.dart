import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:haveno/grpc_models.dart';
import 'package:haveno/haveno_client.dart';

class SeedNodeSetupScreen extends StatefulWidget {
  const SeedNodeSetupScreen({super.key});

  @override
  _SeedNodeSetupScreenState createState() => _SeedNodeSetupScreenState();
}

class _SeedNodeSetupScreenState extends State<SeedNodeSetupScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _seedNodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isConnecting = false;
  bool _connectionSuccessful = false;
  bool _connectionError = false;
  bool _isHovered = false;
  Color _iconColor = Colors.white;
  IconData _connectionIcon = Icons.cloud;

  // Animation controller for shaking the icon
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Regex for validating V3 Onion addresses
  final _onionRegex = RegExp(r'^[a-zA-Z2-7]{56}\.onion$');

  @override
  void initState() {
    super.initState();

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
    _seedNodeController.dispose();
    super.dispose();
  }

  Future<void> _verifySeedNode(String seedNodeInput) async {
    setState(() {
      _isConnecting = true;
      _connectionError = false;
      _iconColor = Colors.blue;
    });

    try {
      // Extract the seed node (no need for port checking here)
      String seedNode = seedNodeInput;

      print('Connecting to $seedNode');

      // Try to connect to Haveno and check its version
      bool isVersionValid = await checkGprcVersion(seedNode, Duration(seconds: 30));

      if (isVersionValid) {
        // Connection successful
        setState(() {
          _iconColor = Colors.green;
          _connectionIcon = Icons.cloud_done;
          _connectionSuccessful = true;
        });

        // Proceed to the next screen after a short delay
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context, true);
      } else {
        // Connection failed
        _showConnectionError();
      }
    } catch (e) {
      print('Error: $e');
      _showConnectionError();
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<bool> checkGprcVersion(String address, Duration timeout) async {
    try {
      HavenoChannel havenoChannel = HavenoChannel();
      havenoChannel.connect(address, 3201, 'boner');
      await havenoChannel.onConnected;
      var versionResponse = await havenoChannel.versionClient?.getVersion(GetVersionRequest());
      if (versionResponse?.version != null && versionResponse!.version.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false; // Connection failed
    }
  }

  void _showConnectionError() {
    _shakeController.forward(from: 0); // Start the shake animation
    setState(() {
      _iconColor = Colors.red;
      _connectionIcon = Icons.cloud_off;
      _connectionError = true;
    });
  }

  void _showSeedNodeInfo() {
    // Show a dialog with information about seed nodes
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('What is a Seed Node?'),
          content: Text(
            'A seed node is a server that helps your client connect to the network. Please enter the address of a seed node to proceed. You can include the port number if necessary, e.g., your-seed-node.onion.',
          ),
          actions: [
            TextButton(
              child: Text('Got it'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleHover(bool hover) {
    setState(() {
      _isHovered = hover;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SingleChildScrollView(
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
                                _connectionIcon,
                                size: 48,
                                color: _iconColor,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                    Text(
                      'Enter Seed Node',
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
                            controller: _seedNodeController,
                            decoration: InputDecoration(
                              labelText: 'Seed Node Address',
                              hintText: 'e.g., yourseednodeaddresshere.onion',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.info_outline,
                                ),
                                onPressed: _showSeedNodeInfo,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a seed node address.';
                              }
                              if (!_onionRegex.hasMatch(value)) {
                                return 'Invalid V3 Onion Address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isConnecting
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      _verifySeedNode(_seedNodeController.text);
                                    }
                                  },
                            child: _isConnecting
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('Connect'),
                          ),
                          if (_connectionError)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                'Connection failed. Please try again.',
                                style: TextStyle(color: Colors.red),
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
          Positioned(
            bottom: 16,
            right: 16,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => _toggleHover(true),
              onExit: (_) => _toggleHover(false),
              child: GestureDetector(
                onTap: _showSeedNodeInfo,
                child: Tooltip(
                  message: 'Learn more about seed nodes.',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: _isHovered ? Colors.orange : Colors.grey.withOpacity(0.46),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 20,
                        child: Stack(
                          children: [
                            Text(
                              'What is a Seed Node?',
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

class NextScreen extends StatelessWidget {
  const NextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Connected to Seed Node!'),
      ),
    );
  }
}
