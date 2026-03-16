import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/models/connection_models.dart';
import 'package:kanairoxo/screens/singles/profile_preview_screen.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';

class NotificationScreen extends StatefulWidget {
  final int initialTab;
  const NotificationScreen({super.key, this.initialTab = 0});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notifications', style: AppTypography.displayMedium.copyWith(fontSize: 20)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Connections'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _GeneralNotificationsTab(),
          _ConnectionsTab(),
        ],
      ),
    );
  }
}

class _GeneralNotificationsTab extends StatelessWidget {
  const _GeneralNotificationsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('No new notifications', style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}

class _ConnectionsTab extends StatefulWidget {
  @override
  State<_ConnectionsTab> createState() => _ConnectionsTabState();
}

class _ConnectionsTabState extends State<_ConnectionsTab> {
  final ApiClient apiClient = ApiClient();
  List<ConnectionRequestModel> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final response = await apiClient.get('api/v1/connections/requests/pending/');
      final list = response['requests'] as List? ?? [];
      setState(() {
        _requests = list.map((r) => ConnectionRequestModel.fromJson(r)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('No connection requests', style: AppTypography.bodyMedium),
            const SizedBox(height: 6),
            Text(
              'When someone wants to connect it will appear here',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
                        Icon(Icons.location_on_outlined, size: 11, color: AppColors.textMuted),
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
                    decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
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
                    child: Icon(Icons.close, color: AppColors.textMuted, size: 18),
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
