import 'package:flutter/material.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final ApiClient apiClient = ApiClient();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedReason;
  bool _isDeleting = false;

  final List<Map<String, String>> _reasons = [
    {'value': 'privacy', 'label': 'Privacy concerns'},
    {'value': 'not_useful', 'label': "I don't find it useful"},
    {'value': 'too_many_notifications', 'label': 'Too many notifications'},
    {'value': 'found_alternative', 'label': 'Found an alternative'},
    {'value': 'other', 'label': 'Other'},
  ];

  Future<void> _handleDelete() async {
    if (_phoneController.text.isEmpty || _selectedReason == null) return;

    setState(() => _isDeleting = true);
    try {
      await apiClient.delete('api/v1/auth/me/delete/', body: {
        'confirm_phone': _phoneController.text,
        'reason': _selectedReason,
      });

      if (mounted) {
        // Clear local storage and sign out
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout(); 
        
        Navigator.of(context).pushNamedAndRemoveUntil('/landing', (route) => false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account successfully scheduled for deletion.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deletion failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text('We\'re sorry to see you go', style: AppTypography.displaySmall.copyWith(color: Colors.white)),
            const SizedBox(height: 12),
            Text(
              'Your account will be permanently deleted after a 30-day grace period. If you log in within 30 days, your deletion request will be cancelled.',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            Text('Why are you leaving?', style: AppTypography.labelLarge.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            ..._reasons.map((r) => RadioListTile<String>(
              title: Text(r['label']!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              value: r['value']!,
              groupValue: _selectedReason,
              activeColor: AppConstants.primaryRed,
              onChanged: (val) => setState(() => _selectedReason = val),
              contentPadding: EdgeInsets.zero,
            )),
            const SizedBox(height: 24),
            Text('Confirm your phone number', style: AppTypography.labelLarge.copyWith(color: Colors.white)),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '0712345678',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isDeleting || _selectedReason == null || _phoneController.text.isEmpty) ? null : _handleDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isDeleting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Permanently Delete My Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
