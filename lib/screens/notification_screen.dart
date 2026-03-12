import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/widgets/notification_card.dart';
import 'package:kanairoxo/providers/notification_provider.dart';
import 'package:kanairoxo/models/notification_model.dart' as model;
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/widgets/glass_card.dart';

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
    try {
      await notificationProvider.acceptConnectionRequest(notificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request accepted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting request: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleMarkAllAsRead() async {
    await notificationProvider.markAllAsRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = Provider.of<NotificationProvider>(context);
    final unreadCount = provider.unreadCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Notifications', style: AppTypography.screenTitle),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            LiquidGlassButton(
              size: LiquidButtonSize.icon,
              variant: LiquidButtonVariant.ghost,
              onPressed: _handleMarkAllAsRead,
              child: const Icon(Icons.check_circle_outline, color: AppColors.primary),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTypography.labelMedium,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 2.0, color: AppColors.primary),
                  insets: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Connections'),
                  Tab(text: 'Tickets'),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllNotificationsList(provider),
                _buildConnectionRequestsList(provider),
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
      return _buildEmptyState(icon: Icons.notifications_none, title: 'No notifications', message: 'Your notifications will appear here');
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
              provider.markAsRead(notification.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildConnectionRequestsList(NotificationProvider provider) {
    final connectionRequests = provider.connectionRequests;
    if (connectionRequests.isEmpty) {
      return _buildEmptyState(icon: Icons.people_outline, title: 'No connection requests', message: 'When someone wants to connect with you, it will appear here.');
    }
    return RefreshIndicator(
      onRefresh: () => provider.refreshNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: connectionRequests.length,
        itemBuilder: (context, index) {
          final notification = connectionRequests[index] as model.Notification;
          return _buildConnectionRequestCard(notification);
        },
      ),
    );
  }

  Widget _buildConnectionRequestCard(model.Notification notification) {
    final sender = notification.sender;
    final senderName = sender != null ? '${sender['first_name']} ${sender['last_name']}'.trim() : 'Someone';

    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: sender?['profile_photo'] != null ? NetworkImage(sender!['profile_photo']) : null,
            child: sender?['profile_photo'] == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(senderName, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                Text(notification.type == model.NotificationType.connectionRequest ? 'Sent you a request' : 'Connected with you', style: AppTypography.bodyMedium),
              ],
            ),
          ),
          if (notification.type == model.NotificationType.connectionRequest && !notification.isActionTaken)
            LiquidGlassButton(
              size: LiquidButtonSize.sm,
              onPressed: () => _handleAcceptRequest(notification.id, notification.data['connection_id'].toString()),
              child: Text('Accept', style: AppTypography.buttonText.copyWith(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildTicketsList(NotificationProvider provider) {
    final ticketNotifications = provider.ticketNotifications;
    if (ticketNotifications.isEmpty) {
      return _buildEmptyState(icon: Icons.confirmation_number_outlined, title: 'No ticket notifications', message: 'Your event tickets will appear here');
    }
    return RefreshIndicator(
      onRefresh: () => provider.refreshNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: ticketNotifications.length,
        itemBuilder: (context, index) {
          final n = ticketNotifications[index] as model.Notification;
          return GlassCard(
            child: ListTile(
              leading: const Icon(Icons.confirmation_number, color: AppColors.primary),
              title: Text(n.title, style: AppTypography.bodyLarge),
              subtitle: Text(n.body, style: AppTypography.bodyMedium),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: AppColors.textMuted),
          const SizedBox(height: 20),
          Text(title, style: AppTypography.displayMedium.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(message, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }
}
