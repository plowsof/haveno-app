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


import 'dart:io';

class LaunchctlManager {
  // Method to execute a launchctl command
  Future<ProcessResult> _runLaunchctl(List<String> arguments) async {
    String printArgs = arguments.join(' ');
    print("Running command: launchctl $printArgs");
    return await Process.run('launchctl', arguments);
  }

  // Load a LaunchAgent or LaunchDaemon
  Future<void> load(String plistPath) async {
    try {
      await _runLaunchctl(['unload', '-w', plistPath]);
    } catch (e) {
      // no worries if there was an error its probably already unloaded
    }
    final result = await _runLaunchctl(['load', '-w', plistPath]);
    print("${result.stdout} : ${result.stderr}");
    if (result.exitCode == 0) {
      print('Successfully loaded: $plistPath');
    } else {
      print('Failed to load: $plistPath\n${result.stderr}');
    }
  }

  // Unload a LaunchAgent or LaunchDaemon
  Future<void> unload(String plistPath) async {
    final result = await _runLaunchctl(['unload', plistPath]);
    if (result.exitCode == 0) {
      print('Successfully unloaded: $plistPath');
    } else {
      print('Failed to unload: $plistPath\n${result.stderr}');
    }
  }

  // List all loaded LaunchAgents and LaunchDaemons
  Future<void> list() async {
    final result = await _runLaunchctl(['list']);
    if (result.exitCode == 0) {
      print(result.stdout);
    } else {
      print('Failed to list services\n${result.stderr}');
    }
  }

  // Bootstrap a LaunchAgent or LaunchDaemon
  Future<void> bootstrap(String domain, String plistPath) async {
    final result = await _runLaunchctl(['bootstrap', domain, plistPath]);
    if (result.exitCode == 0) {
      print('Successfully bootstrapped: $plistPath in $domain');
    } else {
      print('Failed to bootstrap: $plistPath in $domain\n${result.stderr}');
    }
  }

  // Debug a service
  Future<void> debug(String serviceTarget, {String? stdoutPath, String? stderrPath, List<String>? environment}) async {
    List<String> arguments = ['debug', serviceTarget];
    if (stdoutPath != null) {
      arguments.addAll(['--stdout', stdoutPath]);
    }
    if (stderrPath != null) {
      arguments.addAll(['--stderr', stderrPath]);
    }
    if (environment != null) {
      arguments.add('--environment');
      arguments.addAll(environment);
    }
    final result = await _runLaunchctl(arguments);
    if (result.exitCode == 0) {
      print('Successfully started debugging: $serviceTarget');
    } else {
      print('Failed to start debugging: $serviceTarget\n${result.stderr}');
    }
  }

  // Set environment variables
  Future<void> setenv(String key, String value) async {
    final result = await _runLaunchctl(['setenv', key, value]);
    if (result.exitCode == 0) {
      print('Successfully set environment variable: $key=$value');
    } else {
      print('Failed to set environment variable: $key\n${result.stderr}');
    }
  }

  // Unset environment variables
  Future<void> unsetenv(String key) async {
    final result = await _runLaunchctl(['unsetenv', key]);
    if (result.exitCode == 0) {
      print('Successfully unset environment variable: $key');
    } else {
      print('Failed to unset environment variable: $key\n${result.stderr}');
    }
  }
}
