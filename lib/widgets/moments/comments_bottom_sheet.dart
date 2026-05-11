import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/api_client.dart';
import '../../utils/constants.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String momentId;
  const CommentsBottomSheet({required this.momentId, super.key});
  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  List<Map<String, dynamic>> _comments = [];
  final _ctrl = TextEditingController();
  bool _sending = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await ApiClient.instance.get('/api/v1/moments/${widget.momentId}/comments/');
      if (mounted) {
        setState(() {
          // The API returns a paginated response: { "count": ..., "next": ..., "previous": ..., "results": [...] }
          _comments = List<Map<String, dynamic>>.from(r['results'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Comments: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _post() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiClient.instance.post(
        '/api/v1/moments/${widget.momentId}/comments/',
        {'text': text},
      );
      _ctrl.clear();
      // Immediately call the GET again to refresh the list
      await _load();
      if (mounted) setState(() => _sending = false);
    } catch (e) {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}/${dt.month}/${dt.year % 100}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1612) : Colors.white;
    final text = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A0808);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Comments',
                style: AppTypography.labelMedium.copyWith(
                  color: text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                : _comments.isEmpty
                  ? Center(
                      child: Text(
                        'No comments yet',
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _comments.length,
                      itemBuilder: (_, i) {
                        final c = _comments[i];
                        final userName = (c['user_name'] ?? 'User') as String;
                        final userPhoto = c['user_photo'] as String?;
                        final createdAt = c['created_at'] as String?;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primaryGlass,
                                backgroundImage: (userPhoto != null && userPhoto.isNotEmpty)
                                    ? NetworkImage(ApiConstants.fixMediaUrl(userPhoto))
                                    : null,
                                child: (userPhoto == null || userPhoto.isEmpty)
                                    ? Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          userName,
                                          style: AppTypography.caption.copyWith(
                                            color: text,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatTime(createdAt),
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.textMuted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c['text'] ?? '',
                                      style: AppTypography.caption.copyWith(color: text),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: AppTypography.bodyMedium.copyWith(color: text),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: AppTypography.caption.copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF252018) : const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sending ? null : _post,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                            ),
                          )
                        : const Icon(Icons.arrow_upward, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
