import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/notification_card.dart';
import 'package:kanairoxo/models/notification_model.dart' as model;
import 'package:kanairoxo/models/notification_model.dart' show NotificationType;

// Define ConnectionRequest model if not already defined elsewhere
class ConnectionRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String fromUserImage;
  final String? message;
  final DateTime sentAt;
  final bool isAccepted;
  final bool isDeclined;
  final DateTime? respondedAt;

  ConnectionRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserImage,
    this.message,
    required this.sentAt,
    this.isAccepted = false,
    this.isDeclined = false,
    this.respondedAt,
  });

  bool get isPending => !isAccepted && !isDeclined;
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _unreadCount = 12;
  
  final List<model.Notification> _notifications = [
    model.Notification(
      id: '1',
      userId: 'current',
      type: NotificationType.connectionRequest,
      title: 'New Connection Request',
      body: 'Sofia sent you a connection request',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      imageUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100&h=100&fit=crop',
    ),
    model.Notification(
      id: '2',
      userId: 'current',
      type: NotificationType.connectionAccepted,
      title: 'Connection Accepted',
      body: 'Marcus accepted your connection request',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop',
    ),
    model.Notification(
      id: '3',
      userId: 'current',
      type: NotificationType.ticketReady,
      title: 'Your Ticket is Ready',
      body: 'Download your ticket for Morning Coffee & Conversation',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    model.Notification(
      id: '4',
      userId: 'current',
      type: NotificationType.paymentSuccess,
      title: 'Payment Successful',
      body: 'KES 1,500 paid for Gallery Opening',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
  ];
  
  final List<ConnectionRequest> _connectionRequests = [
    ConnectionRequest(
      id: '1',
      fromUserId: 'user1',
      fromUserName: 'Sofia',
      fromUserImage: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=200&h=200&fit=crop',
      message: 'I also love quiet mornings and good design!',
      sentAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ConnectionRequest(
      id: '2',
      fromUserId: 'user2',
      fromUserName: 'David',
      fromUserImage: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop',
      sentAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleAcceptRequest(String requestId) {
    setState(() {
      final request = _connectionRequests.firstWhere((r) => r.id == requestId);
      final index = _connectionRequests.indexOf(request);
      _connectionRequests[index] = ConnectionRequest(
        id: request.id,
        fromUserId: request.fromUserId,
        fromUserName: request.fromUserName,
        fromUserImage: request.fromUserImage,
        message: request.message,
        sentAt: request.sentAt,
        isAccepted: true,
        respondedAt: DateTime.now(),
      );
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Connection request accepted'),
        backgroundColor: AppConstants.successGreen,
      ),
    );
  }
  
  void _handleDeclineRequest(String requestId) {
    setState(() {
      final request = _connectionRequests.firstWhere((r) => r.id == requestId);
      final index = _connectionRequests.indexOf(request);
      _connectionRequests[index] = ConnectionRequest(
        id: request.id,
        fromUserId: request.fromUserId,
        fromUserName: request.fromUserName,
        fromUserImage: request.fromUserImage,
        message: request.message,
        sentAt: request.sentAt,
        isDeclined: true,
        respondedAt: DateTime.now(),
      );
    });
  }
  
  void _markAllAsRead() {
    setState(() {
      _unreadCount = 0;
      for (int i = 0; i < _notifications.length; i++) {
        final notification = _notifications[i];
        _notifications[i] = model.Notification(
          id: notification.id,
          userId: notification.userId,
          type: notification.type,
          title: notification.title,
          body: notification.body,
          timestamp: notification.timestamp,
          isRead: true,
          data: notification.data,
          imageUrl: notification.imageUrl,
          actionUrl: notification.actionUrl,
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final unreadRequests = _connectionRequests.where((r) => r.isPending).length;
    
    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppStrings.notificationsTitle,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            IconButton(
              onPressed: _markAllAsRead,
              icon:  Icon(PhosphorIcons.checkCircle()),
              color: AppConstants.primaryRed,
            ),
        ],
      ),
      body: Column(
        children: [
          // Unread badge
          if (_unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: AppConstants.primaryRed.withOpacity(0.1),
              child: Center(
                child: Text(
                  '$_unreadCount unread notifications',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.primaryRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppConstants.primaryRed,
              labelColor: AppConstants.primaryBlack,
              unselectedLabelColor: AppConstants.secondaryGray,
              labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('All'),
                      if (_unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Connections'),
                      if (unreadRequests > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unreadRequests',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Tickets'),
              ],
            ),
          ),
          
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All notifications
                _buildNotificationsList(),
                
                // Connection requests
                _buildConnectionRequestsList(),
                
                // Tickets
                _buildTicketsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return NotificationCard(
          notification: notification,
          onTap: () {
            // Handle notification tap
          },
        );
      },
    );
  }
  
  Widget _buildConnectionRequestsList() {
    final pendingRequests = _connectionRequests.where((r) => r.isPending).toList();
    final respondedRequests = _connectionRequests.where((r) => !r.isPending).toList();
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (pendingRequests.isNotEmpty) ...[
          Text(
            'Pending Requests',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ...pendingRequests.map((request) {
            return _buildConnectionRequestCard(request);
          }).toList(),
          const SizedBox(height: 32),
        ],
        
        if (respondedRequests.isNotEmpty) ...[
          Text(
            'Responded',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ...respondedRequests.map((request) {
            return _buildConnectionRequestCard(request);
          }).toList(),
        ],
        
        if (_connectionRequests.isEmpty)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Icon(
                PhosphorIcons.users(),
                size: 60,
                color: AppConstants.lightGray,
              ),
              const SizedBox(height: 20),
              Text(
                'No connection requests',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'When someone wants to connect with you,\nit will appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.secondaryGray,
                ),
              ),
            ],
          ),
      ],
    );
  }
  
  Widget _buildConnectionRequestCard(ConnectionRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(
          color: request.isPending 
              ? AppConstants.lightGray 
              : (request.isAccepted ? AppConstants.successGreen : Colors.red.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(request.fromUserImage),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.fromUserName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      request.sentAt.day == DateTime.now().day
                          ? 'Today'
                          : '${DateTime.now().difference(request.sentAt).inDays} days ago',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConstants.secondaryGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (request.isPending)
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _handleAcceptRequest(request.id),
                      icon: Icon(
                        PhosphorIcons.checkCircle(),
                        color: AppConstants.successGreen,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _handleDeclineRequest(request.id),
                      icon: Icon(
                        PhosphorIcons.xCircle(),
                        color: Colors.red,
                      ),
                    ),
                  ],
                )
              else if (request.isAccepted)
                Icon(
                  PhosphorIcons.checkCircle(),
                  color: AppConstants.successGreen,
                )
              else
                Icon(
                  PhosphorIcons.xCircle(),
                  color: Colors.red,
                ),
            ],
          ),
          
          if (request.message != null && request.message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryBeige,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                request.message!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTicketsList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Your Tickets',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        
        // Upcoming events
        _buildTicketCard(
          eventName: 'Morning Coffee & Conversation',
          date: 'Sat, Jan 4 • 9:00 AM',
          location: 'Bluestone Lane, SoHo',
          isUpcoming: true,
          onDownload: () {
            // Download ticket
          },
        ),
        
        _buildTicketCard(
          eventName: 'Gallery Opening: New Perspectives',
          date: 'Mon, Jan 6 • 6:30 PM',
          location: 'Modern Art Gallery, Chelsea',
          isUpcoming: true,
          onDownload: () {
            // Download ticket
          },
        ),
        
        const SizedBox(height: 32),
        Text(
          'Past Events',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        
        _buildTicketCard(
          eventName: 'Jazz Night & Philosophy',
          date: 'Dec 15, 2024 • 8:00 PM',
          location: 'The Blue Note, Greenwich Village',
          isUpcoming: false,
          onViewMemories: () {
            // Navigate to event memories
          },
        ),
      ],
    );
  }
  
  Widget _buildTicketCard({
    required String eventName,
    required String date,
    required String location,
    required bool isUpcoming,
    VoidCallback? onDownload,
    VoidCallback? onViewMemories,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: AppConstants.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppConstants.primaryBeige,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isUpcoming ? PhosphorIcons.ticket() : PhosphorIcons.calendarCheck(),
                  color: AppConstants.secondaryGray,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.calendar(),
                          size: 12,
                          color: AppConstants.secondaryGray,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            date,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.mapPin(),
                          size: 12,
                          color: AppConstants.secondaryGray,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (isUpcoming)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(PhosphorIcons.download(), size: 18),
                label: const Text('Download Ticket'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewMemories,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppConstants.primaryRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon:  Icon(PhosphorIcons.image(), size: 18),
                    label: const Text('View Memories'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppConstants.secondaryGray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon:  Icon(PhosphorIcons.star(), size: 18),
                    label: const Text('Rate'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}