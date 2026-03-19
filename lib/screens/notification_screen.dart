import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/models/connection_models.dart';
import 'package:kanairoxo/screens/singles/profile_preview_screen.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String timeAgo;
  final NotificationSender? sender;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.timeAgo,
    this.sender,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final senderMap = json['sender'] as Map?;
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isRead: json['is_read'] ?? false,
      timeAgo: json['time_ago'] ?? '',
      sender: senderMap != null ? NotificationSender.fromJson(senderMap as Map<String, dynamic>) : null,
    );
  }
}

class NotificationSender {
  final String? id;
  final String? name;
  final String? photoUrl;

  NotificationSender({this.id, this.name, this.photoUrl});

  factory NotificationSender.fromJson(Map<String, dynamic> json) {
    return NotificationSender(
      id: json['id']?.toString(),
      name: json['name'],
      photoUrl: ApiConstants.fixMediaUrl(json['photo_url']),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  final int initialTab;
  const NotificationScreen({super.key, this.initialTab = 0});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient apiClient = ApiClient();

  List<NotificationModel> _notifications = [];
  List<ConnectionRequestModel> _requests = [];
  bool _loadingNotifications = false;
  bool _loadingRequests = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _loadNotifications();

    _tabController.addListener(() {
      if (_tabController.index == 0 && _notifications.isEmpty) {
        _loadNotifications();
      } else if (_tabController.index == 1 && _requests.isEmpty) {
        _loadRequests();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (_loadingNotifications) return;
    setState(() => _loadingNotifications = true);
    try {
      final response = await apiClient.get('/api/v1/notifications/');
      final list = response is List ? response : (response['notifications'] as List? ?? []);
      setState(() {
        _notifications = list.map((n) => NotificationModel.fromJson(n)).toList();
        _loadingNotifications = false;
      });
    } catch (e) {
      setState(() => _loadingNotifications = false);
      debugPrint('Notifications error: $e');
    }
  }

  Future<void> _loadRequests() async {
    if (_loadingRequests) return;
    setState(() => _loadingRequests = true);
    try {
      final response = await apiClient.get('/api/v1/connections/requests/pending/');
      final list = response['requests'] as List? ?? [];
      setState(() {
        _requests = list.map((r) => ConnectionRequestModel.fromJson(r)).toList();
        _loadingRequests = false;
      });
    } catch (e) {
      setState(() => _loadingRequests = false);
      debugPrint('Requests error: $e');
    }
  }

  Future<void> _respond(ConnectionRequestModel request, String action) async {
    try {
      await apiClient.post(
        'api/v1/connections/request/${request.requestId}/respond/',
        {'action': action},
      );

      setState(() => _requests.remove(request));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'accept' ? 'Connected with ${request.initiatorName}' : 'Request declined',
            style: AppTypography.caption.copyWith(color: Colors.white),
          ),
          backgroundColor: action == 'accept' ? Colors.green.shade600 : AppColors.textMuted,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed', style: AppTypography.caption.copyWith(color: Colors.white)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openPreview(ConnectionRequestModel request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePreviewScreen(
          userId: request.initiatorId,
          requestId: request.requestId,
          onAccept: () {
            Navigator.pop(context);
            _respond(request, 'accept');
          },
          onDecline: () {
            Navigator.pop(context);
            _respond(request, 'decline');
          },
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.labelMedium,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Connections'),
          Tab(text: 'Tickets'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAllTab() {
    if (_loadingNotifications) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState(
        Icons.notifications_outlined,
        'No notifications',
        'Your notifications will appear here',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _NotificationItem(notification: _notifications[i]),
    );
  }

  Widget _buildConnectionsTab() {
    if (_loadingRequests) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
    }

    if (_requests.isEmpty) {
      return _buildEmptyState(
        Icons.people_outline,
        'No connection requests',
        'When someone wants to connect with you,\nit will appear here',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _ConnectionRequestCard(
        request: _requests[i],
        onAccept: () => _respond(_requests[i], 'accept'),
        onDecline: () => _respond(_requests[i], 'decline'),
        onTap: () => _openPreview(_requests[i]),
      ),
    );
  }

  Widget _buildTicketsTab() {
    return _buildEmptyState(
      Icons.confirmation_number_outlined,
      'No ticket notifications',
      'Your event tickets will appear here',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: AppTypography.screenTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllTab(),
                _buildConnectionsTab(),
                _buildTicketsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationItem({required this.notification});

  IconData _getNotificationIcon(String type) {
    return switch (type) {
      'connection_request' => Icons.person_add_outlined,
      'connection_accepted' => Icons.people_outline,
      'moment_like' => Icons.favorite_border,
      'moment_comment' => Icons.chat_bubble_outline,
      'event_reminder' => Icons.event_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : AppColors.primaryGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notification.isRead ? Colors.grey.shade100 : AppColors.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          notification.sender != null && notification.sender!.photoUrl != null
              ? ClipOval(
                  child: SafeNetworkImage(
                    url: notification.sender!.photoUrl,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(color: AppColors.primaryGlass, shape: BoxShape.circle),
                  child: Icon(_getNotificationIcon(notification.type), color: AppColors.primary, size: 20),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  notification.body,
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            notification.timeAgo,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ConnectionRequestCard extends StatelessWidget {
  final ConnectionRequestModel request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTap;

  const _ConnectionRequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            ClipOval(
              child: SafeNetworkImage(
                url: request.initiatorPhotoUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.initiatorName,
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  if (request.initiatorNeighborhood.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(request.initiatorNeighborhood, style: AppTypography.caption),
                      ],
                    ),
                  const SizedBox(height: 2),
                  Text(
                    request.timeAgo,
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: onAccept,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onDecline,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
