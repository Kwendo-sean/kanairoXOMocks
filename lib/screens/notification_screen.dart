// lib/screens/notifications/notification_screen.dart - UPDATED VERSION
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/notification_card.dart';
import 'package:kanairoxo/providers/notification_provider.dart';
import 'package:kanairoxo/providers/connection_provider.dart';
import 'package:kanairoxo/models/notification_model.dart' as model;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late NotificationProvider notificationProvider;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    _loadData();
  }

  Future<void> _loadData() async {
    await notificationProvider.loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleAcceptRequest(String notificationId, String connectionId) async {
    // final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);

    try {
      // Accept connection through connection provider
      // await connectionProvider.acceptConnection(connectionId);

      // Update notification
      await notificationProvider.acceptConnectionRequest(notificationId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connection request accepted'),
          backgroundColor: AppConstants.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleDeclineRequest(String notificationId, String connectionId) async {
    // final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);

    try {
      // Decline connection through connection provider
      // await connectionProvider.declineConnection(connectionId);

      // Update notification
      await notificationProvider.declineConnectionRequest(notificationId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error declining request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleMarkAllAsRead() async {
    await notificationProvider.markAllAsRead();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppConstants.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = Provider.of<NotificationProvider>(context);
    final stats = provider.stats;

    final unreadCount = provider.unreadCount;
    final pendingRequestsCount = provider.pendingConnectionRequests;

    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            IconButton(
              onPressed: _handleMarkAllAsRead,
              icon: Icon(PhosphorIcons.checkCircle()),
              color: AppConstants.primaryRed,
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Unread badge
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: AppConstants.primaryRed.withOpacity(0.1),
              child: Center(
                child: Text(
                  '$unreadCount unread notifications',
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
                      if (unreadCount > 0) ...[
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
                            '$unreadCount',
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
                      if (pendingRequestsCount > 0) ...[
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
                            '$pendingRequestsCount',
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
                      const Text('Tickets'),
                      if (provider.ticketNotifications.isNotEmpty) ...[
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
                            '${provider.ticketNotifications.length}',
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
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All notifications
                _buildAllNotificationsList(provider),

                // Connection requests
                _buildConnectionRequestsList(provider),

                // Tickets
                _buildTicketsList(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllNotificationsList(NotificationProvider provider) {
    final notifications = provider.notifications;

    if (notifications.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIcons.bell(),
        title: 'No notifications',
        message: 'Your notifications will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index] as model.Notification;
          return NotificationCard(
            notification: notification,
            onTap: () {
              // Handle notification tap
              provider.markAsRead(notification.id);
              _handleNotificationAction(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildConnectionRequestsList(NotificationProvider provider) {
    final connectionRequests = provider.connectionRequests;

    if (connectionRequests.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIcons.users(),
        title: 'No connection requests',
        message: 'When someone wants to connect with you,\nit will appear here.',
      );
    }

    final pendingRequests = connectionRequests.where((n) => !(n as model.Notification).isActionTaken).toList();
    final respondedRequests = connectionRequests.where((n) => (n as model.Notification).isActionTaken).toList();

    return RefreshIndicator(
      onRefresh: () => provider.refreshNotifications(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (pendingRequests.isNotEmpty) ...[
            Text(
              'Pending Requests',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...pendingRequests.map((notification) {
              return _buildConnectionRequestCard(notification as model.Notification);
            }).toList(),
            const SizedBox(height: 32),
          ],

          if (respondedRequests.isNotEmpty) ...[
            Text(
              'Responded',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...respondedRequests.map((notification) {
              return _buildConnectionRequestCard(notification as model.Notification, isResponded: true);
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionRequestCard(model.Notification notification, {bool isResponded = false}) {
    final sender = notification.sender;
    final senderName = sender != null
        ? '${sender['first_name']} ${sender['last_name']}'.trim()
        : 'Someone';
    final senderImage = sender?['profile_photo'];
    final connectionId = notification.data['connection_id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(
          color: isResponded
              ? (notification.isActionTaken ? AppConstants.successGreen : Colors.red.withOpacity(0.3))
              : AppConstants.lightGray,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: senderImage != null
                    ? NetworkImage(senderImage)
                    : null,
                child: senderImage == null
                    ? Icon(PhosphorIcons.user())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _formatTimeAgo(notification.timestamp),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConstants.secondaryGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isResponded)
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _handleAcceptRequest(notification.id, connectionId),
                      icon: Icon(
                        PhosphorIcons.checkCircle(),
                        color: AppConstants.successGreen,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _handleDeclineRequest(notification.id, connectionId),
                      icon: Icon(
                        PhosphorIcons.xCircle(),
                        color: Colors.red,
                      ),
                    ),
                  ],
                )
              else if (notification.isActionTaken)
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

          if (notification.data['request_message'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryBeige,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notification.data['request_message']!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTicketsList(NotificationProvider provider) {
    final ticketNotifications = provider.ticketNotifications;

    if (ticketNotifications.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIcons.ticket(),
        title: 'No ticket notifications',
        message: 'Your event tickets will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshNotifications(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Your Tickets',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          ...ticketNotifications.map((notification) {
            final n = notification as model.Notification;
            final eventData = n.event ?? n.data;
            final isUpcoming = _isEventUpcoming(eventData);

            return _buildTicketCard(
              notification: n,
              eventData: eventData,
              isUpcoming: isUpcoming,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTicketCard({
    required model.Notification notification,
    required Map<String, dynamic> eventData,
    required bool isUpcoming,
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
                      eventData['event_title'] ?? 'Event',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (eventData['event_date'] != null)
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
                              _formatEventDate(eventData['event_date']),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (eventData['location'] != null)
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
                              eventData['location']!,
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
                onPressed: () {
                  // Navigate to ticket download
                  notificationProvider.markAsRead(notification.id);
                },
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
                    onPressed: () {
                      // View event memories
                      notificationProvider.markAsRead(notification.id);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppConstants.primaryRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(PhosphorIcons.image(), size: 18),
                    label: const Text('View Memories'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Rate event
                      notificationProvider.markAsRead(notification.id);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppConstants.secondaryGray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(PhosphorIcons.star(), size: 18),
                    label: const Text('Rate'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return RefreshIndicator(
      onRefresh: () => notificationProvider.refreshNotifications(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 60,
                  color: AppConstants.lightGray,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppConstants.secondaryGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationAction(model.Notification notification) {
    // Handle different notification types
    switch (notification.type) {
      case model.NotificationType.connectionRequest:
      // Navigate to connection request
        break;
      case model.NotificationType.connectionAccepted:
      // Navigate to connection
        break;
      case model.NotificationType.ticketReady:
      // Navigate to ticket
        break;
      case model.NotificationType.eventInvitation:
      // Navigate to event
        break;
      default:
      // Default action
        break;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatEventDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${_getWeekday(date.weekday)}, ${_getMonth(date.month)} ${date.day} • ${_formatTime(date)}';
    } catch (e) {
      return dateString;
    }
  }

  String _getWeekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  bool _isEventUpcoming(Map<String, dynamic> eventData) {
    try {
      if (eventData['event_date'] != null) {
        final eventDate = DateTime.parse(eventData['event_date']);
        return eventDate.isAfter(DateTime.now());
      }
    } catch (e) {
      return true; // Default to upcoming if we can't parse
    }
    return true;
  }
}
