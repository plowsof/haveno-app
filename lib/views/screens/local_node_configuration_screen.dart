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

class LocalNodeConfigurationScreen extends StatefulWidget {
  const LocalNodeConfigurationScreen({super.key});

  @override
  _LocalNodeConfigurationScreenState createState() => _LocalNodeConfigurationScreenState();
}

class _LocalNodeConfigurationScreenState extends State<LocalNodeConfigurationScreen> {
  // Controllers
  final TextEditingController _daemonAddressController = TextEditingController();
  final TextEditingController _daemonPortController = TextEditingController(text: '18081');
  final TextEditingController _sslPrivateKeyController = TextEditingController();
  final TextEditingController _sslCertificateController = TextEditingController();
  final TextEditingController _daemonUsernameController = TextEditingController();
  final TextEditingController _daemonPasswordController = TextEditingController();
  final TextEditingController _proxyIpController = TextEditingController();
  final TextEditingController _proxyPortController = TextEditingController();
  final TextEditingController _logFileController = TextEditingController();

  // State Variables
  String _networkType = 'Mainnet';
  bool _useSSL = false;
  bool _daemonAuthentication = false;
  bool _trustedDaemon = false;
  bool _useProxy = false;
  bool _offlineMode = false;
  bool _allowMismatchedDaemonVersion = false;
  String _logLevel = '0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Local Node'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Network Selection
            _buildSectionTitle('Network Selection'),
            _buildDropdown(
              label: 'Network Type',
              value: _networkType,
              items: ['Mainnet', 'Testnet', 'Stagenet'],
              onChanged: (newValue) {
                setState(() {
                  _networkType = newValue!;
                });
              },
            ),
            const SizedBox(height: 24),
            // Daemon Connection Settings
            _buildSectionTitle('Daemon Connection Settings'),
            _buildTextInputField(
              controller: _daemonAddressController,
              label: 'Daemon Address',
              hint: 'e.g., 127.0.0.1',
            ),
            const SizedBox(height: 16),
            _buildTextInputField(
              controller: _daemonPortController,
              label: 'Daemon Port',
              hint: 'e.g., 18081',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildToggleSwitch(
              label: 'Use SSL',
              value: _useSSL,
              onChanged: (newValue) {
                setState(() {
                  _useSSL = newValue;
                });
              },
            ),
            if (_useSSL) ...[
              const SizedBox(height: 16),
              _buildTextInputField(
                controller: _sslPrivateKeyController,
                label: 'SSL Private Key Path',
                hint: 'Path to PEM format private key',
              ),
              const SizedBox(height: 16),
              _buildTextInputField(
                controller: _sslCertificateController,
                label: 'SSL Certificate Path',
                hint: 'Path to PEM format certificate',
              ),
            ],
            const SizedBox(height: 24),

            // Authentication Settings
            _buildSectionTitle('Authentication Settings'),
            _buildToggleSwitch(
              label: 'Requires Authentication',
              value: _daemonAuthentication,
              onChanged: (newValue) {
                setState(() {
                  _daemonAuthentication = newValue;
                });
              },
            ),
            if (_daemonAuthentication) ...[
              const SizedBox(height: 16),
              _buildTextInputField(
                controller: _daemonUsernameController,
                label: 'Username',
              ),
              const SizedBox(height: 16),
              _buildTextInputField(
                controller: _daemonPasswordController,
                label: 'Password',
                obscureText: true,
              ),
            ],
            const SizedBox(height: 24),

            // Advanced Options
            _buildSectionTitle('Advanced Options'),
            _buildToggleSwitch(
              label: 'Trusted Daemon',
              value: _trustedDaemon,
              onChanged: (newValue) {
                setState(() {
                  _trustedDaemon = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildToggleSwitch(
              label: 'Use Proxy',
              value: _useProxy,
              onChanged: (newValue) {
                setState(() {
                  _useProxy = newValue;
                });
              },
            ),
            if (_useProxy) ...[
              const SizedBox(height: 16),
              _buildTextInputField(
                controller: _proxyIpController,
                label: 'Proxy IP',
                hint: 'e.g., 127.0.0.1',
              ),
              const SizedBox(height: 16),
              _buildTextInputField(
                controller: _proxyPortController,
                label: 'Proxy Port',
                hint: 'e.g., 9050',
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 24),

            // Logging Options
            _buildSectionTitle('Logging Options'),
            _buildDropdown(
              label: 'Log Level',
              value: _logLevel,
              items: ['0', '1', '2', '3', '4'],
              onChanged: (newValue) {
                setState(() {
                  _logLevel = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildTextInputField(
              controller: _logFileController,
              label: 'Log File Path',
              hint: 'Specify log file path',
            ),
            const SizedBox(height: 24),

            // Miscellaneous Options
            _buildSectionTitle('Miscellaneous Options'),
            _buildToggleSwitch(
              label: 'Offline Mode',
              value: _offlineMode,
              onChanged: (newValue) {
                setState(() {
                  _offlineMode = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildToggleSwitch(
              label: 'Allow Mismatched Daemon Version',
              value: _allowMismatchedDaemonVersion,
              onChanged: (newValue) {
                setState(() {
                  _allowMismatchedDaemonVersion = newValue;
                });
              },
            ),
            const SizedBox(height: 32),

            // Save Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _saveConfiguration,
                icon: const Icon(Icons.save),
                label: const Text('Save Configuration'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Helper methods

  Widget _buildTextInputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildToggleSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _saveConfiguration() {
    // Collect all the configurations
    Map<String, dynamic> config = {
      'networkType': _networkType,
      'daemonAddress': _daemonAddressController.text,
      'daemonPort': _daemonPortController.text,
      'useSSL': _useSSL,
      'sslPrivateKey': _sslPrivateKeyController.text,
      'sslCertificate': _sslCertificateController.text,
      'daemonAuthentication': _daemonAuthentication,
      'daemonUsername': _daemonUsernameController.text,
      'daemonPassword': _daemonPasswordController.text,
      'trustedDaemon': _trustedDaemon,
      'useProxy': _useProxy,
      'proxyIp': _proxyIpController.text,
      'proxyPort': _proxyPortController.text,
      'logLevel': _logLevel,
      'logFile': _logFileController.text,
      'offlineMode': _offlineMode,
      'allowMismatchedDaemonVersion': _allowMismatchedDaemonVersion,
    };

    // TODO: Save the configuration to the appropriate place
    // For now, just print it to the console
    print('Configuration Saved: $config');

    // Provide feedback to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Configuration saved successfully')),
    );

    // Navigate back
    Navigator.pop(context);
  }
}
