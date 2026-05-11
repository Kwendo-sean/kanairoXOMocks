import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/models/notification_model.dart' as model;
import 'package:kanairoxo/providers/notification_provider.dart';
import 'package:kanairoxo/screens/singles/profile_preview_screen.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/utils/constants.dart';

class NotificationScreen extends StatefulWidget {
  final int initialTab;
  const NotificationScreen({super.key, this.initialTab = 0});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTab);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadTabContent(_tabController.index);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTabContent(_tabController.index);
    });
  }

  void _loadTabContent(int index) {
    final p = Provider.of<NotificationProvider>(context, listen: false);
    switch (index) {
      case 0:
        p.loadNotifications();
        break;
      case 1:
        p.loadMoments();
        break;
      case 2:
        p.loadConnections();
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openPreview(model.Notification n) {
    final senderId = n.sender?['id']?.toString();
    if (senderId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePreviewScreen(
          userId: senderId,
          onAccept: () => Navigator.pop(context),
          onDecline: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsBold.caretLeft, color: context.textColor, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications',
            style: AppTypography.screenTitle.copyWith(color: context.textColor, fontWeight: FontWeight.w800)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.primaryColor,
          unselectedLabelColor: context.mutedColor,
          indicatorColor: context.primaryColor,
          indicatorWeight: 3,
          dividerColor: context.borderColor.withOpacity(0.5),
          labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Moments'),
            Tab(text: 'Connections'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NotificationListView(
            tabName: 'notifications',
            emptyIcon: PhosphorIconsRegular.bellSimpleSlash,
            notifications: provider.notifications,
            isLoading: provider.isLoading,
            onRefresh: provider.loadNotifications,
            onTap: _openPreview,
            showConnectionActions: true,
          ),
          _NotificationListView(
            tabName: 'moments',
            emptyIcon: PhosphorIconsRegular.imageSquare,
            notifications: provider.momentNotifications,
            isLoading: provider.isLoading,
            onRefresh: provider.loadMoments,
            onTap: (_) {},
            showConnectionActions: false,
          ),
          _NotificationListView(
            tabName: 'connections',
            emptyIcon: PhosphorIconsRegular.userPlus,
            notifications: provider.connectionRequests,
            isLoading: provider.isLoading,
            onRefresh: provider.loadConnections,
            onTap: _openPreview,
            showConnectionActions: true,
          ),
        ],
      ),
    );
  }
}

class _NotificationListView extends StatelessWidget {
  final String tabName;
  final IconData emptyIcon;
  final List<model.Notification> notifications;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Function(model.Notification) onTap;
  final bool showConnectionActions;

  const _NotificationListView({
    required this.tabName,
    required this.emptyIcon,
    required this.notifications,
    required this.isLoading,
    required this.onRefresh,
    required this.onTap,
    required this.showConnectionActions,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && notifications.isEmpty) {
      return Center(
          child: CircularProgressIndicator(color: context.primaryColor));
    }

    if (notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: context.primaryColor,
        backgroundColor: context.surfaceColor,
        child: Stack(
          children: [
            ListView(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(emptyIcon, size: 64, color: context.mutedColor.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No $tabName yet',
                    style: AppTypography.bodyLarge.copyWith(color: context.textColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We\'ll let you know when something happens',
                    style: AppTypography.caption.copyWith(color: context.mutedColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: context.primaryColor,
      backgroundColor: context.surfaceColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final n = notifications[i];
          if (showConnectionActions &&
              n.type == model.NotificationType.connectionRequest) {
            return _ConnectionRequestItem(notification: n);
          }
          return _NotificationItem(
            notification: n,
            onTap: () => onTap(n),
          );
        },
      ),
    );
  }
}

// ── Connection request card ──────────────────────────────────────────────────

class _ConnectionRequestItem extends StatefulWidget {
  final model.Notification notification;
  const _ConnectionRequestItem({required this.notification});

  @override
  State<_ConnectionRequestItem> createState() => _ConnectionRequestItemState();
}

class _ConnectionRequestItemState extends State<_ConnectionRequestItem> {
  bool _isActing = false;
  bool _showSuccess = false;

  String? get _connectionId =>
      widget.notification.data['connection_id']?.toString();

  Future<void> _accept() async {
    final cid = _connectionId;
    if (cid == null) return;
    setState(() => _isActing = true);
    final provider =
        Provider.of<NotificationProvider>(context, listen: false);
    final ok = await provider.acceptConnection(cid, widget.notification.id);
    if (mounted) {
      if (ok) {
        setState(() {
          _isActing = false;
          _showSuccess = true;
        });
      } else {
        setState(() => _isActing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not accept — try again')));
      }
    }
  }

  Future<void> _decline() async {
    final cid = _connectionId;
    if (cid == null) return;
    setState(() => _isActing = true);
    final provider =
        Provider.of<NotificationProvider>(context, listen: false);
    final ok = await provider.declineConnection(cid, widget.notification.id);
    if (mounted && !ok) {
      setState(() => _isActing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not decline — try again')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.surfaceColor;
    final textColor = context.textColor;
    final mutedColor = context.mutedColor;
    final accentColor = context.primaryColor;

    final sender = widget.notification.sender;
    final photoUrl = sender?['photo_url'];
    final name = sender?['name'] ?? 'Someone';

    if (_showSuccess) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(PhosphorIconsFill.checkCircle, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Text('Connected with $name!', style: AppTypography.labelMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.notification.isRead
              ? context.borderColor.withOpacity(0.1)
              : accentColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SafeNetworkImage(
                  url: photoUrl != null
                      ? ApiConstants.fixMediaUrl(photoUrl)
                      : null,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: accentColor.withOpacity(0.1),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: accentColor, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        Text(
                          widget.notification.timeAgo,
                          style: AppTypography.caption
                              .copyWith(color: mutedColor, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.notification.body,
                      style:
                          AppTypography.bodyMedium.copyWith(color: mutedColor, fontSize: 13, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isActing)
            Center(
                child: SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: accentColor)))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _decline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: context.borderColor.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Decline',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _accept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Accept',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Generic & Moment notification item ───────────────────────────────────────

class _NotificationItem extends StatelessWidget {
  final model.Notification notification;
  final VoidCallback onTap;

  const _NotificationItem(
      {required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.surfaceColor;
    final textColor = context.textColor;
    final mutedColor = context.mutedColor;
    final accentColor = context.primaryColor;

    final isMoment = notification.type == model.NotificationType.momentLike ||
                     notification.type == model.NotificationType.momentComment;
    
    final sender = notification.sender;
    final photoUrl = sender?['photo_url'];
    final name = sender?['name'] ?? 'Someone';
    final momentPhoto = notification.data['moment_photo'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : accentColor.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SafeNetworkImage(
                    url: photoUrl != null
                        ? ApiConstants.fixMediaUrl(photoUrl)
                        : null,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: accentColor.withOpacity(0.1),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!notification.isRead)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: surfaceColor, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: AppTypography.bodyMedium.copyWith(color: textColor, height: 1.3),
                      children: [
                        TextSpan(
                          text: '$name ',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text: isMoment ? (notification.type == model.NotificationType.momentLike ? 'liked your moment' : 'commented on your moment') : notification.body,
                          style: TextStyle(color: textColor.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.timeAgo,
                    style: AppTypography.caption
                        .copyWith(color: mutedColor, fontSize: 10),
                  ),
                ],
              ),
            ),
            if (isMoment && momentPhoto != null) ...[
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SafeNetworkImage(
                  url: ApiConstants.fixMediaUrl(momentPhoto),
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
