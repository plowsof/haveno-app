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
import 'package:haveno/grpc_models.dart';
import 'package:haveno_app/utils/string_utils.dart';
import 'package:haveno_app/views/widgets/loading_button.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/xmr_connections_provider.dart';

class RemoteNodeForm extends StatefulWidget {
  final UrlConnection? node;

  const RemoteNodeForm({super.key, this.node});

  @override
  _RemoteNodeFormState createState() => _RemoteNodeFormState();
}

class _RemoteNodeFormState extends State<RemoteNodeForm> {
  late TextEditingController hostController;
  late TextEditingController portController;
  late TextEditingController usernameController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    final parsedUrl = parseNodeUrl(widget.node?.url ?? '');
    final String? host = parsedUrl['host'];
    final String? port = parsedUrl['port'];

    hostController = TextEditingController(text: host);
    portController = TextEditingController(text: port ?? '18081');
    usernameController = TextEditingController(text: widget.node?.username ?? '');
    passwordController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16.0,
        left: 16.0,
        right: 16.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Remote Node',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: hostController,
              decoration: const InputDecoration(
                labelText: 'Host IP/Domain',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password (Optional)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48, // Set equal height for both buttons
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Cancel button action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey, // Optional: customize the color
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0), // Space between the buttons
                Expanded(
                  child: SizedBox(
                    height: 48, // Set equal height for both buttons
                    child: LoadingButton(
                      onPressed: () async {
                        try {
                          final newNode = UrlConnection(
                            url: hostController.text,
                            username: usernameController.text,
                            password: passwordController.text,
                          );

                          await Provider.of<XmrConnectionsProvider>(context, listen: false)
                              .addConnection(newNode);

                          // Show success snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Node added successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          Navigator.of(context).pop(); // Close the form on success
                        } catch (e) {
                          // Show error snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add node: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          print(e); // Log the error
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0), // Bottom margin to balance the layout
          ],
        ),
      ),
    );
  }
}
