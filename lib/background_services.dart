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
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:haveno/enums.dart';
import 'package:haveno/haveno_client.dart';
import 'package:haveno/haveno_service.dart';
import 'package:haveno_app/models/haveno_daemon_config.dart';
import 'package:haveno_app/models/schema.dart';
import 'package:haveno_app/services/local_notification_service.dart';
import 'package:haveno_app/services/secure_storage_service.dart';

// This is for Mobile background services only (for now) fuck off if you wanted something else. But we could run native Tor on Desktop too!

class BackgroundServiceListener {
  final FlutterBackgroundService service = FlutterBackgroundService();
  final EventDispatcher dispatcher;

  BackgroundServiceListener(this.dispatcher);

  Future<void> startListening() async {
    service.on('updateTorStatus').listen((event) {
      if (event != null) {
        dispatcher.dispatch(BackgroundEvent(
          type: BackgroundEventType.updateTorStatus,
          data: event,
        ));
      }
    });

    service.on('updateDaemonStatus').listen((event) {
      if (event != null) {
        dispatcher.dispatch(BackgroundEvent(
          type: BackgroundEventType.updateDaemonStatus,
          data: event,
        ));
      }
    });

    service.on('torStdOutLog').listen((event) {
      if (event != null) {
        dispatcher.dispatch(BackgroundEvent(
          type: BackgroundEventType.torStdOutLog,
          data: event,
        ));
      }
    });

    service.on('torStdErrLog').listen((event) {
      if (event != null) {
        dispatcher.dispatch(BackgroundEvent(
          type: BackgroundEventType.torStdErrLog,
          data: event,
        ));
      }
    });
  }
}


void startBackgroundService() {
  final service = FlutterBackgroundService();
  service.startService();
}

void stopBackgroundService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
}

void markServiceNotificationSeen() {
  final service = FlutterBackgroundService(); // just notify the UI to show the notificiation instead???
  service.invoke("mark_notification_as_seen");
}

Future<void> startLongRunningForegroundService(ServiceInstance service) async {
  //await _startTor(service);
  LocalNotificationsService localNotificationsService = LocalNotificationsService();
  localNotificationsService.init();

  NotificationsService notificationsService =
      NotificationsService();

  notificationsService.addListener(
    NotificationMessage_NotificationType.APP_INITIALIZED,
    (object) {
      localNotificationsService.updateForegroundServiceNotification(
        title: 'Status',
        body: 'Connected',
      );
    },
  );

  notificationsService.addListener(
    NotificationMessage_NotificationType.TRADE_UPDATE,
    (object) {
      localNotificationsService.showNotification(
          id: object.hashCode,
          title: 'Trade Update',
          body: object.message,
          payload: jsonEncode({
            'action': 'route_to_active_trades_screen',
            'tradeProtobufAsJson': jsonEncode(object.trade.toProto3Json())
          }));
    },
  );

  notificationsService.addListener(
    NotificationMessage_NotificationType.CHAT_MESSAGE,
    (object) {
      var payload = {
        'action': 'route_to_chat_screen',
        'chatMessageProtobufAsJson':
            jsonEncode(object.chatMessage.toProto3Json())
      };
      print(jsonEncode(object.trade.toProto3Json()));

      localNotificationsService.showNotification(
          id: object.hashCode,
          title: object.chatMessage.type == SupportType.TRADE
              ? 'New Message'
              : 'New Support Message',
          body: object.chatMessage.message,
          payload: jsonEncode(payload));
    },
  );

  notificationsService.listen();

  localNotificationsService.updateForegroundServiceNotification(
    title: 'Status',
    body: 'Attempting to connect...',
  );

  //_connectToHavenoDaemonHeadless(service);

  service.on("stop").listen((event) {
    // We may need to just trigger this when the app is opened, and when its closed, enable it again
    service.stopSelf();
    // Set something in database for this or in secure storage, if it stops we need to make sure ios background fetch is running at least
  });
}

// For iOS to update notifications and state (mainly notifications)
Future<void> startShortLivedBackgroundFetch(ServiceInstance service) async {
  LocalNotificationsService localNotificationsService = LocalNotificationsService();
  localNotificationsService.init(); // This whole thing might not complete in time for iOS
//  if (!Tor.instance.enabled) {
//    await _startTor(service);
//  } else {
    //
// }
//  await _connectToHavenoDaemonHeadless(service, retryUntilSuccess: true, failWhenNoDaemonConfig: true);

  // Check for new trades and chat messages only then send notification
  // TODO
}

//Future<void> _startTor(ServiceInstance service) async {
//  try {
//    if (!Tor.instance.started) {
//      service.invoke("updateTorStatus", {
//        "status": "intializing",
//        "details": "Tor is is now initializing..."
//      });
//      await Tor.init();
//      service.invoke("updateTorStatus", {
//        "status": "initialized",
//        "details": "Tor has now been initialized. (Not yet started)"
//      });
//      service.invoke("updateTorStatus", {
//          "status": "starting",
//          "details": "Start is now starting..."
//        }
//      );
//      if (!Tor.instance.enabled) {
//        await Tor.instance.enable();
//      }
//      await Tor.instance.start();
//      while (!Tor.instance.bootstrapped) {
//        await Future.delayed(const Duration(seconds: 1));
//      }
//      service.invoke("updateTorStatus", {
//        "status": "started",
//        "port": Tor.instance.port,
//        "details": "Tor service successfully started on port ${Tor.instance.port}"
//     });
//    } else {
//      service.invoke("updateTorStatus", {
//        "status": "started",
//        "port": Tor.instance.port,
//        "details": "Tor service successfully started on port ${Tor.instance.port}"
//      });   
//    }
//  } catch (e) {
//    service.invoke("updateTorStatus", {
//      "status": "error",
//      "details": e.toString()
//    });
//    rethrow;
//  }
//
//  StreamSubscription<dynamic> subscription = Tor.instance.events.stream.listen(  /// might have to make sure this is close or reopenable on closure automatically
//    (event) {
//      // Handle each event
//      service.invoke("torStdOutLog", {
//        "details": event.toString(),
//      });
//    },
//    onError: (error) {
//      // Handle any errors that occur during the stream
//      service.invoke("torStdErrLog", {
//        "details": error.toString(),
//      });
//    },
//    onDone: () {
//      // Handle when the stream is closed or completed
//      service.invoke("updateTorStatus", {
//        "status": "Tor stream closed",
//      });
//    },
//    cancelOnError: false, // If true, the stream will cancel on the first error
//  );

//}

Future<void> _connectToHavenoDaemonHeadless(ServiceInstance service, {bool retryUntilSuccess = true, bool failWhenNoDaemonConfig = false}) async {
  HavenoChannel havenoService = HavenoChannel();
  HavenoDaemonConfig? daemonConfig;
  while (daemonConfig == null && retryUntilSuccess) {
    service.invoke("updateDaemonStatus", {
      "status": "aquiringRemoteDaemonConfig",
      "details": "Aquiring remote daemon configuration from shared preferences..."
    });
    daemonConfig = await SecureStorageService().readHavenoDaemonConfig();
    if (daemonConfig == null) {
      service.invoke("updateDaemonStatus", {
        "status": "remoteDaemonConfigNotFound",
        "details": "No remote daemon configuration in shared preferences..."
      });
      if (failWhenNoDaemonConfig) {
        service.invoke("updateDaemonStatus", {
          "status": "stopped",
          "details": "No daemon config found and it is configured to fail in this case and not retry..."
        });
      } else {
        service.invoke("updateDaemonStatus", {
          "status": "retryingConfig",
          "details": "Scheduled to check for config again in 20 seconds..."
        });
        await Future.delayed(const Duration(seconds: 10));
      }
    } else {
      service.invoke("updateDaemonStatus", {
        "status": "foundDaemonConfig",
        "details": "Found remote daemon configuration from shared preferences..."
      });
      if (havenoService.isConnected) {
        break;
      } else {
        try {
          service.invoke("updateDaemonStatus", {
            "status": "connecting",
            "details": "Connecting to the daemon..."
          });
          await havenoService.connect(daemonConfig.host, daemonConfig.port,
              daemonConfig.clientAuthPassword);
          service.invoke("updateDaemonStatus", {
            "status": "connected",
            "details": "Connects to the daemon..."
          });
        } catch (e) {
          service.invoke("updateDaemonStatus", {
            "status": "unknownError",
            "details": "Failure: ${e.toString()}"       
          });
        
          await Future.delayed(const Duration(seconds: 10));
        }
      }
    }
  }
}
