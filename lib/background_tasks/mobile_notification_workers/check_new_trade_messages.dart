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

/* import 'package:haveno_app/background_tasks/mobile_notification_workers/schema.dart';
import 'package:haveno_app/proto/compiled/pb.pb.dart';
import 'package:haveno_app/proto/compiled/grpc.pb.dart';
import 'package:haveno_app/services/haveno_grpc_clients/trades_client_service.dart';

class CheckNewTradeMessagesTask extends MobileTask {
  @override
  Future<void> run() async {
    TradesClientService tradesClient = TradesClientService(havenoService: havenoService);
    List<TradeInfo>? trades = await tradesClient.getTrades();

    if (trades != null) {
      for (var trade in trades) {
        List<ChatMessage>? chatMessages = await tradesClient.getChatMessages(trade.tradeId);
        for (var message in chatMessages!) {
          bool isNewMessage = await db.isTradeChatMessageNew(message.uid);
          await db.insertTradeChatMessage(message, trade.tradeId);

          if (!trade.role.contains('buyer') && (trade.tradePeerNodeAddress != trade.contract.buyerNodeAddress)) {
            if (isNewMessage) {
              await sendNotification(
                id: message.uid.hashCode,
                title: 'New Trade Message',
                body: message.message,
              );
            }
          }
        }
        //await Future.delayed(const Duration(minutes: 1));
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