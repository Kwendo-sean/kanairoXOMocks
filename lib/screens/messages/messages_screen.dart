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
      userImage: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop',
      lastMessage: 'Looking forward to the gallery opening tomorrow!',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
      unreadCount: 2,
      isOnline: true,
    ),
    Chat(
      id: '2',
      userId: 'user2',
      userName: 'Marcus',
      userImage: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
      lastMessage: 'The jazz night was amazing. Thanks for joining!',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 0,
      isOnline: false,
    ),
    Chat(
      id: '3',
      userId: 'user3',
      userName: 'Amina',
      userImage: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop',
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
      backgroundColor: AppConstants.primaryBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppStrings.messagesTitle,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // Navigate to new message screen
            },
            icon: Icon(PhosphorIcons.plus()),
            color: AppConstants.primaryBlack,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stories/Status header
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // My status
                Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppConstants.primaryRed,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              PhosphorIcons.plus(),
                              color: AppConstants.primaryRed,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'My Status',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Other users' status
                ..._chats.map((chat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: chat.hasUnseenStory 
                                  ? AppConstants.primaryRed 
                                  : AppConstants.lightGray,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(chat.userImage),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          chat.userName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Active Now section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Active Now',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'See All',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppConstants.primaryRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Active users horizontal list
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _chats.where((c) => c.isOnline).length,
              itemBuilder: (context, index) {
                final activeChat = _chats.where((c) => c.isOnline).toList()[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(activeChat.userImage),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppConstants.successGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activeChat.userName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Chats list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      children: [
                        Text(
                          'Messages',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_chats.length}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppConstants.primaryRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: _chats.length,
                      itemBuilder: (context, index) {
                        final chat = _chats[index];
                        return ChatHeader(
                          chat: chat,
                          onTap: () => _navigateToChat(chat),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}