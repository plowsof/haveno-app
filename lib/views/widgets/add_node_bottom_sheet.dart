import 'dart:io';
import 'package:flutter/material.dart';
import 'remote_node_form.dart';

class AddNodeBottomSheet extends StatelessWidget {
  const AddNodeBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add New Node',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            if (Platform.isIOS || Platform.isAndroid)
              ListTile(
                title: const Text('Remote Node'),
                onTap: () {
                  Navigator.pop(context);
                  _showRemoteNodeForm(context);
                },
              )
            else
              Column(
                children: [
                  ListTile(
                    title: const Text('Local Node'),
                    onTap: () {
                      Navigator.pop(context);
                      // Show form to add local node
                    },
                  ),
                  ListTile(
                    title: const Text('Remote Node'),
                    onTap: () {
                      Navigator.pop(context);
                      _showRemoteNodeForm(context);
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showRemoteNodeForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return RemoteNodeForm();
      },
    );
  }
}
