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
import 'package:flutter/material.dart';
import 'package:haveno/grpc_models.dart';
import 'package:haveno/profobuf_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class DeviceManagerAutoInitialization {  
  Future<void> init();
}

abstract class PollingProvider with ChangeNotifier {
  Timer? _timer;
  bool _isPolling = false;
  final Duration maxPollingInterval;

  PollingProvider(this.maxPollingInterval);

  // Method to be implemented by subclasses to define the polling action
  Future<void> pollAction();

  // Method to start polling with a custom interval
  void startPolling([Duration? interval]) {
    if (_isPolling) return; // Prevent multiple polling tasks

    _isPolling = true;
    _timer = Timer.periodic(interval ?? maxPollingInterval, (Timer t) async {
      await pollAction();
    });
  }

  // Method to stop polling
  void stopPolling() {
    _timer?.cancel();
    _isPolling = false;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

class SyncTask {
  final Future<void> Function() taskFunction;
  final Duration cooldown;
  final List<SyncTask> dependencies;
  DateTime _lastRun;

  SyncTask({
    required this.taskFunction,
    required this.cooldown,
    this.dependencies = const [], // Default to no dependencies
  }) : _lastRun = DateTime.fromMillisecondsSinceEpoch(0); // Initialize to a time far in the past

  bool shouldRun() {
    // Check if all dependencies have been run
    bool dependenciesMet = dependencies.every((task) => task.hasRun);

    // Check if cooldown period has passed and dependencies are met
    return dependenciesMet && DateTime.now().difference(_lastRun) >= cooldown;
  }

  Future<void> run() async {
    if (shouldRun()) {
      await taskFunction();
      _lastRun = DateTime.now();
    }
  }

  bool get hasRun => _lastRun.isAfter(DateTime.fromMillisecondsSinceEpoch(0));
}

class SyncManager {
  final List<SyncTask> _tasks = [];
  final Duration checkInterval;
  Timer? _timer;

  SyncManager({required this.checkInterval});

  void addTask(SyncTask task) {
    _tasks.add(task);
  }

  void start() {
    _timer = Timer.periodic(checkInterval, (timer) async {
      // Iterate over tasks, making sure dependencies are resolved
      for (var task in _tasks) {
        await task.run();
      }
    });
  }

  void stop() {
    _timer?.cancel();
  }
}

mixin CooldownMixin {
  final Map<String, Duration> _cooldownDurations = {};

  // Initialize cooldown durations
  void setCooldownDurations(Map<String, Duration> durations) {
    _cooldownDurations.addAll(durations);
  }

  // Check if the cooldown is valid by comparing the current time with the stored last run time
  Future<bool> isCooldownValid(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final lastRunTimestamp = prefs.getInt('cooldown_$key');

    if (lastRunTimestamp == null) return false;  // No previous run recorded, so it's invalid.

    final lastRunTime = DateTime.fromMillisecondsSinceEpoch(lastRunTimestamp);
    final duration = _cooldownDurations[key] ?? const Duration(minutes: 5);
    
    return DateTime.now().isBefore(lastRunTime.add(duration));  // Valid if current time is before cooldown expires.
  }

  // Update the cooldown with the current time and store it in shared_preferences
  Future<void> updateCooldown(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final duration = _cooldownDurations[key] ?? const Duration(minutes: 5);  // Default to 5 minutes if not defined

    final cooldownEndTime = now.add(duration);
    await prefs.setInt('cooldown_$key', cooldownEndTime.millisecondsSinceEpoch);  // Store the expiration time
  }

  // Optionally, you can add a method to clear cooldowns for testing or reset purposes
  Future<void> clearCooldown(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('cooldown_$key');
  }
}


abstract class PlatformLifecycleWidget extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, Widget child) builder;

  const PlatformLifecycleWidget({
    super.key,
    required this.child,
    required this.builder,
  });
}

abstract class PlatformLifecycleState<T extends PlatformLifecycleWidget> extends State<T> {
  Future<void> initPlatform();

  @override
  void initState() {
    super.initState();
    initPlatform();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.child);
  }
}

enum BackgroundEventType {
  updateTorStatus,
  updateDaemonStatus,
  torStdOutLog,
  torStdErrLog,
}

class BackgroundEvent {
  final BackgroundEventType type;
  final Map<String, dynamic> data;

  BackgroundEvent({required this.type, required this.data});
}

class EventDispatcher {
  final Map<BackgroundEventType, List<Function(Map<String, dynamic>)>> _listeners = {};

  void subscribe(BackgroundEventType eventType, Function(Map<String, dynamic>) callback) {
    _listeners[eventType] ??= [];
    _listeners[eventType]!.add(callback);
  }

  void unsubscribe(BackgroundEventType eventType, Function(Map<String, dynamic>) callback) {
    _listeners[eventType]?.remove(callback);
  }

  void dispatch(BackgroundEvent event) {
    if (_listeners[event.type] != null) {
      for (var listener in _listeners[event.type]!) {
        listener(event.data);
      }
    }
  }
}

mixin StreamListenerProviderMixin on ChangeNotifier {
  StreamSubscription? _subscription;

  // A helper function to manage stream subscriptions
  void listenToStream(Stream<void> stream, VoidCallback onData) {
    _subscription = stream.listen((_) {
      onData();  // Perform action when data arrives (e.g., notifyListeners)
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}



// Notification callbacks
typedef NewChatMessageCallback = void Function(ChatMessage chatMessage);
typedef TradeUpdateCallback = void Function(TradeInfo trade, bool isNewTrade);

// Background service callbacks
typedef UpdateTorStatusBackgroundCallback = void Function(String status, String detail);
typedef UpdateDaemonStatusBackgroundCallback = void Function(String status, String detail);
typedef TorStdOutLogBackgroundCallback = void Function(String details);
typedef TorStdErrLogBackgroundCallback = void Function(String details);
