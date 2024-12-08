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

/* // mobile_tasks/check_new_trades.dart

import 'package:haveno_app/background_tasks/mobile_notification_workers/schema.dart';

import 'package:haveno_app/proto/compiled/grpc.pb.dart';
import 'package:haveno_app/services/haveno_grpc_clients/trades_client_service.dart';
import 'package:haveno_app/utils/payment_utils.dart';

class CheckNewTradesTask extends MobileTask {

  CheckNewTradesTask() : super(minIntervalDuration: const Duration(minutes: 10));

  @override
  Future<void> run() async {
    TradesClientService tradesClient = TradesClientService(havenoService: havenoService);
    List<TradeInfo>? trades = await tradesClient.getTrades();

    if (trades != null) {
      for (var trade in trades) {
        bool isNewTrade = await db.isTradeNew(trade.tradeId);
        await db.insertTrade(trade);

        if (isNewTrade) {
          await sendNotification(
            id: trade.tradeId.hashCode,
            title: 'New Trade',
            body: 'You have a new trade for ${formatXmr(trade.amount)} XMR',
          );
        }
      }
    }
  }

  @override
  Future<void> updateState() {
    // Implement state update logic if needed
    throw UnimplementedError();
  }
}
 */