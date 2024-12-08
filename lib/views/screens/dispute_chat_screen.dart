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
import 'package:haveno_app/providers/haveno_client_providers/disputes_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:haveno_app/providers/haveno_client_providers/trades_provider.dart';
import 'package:chatview/chatview.dart';

class DisputeChatScreen extends StatefulWidget {
  final String tradeId;

  const DisputeChatScreen({super.key, required this.tradeId});

  @override
  _DisputeChatScreenState createState() => _DisputeChatScreenState();
}

class _DisputeChatScreenState extends State<DisputeChatScreen> {
  ChatController? _chatController;
  late final ChatUser _systemUser;
  late final ChatUser _myUser;
  late String _tradePeerId;
  late ChatUser _tradePeerUser;
  late String _arbitratorId;
  late ChatUser _arbitratorUser;
  Dispute? _dispute;
  TradeInfo? _trade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _systemUser = ChatUser(id: 'system', name: 'System');
    _myUser = ChatUser(id: 'me', name: 'Me');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeDisputeData() async {
    _trade = await _getTrade(widget.tradeId);
    if (_trade == null) {
      Navigator.of(context).pop(); // Exit if trade is not found
      return;
    }
    _dispute = Provider.of<DisputesProvider>(context, listen: false).getDisputeByTradeId(widget.tradeId);
    _setUserRoles();
    await _initializeChatController();
  }

  Future<TradeInfo?> _getTrade(String tradeId) async {
    final tradesProvider = Provider.of<TradesProvider>(context, listen: false);
    await tradesProvider.getTrade(tradeId);
    var trade = tradesProvider.trades.firstWhere((trade) => trade.tradeId == tradeId);
    return trade;
  }

  void _setUserRoles() {
    if (_trade == null) return;

    _tradePeerId = _trade!.tradePeerNodeAddress.split('.').first;
    _arbitratorId = _trade!.arbitratorNodeAddress.split('.').first;

    _tradePeerUser = ChatUser(id: _tradePeerId, name: 'Peer');
    _arbitratorUser = ChatUser(id: _arbitratorId, name: 'Arbitrator');

    print(_myUser.id);
    print(_tradePeerUser.id);
  }

  Future<void> _initializeChatController() async {
    if (_chatController != null || _trade == null || _dispute == null) return;

    final disputesProvider = Provider.of<DisputesProvider>(context, listen: false);
    List<ChatMessage> chatMessages = [];

    if (_trade!.disputeState != 'NO_DISPUTE') {
      try {
        await disputesProvider.loadInitialMessages(_dispute!.id);
        List<ChatMessage>? disputeChatMessages = disputesProvider.getInitialChatMessages(_dispute!.id);
        chatMessages.addAll(disputeChatMessages);

        disputesProvider.chatMessagesStream(_dispute!.id).listen((newMessages) {
          _updateChatControllerWithNewMessages(newMessages);
        });
      } catch (e) {
        print("Dispute state is set but provider returned no dispute");
      }
    }

    chatMessages.sort((a, b) => a.date.compareTo(b.date));

    final messageList = chatMessages.map(_mapChatMessageToMessage).toList();

    _chatController = ChatController(
      initialMessageList: messageList,
      scrollController: ScrollController(),
      currentUser: _myUser,
      otherUsers: [_tradePeerUser, _arbitratorUser, _systemUser],
    );
  }

  void _updateChatControllerWithNewMessages(List<ChatMessage> newMessages) {
    final newMessageList = newMessages.map(_mapChatMessageToMessage).toList();
    for (var message in newMessageList) {
      _chatController?.addMessage(message);
    }
  }

  Message _mapChatMessageToMessage(ChatMessage chatMessage) {
    final senderNodeAddress = chatMessage.senderNodeAddress.hostName.split('.').first;

    final sentBy = senderNodeAddress == _tradePeerId
        ? _tradePeerId
        : senderNodeAddress == _arbitratorId
            ? _arbitratorId
            : chatMessage.isSystemMessage
                ? _systemUser.name
                : _myUser.name;

    return Message(
      id: chatMessage.uid,
      message: chatMessage.message,
      createdAt: DateTime.fromMillisecondsSinceEpoch(chatMessage.date.toInt()),
      sentBy: sentBy,
      status: chatMessage.acknowledged ? MessageStatus.read : MessageStatus.delivered,
    );
  }

  void _handlePaymentSentPressed() {
    final tradesProvider = Provider.of<TradesProvider>(context, listen: false);
    tradesProvider.confirmPaymentSent(_trade!.tradeId).then((_) {
      _addSystemMessage('Payment marked as sent.');
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm payment: $error')),
      );
    });
  }

  void _handleDisputePressed() {
    final disputesProvider = Provider.of<DisputesProvider>(context, listen: false);
    disputesProvider.openDispute(_trade!.tradeId).then((_) {
      print("Simulating navigation to dispute chat screen");
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to dispute trade: $error')),
      );
    });
  }

  void _handleSendPressed(String messageText, ReplyMessage replyMessage, MessageType messageType) async {
    final newMessage = Message(
      id: const Uuid().v4(),
      message: messageText,
      createdAt: DateTime.now(),
      sentBy: _myUser.name,
      messageType: messageType,
      replyMessage: replyMessage,
    );

    _chatController?.addMessage(newMessage);

    final disputesProvider = Provider.of<DisputesProvider>(context, listen: false);
    try {
      await disputesProvider.sendDisputeChatMessage(_trade!.tradeId, messageText, []);
      newMessage.setStatus = MessageStatus.delivered;
    } catch (e) {
      newMessage.setStatus = MessageStatus.undelivered;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only send 1 message per minute!')),
      );
    }
  }

  void _addSystemMessage(String text) {
    final systemMessage = Message(
      id: const Uuid().v1(),
      message: text,
      createdAt: DateTime.now(),
      sentBy: _systemUser.name,
    );

    _chatController?.addMessage(systemMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeDisputeData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_trade == null || _dispute == null) {
            return const Center(child: Text("Trade or Dispute not found"));
          }

          return ChatView(
            chatController: _chatController!,
            onSendTap: _handleSendPressed,
            chatViewState: _chatController!.initialMessageList.isEmpty ? ChatViewState.noData : ChatViewState.hasMessages,
            appBar: ChatViewAppBar(
              backGroundColor: Theme.of(context).scaffoldBackgroundColor,
              chatTitle: 'Support Chat for Trade #${_trade!.shortId}',
              userStatus: 'Active',
              actions: [
                if (_trade!.isPaymentSent)
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _handlePaymentSentPressed,
                    tooltip: 'Confirm Transfer of Funds',
                  ),
              ],
            ),
            featureActiveConfig: const FeatureActiveConfig(
              enableSwipeToReply: true,
              enableSwipeToSeeTime: true,
            ),
            chatBackgroundConfig: ChatBackgroundConfiguration(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              messageSorter: (message1, message2) {
                return message1.createdAt.compareTo(message2.createdAt);
              },
            ),
            sendMessageConfig: const SendMessageConfiguration(
              replyMessageColor: Colors.white,
              replyDialogColor: Colors.blue,
              replyTitleColor: Colors.black,
              closeIconColor: Colors.black,
              textFieldBackgroundColor: Color(0xFF424242),
              textFieldConfig: TextFieldConfiguration(),
              enableCameraImagePicker: true,
              enableGalleryImagePicker: true,
            ),
            chatBubbleConfig: ChatBubbleConfiguration(
              outgoingChatBubbleConfig: const ChatBubble(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              inComingChatBubbleConfig: ChatBubble(
                color: Colors.black.withOpacity(0.2),
                textStyle: const TextStyle(color: Colors.white),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
