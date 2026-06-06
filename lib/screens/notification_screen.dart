import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kanairoxo/models/notification_model.dart';
import 'package:kanairoxo/providers/notification_provider.dart';
import 'package:kanairoxo/screens/singles/profile_preview_screen.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  final int initialTab;
  const NotificationScreen({super.key, this.initialTab = 0});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  void _handleTap(NotificationModel notification) {
    context.read<NotificationProvider>().markAsRead(notification.id);

    switch (notification.notificationType) {
      case 'moment_like':
      case 'moment_comment':
      case 'moment_save':
      case 'new_like':
      case 'new_comment':
        if (notification.referenceId != null) {
          // Navigate to MomentDetailScreen
          // Navigator.pushNamed(context, '/moment-detail', arguments: notification.referenceId);
        }
        break;
      case 'connection_request':
        // ITEM 4: Restore Profile Preview with connection_id
        final senderId = notification.sender?.id.toString();
        final connectionId = notification.data['connection_id']?.toString();
        if (senderId != null) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ProfilePreviewScreen(
              userId: senderId,
              requestId: connectionId, // Using existing requestId field for connection_id
            ),
          ));
        }
        break;
      case 'connection_accepted':
      case 'connection_rejected':
        if (notification.sender != null) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ProfilePreviewScreen(
              userId: notification.sender!.id.toString(),
            ),
          ));
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAF7F4);
    final textColor = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A1A1A);
    final primaryColor = const Color(0xFF9B111E);

    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTab,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            "Notifications",
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          leading: BackButton(color: textColor),
          actions: [
            TextButton(
              onPressed: () => provider.markAllAsRead(),
              child: Text(
                "Mark all read",
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: primaryColor,
                ),
              ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(text: "All"),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Moments"),
                    if (provider.hasUnreadMoments) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
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
                    const Text("Connections"),
                    if (provider.hasUnreadConnections) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            labelColor: primaryColor,
            unselectedLabelColor: const Color(0xFF999999),
            labelStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: primaryColor, width: 2),
              insets: const EdgeInsets.symmetric(horizontal: 16),
            ),
            indicatorSize: TabBarIndicatorSize.label,
          ),
        ),
        body: TabBarView(
          children: [
            _buildNotificationList(provider.all, provider.isLoading, "All"),
            _buildNotificationList(provider.moments, provider.isLoading, "Moments"),
            _buildNotificationList(provider.connections, provider.isLoading, "Connections"),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifications, bool isLoading, String tabType) {
    if (isLoading && notifications.isEmpty) {
      return _buildShimmerList();
    }

    if (notifications.isEmpty) {
      IconData emptyIcon;
      String emptyMessage;
      switch (tabType) {
        case "Moments":
          emptyIcon = Icons.image_outlined;
          emptyMessage = "No moment activity yet";
          break;
        case "Connections":
          emptyIcon = Icons.people_outline;
          emptyMessage = "No connection requests";
          break;
        default:
          emptyIcon = Icons.notifications_none_rounded;
          emptyMessage = "No notifications yet";
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 48, color: const Color(0xFFDDD5C8)),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const Divider(
        color: Color(0xFFE8E0D0),
        height: 1,
        indent: 72,
      ),
      itemBuilder: (context, index) => _buildNotificationItem(notifications[index]),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF9B111E);
    final nearBlack = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A1A1A);
    final bodyColor = isDark ? Colors.white70 : const Color(0xFF444444);

    return InkWell(
      onTap: () => _handleTap(notification),
      child: Container(
        color: notification.isRead
            ? Colors.transparent
            : primaryColor.withOpacity(0.04),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFF0E8E0),
                  backgroundImage: notification.sender?.photo != null
                      ? CachedNetworkImageProvider(notification.sender!.photo!)
                      : null,
                  child: notification.sender?.photo == null
                      ? Text(
                          notification.sender?.name.isNotEmpty == true
                              ? notification.sender!.name[0].toUpperCase()
                              : 'K',
                          style: const TextStyle(
                            fontFamily: 'CormorantGaramond',
                            fontSize: 20,
                            color: Color(0xFF9B111E),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _typeColor(notification.notificationType),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _typeIcon(notification.notificationType),
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        color: nearBlack,
                      ),
                      children: [
                        TextSpan(
                          text: notification.sender?.name ?? 'KanairoXO',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (notification.sender?.isOfficial == true) ...[
                          const WidgetSpan(
                            child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.verified, size: 14, color: Colors.blue),
                            ),
                          ),
                        ],
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: _bodyText(notification),
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(notification.createdAt),
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              const CircleAvatar(radius: 24, backgroundColor: Colors.white),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: double.infinity, height: 14, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 100, height: 12, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'moment_like':
      case 'new_like':
        return Icons.favorite_rounded;
      case 'moment_comment':
      case 'new_comment':
        return Icons.chat_bubble_rounded;
      case 'moment_save':
        return Icons.bookmark_rounded;
      case 'connection_request':
        return Icons.person_add_rounded;
      case 'connection_accepted':
        return Icons.handshake_outlined;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String type) {
    if (['moment_like', 'moment_comment', 'moment_save', 'new_like', 'new_comment'].contains(type)) {
      return const Color(0xFF9B111E);
    }
    if (['connection_request', 'connection_accepted', 'connection_rejected'].contains(type)) {
      return const Color(0xFF2E7D32);
    }
    return const Color(0xFF666666);
  }

  String _bodyText(NotificationModel n) {
    switch (n.notificationType) {
      case 'moment_like':
      case 'new_like':
        return 'liked your moment';
      case 'moment_comment':
      case 'new_comment':
        return 'commented: "${n.message}"';
      case 'moment_save':
        return 'saved your moment';
      case 'connection_request':
        return 'wants to connect with you';
      case 'connection_accepted':
        return 'accepted your connection';
      case 'connection_rejected':
        return 'declined your connection';
      default:
        return n.message;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) return DateFormat('d MMM').format(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
