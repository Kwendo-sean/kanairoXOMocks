import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/messaging/conversation_model.dart';
import '../../models/messaging/message_model.dart';
import '../../services/api_client.dart';
import '../../utils/auth_storage.dart';
import '../../widgets/liquid_glass_button.dart';
import '../../services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ApiClient apiClient = ApiClient();
  List<MessageModel> _messages = [];
  bool _isLoading = true;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  
  Timer? _pollTimer;
  bool _isRecordingVoice = false;
  
  List<Map<String, dynamic>> _suggestions = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages().then((_) {
      _startPolling();
    });
    _loadSuggestions();
    
    NotificationService.newMessageNotifier.addListener(_onPushMessage);
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    NotificationService.newMessageNotifier.removeListener(_onPushMessage);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else {
      _pollTimer?.cancel();
    }
  }

  void _onPushMessage() {
    final convId = NotificationService.newMessageNotifier.value;
    if (convId == widget.conversation.id && mounted) {
      _pollNewMessages();
    }
  }
  
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _pollNewMessages();
    });
  }
  
  Future<void> _loadMessages() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await apiClient.get(
        'api/v1/messaging/${widget.conversation.id}/messages/');
      
      List<dynamic> list = [];
      if (response is List) {
        list = response;
      } else if (response is Map) {
        list = response['results'] as List? ?? [];
      }

      if (mounted) {
        setState(() {
          final seen = <String>{};
          _messages = list
            .map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
            .where((m) => seen.add(m.id))
            .toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _pollNewMessages() async {
    try {
      String? lastId;
      for (int i = _messages.length - 1; i >= 0; i--) {
        if (!_messages[i].id.startsWith('temp_')) {
          lastId = _messages[i].id;
          break;
        }
      }
      
      final params = <String, dynamic>{};
      if (lastId != null) {
        params['after'] = lastId;
      }
      
      final response = await ApiClient.instance.dio.get(
        '/api/v1/messaging/${widget.conversation.id}/messages/',
        queryParameters: params);
      
      List<dynamic> list = [];
      if (response.data is List) {
        list = response.data as List;
      } else if (response.data is Map) {
        list = (response.data['results'] as List?) ?? [];
      }
      
      if (list.isEmpty || !mounted) return;
      
      final existing = _messages.map((m) => m.id).toSet();
      
      final newOnes = list
        .map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
        .where((m) => !existing.contains(m.id))
        .toList();
      
      if (newOnes.isNotEmpty) {
        setState(() {
          _messages.addAll(newOnes);
        });
        _scrollToBottom();
      }
    } catch (e) {
      // Silent fail
    }
  }
  
  Future<void> _loadSuggestions() async {
    try {
      final response = await apiClient.get(
        'api/v1/messaging/${widget.conversation.id}/suggestions/');
      final list = response['suggestions'] as List? ?? [];
      if (mounted) {
        setState(() {
          _suggestions = list
            .map((s) => s as Map<String, dynamic>)
            .toList();
        });
      }
    } catch (e) {
      debugPrint('Suggestions error: $e');
    }
  }
  
  Future<void> _sendMessage({
    String type = 'text',
    String? content,
    File? mediaFile,
    double? duration,
  }) async {
    final text = content ?? _textController.text.trim();
    if (type == 'text' && text.isEmpty) return;
    
    final tempMsg = MessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      senderId: AuthStorage.getCachedUserId() ?? '',
      senderName: 'You',
      messageType: type,
      content: text,
      isRead: false,
      sentAt: DateTime.now(),
      isDeleted: false,
    );
    
    setState(() {
      _messages.add(tempMsg);
      if (type == 'text') _textController.clear();
    });
    _scrollToBottom();
    
    try {
      Map<String, dynamic> data;
      if (mediaFile != null) {
        data = {
          'message_type': type,
          'content': text,
          'media_duration': duration,
          'media_file': await dio.MultipartFile.fromFile(mediaFile.path),
        };
      } else {
        data = {
          'message_type': type,
          'content': text,
        };
      }
      
      final response = await apiClient.post(
        'api/v1/messaging/${widget.conversation.id}/send/',
        data);
      
      if (mounted && response['message'] != null) {
        final real = MessageModel.fromJson(response['message']);
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == tempMsg.id);
          if (idx != -1) _messages[idx] = real;
        });
      }
    } catch (e) {
      setState(() {
        _messages.removeWhere((m) => m.id == tempMsg.id);
      });
      
      // Check if locked
      if (e.toString().contains('429')) {
         _showLockedDialog({'error': 'Messaging limit reached'});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  void _showLockedDialog(dynamic data) {
    final reason = data?['error'] ?? 'Messaging limit reached';
    showDialog(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Messaging Paused', style: AppTypography.displayMedium.copyWith(fontSize: 18)),
        content: Text(reason, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary))),
          if (data?['suggestion'] != null)
            LiquidGlassButton(
              size: LiquidButtonSize.sm,
              onPressed: () {
                Navigator.pop(context);
                // Navigate to date planner
              },
              child: Text('Make a plan', style: AppTypography.caption.copyWith(color: Colors.white))),
        ]));
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAF7F4);
    final textColor = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A1A1A);
    final conv = widget.conversation;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(conv, textColor, bgColor),
      body: Column(children: [
        _buildStatusBar(conv),
        if (_suggestions.isNotEmpty) _buildSuggestions(),
        Expanded(child: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                final showDate = i == 0 || !_sameDay(_messages[i-1].sentAt, msg.sentAt);
                return Column(children: [
                  if (showDate) _DateDivider(date: msg.sentAt),
                  _MessageBubble(message: msg, isDark: isDark),
                ]);
              })),
        _buildInputBar(conv, isDark),
      ]));
  }
  
  PreferredSizeWidget _buildAppBar(ConversationModel conv, Color textColor, Color bgColor) {
    final photoUrl = conv.otherUser.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textColor, size: 22),
        onPressed: () => Navigator.pop(context)),
      title: Row(children: [
        ClipOval(child: hasPhoto
          ? CachedNetworkImage(imageUrl: photoUrl, width: 36, height: 36, fit: BoxFit.cover, errorWidget: (ctx, url, err) => _AvatarFallback(name: conv.otherUser.name))
          : _AvatarFallback(name: conv.otherUser.name)),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conv.otherUser.name,
              style: AppTypography.labelMedium.copyWith(color: textColor, fontWeight: FontWeight.w600)),
            if (conv.otherUser.neighborhood != null)
              Text(conv.otherUser.neighborhood!,
                style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10)),
          ])),
      ]));
  }

  Widget _buildStatusBar(ConversationModel conv) {
    if (conv.sparkStatus.active && conv.sparkStatus.secondsRemaining != null && conv.sparkStatus.secondsRemaining! < 24 * 3600) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.primary.withOpacity(0.08),
        child: Row(children: [
          const Icon(Icons.local_fire_department, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('Spark window closing soon — make a plan',
            style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500)),
        ]));
    }
    if (!conv.sparkStatus.active && conv.messagesRemaining != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.orange.withOpacity(0.08),
        child: Row(children: [
          Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Text('${conv.messagesRemaining} messages remaining today',
            style: AppTypography.caption.copyWith(color: Colors.orange.shade700)),
        ]));
    }
    return const SizedBox.shrink();
  }
  
  Widget _buildSuggestions() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final s = _suggestions[i];
          return _SuggestionCard(suggestion: s, onTap: () => _handleSuggestion(s));
        }));
  }
  
  void _handleSuggestion(Map<String, dynamic> s) {
    final msg = 'What about: ${s['title']}?\n${s['subtitle']}';
    _textController.text = msg;
  }
  
  Widget _buildInputBar(ConversationModel conv, bool isDark) {
    final canSend = conv.canSend.allowed;
    final surfaceColor = isDark ? const Color(0xFF1C1612) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2820) : Colors.grey.shade200;
    
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(color: surfaceColor, border: Border(top: BorderSide(color: borderColor))),
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.image_outlined, size: 22, color: canSend ? AppColors.textMuted : AppColors.textMuted.withOpacity(0.3)),
          onPressed: canSend ? _pickAndSendPhoto : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints()),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          controller: _textController,
          enabled: canSend,
          maxLines: 4,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          style: AppTypography.bodyMedium,
          onChanged: (val) => setState(() {}),
          decoration: InputDecoration(
            hintText: canSend ? 'Message...' : conv.canSend.reason ?? 'Messaging paused',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            filled: true,
            fillColor: isDark ? const Color(0xFF252018) : const Color(0xFFF5F5F5),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none)))),
        const SizedBox(width: 8),
        _textController.text.isEmpty
          ? GestureDetector(
              onLongPressStart: canSend ? (_) => _startVoiceRecording() : null,
              onLongPressEnd: canSend ? (_) => _stopVoiceRecording() : null,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: canSend ? AppColors.primaryGlass : Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(_isRecordingVoice ? Icons.stop : Icons.mic_outlined, size: 20, color: canSend ? AppColors.primary : AppColors.textMuted)))
          : GestureDetector(
              onTap: canSend ? _sendMessage : null,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: canSend ? AppColors.primary : Colors.grey.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_upward, size: 20, color: Colors.white))),
      ]));
  }
  
  Future<void> _pickAndSendPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    await _sendMessage(type: 'photo', mediaFile: File(picked.path));
  }
  
  void _startVoiceRecording() {
    setState(() => _isRecordingVoice = true);
  }
  
  void _stopVoiceRecording() {
    setState(() => _isRecordingVoice = false);
  }
  
  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback({required this.name});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      color: AppColors.primaryGlass,
      child: Center(child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14))));
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isDark;
  const _MessageBubble({required this.message, required this.isDark});
  
  @override
  Widget build(BuildContext context) {
    final isMe = message.isFromMe;
    final myBubble = AppColors.primary;
    final theirBubble = isDark ? const Color(0xFF1C1612) : Colors.white;
    final myText = Colors.white;
    final theirText = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A1A1A);
    
    if (message.messageType == 'system') {
      return Center(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(message.content,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center)));
    }
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        margin: EdgeInsets.only(bottom: 4, left: isMe ? 48 : 0, right: isMe ? 0 : 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: message.messageType == 'photo' ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? myBubble : theirBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]),
              child: _buildBubbleContent(message, isMe, myText, theirText)),
            const SizedBox(height: 2),
            Text(_formatTime(message.sentAt),
              style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 9)),
          ])));
  }
  
  Widget _buildBubbleContent(MessageModel msg, bool isMe, Color myText, Color theirText) {
    final textColor = isMe ? myText : theirText;
    switch (msg.messageType) {
      case 'photo':
        final photoUrl = msg.mediaUrl;
        final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18)),
          child: hasPhoto
            ? CachedNetworkImage(imageUrl: photoUrl, width: 220, fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: 220, height: 160, color: Colors.grey.shade200),
                errorWidget: (_, __, ___) => Container(width: 220, height: 160, color: Colors.grey.shade200, child: const Icon(Icons.broken_image_outlined, color: Colors.grey)))
            : Container(width: 220, height: 160, color: Colors.grey.shade200, child: const Icon(Icons.photo_outlined, color: Colors.grey)));
      case 'voice':
        return _VoiceMessagePlayer(message: msg, isMe: isMe);
      default:
        return Text(msg.content, style: AppTypography.bodyMedium.copyWith(color: textColor));
    }
  }
  
  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
}

class _VoiceMessagePlayer extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _VoiceMessagePlayer({required this.message, required this.isMe});
  
  @override
  Widget build(BuildContext context) {
    final color = isMe ? Colors.white : AppColors.primary;
    final duration = message.mediaDuration ?? 0;
    final mins = (duration ~/ 60).toString().padLeft(2, '0');
    final secs = (duration % 60).toInt().toString().padLeft(2, '0');
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.play_circle_outline, color: color, size: 28),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 100, height: 2, color: color.withOpacity(0.3),
          child: const FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0, child: SizedBox())),
        const SizedBox(height: 4),
        Text('$mins:$secs', style: AppTypography.caption.copyWith(color: isMe ? Colors.white.withOpacity(0.7) : AppColors.textMuted, fontSize: 10)),
      ]),
    ]);
  }
}

class _SuggestionCard extends StatelessWidget {
  final Map<String, dynamic> suggestion;
  final VoidCallback onTap;
  const _SuggestionCard({required this.suggestion, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppColors.primaryGlass, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(suggestion['title'] ?? '', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            Text(suggestion['subtitle'] ?? '', style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 9)),
          ]),
        ])));
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});
  @override
  Widget build(BuildContext context) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final label = '${date.day} ${months[date.month-1]}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(child: Container(height: 0.5, color: AppColors.textMuted.withOpacity(0.2))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10))),
        Expanded(child: Container(height: 0.5, color: AppColors.textMuted.withOpacity(0.2))),
      ]));
  }
}
