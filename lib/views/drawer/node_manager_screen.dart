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
import 'package:haveno/enums.dart';
import 'package:haveno_app/providers/haveno_client_providers/xmr_connections_provider.dart';
import 'package:provider/provider.dart';

class NodeManagerScreen extends StatefulWidget {
  const NodeManagerScreen({super.key});

  @override
  _NodeManagerScreenState createState() => _NodeManagerScreenState();
}

class _NodeManagerScreenState extends State<NodeManagerScreen> {
  bool _isAutoSwitchEnabled = false; // This tracks the state of the toggle switch
  final Map<String, bool> _isDeleting = {}; // Tracks the deletion status for each node

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<XmrConnectionsProvider>(context, listen: false);
      
      // Fetch all node connections
      provider.getXmrConnectionSettings(); 
      
      // Fetch the current active node
      provider.getActiveConnection(); 
      
      // Fetch if auto switch is enabled and update the state
      provider.getAutoSwitchBestConnection().then((autoSwitchEnabled) {
        print("Is Auto Switch Enabled On Daemon: $autoSwitchEnabled");
        setState(() {
          _isAutoSwitchEnabled = autoSwitchEnabled;
        });
      });
    });
  }

  // Toggle switch handler
  Future<void> _handleAutoSwitchToggle(bool value, XmrConnectionsProvider provider) async {
    setState(() {
      _isAutoSwitchEnabled = value; // Optimistically update the UI
    });
    print("You turned $value xmr connection autosswitch");
    // Call the provider's autoSwitchBestConnection method
    final success = await provider.setAutoSwitchBestConnection(value);

    if (!success) {
      // If the operation failed, revert the switch and show an error snackbar
      setState(() {
        _isAutoSwitchEnabled = !value; // Revert to previous state
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to enable auto-switch to best node.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Auto-switch to best node enabled successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Node Manager'),
      ),
      body: Consumer<XmrConnectionsProvider>(
        builder: (context, provider, child) {
          final nodes = provider.xmrNodeConnections;
          final activeNode = provider.xmrActiveConnection;

          if (nodes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Toggle switch widget
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Automatically connect to the best node'),
                    Switch(
                      value: _isAutoSwitchEnabled,
                      onChanged: (value) => _handleAutoSwitchToggle(value, provider),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: nodes.length,
                  itemBuilder: (context, index) {
                    final node = nodes[index];
                    final isActiveNode = activeNode != null && activeNode.url == node.url;
                    final isOnline = node.onlineStatus == UrlConnection_OnlineStatus.ONLINE;
                    final dotColor = isOnline ? Colors.green : Colors.red;
                    final isDeleting = _isDeleting[node.url] ?? false; // Check if the node is being deleted

                    return GestureDetector(
                      onTap: () async {
                        await provider.setConnection(node); // Set the new active node
                      },
                      child: Card(
                        margin: const EdgeInsets.fromLTRB(8, 8, 8, 2), // Consistent margins with the PaymentAccountsScreen
                        color: Theme.of(context).cardTheme.color,
                        elevation: isActiveNode ? 4.0 : 2.0, // Slightly more elevated when active
                        shadowColor: isActiveNode ? const Color.fromARGB(255, 255, 103, 2).withOpacity(0.5) : Colors.black12, // Glow effect when active
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: isActiveNode
                              ? BorderSide(
                                  color: const Color.fromARGB(255, 255, 103, 2).withOpacity(0.5), // Orange border for the active node
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8), // Consistent padding
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center, // Vertically center the row content
                            children: [
                              Icon(Icons.circle, color: dotColor, size: 16), // Status icon
                              const SizedBox(width: 16), // Spacing between the icon and the text
                              Expanded(
                                child: Text(
                                  node.url,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              isDeleting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.secondary.withOpacity(0.23)),
                                      onPressed: () async {
                                        setState(() {
                                          _isDeleting[node.url] = true;
                                        });

                                        // Call the removeConnection function in the provider
                                        final success = await provider.removeConnection(node.url);

                                        // After the response, remove the loading indicator
                                        setState(() {
                                          _isDeleting.remove(node.url);
                                        });

                                        if (success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Node removed: ${node.url}'),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Failed to remove node: ${node.url}'),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your logic for adding a new node here.
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
