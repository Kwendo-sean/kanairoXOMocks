import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/models/data_models.dart';
import 'package:kanairoxo/providers/events_provider.dart';
import 'package:kanairoxo/widgets/experience_card.dart';
import 'package:kanairoxo/services/api_client.dart';

class SavedEventsScreen extends StatefulWidget {
  const SavedEventsScreen({super.key});

  @override
  State<SavedEventsScreen> createState() => _SavedEventsScreenState();
}

class _SavedEventsScreenState extends State<SavedEventsScreen> {
  List<Experience> _savedEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedEvents();
  }

  Future<void> _loadSavedEvents() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.get('api/v1/events/saved/');
      List<dynamic> list = [];
      if (response is List) {
        list = response;
      } else if (response is Map) {
        list = response['results'] ?? response['events'] ?? [];
      }
      if (mounted) {
        setState(() {
          _savedEvents = list.map((e) => Experience.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAF7F4);
    final textColor = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Saved Events', style: AppTypography.screenTitle.copyWith(color: textColor)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _savedEvents.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_outline, size: 64, color: AppColors.textMuted.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          "Save events you're considering — they'll show up here",
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _savedEvents.length,
                  itemBuilder: (context, index) {
                    final event = _savedEvents[index];
                    return ExperienceCard(
                      experience: event,
                      onJoin: () {
                        // Navigate to detail
                      },
                      onTap: () {
                         Navigator.pushNamed(context, '/events/${event.id}');
                      },
                      onSave: () async {
                        await ApiClient.instance.post('api/v1/events/${event.id}/save/', {});
                        _loadSavedEvents();
                      },
                    );
                  },
                ),
    );
  }
}
