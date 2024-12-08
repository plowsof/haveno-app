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
import 'package:chatview/chatview.dart';
import 'package:haveno/profobuf_models.dart';
import 'package:uuid/uuid.dart';

abstract class BaseChatScreen extends StatefulWidget {
  final String chatId;
  final String chatTitle;

  const BaseChatScreen({super.key, required this.chatId, required this.chatTitle});

  @override
  BaseChatScreenState createState();
}

abstract class BaseChatScreenState<T extends BaseChatScreen> extends State<T> {
  ChatController? _chatController;
  late final ChatUser _systemUser = ChatUser(id: 'me', name: 'Me');
  late final ChatUser _myUser = ChatUser(id: 'me', name: 'Me');
  List<ChatUser> otherUsers = [];

  @override
  void initState() {
    super.initState();
    _initializeChatController();
  }

  @override
  void dispose() {
    _chatController?.scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChatController() async {
    final chatMessages = await loadChatMessages();

    // Map ChatMessage to the Message type expected by the ChatController
    final messageList = chatMessages.map(_mapChatMessageToMessage).toList();

    _chatController = ChatController(
      initialMessageList: messageList,
      scrollController: ScrollController(),
      currentUser: _myUser,
      otherUsers: otherUsers,
    );
  }

  Message _mapChatMessageToMessage(ChatMessage chatMessage) {
    final sentBy = _determineSender(chatMessage);
    return Message(
      id: chatMessage.uid,
      message: chatMessage.message,
      createdAt: DateTime.fromMillisecondsSinceEpoch(chatMessage.date.toInt()),
      sentBy: sentBy,
      status: chatMessage.acknowledged ? MessageStatus.read : MessageStatus.delivered,
    );
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
        future: _initializeChatController(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return ChatView(
            chatController: _chatController!,
            onSendTap: _handleSendPressed,
            chatViewState: _chatController!.initialMessageList.isEmpty ? ChatViewState.noData : ChatViewState.hasMessages,
            appBar: ChatViewAppBar(
              backGroundColor: Theme.of(context).scaffoldBackgroundColor,
              profilePicture: 'X',
              chatTitle: widget.chatTitle,
              userStatus: 'Active',
              actions: buildAppBarActions(),
            ),
            featureActiveConfig: const FeatureActiveConfig(
              enableSwipeToReply: true,
              enableSwipeToSeeTime: true,
            ),
            chatBackgroundConfig: ChatBackgroundConfiguration(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              messageSorter: (message1, message2) {
                return message1.createdAt.compareTo(message2.createdAt);
              }
            ),
            sendMessageConfig: const SendMessageConfiguration(
              replyMessageColor: Colors.white,
              replyDialogColor: Colors.blue,
              replyTitleColor: Colors.black,
              closeIconColor: Colors.black,
              textFieldBackgroundColor: Color(0xFF424242),
              textFieldConfig: TextFieldConfiguration()
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

  void _handleSendPressed(String messageText, ReplyMessage replyMessage, MessageType messageType) async {
    final newMessage = Message(
      id: Uuid().v4(),
      message: messageText,
      createdAt: DateTime.now(),
      sentBy: 'me',
      messageType: messageType,
      replyMessage: replyMessage,
    );

    _chatController?.addMessage(newMessage);

    try {
      await sendMessage(messageText);
      newMessage.setStatus = MessageStatus.delivered;
    } catch (e) {
      newMessage.setStatus = MessageStatus.undelivered;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sending failed!')),
      );
    }
  }

  // These methods are to be implemented by subclasses
  Future<List<ChatMessage>> loadChatMessages();
  String _determineSender(ChatMessage chatMessage);
  Future<void> sendMessage(String messageText);
  List<Widget> buildAppBarActions();
}
