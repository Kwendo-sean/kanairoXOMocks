import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kanairoxo/screens/messages/date_planner_screen.dart';
import 'package:kanairoxo/screens/messages/date_requests_screen.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../models/messaging/conversation_model.dart';
import '../../services/api_client.dart';
import '../../providers/date_plan_provider.dart';
import '../../widgets/safe_network_image.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ApiClient apiClient = ApiClient();
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _loadConversations();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _loadConversations();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadConversations() async {
    try {
      final response = await apiClient.get(
        'api/v1/messaging/conversations/');
      final list = response is List
        ? response
        : (response['results'] as List? ?? []);
      setState(() {
        _conversations = list.map((c) =>
          ConversationModel.fromJson(
            c as Map<String, dynamic>))
          .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Conversations error: $e');
    }
  }

  void _openChat(ConversationModel conv) async {
    await Navigator.push(context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversation: conv)));
    if (mounted) _loadConversations();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_month_outlined, 
              size: 20, 
              color: context.primaryColor),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DatePlannerScreen()),
            );
          },
        ),
        title: Text('Messages',
          style: AppTypography.screenTitle
            .copyWith(color: context.textColor)),
        centerTitle: true,
        actions: [
          Consumer<DatePlanProvider>(
            builder: (context, provider, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.favorite_outline_rounded, color: context.textColor),
                    onPressed: () {
                      Navigator.pushNamed(context, '/date-requests');
                    },
                  ),
                  if (provider.pendingCount > 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      body: (_isLoading && _conversations.isEmpty)
        ? _buildLoadingSkeleton()
        : _conversations.isEmpty
          ? _buildEmptyState(context.mutedColor)
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadConversations,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _conversations.length,
                separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
                itemBuilder: (ctx, i) =>
                  _ConversationTile(
                    conversation: _conversations[i],
                    surfaceColor: context.surfaceColor,
                    textColor: context.textColor,
                    mutedColor: context.mutedColor,
                    borderColor: context.borderColor,
                    onTap: () => _openChat(
                      _conversations[i])))));
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const PulsingGlassPlaceholder(height: 76, borderRadius: 14),
    );
  }
  
  Widget _buildEmptyState(Color mutedColor) {
    return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.chat_bubble_outline,
          size: 52, color: mutedColor),
        const SizedBox(height: 16),
        Text('No conversations yet',
          style: AppTypography.bodyMedium
            .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          'Connect with someone to start messaging',
          style: AppTypography.caption.copyWith(
            color: mutedColor),
          textAlign: TextAlign.center),
      ]));
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final Color borderColor;
  final VoidCallback onTap;
  
  const _ConversationTile({
    required this.conversation,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.borderColor,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final conv = conversation;
    final hasUnread = conv.unreadCount > 0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasUnread
              ? AppColors.primary.withOpacity(0.25)
              : borderColor)),
        child: Row(children: [
          
          // Avatar
          Stack(children: [
            ClipOval(
              child: conv.otherUser.photoUrl != null && conv.otherUser.photoUrl!.isNotEmpty
                ? SafeNetworkImage(
                    url: conv.otherUser.photoUrl!,
                    width: 48, height: 48,
                    fit: BoxFit.cover)
                : _AvatarPlaceholder(
                    name: conv.otherUser.name)),
            
            // Spark indicator
            if (conv.sparkStatus.active)
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: surfaceColor,
                      width: 1.5)))),
          ]),
          
          const SizedBox(width: 12),
          
          Expanded(child: Column(
            crossAxisAlignment: 
              CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(
                  conv.otherUser.name,
                  style: AppTypography.labelMedium
                    .copyWith(
                      color: textColor,
                      fontWeight: hasUnread
                        ? FontWeight.w700
                        : FontWeight.w500))),
                if (conv.lastMessageAt != null)
                  Text(
                    _formatTime(conv.lastMessageAt!),
                    style: AppTypography.caption
                      .copyWith(
                        color: mutedColor,
                        fontSize: 10)),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Expanded(child: Text(
                  conv.lastMessagePreview ?? '',
                  style: AppTypography.caption
                    .copyWith(
                      color: hasUnread
                        ? textColor
                        : mutedColor,
                      fontWeight: hasUnread
                        ? FontWeight.w500
                        : FontWeight.w400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: 
                        BorderRadius.circular(999)),
                    child: Text(
                      '${conv.unreadCount}',
                      style: AppTypography.caption
                        .copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: 
                            FontWeight.w700))),
              ]),
            ])),
        ])));
  }
  
  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h';
    }
    return '${diff.inDays}d';
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  final String name;
  const _AvatarPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      color: AppColors.primaryGlass,
      child: Center(child: Text(
        name.isNotEmpty
          ? name[0].toUpperCase() : '?',
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 18))));
  }
}

class PulsingGlassPlaceholder extends StatelessWidget {
  final double height;
  final double borderRadius;
  const PulsingGlassPlaceholder({super.key, required this.height, this.borderRadius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
