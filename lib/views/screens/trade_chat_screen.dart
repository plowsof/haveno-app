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
import 'package:haveno_app/utils/human_readable_helpers.dart';
import 'package:haveno_app/views/screens/dispute_chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:haveno_app/providers/haveno_client_providers/trades_provider.dart';
import 'package:chatview/chatview.dart';

class TradeChatScreen extends StatefulWidget {
  final String tradeId;

  const TradeChatScreen({super.key, required this.tradeId});

  @override
  _TradeChatScreenState createState() => _TradeChatScreenState();
}

class _TradeChatScreenState extends State<TradeChatScreen> {
  ChatController? _chatController;
  late final ChatUser _systemUser;
  late final ChatUser _myUser;
  late String _tradePeerId;
  late ChatUser _tradePeerUser;
  late String _arbitratorId;
  late ChatUser _arbitratorUser;
  late ChatViewState _chatViewState;
  late String _chatUserStatus;
  TradeInfo? _trade;
  Dispute? _dispute;
  late TradesProvider _tradesProvider;

  @override
  void initState() {
    super.initState();
    _systemUser = ChatUser(id: 'system', name: 'System');
    _myUser = ChatUser(id: 'me', name: 'Me');
    _chatViewState = ChatViewState.hasMessages;

    // Store a reference to the provider
    _tradesProvider = Provider.of<TradesProvider>(context, listen: false);
    // Listen for changes in chat messages
    _tradesProvider.onNewChatMessage = (chatMessage) {
      _handleNewChatMessage(chatMessage);
    };
    _tradesProvider.onTradeUpdate = (trade, isNewTrade) {
      if (!isNewTrade) {
        _handleTradeUpdate(trade);
      }
    };

    // Initialize trade data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTradeData();
    });
  }

  void _handleNewChatMessage(ChatMessage chatMessage) {
    if (!mounted) return;

    List<ChatMessage> chatMessages = _tradesProvider.chatMessages[widget.tradeId] ?? [];

    for (var chatMessage in chatMessages) {
      bool messageExists = _chatController?.initialMessageList.any((msg) => msg.id == chatMessage.uid) ?? false;

      if (!messageExists) {
        final message = _mapChatMessageToMessage(chatMessage);
        _chatController?.addMessage(message);

        if (_chatViewState == ChatViewState.noData) {
          setState(() {
            _chatViewState = ChatViewState.hasMessages;
          });
        }
      }
    }
  }

  void _handleTradeUpdate(TradeInfo trade) {
    if (trade.tradeId == _trade?.tradeId) {
      if (trade.state != _trade?.state) {
        _trade = trade;
        setState(() {
          _chatUserStatus = humanReadablePhaseAs(
            _trade!.phase,
            _trade!.role.contains('buyer'),
            true,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeTradeData() async {
    _trade = await _getTrade(widget.tradeId);
    if (_trade == null && mounted) {
      Navigator.of(context).pop(); // Exit if trade is not found
      return;
    }
    if (_trade != null) {
      _chatUserStatus = humanReadablePhaseAs(_trade!.phase, _trade!.role.contains('buyer'), true);
      _setUserRoles();
      await _initializeChatController();
    }
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

  Future<TradeInfo?> _getTrade(String tradeId) async {
    await _tradesProvider.getTrade(tradeId);
    var trade = _tradesProvider.trades.firstWhere((trade) => trade.tradeId == tradeId);
    return trade;
  }

  Future<void> _initializeChatController() async {
    if (_chatController != null || _trade == null) return;

    await _tradesProvider.getChatMessages(_trade!.tradeId);

    List<ChatMessage> chatMessages = _tradesProvider.chatMessages[_trade!.tradeId] ?? [];
    chatMessages.sort((a, b) => a.date.compareTo(b.date));

    final messageList = chatMessages.map(_mapChatMessageToMessage).toList();

    _chatController = ChatController(
      initialMessageList: messageList,
      scrollController: ScrollController(),
      currentUser: _myUser,
      otherUsers: [_tradePeerUser, _arbitratorUser, _systemUser],
    );

    _chatViewState = _chatController!.initialMessageList.isEmpty
        ? ChatViewState.noData
        : ChatViewState.hasMessages;
  }

  Message _mapChatMessageToMessage(ChatMessage chatMessage) {
    final senderNodeAddress = chatMessage.senderNodeAddress.hostName.split('.').first;

    final sentBy = senderNodeAddress == _tradePeerId
        ? _tradePeerId
        : senderNodeAddress == _arbitratorId
            ? _arbitratorId
            : chatMessage.isSystemMessage
                ? 'system'
                : 'me'; // Assuming messages not matching peer or arbitrator are sent by the user

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
        SnackBar(content: Text('Failed to confirm payment as sent: $error')),
      );
    });
  }

  void _handlePaymentReceivedPressed() async {
    final tradesProvider = Provider.of<TradesProvider>(context, listen: false);
    if (_trade!.disputeState != "NO_DISPUTE") {
      final disputesProvider = Provider.of<DisputesProvider>(context, listen: false);
      try {
        await disputesProvider.resolveDispute(
          _trade!.tradeId,
          DisputeResult_Winner.BUYER,
          DisputeResult_Reason.TRADE_ALREADY_SETTLED,
          "Seller marks payment as received",
          _trade!.sellerPayoutAmount,
        );
      } catch (e) {
        print(e.toString());
      }
    }
    tradesProvider.confirmPaymentReceived(_trade!.tradeId).then((_) {
      _addSystemMessage('Payment marked as received.');
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm payment as received: $error')),
      );
    });
  }

  void _handleDisputePressed() {
    final disputesProvider = Provider.of<DisputesProvider>(context, listen: false);
    disputesProvider.openDispute(_trade!.tradeId).then((dispute) {
      if (dispute != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DisputeChatScreen(tradeId: _trade!.tradeId),
          ),
        );
      } else {
        throw Exception("No dispute object returned");
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to dispute trade: $error')),
      );
    });
  }

  void _handleSwitchToSupportChatPressed() async {
    if (_dispute == null) {
      final disputesProvider = Provider.of<DisputesProvider>(context, listen: false);
      _dispute = await disputesProvider.getDispute(_trade!.tradeId);
    }

    if (_dispute != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisputeChatScreen(tradeId: _trade!.tradeId),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load dispute chat.')),
        );
      }
    }
  }

void _handleSendPressed(String messageText, ReplyMessage replyMessage, MessageType messageType) async {
  final newMessage = Message(
    id: const Uuid().v4(),
    message: messageText,
    createdAt: DateTime.now(),
    sentBy: 'me',
    messageType: messageType,
    replyMessage: replyMessage,
  );

  _chatController?.addMessage(newMessage);

  // Update the state to reflect that there are now messages in the chat
  if (_chatViewState != ChatViewState.hasMessages && newMessage.message.isNotEmpty) {
    setState(() {
      _chatViewState = ChatViewState.hasMessages;
    });
  }

  // If your send message process involves asynchronous calls, you should handle errors like so:
  try {
    final tradesProvider = Provider.of<TradesProvider>(context, listen: false);
    await tradesProvider.sendChatMessage(_trade!.tradeId, messageText);
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
      sentBy: 'system',
    );

    _chatController?.addMessage(systemMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeTradeData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_trade == null) {
            return const Center(child: Text("Trade not found"));
          }

          return ChatView(
            chatController: _chatController!,
            onSendTap: _handleSendPressed,
            chatViewState: _chatViewState,
            chatViewStateConfig: ChatViewStateConfiguration(
              noMessageWidgetConfig: ChatViewStateWidgetConfiguration(
                showDefaultReloadButton: false,
                subTitle: 'Start a conversation below...',
                subTitleTextStyle: TextStyle(color: Colors.white.withOpacity(0.5), ),
                titleTextStyle: TextStyle(inherit: true, color: Colors.white.withOpacity(0.5), fontSize: 21)
              )
            ),
            appBar: ChatViewAppBar(
              backGroundColor: Theme.of(context).scaffoldBackgroundColor,
              chatTitle: 'Trade #${_trade!.shortId}',
              userStatus: _chatUserStatus,
              actions: [
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    switch (value) {
                      case 'Dispute Trade':
                        _handleDisputePressed();
                        break;
                      case 'Switch to Support Chat':
                        _handleSwitchToSupportChatPressed();
                        break;
                      case 'Confirm Transfer of Funds':
                        _handlePaymentSentPressed();
                        break;
                      case 'Confirm Receipt of Funds':
                        _handlePaymentReceivedPressed();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry<String>>[
                      if (_trade!.disputeState == "NO_DISPUTE")
                        const PopupMenuItem<String>(
                          value: 'Dispute Trade',
                          child: Text('Dispute Trade'),
                        ),
                      if (_trade!.disputeState != "NO_DISPUTE")
                        const PopupMenuItem<String>(
                          value: 'Switch to Support Chat',
                          child: Text('Switch to Support Chat'),
                        ),
                      if (!_trade!.isPaymentSent && !_trade!.role.contains('seller'))
                        const PopupMenuItem<String>(
                          value: 'Confirm Transfer of Funds',
                          child: Text('Confirm Transfer of Funds'),
                        ),
                      if (_trade!.role.contains('seller'))
                        const PopupMenuItem<String>(
                          value: 'Confirm Receipt of Funds',
                          child: Text('Confirm Receipt of Funds'),
                        ),
                    ];
                  },
                  icon: const Icon(Icons.more_vert),
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
              margin: const EdgeInsets.fromLTRB(4, 4, 4, 0)
            ),
            sendMessageConfig: SendMessageConfiguration(
              defaultSendButtonColor: Theme.of(context).colorScheme.primary,
              replyMessageColor: Colors.white,
              replyDialogColor: Colors.blue,
              replyTitleColor: Colors.black,
              closeIconColor: Colors.black,
              textFieldBackgroundColor: const Color(0xFF424242),
              textFieldConfig: const TextFieldConfiguration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                contentPadding: EdgeInsets.all(4),
                padding: EdgeInsets.fromLTRB(4, 4, 4, 4),
                margin: EdgeInsets.zero,
                ),
              enableCameraImagePicker: false,
              enableGalleryImagePicker: false,
              allowRecordingVoice: false,
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
