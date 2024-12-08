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
import 'package:haveno/haveno_client.dart';
import 'package:haveno_app/models/haveno_daemon_config.dart';
import 'package:haveno_app/models/schema.dart';
import 'package:haveno_app/providers/haveno_client_providers/offers_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/price_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/trades_provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/wallets_provider.dart';
import 'package:haveno_app/services/connection_checker_service.dart';
import 'package:haveno_app/services/mobile_manager_service.dart';
import 'package:haveno_app/services/platform_system_service/schema.dart';
import 'package:provider/provider.dart';

class MobileLifecycleWidget extends PlatformLifecycleWidget {
  const MobileLifecycleWidget({
    super.key,
    required super.child,
    required super.builder,
  });

  @override
  _MobileLifecycleWidgetState createState() => _MobileLifecycleWidgetState();
}

class _MobileLifecycleWidgetState extends PlatformLifecycleState<MobileLifecycleWidget> {
  late PlatformService platformService;
  late String daemonPassword;
  HavenoDaemonConfig? _remoteHavenoDaemonNodeConfig;
  bool _hasHavenoDaemonNodeConfig = false;
  
  get tradesProvider => null;

  @override
  Future<void> initPlatform() async {

    //final torStatusService = TorStatusService();
    HavenoChannel havenoChannel = HavenoChannel();
    final mobileManagerService = MobileManagerService();

    _remoteHavenoDaemonNodeConfig = await mobileManagerService.getRemoteHavenoDaemonNode();

    if (_remoteHavenoDaemonNodeConfig != null) {
      // Paired with desktop
      try {
        //await torStatusService.waitForInitialization();
        await ConnectionCheckerService().isTorConnected();
        print("About to try to connect to daemon");
        await havenoChannel.connect(
          _remoteHavenoDaemonNodeConfig!.host,
          _remoteHavenoDaemonNodeConfig!.port,
          _remoteHavenoDaemonNodeConfig!.clientAuthPassword,
        );
        print("Should be connected to Daemon!");
        _hasHavenoDaemonNodeConfig = true;
      } catch (e) {
        print("Failed to connect to HavenoService: $e");
      }
    } else {
      // Not yet paired with desktop
      _hasHavenoDaemonNodeConfig = false;
    }

    // Delay the initialization of providers until the widget is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await havenoChannel.onConnected;
      print("Haveno Daemon Connected!");
      await createSyncManagerWithTasks();
      print("Created sync manager with tasks!");
    });

  }

  Future<void> createSyncManagerWithTasks() async {

    var syncManager = SyncManager(checkInterval: const Duration(seconds: 1));

    // Access providers using context now that the widget is fully initialized
    var offersProvider = Provider.of<OffersProvider>(context, listen: false);
    var pricesProvider = Provider.of<PricesProvider>(context, listen: false);
    var walletsProvider = Provider.of<WalletsProvider>(context, listen: false);
    var tradesProvider = Provider.of<TradesProvider>(context, listen: false);

    var fetchOffersTask = SyncTask(taskFunction: offersProvider.getAllOffers, cooldown: const Duration(minutes: 3));
    var fetchPricesTask = SyncTask(taskFunction: pricesProvider.getXmrMarketPrices, cooldown: const Duration(seconds: 5));
    var fetchBalancesTask = SyncTask(taskFunction: walletsProvider.getBalances, cooldown: const Duration(minutes: 2));
    var fetchTransactionsTask = SyncTask(taskFunction: walletsProvider.getXmrTxs, cooldown: const Duration(minutes: 2));
    //var fetchTrades = SyncTask(taskFunction: tradesProvider.getTrades, cooldown: const Duration(minutes: 1));

    syncManager.addTask(fetchOffersTask);
    syncManager.addTask(fetchPricesTask);
    syncManager.addTask(fetchBalancesTask);
    //syncManager.addTask(fetchTrades);
    syncManager.addTask(fetchTransactionsTask);

    // Start the sync manager (if it needs to run immediately)

    syncManager.start();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}