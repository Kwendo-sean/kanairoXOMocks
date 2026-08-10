import 'package:flutter/material.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/utils/constants.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final ApiClient apiClient = ApiClient();
  bool _loading = true;
  List<dynamic> _preferences = [];

  @override
  void initState() {
    super.initState();
    _fetchPreferences();
  }

  Future<void> _fetchPreferences() async {
    try {
      final response = await apiClient.get('api/v1/notifications/preferences/');
      setState(() {
        _preferences = response['preferences'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  /// One switch per category — flips push and in-app together. Email is never
  /// exposed; the backend keeps whatever it already has for that channel.
  Future<void> _togglePreference(int index, bool value) async {
    final previous = Map<String, dynamic>.from(_preferences[index]);
    final updated = Map<String, dynamic>.from(previous)
      ..['push_enabled'] = value
      ..['in_app_enabled'] = value;

    setState(() => _preferences[index] = updated);

    try {
      await apiClient.patch('api/v1/notifications/preferences/', {
        'preferences': [updated]
      });
    } catch (e) {
      setState(() => _preferences[index] = previous);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Notification Settings', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildGroup('Connections', ['connection_request', 'connection_accepted', 'connection_rejected']),
              _buildGroup('Moments', ['moment_like', 'moment_comment', 'moment_save']),
              _buildGroup('Messages', ['new_message']),
              _buildGroup('Events', ['event_reminder', 'ticket_ready']),
              _buildGroup('Dates', ['date_request', 'date_accepted', 'date_declined', 'date_reminder']),
            ],
          ),
    );
  }

  Widget _buildGroup(String title, List<String> categories) {
    final groupPrefs = _preferences.where((p) => categories.contains(p['category'])).toList();
    if (groupPrefs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Text(title, style: AppTypography.labelLarge.copyWith(color: AppConstants.primaryRed, fontWeight: FontWeight.bold)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: groupPrefs.map((pref) {
              final idx = _preferences.indexOf(pref);
              return Column(
                children: [
                  _buildPrefTile(idx, pref),
                  if (groupPrefs.last != pref) Divider(height: 1, color: Colors.white.withOpacity(0.05)),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPrefTile(int index, Map<String, dynamic> pref) {
    final raw = pref['category'].toString();
    final label = raw.replaceAll('_', ' ').replaceFirst(raw[0], raw[0].toUpperCase());
    final enabled = pref['push_enabled'] == true || pref['in_app_enabled'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ),
          Switch(
            value: enabled,
            activeColor: AppConstants.primaryRed,
            onChanged: (val) => _togglePreference(index, val),
          ),
        ],
      ),
    );
  }
}
