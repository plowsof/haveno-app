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
import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart';
import 'package:haveno/haveno_client.dart';
import 'package:haveno/haveno_service.dart';
import 'package:haveno/profobuf_models.dart';

class DisputesProvider with ChangeNotifier {
  final HavenoChannel _havenoChannel = HavenoChannel();
  List<Dispute?> _disputes = [];

  // Map to hold StreamControllers for each chat
  final Map<String, StreamController<List<ChatMessage>>> _chatControllers = {};

  // Map to store unique chat messages for each dispute
  final Map<String, List<ChatMessage>> _chatMessages = {};

  // Map to store tradeId to disputeId mapping
  final Map<String, String> _disputeToTradeIdMap = {};

  // TradeID to dispute map
  final Map<String, Dispute> _tradeIdToDisputeMap = {};

  DisputesProvider(); //: super(const Duration(minutes: 1));

  @override
  void dispose() {
    // Close all StreamControllers when the provider is disposed
    _chatControllers.forEach((_, controller) => controller.close());
    super.dispose();
  }

  // Method to get or create a StreamController for a specific chat
  Stream<List<ChatMessage>> chatMessagesStream(String disputeId) {
    if (!_chatControllers.containsKey(disputeId)) {
      _chatControllers[disputeId] = StreamController<List<ChatMessage>>.broadcast();

      // Start polling for new messages (if needed)
      _startPolling(disputeId);
    }
    return _chatControllers[disputeId]!.stream;
  }

  // Load initial messages independently of stream creation
  Future<void> loadInitialMessages(String disputeId) async {
    // Retrieve the tradeId from the mapping
    final tradeId = _disputeToTradeIdMap[disputeId];
    if (tradeId == null) return;

    // Retrieve the dispute from the _disputes list using the disputeId
    Dispute? dispute = _disputes.firstWhere((d) => d!.id == disputeId, orElse: () => null);

    if (dispute != null) {
      print("Setting chat messages for dispute: $disputeId with ${dispute.chatMessage.length} messages");

      // Store the chat messages in _chatMessages for this disputeId
      _chatMessages[disputeId] = dispute.chatMessage;

      // If a stream controller exists for this disputeId, add the messages to the stream
      if (_chatControllers.containsKey(disputeId)) {
        _chatControllers[disputeId]!.add(_chatMessages[disputeId]!);
      }
    } else {
      // Handle case where no dispute is found
      print("No dispute found for ID: $disputeId");
      _chatMessages[disputeId] = [];
    }
  }

  List<ChatMessage> getInitialChatMessages(String disputeId) {
    print("Getting initial chat messages for dispute: $disputeId");
    return _chatMessages[disputeId] ?? [];
  }

/// Probsblt just redo the polling when not tired
  void _startPolling(String disputeId) {
    Timer.periodic(const Duration(minutes: 2), (timer) async {
      print("POLLIN FROM DISPUTES PROVIER");
      // Get the tradeId from the mapping using disputeId
      final tradeId = _disputeToTradeIdMap[disputeId];
      if (tradeId == null) {
        print("No tradeId found for disputeId: $disputeId");
        return;
      }

      Dispute? dispute = await getDispute(tradeId);
      if (dispute != null && dispute.id == disputeId) {
        for (var message in dispute.chatMessage) {
          if (message.senderIsTrader) {
            return;
          }
          if (!_chatMessages[disputeId]!.contains(message)) {
            _chatMessages[disputeId]!.add(message);
            if (_chatControllers.containsKey(disputeId)) {
              _chatControllers[disputeId]!.add(_chatMessages[disputeId]!);
            }
          }
        }
      }
    });
  }

void debugPrintTradeIdToDisputeMap() {
  if (_tradeIdToDisputeMap.isEmpty) {
    print("The _tradeIdToDisputeMap is currently empty.");
  } else {
    //_tradeIdToDisputeMap.forEach((tradeId, dispute) {
      //print('Trade ID: $tradeId, Dispute ID: ${dispute.id}');
    //});
  }
}
Dispute? getDisputeByTradeId(String tradeId) {
  print("Attempting to retrieve dispute for Trade ID: $tradeId");

  if (_tradeIdToDisputeMap.containsKey(tradeId)) {
    print("Dispute found for Trade ID: $tradeId");
    debugPrintTradeIdToDisputeMap(); // Print the entire map for debugging
    return _tradeIdToDisputeMap[tradeId];
  } else {
    print("No dispute found for Trade ID: $tradeId");
    //debugPrintTradeIdToDisputeMap(); // Print the entire map for debugging
    return null;
  }
}

Future<List<Dispute>?> getDisputes() async {
    List<Dispute> disputes = [];
    // Attempt to retrieve disputes from the service
    try {
      var disputeClient = DisputeService();
      disputes = await disputeClient.getDisputes();
    } catch (e) {
      return null;
    }

    // Extract the list of disputes
    List<Dispute> disputesList = disputes;

    // Check if the disputes list is empty
    if (disputesList.isEmpty) {
      print("No disputes found.");
    } else {
      // Iterate through each dispute and map the tradeId to the dispute
      for (var dispute in disputesList) {
        _disputeToTradeIdMap[dispute.id] = dispute.tradeId;
        _tradeIdToDisputeMap[dispute.tradeId] = dispute;

        // Debugging output to verify the mapping
        print("Mapping added: Trade ID ${dispute.tradeId} -> Dispute ID ${dispute.id}");
        print("Current _tradeIdToDisputeMap contents:");
        _tradeIdToDisputeMap.forEach((tradeId, mappedDispute) {
          print("Trade ID: $tradeId, Dispute ID: ${mappedDispute.id}");
        });
      }
    }

    // Assign disputes to the internal list and notify listeners
    _disputes = disputesList;
    notifyListeners();
    return null;
}

Future<Dispute?> getDispute(String tradeId) async {
  try {
    await _havenoChannel.onConnected;
    Dispute? dispute;
    var disputeClient = DisputeService();
    dispute = await disputeClient.getDispute(tradeId);

    Dispute? newDispute = dispute;
    
    if (newDispute != null) {
      _disputeToTradeIdMap[newDispute.id] = tradeId;
      _tradeIdToDisputeMap[newDispute.tradeId] = newDispute;

      // Update the _disputes list or map if necessary
      final int existingIndex = _disputes.indexWhere((d) => d!.id == newDispute.id);

      if (existingIndex != -1) {
        _disputes[existingIndex] = newDispute;
      } else {
        _disputes.add(newDispute);
      }

      notifyListeners();
      return newDispute;
    }
    return null;
  } catch (e) {
    print("Failed to get dispute: $e");
    return null;
  }
}

  Future<void> resolveDispute(String tradeId, DisputeResult_Winner? winner, DisputeResult_Reason? reason, String? summaryNotes, Int64? customPayoutAmount) async {
    await _havenoChannel.onConnected;

    Dispute? dispute = await getDispute(tradeId);
    if (!dispute!.isOpener) {
      throw Exception("You can't close a dispute you didn't open!");
    }

    try {
      DisputeService().resolveDispute(
        tradeId,
        winner,
        reason,
        summaryNotes,
        customPayoutAmount,
      );

      getDisputes();
    } catch (e) {
      print("Failed to resolve dispute: $e");
      rethrow;
    }
  }

  Future<Dispute?> openDispute(String tradeId) async {
    await _havenoChannel.onConnected;
    try {
      await DisputeService().openDispute(tradeId);
      await getDisputes();
      Dispute? dispute = _disputes.firstWhere((d) => d!.tradeId == tradeId, orElse: () => null);
      return dispute;
    } catch (e) {
      print("Failed to open dispute: $e");
      rethrow;
    }
  }

  Future<void> sendDisputeChatMessage(String disputeId, String message, Iterable<Attachment> attachments) async {
    await _havenoChannel.onConnected;
    try {
      await DisputeService().sendDisputeChatMessage(
        disputeId,
        message,
        attachments,
      );

      // Might need to create a fake protobuf message and add it to the stream controller just to conform (so the message appears instantly)

    } catch (e) {
      print("Failed to send dispute chat message: $e");
      rethrow;
    }
  }

  // Optional: Method to close a specific chat stream
  void closeChat(String disputeId) {
    if (_chatControllers.containsKey(disputeId)) {
      _chatControllers[disputeId]!.close();
      _chatControllers.remove(disputeId);
      _chatMessages.remove(disputeId);
      _disputeToTradeIdMap.remove(disputeId);
    }
  }

  void addChatMessage(ChatMessage chatMessage) {
    // do something special!!!
  }
  
//  @override
//  Future<void> pollAction() async {
//    getDisputes();
//  }

}



class DisputeChatProvider with ChangeNotifier {
  final HavenoChannel _havenoChannel;

  // Map to store StreamControllers for each chat
  final Map<String, StreamController<List<ChatMessage>>> _chatControllers = {};

  // Map to store chat messages
  final Map<String, List<ChatMessage>> _chatMessages = {};

  DisputeChatProvider(this._havenoChannel);

  // Get or create a StreamController for specific chat
  Stream<List<ChatMessage>> chatMessagesStream(String disputeId) {
    if (!_chatControllers.containsKey(disputeId)) {
      _chatControllers[disputeId] = StreamController<List<ChatMessage>>.broadcast();
      // Load initial messages and start polling if needed
      _startPolling(disputeId);
    }
    return _chatControllers[disputeId]!.stream;
  }

  // Load initial messages for the dispute
  Future<void> loadInitialMessages(String disputeId, Dispute dispute) async {
    _chatMessages[disputeId] = dispute.chatMessage;
    if (_chatControllers.containsKey(disputeId)) {
      _chatControllers[disputeId]!.add(_chatMessages[disputeId]!);
    }
  }

  // Add a new message
  void addChatMessage(String disputeId, ChatMessage message) {
    if (!_chatMessages.containsKey(disputeId)) {
      _chatMessages[disputeId] = [];
    }
    _chatMessages[disputeId]!.add(message);
    _chatControllers[disputeId]?.add(_chatMessages[disputeId]!);
  }

  Future<void> sendDisputeChatMessage(String disputeId, String message, Iterable<Attachment> attachments) async {
    await _havenoChannel.onConnected;
    try {
      await DisputeService().sendDisputeChatMessage(
        disputeId,
        message,
        attachments,
      );
    } catch (e) {
      print("Failed to send dispute chat message: $e");
      rethrow;
    }
  }

  void _startPolling(String disputeId) {
    Timer.periodic(const Duration(minutes: 2), (timer) async {
      // Implement polling logic to fetch new messages periodically
      print("Polling for new messages for dispute: $disputeId");
      // Fetch dispute or chat messages and update the stream
    });
  }

  @override
  void dispose() {
    _chatControllers.forEach((_, controller) => controller.close());
    super.dispose();
  }
}