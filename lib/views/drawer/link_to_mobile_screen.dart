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


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:haveno_app/services/desktop_manager_service.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LinkToMobileScreen extends StatelessWidget {
  const LinkToMobileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final desktopManager = DesktopManagerService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Your Mobile'),
      ),
      body: FutureBuilder<Uri?>(
        future: desktopManager.getDesktopDaemonNodeUri(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No URL available'));
          } else {
            final url = snapshot.data!.toString();
            final base64Url = base64.encode(utf8.encode("http://$url"));

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Download the app and scan the QR code to link your mobile to your desktop:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    QrImageView(
                      data: 'http://$url',
                      version: QrVersions.auto,
                      size: 200.0,
                      eyeStyle: const QrEyeStyle(color: Colors.white, eyeShape: QrEyeShape.square),
                      dataModuleStyle: const QrDataModuleStyle(color: Colors.white, dataModuleShape: QrDataModuleShape.square),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Alternatively, you can use the Linkage Key:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: TextEditingController(text: base64Url),
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Linkage Key',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: base64Url));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Linkage Key copied to clipboard')),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
