import 'package:flutter/material.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/utils/constants.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final ApiClient apiClient = ApiClient();
  bool _loading = true;
  Map<String, dynamic> _privacy = {};

  @override
  void initState() {
    super.initState();
    _fetchPrivacy();
  }

  Future<void> _fetchPrivacy() async {
    try {
      final response = await apiClient.get('api/v1/profiles/me/privacy/');
      setState(() {
        _privacy = response;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updatePrivacy(String field, dynamic value) async {
    final originalValue = _privacy[field];
    setState(() => _privacy[field] = value);

    try {
      await apiClient.patch('api/v1/profiles/me/privacy/', {field: value});
    } catch (e) {
      setState(() => _privacy[field] = originalValue);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update privacy setting')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Privacy Settings', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDropdownTile(
                'Profile Visibility',
                'Who can see your profile on KanairoXO.',
                'profile_visibility',
                _privacy['profile_visibility'],
                ['Public', 'Connections', 'Hidden'],
              ),
              _buildToggleTile(
                'Show Age',
                'Display your age on your profile.',
                'show_age',
                _privacy['show_age'] ?? true,
              ),
              _buildToggleTile(
                'Show Neighborhood',
                'Display your neighborhood on your profile.',
                'show_neighborhood',
                _privacy['show_neighborhood'] ?? true,
              ),
              _buildToggleTile(
                'Allow Message Requests',
                'Let people you aren\'t connected with send you requests.',
                'allow_message_requests',
                _privacy['allow_message_requests'] ?? true,
              ),
              _buildToggleTile(
                'Discoverable in Search',
                'Show up in search results and suggestions.',
                'discoverable_in_search',
                _privacy['discoverable_in_search'] ?? true,
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Blocked Accounts', style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                onTap: () => Navigator.pushNamed(context, '/settings/blocked'),
              ),
            ],
          ),
    );
  }

  Widget _buildToggleTile(String title, String subtitle, String field, bool value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        trailing: Switch(
          value: value,
          activeColor: AppConstants.primaryRed,
          onChanged: (val) => _updatePrivacy(field, val),
        ),
      ),
    );
  }

  Widget _buildDropdownTile(String title, String subtitle, String field, String current, List<String> options) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
              DropdownButton<String>(
                value: options.contains(current) ? current : options.first,
                dropdownColor: Colors.grey[900],
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                items: options.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _updatePrivacy(field, val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
