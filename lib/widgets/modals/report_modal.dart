import 'package:flutter/material.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/utils/constants.dart';

class ReportModal extends StatefulWidget {
  final String targetType;
  final String targetId;

  const ReportModal({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  static void show(BuildContext context, {required String targetType, required String targetId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportModal(targetType: targetType, targetId: targetId),
    );
  }

  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  final ApiClient apiClient = ApiClient();
  String? _selectedCategory;
  final TextEditingController _noteController = TextEditingController();
  bool _submitting = false;

  final List<Map<String, String>> _categories = [
    {'value': 'harassment', 'label': 'Harassment'},
    {'value': 'spam', 'label': 'Spam'},
    {'value': 'inappropriate', 'label': 'Inappropriate Content'},
    {'value': 'impersonation', 'label': 'Impersonation'},
    {'value': 'underage', 'label': 'Underage User'},
    {'value': 'violence', 'label': 'Violence'},
    {'value': 'hate_speech', 'label': 'Hate Speech'},
    {'value': 'other', 'label': 'Other'},
  ];

  Future<void> _submitReport() async {
    if (_selectedCategory == null) return;

    setState(() => _submitting = true);
    try {
      await apiClient.post('api/v1/moderation/report/', {
        'target_type': widget.targetType,
        'target_id': widget.targetId,
        'category': _selectedCategory,
        'note': _noteController.text,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks. Our team will review within 24 hours.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Report', style: AppTypography.displaySmall.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text('Why are you reporting this ${widget.targetType}?', 
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70)),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView(
              shrinkWrap: true,
              children: _categories.map((cat) => RadioListTile<String>(
                title: Text(cat['label']!, style: const TextStyle(color: Colors.white)),
                value: cat['value']!,
                groupValue: _selectedCategory,
                activeColor: AppConstants.primaryRed,
                onChanged: (val) => setState(() => _selectedCategory = val),
                contentPadding: EdgeInsets.zero,
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Additional notes (optional)',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedCategory == null || _submitting) ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
