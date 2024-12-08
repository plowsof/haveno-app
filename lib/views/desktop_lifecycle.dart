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
import 'package:haveno/haveno_client.dart';
import 'package:haveno/haveno_service.dart';
import 'package:haveno_app/models/schema.dart';
import 'package:haveno_app/providers/haveno_client_providers/disputes_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/offers_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/price_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/trades_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/wallets_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/xmr_connections_provider.dart';
import 'package:haveno_app/services/desktop_manager_service.dart';
import 'package:haveno_app/services/local_notification_service.dart';
import 'package:haveno_app/services/platform_system_service/factory.dart';
import 'package:haveno_app/services/platform_system_service/schema.dart';
import 'package:haveno_app/services/secure_storage_service.dart';
import 'package:haveno_app/utils/payment_utils.dart';
import 'package:haveno_app/utils/salt.dart';
import 'package:haveno_app/views/screens/seednode_setup_screen.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';

class DesktopLifecycleWidget extends PlatformLifecycleWidget {
  const DesktopLifecycleWidget({
    super.key,
    required super.child,
    required super.builder,
  });

  @override
  _DesktopLifecycleWidgetState createState() => _DesktopLifecycleWidgetState();
}

class _DesktopLifecycleWidgetState extends PlatformLifecycleState<DesktopLifecycleWidget> with TrayListener {
  late PlatformService platformService;
  late SyncManager syncManager;
  late NotificationsService notificationsService;
  late String? _daemonPassword;

  @override
  Future<void> initPlatform() async {
    final desktopManagerService = DesktopManagerService();

    print("Intializing tray mananger and adding lifecycle widget as listener");
    //intializeSystemTray();
    trayManager.addListener(this);
    print("Initialized desktop platform");
    HavenoChannel havenoChannel = HavenoChannel();
    SecureStorageService secureStorageService = SecureStorageService();
    platformService = await getPlatformService();

    print("Setting up Tor daemon...");
    await platformService.setupTorDaemon();


    // Ensure seed node is configured
    var seedNodeConfigured = await desktopManagerService.isSeednodeConfigured();
    while (seedNodeConfigured == null || seedNodeConfigured == false) {
      // Navigate to SeedNodeSetupScreen and wait for the result
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeedNodeSetupScreen(),
        ),
      );
      // Recheck seed node configuration
      seedNodeConfigured = await desktopManagerService.isSeednodeConfigured();
    }

    _daemonPassword = await secureStorageService.readHavenoDaemonPassword();

    if (_daemonPassword == null) {
      _daemonPassword = generateHexSalt(16);
      await secureStorageService
          .writeHavenoDaemonPassword(_daemonPassword as String);
      print("Generated and saved new daemon password.");
      await platformService.setupHavenoDaemon(_daemonPassword);
      await havenoChannel.connect('127.0.0.1', 3201, _daemonPassword as String);
    } else {
      print("Loaded existing daemon password.");
      await platformService.setupHavenoDaemon(_daemonPassword);
      await havenoChannel.connect('127.0.0.1', 3201, _daemonPassword as String);

      print("Haveno Daemon connected.");
      setState(() {});

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        print(
            "Setting up and starting sync manager and notification listeners");
        await havenoChannel.onConnected;
        await _createSyncManagerWithTasks();
        await _createNotificationListeners();
      });
    }
  }

  Future<void> _createSyncManagerWithTasks() async {
    syncManager = SyncManager(checkInterval: const Duration(seconds: 1));

    var offersProvider = Provider.of<OffersProvider>(context, listen: false);
    var pricesProvider = Provider.of<PricesProvider>(context, listen: false);
    var walletsProvider = Provider.of<WalletsProvider>(context, listen: false);
    var tradesProvider = Provider.of<TradesProvider>(context, listen: false);
    var xmrConnectionsProvider = Provider.of<XmrConnectionsProvider>(context, listen: false);

    var fetchOffersTask = SyncTask(taskFunction: offersProvider.getOffers, cooldown: const Duration(minutes: 1));
    var fetchMyOffersTask = SyncTask(taskFunction: offersProvider.getMyOffers, cooldown: const Duration(minutes: 2));
    var fetchPricesTask = SyncTask(taskFunction: pricesProvider.getXmrMarketPrices, cooldown: const Duration(seconds: 5));
    var fetchBalancesTask = SyncTask(taskFunction: walletsProvider.getBalances, cooldown: const Duration(minutes: 2));
    var fetchTransactionsTask = SyncTask(taskFunction: walletsProvider.getXmrTxs, cooldown: const Duration(minutes: 2));
    var fetchTradesTask = SyncTask(taskFunction: tradesProvider.getTrades, cooldown: const Duration(minutes: 1));
    var fetchXmrConnections = SyncTask(taskFunction: xmrConnectionsProvider.checkConnections, cooldown: const Duration(minutes: 1));


    syncManager.addTask(fetchOffersTask);
    syncManager.addTask(fetchMyOffersTask);
    syncManager.addTask(fetchPricesTask);
    syncManager.addTask(fetchBalancesTask);
    syncManager.addTask(fetchTransactionsTask);
    syncManager.addTask(fetchTradesTask);
    syncManager.addTask(fetchXmrConnections);

    syncManager.start();
  }

  Future<void> _createNotificationListeners() async {
    var tradesProvider = Provider.of<TradesProvider>(context, listen: false);
    var disputesProvider =
        Provider.of<DisputesProvider>(context, listen: false);
    notificationsService = NotificationsService();
    var localNotificationsService = LocalNotificationsService();

    notificationsService.addListener(
      NotificationMessage_NotificationType.CHAT_MESSAGE,
      (notification) {
        if (notification.chatMessage.type == SupportType.TRADE) {
          tradesProvider.addChatMessage(notification.chatMessage);
          localNotificationsService.showNotification(
              id: notification.chatMessage.hashCode,
              title: 'New Message',
              body: notification.chatMessage.message);
        } else {
          disputesProvider.addChatMessage(notification.chatMessage);
          tradesProvider.addChatMessage(notification.chatMessage);
          localNotificationsService.showNotification(
              id: notification.chatMessage.hashCode,
              title: 'New Support Message',
              body: notification.chatMessage.message);
        }
      },
    );

    notificationsService.addListener(
      NotificationMessage_NotificationType.TRADE_UPDATE,
      (notification) {
        tradesProvider.createOrUpdateTrade(notification.trade);
        var direction =
            notification.trade.role.contains('buyer') ? 'buying' : 'selling';
        var total = formatXmr(notification.trade.amount);
        var paymentMethod = notification.trade.offer.paymentMethodShortName;
        localNotificationsService.showNotification(
            id: notification.chatMessage.hashCode,
            title: 'New Trade Opened',
            body:
                'You\'re $direction a total of $total XMR via $paymentMethod');
      },
    );

    notificationsService.listen();
  }

  @override
  void dispose() {
    notificationsService.stop(); // Stop listening to notifications
    syncManager.stop(); // Stop sync manager
    trayManager.removeListener(this);
    super.dispose();
  }
}
