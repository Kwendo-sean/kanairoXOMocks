import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/messages/chat_header.dart';
import 'package:kanairoxo/models/message_model.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final List<Chat> _chats = [
    Chat(
      id: '1',
      userId: 'user1',
      userName: 'Sofia',
      userImage: 'assets/images/kanairoxo_logo.png',
      lastMessage: 'Looking forward to the gallery opening tomorrow!',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
      unreadCount: 2,
      isOnline: true,
    ),
    Chat(
      id: '2',
      userId: 'user2',
      userName: 'Marcus',
      userImage: 'assets/images/kanairoxo_logo.png',
      lastMessage: 'The jazz night was amazing. Thanks for joining!',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 0,
      isOnline: false,
    ),
    Chat(
      id: '3',
      userId: 'user3',
      userName: 'Amina',
      userImage: 'assets/images/kanairoxo_logo.png',
      lastMessage: 'Want to grab coffee this weekend?',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 1,
      isOnline: true,
    ),
  ];
  
  void _navigateToChat(Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chat: chat),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return ChatHeader(
            chat: chat,
            onTap: () => _navigateToChat(chat),
          );
        },
      ),
    );
  }
}