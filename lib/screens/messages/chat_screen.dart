import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  
  const ChatScreen({super.key, required this.chat});
  
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [
    Message(
      id: '1',
      chatId: '1',
      senderId: 'user1',
      content: 'Hi there! How was your weekend?',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
      isDelivered: true,
    ),
    Message(
      id: '2',
      chatId: '1',
      senderId: 'current_user_id',
      content: 'It was great! I went to that gallery opening we talked about.',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: true,
      isDelivered: true,
    ),
    Message(
      id: '3',
      chatId: '1',
      senderId: 'user1',
      content: 'Oh amazing! I wanted to go but had other plans.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
      isDelivered: true,
    ),
    Message(
      id: '4',
      chatId: '1',
      senderId: 'user1',
      content: 'Want to grab coffee this Saturday morning?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isRead: true,
      isDelivered: true,
    ),
  ];
  
  // Removed unused field _isTyping
  
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: widget.chat.id,
      senderId: 'current_user_id',
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
      expiresAt: DateTime.now().add(
        const Duration(hours: 48), // Disappearing messages
      ),
    );
    
    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });
    
    // Simulate reply
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add(Message(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            chatId: widget.chat.id,
            senderId: widget.chat.userId,
            content: 'Sounds good! Looking forward to it.',
            timestamp: DateTime.now().add(const Duration(seconds: 1)),
            expiresAt: DateTime.now().add(
              const Duration(hours: 48),
            ),
          ));
        });
      }
    });
  }
  
  void _showDatePlanner() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return const DatePlannerModal();
      },
    );
  }
  
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(PhosphorIcons.image(), color: AppConstants.primaryRed),
                title: const Text('Photo & Video'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle photo/video picker
                },
              ),
              ListTile(
                leading: Icon(PhosphorIcons.camera(), color: AppConstants.primaryRed),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle camera
                },
              ),
              ListTile(
                leading: Icon(PhosphorIcons.mapPin(), color: AppConstants.primaryRed),
                title: const Text('Location'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle location sharing
                },
              ),
              ListTile(
                leading: Icon(PhosphorIcons.calendar(), color: AppConstants.primaryRed),
                title: const Text('Plan a Date'),
                onTap: () {
                  Navigator.pop(context);
                  _showDatePlanner();
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildMessageBubble(Message message) {
    final isOutgoing = message.senderId == 'current_user_id';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOutgoing)
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(widget.chat.userImage),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isOutgoing 
                    ? AppConstants.primaryRed.withOpacity(0.9)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isOutgoing ? Colors.white : AppConstants.primaryBlack,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: isOutgoing 
                              ? Colors.white.withOpacity(0.7)
                              : AppConstants.secondaryGray,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (isOutgoing)
                        Icon(
                          message.isRead 
                              ? PhosphorIcons.checkCircle() 
                              : PhosphorIcons.check(),
                          size: 12,
                          color: message.isRead 
                              ? Colors.blue.withOpacity(0.7)
                              : Colors.white.withOpacity(0.7),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon:  Icon(PhosphorIcons.arrowLeft()),
          color: AppConstants.primaryBlack,
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.chat.userImage),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.userName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  widget.chat.isOnline ? 'Online' : 'Last seen ${widget.chat.lastMessageTimeFormatted}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: AppConstants.secondaryGray,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // View profile
            },
            icon:  Icon(PhosphorIcons.info()),
            color: AppConstants.primaryBlack,
          ),
          IconButton(
            onPressed: () {
              // More options
            },
            icon:  Icon(PhosphorIcons.dotsThreeVertical()),
            color: AppConstants.primaryBlack,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: AppConstants.primaryBeige,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[_messages.length - 1 - index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
          ),
          
          // Disappearing message notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppConstants.primaryRed.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.clock(),
                  size: 14,
                  color: AppConstants.primaryRed,
                ),
                const SizedBox(width: 6),
                Text(
                  'Messages disappear after 48 hours',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: AppConstants.primaryRed,
                  ),
                ),
              ],
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  onPressed: _showAttachmentOptions,
                  icon: Icon(PhosphorIcons.paperclip()),
                  color: AppConstants.secondaryGray,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryBeige,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppConstants.secondaryGray,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppConstants.primaryRed,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(PhosphorIcons.paperPlaneRight(), color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DatePlannerModal extends StatelessWidget {
  const DatePlannerModal({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppConstants.primaryRed,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(PhosphorIcons.x(), color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Plan a Date',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Select a restaurant',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                // Restaurant cards
                _buildRestaurantCard(
                  context: context,
                  name: 'The Social Table',
                  cuisine: 'Contemporary African',
                  price: 'KES 2,500 - 4,000',
                  rating: 4.8,
                  discount: '15% off for KanairoXO dates',
                ),
                
                _buildRestaurantCard(
                  context: context,
                  name: 'Artisan Coffee House',
                  cuisine: 'Coffee & Light Bites',
                  price: 'KES 800 - 1,500',
                  rating: 4.6,
                  discount: 'Free dessert for couples',
                ),
                
                _buildRestaurantCard(
                  context: context,
                  name: 'Rooftop Lounge',
                  cuisine: 'Cocktails & Small Plates',
                  price: 'KES 1,800 - 3,000',
                  rating: 4.7,
                  discount: '20% off total bill',
                ),
                
                const SizedBox(height: 32),
                Text(
                  'Select Date & Time',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                // Date selector
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: List.generate(7, (index) {
                      final date = DateTime.now().add(Duration(days: index + 1));
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryBeige,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppConstants.lightGray),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getWeekday(date.weekday),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: AppConstants.secondaryGray,
                              ),
                            ),
                            Text(
                              date.day.toString(),
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              _getMonth(date.month),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: AppConstants.secondaryGray,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Time selector
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    '7:00 PM',
                    '7:30 PM',
                    '8:00 PM',
                    '8:30 PM',
                    '9:00 PM',
                  ].map((time) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryBeige,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.lightGray),
                      ),
                      child: Text(time),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Send date invitation
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Date invitation sent!'),
                          backgroundColor: AppConstants.successGreen,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text('Send Date Invitation'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRestaurantCard({
    required BuildContext context,
    required String name,
    required String cuisine,
    required String price,
    required double rating,
    required String discount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppConstants.primaryBeige,
              borderRadius: BorderRadius.circular(12),
            ),
            child:  Icon(
              PhosphorIcons.storefront(),
              color: AppConstants.secondaryGray,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  cuisine,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.secondaryGray,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.star(),
                      size: 14,
                      color: AppConstants.warningAmber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      PhosphorIcons.money(),
                      size: 14,
                      color: AppConstants.secondaryGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      price,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConstants.secondaryGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    discount,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: AppConstants.primaryRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // View restaurant details
            },
            icon:  Icon(PhosphorIcons.arrowRight()),
            color: AppConstants.primaryRed,
          ),
        ],
      ),
    );
  }
  
  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
  
  String _getMonth(int month) {
    switch (month) {
      case 1: return 'Jan';
      case 2: return 'Feb';
      case 3: return 'Mar';
      case 4: return 'Apr';
      case 5: return 'May';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Aug';
      case 9: return 'Sep';
      case 10: return 'Oct';
      case 11: return 'Nov';
      case 12: return 'Dec';
      default: return '';
    }
  }
}