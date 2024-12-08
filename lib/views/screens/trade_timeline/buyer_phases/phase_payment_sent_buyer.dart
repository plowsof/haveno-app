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
import 'package:haveno/grpc_models.dart';
import 'package:haveno_app/views/screens/trade_chat_screen.dart';
import 'package:haveno_app/views/screens/trade_timeline/phase_base.dart';

class PhasePaymentSentBuyer extends PhaseBase {
  final TradeInfo trade;

  const PhasePaymentSentBuyer({super.key, required this.trade})
      : super(phaseText: "Seller Confirming Payment");

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scrollable content (if any, here it's just a placeholder for your phase text)
        Padding(
          padding: const EdgeInsets.only(bottom: 80.0), // Adjust padding for button space
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  phaseText,
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
        ),
        // Static chat button at the bottom
        Positioned(
          bottom: 16.0,
          right: 16.0,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TradeChatScreen(tradeId: trade.tradeId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(48, 48), // Set the height and width
              padding: EdgeInsets.zero, // Remove extra padding
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Icon(Icons.chat),
          ),
        ),
      ],
    );
  }
}
