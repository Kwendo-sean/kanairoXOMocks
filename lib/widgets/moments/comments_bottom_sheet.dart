import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/api_client.dart';
import '../../utils/constants.dart';
import '../modals/report_modal.dart';

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
      final r = await ApiClient.instance.get('api/v1/moments/${widget.momentId}/comments/');
      if (mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(r['results'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _post() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiClient.instance.post('api/v1/moments/${widget.momentId}/comments/', {'text': text});
      _ctrl.clear();
      await _load();
    } catch (e) {
      // Error
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showCommentOptions(Map<String, dynamic> comment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.report_outlined, color: Colors.white),
            title: const Text('Report Comment', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              ReportModal.show(context, targetType: 'comment', targetId: comment['id'].toString());
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
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
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textMuted.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.all(16), child: Text('Comments', style: AppTypography.labelMedium.copyWith(color: text, fontWeight: FontWeight.w700))),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _comments.length,
                    itemBuilder: (_, i) {
                      final c = _comments[i];
                      return GestureDetector(
                        onLongPress: () => _showCommentOptions(c),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(radius: 16, backgroundImage: c['user_photo'] != null ? NetworkImage(ApiConstants.fixMediaUrl(c['user_photo'])) : null),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c['user_name'] ?? 'User', style: AppTypography.caption.copyWith(color: text, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(c['text'] ?? '', style: AppTypography.caption.copyWith(color: text)),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                      decoration: InputDecoration(hintText: 'Add a comment...', filled: true, fillColor: isDark ? const Color(0xFF252018) : const Color(0xFFF5F5F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(onPressed: _sending ? null : _post, icon: const Icon(Icons.send, color: AppConstants.primaryRed)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
