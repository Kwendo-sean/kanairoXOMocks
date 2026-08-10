import 'dart:async';
import 'dart:io';
import 'dart:ui' show FontFeature;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/messaging/conversation_model.dart';
import '../../models/messaging/message_model.dart';
import '../../services/api_client.dart';
import '../../utils/auth_storage.dart';
import '../../widgets/liquid_glass_button.dart';
import '../../services/notification_service.dart';
import '../../widgets/modals/report_modal.dart';
import '../../widgets/center_toast.dart';

const _kReactionEmojis = ['❤️', '😂', '😮', '😢', '🔥', '👍'];
const _kScreenshotChannel = MethodChannel('com.kanairoxo.app/screenshots');

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
  final _recorder = Record();
  DateTime? _recordingStartedAt;
  Timer? _recordingTicker;

  List<Map<String, dynamic>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages().then((_) => _startPolling());
    _loadSuggestions();
    NotificationService.newMessageNotifier.addListener(_onPushMessage);
    _kScreenshotChannel.setMethodCallHandler(_onScreenshotChannel);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _recordingTicker?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
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
    if (convId == widget.conversation.id && mounted) _pollNewMessages();
  }

  Future<dynamic> _onScreenshotChannel(MethodCall call) async {
    if (call.method == 'screenshotTaken') _reportScreenshot();
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
      final response =
          await apiClient.get('api/v1/messaging/${widget.conversation.id}/messages/');

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
      if (lastId != null) params['after'] = lastId;

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
        setState(() => _messages.addAll(newOnes));
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _loadSuggestions() async {
    try {
      final response = await apiClient
          .get('api/v1/messaging/${widget.conversation.id}/suggestions/');
      final list = response['suggestions'] as List? ?? [];
      if (mounted) {
        setState(() {
          _suggestions = list.map((s) => s as Map<String, dynamic>).toList();
        });
      }
    } catch (_) {}
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
      isMine: true,
    );

    setState(() {
      _messages.add(tempMsg);
      if (type == 'text') _textController.clear();
    });
    _scrollToBottom();

    try {
      final endpoint = 'api/v1/messaging/${widget.conversation.id}/send/';
      final dynamic response;

      if (mediaFile != null) {
        response = await apiClient.postMultipart(
          endpoint,
          fields: {
            'message_type': type,
            'content': text,
            if (duration != null) 'media_duration': duration.toString(),
          },
          fileField: 'media_file',
          filePath: mediaFile.path,
        );
      } else {
        response = await apiClient.post(endpoint, {
          'message_type': type,
          'content': text,
        });
      }

      if (mounted && response['message'] != null) {
        final real = MessageModel.fromJson(response['message']);
        setState(() {
          // Remove the placeholder AND any copy the poller already inserted
          // before we could confirm the real ID — prevents duplicates.
          _messages.removeWhere((m) => m.id == tempMsg.id || m.id == real.id);
          _messages.add(real);
        });
      }
    } catch (e) {
      setState(() => _messages.removeWhere((m) => m.id == tempMsg.id));
      if (e.toString().contains('429')) {
        _showLockedDialog({'error': 'Messaging limit reached'});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Failed to send'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    // Optimistic: mark as deleted locally
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    setState(() {
      _messages[idx] = _messages[idx].copyWith(isDeleted: true);
    });
    try {
      await apiClient.delete(
          'api/v1/messaging/${widget.conversation.id}/messages/$messageId/');
    } catch (_) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _messages[idx] = _messages[idx].copyWith(isDeleted: false);
        });
      }
    }
  }

  Future<void> _reactToMessage(String messageId, String emoji) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;

    final current = _messages[idx].reactions;
    final alreadyMyEmoji =
        current.where((r) => r['reacted_by_me'] == true).firstOrNull?['emoji'];

    List<Map<String, dynamic>> updated;

    if (alreadyMyEmoji == emoji) {
      // Toggle off
      updated = current.map((r) {
        if (r['emoji'] == emoji) {
          final newCount = (r['count'] as int) - 1;
          if (newCount <= 0) return null;
          return {'emoji': emoji, 'count': newCount, 'reacted_by_me': false};
        }
        return r;
      }).whereType<Map<String, dynamic>>().toList();
    } else {
      // Remove old reaction if any, add new one
      updated = current.map((r) {
        if (r['reacted_by_me'] == true) {
          final newCount = (r['count'] as int) - 1;
          if (newCount <= 0) return null;
          return {'emoji': r['emoji'], 'count': newCount, 'reacted_by_me': false};
        }
        return r;
      }).whereType<Map<String, dynamic>>().toList();

      final existingEmoji = updated.where((r) => r['emoji'] == emoji).firstOrNull;
      if (existingEmoji != null) {
        updated = updated.map((r) {
          if (r['emoji'] == emoji) {
            return {'emoji': emoji, 'count': (r['count'] as int) + 1, 'reacted_by_me': true};
          }
          return r;
        }).toList();
      } else {
        updated.add({'emoji': emoji, 'count': 1, 'reacted_by_me': true});
      }
    }

    setState(() => _messages[idx] = _messages[idx].copyWith(reactions: updated));

    try {
      if (alreadyMyEmoji == emoji) {
        await apiClient.delete(
            'api/v1/messaging/${widget.conversation.id}/messages/$messageId/react/');
      } else {
        await apiClient.post(
            'api/v1/messaging/${widget.conversation.id}/messages/$messageId/react/',
            {'emoji': emoji});
      }
    } catch (_) {}
  }

  Future<void> _reportScreenshot() async {
    try {
      await apiClient.post(
          'api/v1/messaging/${widget.conversation.id}/screenshot/', {});
    } catch (_) {}
  }

  void _showMessageOptions(MessageModel msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageOptionsSheet(
        message: msg,
        onReact: (emoji) {
          Navigator.pop(context);
          _reactToMessage(msg.id, emoji);
        },
        onDelete: msg.isMine && !msg.isDeleted
            ? () {
                Navigator.pop(context);
                _deleteMessage(msg.id);
              }
            : null,
        onReport: !msg.isMine
            ? () {
                Navigator.pop(context);
                ReportModal.show(context,
                    targetType: 'message', targetId: msg.id);
              }
            : null,
      ),
    );
  }

  void _showLockedDialog(dynamic data) {
    final reason = data?['error'] ?? 'Messaging paused';
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Messaging Paused',
                  style: AppTypography.displayMedium.copyWith(fontSize: 18)),
              content: Text(reason,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textMuted)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK',
                        style: TextStyle(color: AppColors.primary))),
                if (data?['suggestion'] != null)
                  LiquidGlassButton(
                      size: LiquidButtonSize.sm,
                      onPressed: () => Navigator.pop(context),
                      child: Text('Make a plan',
                          style: AppTypography.caption
                              .copyWith(color: Colors.white))),
              ],
            ));
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
    final bgColor =
        isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAF7F4);
    final textColor =
        isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A1A1A);
    final conv = widget.conversation;

    return Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(conv, textColor, bgColor),
        body: Column(children: [
          _buildStatusBar(conv),
          if (_suggestions.isNotEmpty) _buildSuggestions(),
          Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = _messages[i];
                        final showDate = i == 0 ||
                            !_sameDay(_messages[i - 1].sentAt, msg.sentAt);
                        return Column(children: [
                          if (showDate) _DateDivider(date: msg.sentAt),
                          _MessageBubble(
                            message: msg,
                            isDark: isDark,
                            onLongPress: () => _showMessageOptions(msg),
                            onPhotoTap: (url) => Navigator.push(
                                context,
                                PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (_, __, ___) =>
                                      _FullScreenPhotoView(url: url),
                                )),
                          ),
                        ]);
                      })),
          _buildInputBar(conv, isDark),
        ]));
  }

  PreferredSizeWidget _buildAppBar(
      ConversationModel conv, Color textColor, Color bgColor) {
    final photoUrl = conv.otherUser.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor, size: 22),
            onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          ClipOval(
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorWidget: (ctx, url, err) =>
                          _AvatarFallback(name: conv.otherUser.name))
                  : _AvatarFallback(name: conv.otherUser.name)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(conv.otherUser.name,
                    style: AppTypography.labelMedium.copyWith(
                        color: textColor, fontWeight: FontWeight.w600)),
                if (conv.otherUser.neighborhood != null)
                  Text(conv.otherUser.neighborhood!,
                      style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted, fontSize: 10)),
              ])),
        ]));
  }

  Widget _buildStatusBar(ConversationModel conv) {
    if (conv.sparkStatus.active &&
        conv.sparkStatus.secondsRemaining != null &&
        conv.sparkStatus.secondsRemaining! < 24 * 3600) {
      return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.primary.withOpacity(0.08),
          child: Row(children: [
            const Icon(Icons.local_fire_department,
                size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('Spark window closing soon — make a plan',
                style: AppTypography.caption.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w500)),
          ]));
    }
    return const SizedBox.shrink();
  }

  Widget _buildSuggestions() {
    return SizedBox(
        height: 80,
        child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final s = _suggestions[i];
              return _SuggestionCard(
                  suggestion: s, onTap: () => _handleSuggestion(s));
            }));
  }

  void _handleSuggestion(Map<String, dynamic> s) {
    final msg = 'What about: ${s['title']}?\n${s['subtitle']}';
    _textController.text = msg;
  }

  Widget _buildInputBar(ConversationModel conv, bool isDark) {
    final canSend = conv.canSend.allowed;
    final surfaceColor = isDark ? const Color(0xFF1C1612) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2E2820) : Colors.grey.shade200;

    // While recording, the whole bar becomes the recorder: timer, cancel,
    // send. Hold-to-record had no affordance at all — nothing on screen told
    // you to hold, so tapping the mic looked broken.
    if (_isRecordingVoice) {
      return _buildRecordingBar(surfaceColor, borderColor);
    }

    return Container(
        padding: EdgeInsets.fromLTRB(
            12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
        decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(top: BorderSide(color: borderColor))),
        child: Row(children: [
          IconButton(
              icon: Icon(Icons.image_outlined,
                  size: 22,
                  color: canSend
                      ? AppColors.textMuted
                      : AppColors.textMuted.withOpacity(0.3)),
              onPressed: canSend ? _pickAndSendPhoto : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints()),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
                  controller: _textController,
                  enabled: canSend,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTypography.bodyMedium,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                      hintText: canSend
                          ? 'Message...'
                          : conv.canSend.reason ?? 'Messaging paused',
                      hintStyle: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF252018)
                          : const Color(0xFFF5F5F5),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none),
                      disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none)))),
          const SizedBox(width: 8),
          _textController.text.isEmpty
              ? GestureDetector(
                  onTap: canSend ? _startVoiceRecording : null,
                  child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: canSend
                              ? AppColors.primaryGlass
                              : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: Icon(
                          Icons.mic_none_rounded,
                          size: 20,
                          color: canSend
                              ? AppColors.primary
                              : AppColors.textMuted)))
              : GestureDetector(
                  onTap: canSend ? _sendMessage : null,
                  child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: canSend
                              ? AppColors.primary
                              : Colors.grey.withOpacity(0.2),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_upward,
                          size: 20, color: Colors.white))),
        ]));
  }

  Future<void> _pickAndSendPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(); // no quality reduction
    if (picked.isEmpty) return;
    final capped = picked.take(7).toList();

    if (!mounted) return;
    if (capped.length == 1) {
      await _sendMessage(type: 'photo', mediaFile: File(capped.first.path));
      return;
    }

    // Multi-photo preview sheet
    final toSend = await showModalBottomSheet<List<XFile>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoPreviewSheet(files: capped),
    );
    if (toSend == null || toSend.isEmpty || !mounted) return;
    for (final f in toSend) {
      await _sendMessage(type: 'photo', mediaFile: File(f.path));
    }
  }

  /// The recorder replaces the whole input bar while active: elapsed timer,
  /// a discard button and a send button. Tap the mic to start, tap send to
  /// finish — no hidden hold gesture.
  Widget _buildRecordingBar(Color surfaceColor, Color borderColor) {
    final elapsed = _recordingStartedAt == null
        ? Duration.zero
        : DateTime.now().difference(_recordingStartedAt!);
    final mins = elapsed.inMinutes.toString().padLeft(2, '0');
    final secs = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(top: BorderSide(color: borderColor))),
      child: Row(children: [
        // Discard
        GestureDetector(
          onTap: _cancelVoiceRecording,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.12),
                shape: BoxShape.circle),
            child: Icon(Icons.delete_outline_rounded,
                size: 20, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(width: 12),
        // Pulsing dot + timer
        Expanded(
          child: Row(children: [
            _PulsingDot(),
            const SizedBox(width: 10),
            Text('$mins:$secs',
                style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(width: 10),
            Text('Recording…',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textMuted)),
          ]),
        ),
        // Send
        GestureDetector(
          onTap: _stopVoiceRecording,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_upward,
                size: 21, color: Colors.white),
          ),
        ),
      ]),
    );
  }

  Future<void> _startVoiceRecording() async {
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      CenterToast.show(
          context, 'Allow microphone access to send voice notes',
          isError: true);
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _recorder.start(path: path, encoder: AudioEncoder.aacLc);
    } catch (_) {
      if (mounted) {
        CenterToast.show(context, 'Sorry, something went wrong',
            isError: true);
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isRecordingVoice = true;
      _recordingStartedAt = DateTime.now();
    });
    // Drive the on-screen timer.
    _recordingTicker?.cancel();
    _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isRecordingVoice) {
        setState(() {});
      }
    });
  }

  Future<void> _cancelVoiceRecording() async {
    if (!_isRecordingVoice) return;
    _recordingTicker?.cancel();
    _recordingTicker = null;
    final path = await _recorder.stop();
    if (mounted) {
      setState(() {
        _isRecordingVoice = false;
        _recordingStartedAt = null;
      });
    }
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
  }

  Future<void> _stopVoiceRecording() async {
    if (!_isRecordingVoice) return;
    _recordingTicker?.cancel();
    _recordingTicker = null;
    final startedAt = _recordingStartedAt;
    final path = await _recorder.stop();

    if (mounted) {
      setState(() {
        _isRecordingVoice = false;
        _recordingStartedAt = null;
      });
    }
    if (path == null) return;

    final seconds = startedAt == null
        ? 0.0
        : DateTime.now().difference(startedAt).inMilliseconds / 1000;
    if (seconds < 1.0) {
      if (mounted) {
        CenterToast.show(context, 'Hold on a bit longer to record');
      }
      try {
        await File(path).delete();
      } catch (_) {}
      return;
    }

    await _sendMessage(
        type: 'voice', mediaFile: File(path), duration: seconds);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Red dot that breathes while recording.
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isDark;
  final VoidCallback onLongPress;
  final void Function(String url) onPhotoTap;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.onLongPress,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMine;
    final myBubble = AppColors.primary;
    final theirBubble =
        isDark ? const Color(0xFF1C1612) : Colors.white;
    final myText = Colors.white;
    final theirText =
        isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A1A1A);

    if (message.messageType == 'system') {
      return Center(
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(message.content,
                  style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted),
                  textAlign: TextAlign.center)));
    }

    if (message.isDeleted) {
      return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
              margin: EdgeInsets.only(
                  bottom: 4, left: isMe ? 48 : 0, right: isMe ? 0 : 48),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1612)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300)),
              child: Text('Message unsent',
                  style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted))));
    }

    final reactions = message.reactions;

    return GestureDetector(
        onLongPress: onLongPress,
        child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72),
                margin: EdgeInsets.only(
                    bottom: reactions.isNotEmpty ? 2 : 4,
                    left: isMe ? 48 : 0,
                    right: isMe ? 0 : 48),
                child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                          onTap: message.messageType == 'photo' &&
                                  (message.mediaUrl?.isNotEmpty ?? false)
                              ? () => onPhotoTap(message.mediaUrl!)
                              : null,
                          child: Container(
                              padding: message.messageType == 'photo'
                                  ? EdgeInsets.zero
                                  : const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                  color: isMe ? myBubble : theirBubble,
                                  borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft:
                                          Radius.circular(isMe ? 18 : 4),
                                      bottomRight:
                                          Radius.circular(isMe ? 4 : 18)),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2))
                                  ]),
                              child: _buildBubbleContent(
                                  message, isMe, myText, theirText))),
                      const SizedBox(height: 2),
                      Text(_formatTime(message.sentAt),
                          style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted, fontSize: 9)),
                      if (reactions.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _ReactionsRow(reactions: reactions),
                      ],
                    ]))));
  }

  Widget _buildBubbleContent(
      MessageModel msg, bool isMe, Color myText, Color theirText) {
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
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    width: 220,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 220,
                        height: 160,
                        color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) => Container(
                        width: 220,
                        height: 160,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_outlined,
                            color: Colors.grey)))
                : Container(
                    width: 220,
                    height: 160,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.photo_outlined,
                        color: Colors.grey)));
      case 'voice':
        return _VoiceMessagePlayer(message: msg, isMe: isMe);
      default:
        return Text(msg.content,
            style: AppTypography.bodyMedium.copyWith(color: textColor));
    }
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Reactions row
// ---------------------------------------------------------------------------

class _ReactionsRow extends StatelessWidget {
  final List<Map<String, dynamic>> reactions;
  const _ReactionsRow({required this.reactions});

  @override
  Widget build(BuildContext context) {
    return Wrap(
        spacing: 4,
        children: reactions.map((r) {
          final emoji = r['emoji'] as String;
          final count = r['count'] as int;
          final mine = r['reacted_by_me'] == true;
          return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: mine
                      ? AppColors.primary.withOpacity(0.12)
                      : Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: mine
                          ? AppColors.primary.withOpacity(0.4)
                          : Colors.grey.withOpacity(0.3))),
              child: Text('$emoji $count',
                  style: const TextStyle(fontSize: 12)));
        }).toList());
  }
}

// ---------------------------------------------------------------------------
// Message options bottom sheet
// ---------------------------------------------------------------------------

class _MessageOptionsSheet extends StatelessWidget {
  final MessageModel message;
  final void Function(String emoji) onReact;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  const _MessageOptionsSheet({
    required this.message,
    required this.onReact,
    this.onDelete,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1612)
                : Colors.white,
            borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 16),
          // Emoji row
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _kReactionEmojis
                      .map((emoji) => GestureDetector(
                            onTap: () => onReact(emoji),
                            child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.08),
                                    shape: BoxShape.circle),
                                child: Center(
                                    child: Text(emoji,
                                        style: const TextStyle(
                                            fontSize: 22)))),
                          ))
                      .toList())),
          const SizedBox(height: 12),
          const Divider(height: 1),
          if (onDelete != null)
            ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.redAccent),
                title: const Text('Unsend',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: onDelete),
          if (onReport != null)
            ListTile(
                leading: const Icon(Icons.flag_outlined,
                    color: AppColors.textMuted),
                title: Text('Report',
                    style:
                        TextStyle(color: AppColors.textMuted)),
                onTap: onReport),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ]));
  }
}

// ---------------------------------------------------------------------------
// Full screen photo viewer
// ---------------------------------------------------------------------------

class _FullScreenPhotoView extends StatelessWidget {
  final String url;
  const _FullScreenPhotoView({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(children: [
              Center(
                  child: InteractiveViewer(
                      child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)),
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white,
                              size: 48)))),
              SafeArea(
                  child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 20)))))),
            ])));
  }
}

// ---------------------------------------------------------------------------
// Voice message player (stateful — manages audioplayers lifecycle)
// ---------------------------------------------------------------------------

class _VoiceMessagePlayer extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  const _VoiceMessagePlayer({required this.message, required this.isMe});

  @override
  State<_VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<_VoiceMessagePlayer> {
  final _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final url = widget.message.mediaUrl;
    if (url == null || url.isEmpty) return;
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else if (_playerState == PlayerState.paused) {
      await _player.resume();
    } else {
      await _player.play(UrlSource(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe ? Colors.white : AppColors.primary;
    final isPlaying = _playerState == PlayerState.playing;

    final totalMs = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds
        : ((widget.message.mediaDuration ?? 0) * 1000).toInt();
    final totalSecs = totalMs ~/ 1000;
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    final progress = totalMs > 0 ? _position.inMilliseconds / totalMs : 0.0;

    return GestureDetector(
        onTap: _toggle,
        child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                  isPlaying
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  color: color,
                  size: 30),
              const SizedBox(width: 10),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 110,
                        height: 3,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                backgroundColor: color.withOpacity(0.2),
                                valueColor:
                                    AlwaysStoppedAnimation(color)))),
                    const SizedBox(height: 4),
                    Text('$mins:$secs',
                        style: AppTypography.caption.copyWith(
                            color: widget.isMe
                                ? Colors.white.withOpacity(0.7)
                                : AppColors.textMuted,
                            fontSize: 10)),
                  ]),
            ])));
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets (unchanged)
// ---------------------------------------------------------------------------

class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback({required this.name});
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 36,
        height: 36,
        color: AppColors.primaryGlass,
        child: Center(
            child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14))));
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: AppColors.primaryGlass,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.2))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lightbulb_outline,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 8),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(suggestion['title'] ?? '',
                        style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                    Text(suggestion['subtitle'] ?? '',
                        style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted, fontSize: 9)),
                  ]),
            ])));
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});
  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final label = '${date.day} ${months[date.month - 1]}';
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Expanded(
              child: Container(
                  height: 0.5,
                  color: AppColors.textMuted.withOpacity(0.2))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(label,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textMuted, fontSize: 10))),
          Expanded(
              child: Container(
                  height: 0.5,
                  color: AppColors.textMuted.withOpacity(0.2))),
        ]));
  }
}

// ---------------------------------------------------------------------------
// Multi-photo preview sheet (WhatsApp-style)
// ---------------------------------------------------------------------------

class _PhotoPreviewSheet extends StatefulWidget {
  final List<XFile> files;
  const _PhotoPreviewSheet({required this.files});

  @override
  State<_PhotoPreviewSheet> createState() => _PhotoPreviewSheetState();
}

class _PhotoPreviewSheetState extends State<_PhotoPreviewSheet> {
  late final List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.files.length, true);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.where((s) => s).length;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('$selectedCount photo${selectedCount == 1 ? '' : 's'} selected',
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              const Spacer(),
              TextButton(
                  onPressed: () => Navigator.pop(context, <XFile>[]),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white54))),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.files.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sel = _selected[i];
                return GestureDetector(
                  onTap: () => setState(() => _selected[i] = !_selected[i]),
                  child: Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(widget.files[i].path),
                          width: 90,
                          height: 110,
                          fit: BoxFit.cover,
                          color: sel ? null : Colors.black.withOpacity(0.5),
                          colorBlendMode:
                              sel ? null : BlendMode.darken),
                    ),
                    if (!sel)
                      Positioned.fill(
                          child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius:
                                      BorderRadius.circular(10)))),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel
                              ? const Color(0xFF9B111E)
                              : Colors.white24,
                          border: Border.all(
                              color: Colors.white, width: 1.5),
                        ),
                        child: sel
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 13)
                            : null,
                      ),
                    ),
                  ]),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedCount == 0
                    ? null
                    : () {
                        final toSend = [
                          for (int i = 0; i < widget.files.length; i++)
                            if (_selected[i]) widget.files[i]
                        ];
                        Navigator.pop(context, toSend);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B111E),
                  disabledBackgroundColor: Colors.grey.shade800,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  selectedCount == 0
                      ? 'Send'
                      : 'Send $selectedCount photo${selectedCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
