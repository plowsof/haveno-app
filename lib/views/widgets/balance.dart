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


import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:haveno_app/utils/payment_utils.dart';
import 'package:provider/provider.dart';
import 'package:haveno_app/providers/haveno_client_providers/wallets_provider.dart';

class MoneroBalanceWidget extends StatelessWidget {
  const MoneroBalanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletsProvider>(
      builder: (context, walletsProvider, child) {
        if (walletsProvider.balances == null) {
          // Load balances only if not already loaded
          walletsProvider.getBalances();
        }

        if (walletsProvider.balances == null) {
          // Show loading animation only if it's the first time loading
          return const AnimatedDots();
        } else {
          // Show the current balance
          final balances = walletsProvider.balances;
          final balance = (balances?.xmr.balance ?? Int64(0)) +
              (balances?.xmr.reservedOfferBalance ?? Int64(0)) +
              (balances?.xmr.reservedTradeBalance ?? Int64(0));

          final formattedBalance = formatXmr(balance);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: const Color(0xFF424242),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: const Color(0xFF2E2E2E),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 28.0,  // Match this height to the ExchangeRateWidget height
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A4A4A),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.monero,
                      color: Color(0xFFFF6602),
                      size: 18.0, // Adjust icon size to fit within the height
                    ),
                  ),
                ),
                const SizedBox(width: 6.0),
                Container(
                  height: 28.0,  // Ensure the height is consistent with the icon box
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Center(
                    child: Text(
                      formattedBalance,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

class AnimatedDots extends StatefulWidget {
  const AnimatedDots({super.key});

  @override
  _AnimatedDotsState createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<AnimatedDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 3.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: const Color(0xFF2E2E2E),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value > index && _animation.value < index + 1
                    ? 1.0
                    : 0.3,
                child: const Text(
                  '.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
