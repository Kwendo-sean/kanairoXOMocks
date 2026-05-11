import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/services/couple_service.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final CoupleService _coupleService = CoupleService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  Timer? _pollingTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchMessages());
  }

  Future<void> _fetchMessages() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final coupleId = authProvider.coupleStatus?.coupleId;
      if (coupleId == null) return;

      final messages = await _coupleService.getMessages(coupleId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await _coupleService.sendMessage(authProvider.coupleStatus!.coupleId, text);
      _fetchMessages();
    } catch (e) {
      // Error handling
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final partner = authProvider.partner;
    final photoUrl = partner?.profile?.mainProfilePhoto;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 1,
        leading: BackButton(color: context.textColor),
        title: Row(
          children: [
            hasPhoto
              ? CachedNetworkImage(
                  imageUrl: photoUrl,
                  imageBuilder: (ctx, img) => CircleAvatar(radius: 16, backgroundImage: img),
                  errorWidget: (ctx, url, err) => _buildAvatarFallback(partner?.firstName),
                )
              : _buildAvatarFallback(partner?.firstName),
            const SizedBox(width: 10),
            Text(partner?.firstName ?? 'Partner', style: AppTypography.labelMedium.copyWith(fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: AppColors.primary),
            onPressed: () async {
              await _coupleService.thinkingOfYou(authProvider.coupleStatus!.coupleId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thinking of you sent!')));
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    reverse: true, // Show latest at bottom
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = _messages[i];
                      final isSent = msg['sender_id'].toString() == authProvider.user?.id;
                      return _buildMessageBubble(msg, isSent);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String? name) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      child: Text(
        name != null && name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMessageBubble(dynamic msg, bool isSent) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sentAt = DateTime.parse(msg['sent_at']);

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: screenWidth * 0.72),
        decoration: BoxDecoration(
          color: isSent ? AppColors.themePrimary(context) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isSent ? 16 : 4),
            bottomRight: Radius.circular(isSent ? 4 : 16),
          ),
          border: isSent ? null : Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['content'] ?? '',
              style: AppTypography.bodyMedium.copyWith(color: isSent ? Colors.white : context.textColor),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('HH:mm').format(sentAt),
              style: AppTypography.caption.copyWith(fontSize: 10, color: isSent ? Colors.white60 : AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Say something...',
                hintStyle: AppTypography.caption,
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
