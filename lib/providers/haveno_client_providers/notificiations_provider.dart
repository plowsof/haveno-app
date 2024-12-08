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
import 'package:flutter/widgets.dart';
import 'package:grpc/grpc.dart';
import 'package:haveno/grpc_models.dart';
import 'package:haveno/haveno_service.dart';

class NotificationsProvider with ChangeNotifier {

  NotificationsProvider();

  Future<void> listen() async {
    ResponseStream<NotificationMessage> responseStream = NotificationsService() as ResponseStream<NotificationMessage>;
 
    // Listen to the stream of notifications
    responseStream.listen(
      (notification) {
        // Handle the notification, for example, print it to the debug console
        print('Received notification: ${notification.toString()}');
        
        // You can also add custom logic to handle different types of notifications here
      },
      onError: (error) {
        // Handle errors from the stream
        print('Error receiving notifications: $error');
      },
      onDone: () {
        // Handle the completion of the stream
        print('Notification stream closed');
      },
      cancelOnError: true, // Optionally cancel the subscription if an error occurs
    );
  }
}
