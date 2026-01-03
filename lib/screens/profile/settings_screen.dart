import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _disappearingMessagesEnabled = true;
  int _disappearingMessageDuration = 48;
  bool _storyEnabled = true;
  int _storyDuration = 12;
  bool _showOnlineStatus = true;
  bool _showAge = true;
  bool _showDistance = true;
  
  final List<Map<String, dynamic>> _blockedUsers = [
    {
      'name': 'John Doe',
      'image': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop',
      'blockedDate': '2024-12-01',
    },
  ];
  
  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(PhosphorIcons.sun()),
                title: const Text('Light'),
                trailing: _darkModeEnabled ? null : Icon(PhosphorIcons.check()),
                onTap: () {
                  setState(() => _darkModeEnabled = false);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading:  Icon(PhosphorIcons.moon()),
                title: const Text('Dark'),
                trailing: _darkModeEnabled ? Icon(PhosphorIcons.check()) : null,
                onTap: () {
                  setState(() => _darkModeEnabled = true);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(PhosphorIcons.devices()),
                title: const Text('System'),
                trailing: Icon(PhosphorIcons.check()),
                onTap: () {
                  // Handle system theme
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showBlockedUsers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(PhosphorIcons.x()),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Blocked Users',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _blockedUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIcons.users(),
                              size: 60,
                              color: AppConstants.lightGray,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No blocked users',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Users you block will appear here',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppConstants.secondaryGray,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _blockedUsers.length,
                        itemBuilder: (context, index) {
                          final user = _blockedUsers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(user['image']),
                            ),
                            title: Text(user['name']),
                            subtitle: Text('Blocked on ${user['blockedDate']}'),
                            trailing: TextButton(
                              onPressed: () {
                                // Unblock user
                              },
                              child: const Text(
                                'Unblock',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to login
              },
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'This action cannot be undone. All your data will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Handle account deletion
              },
              child: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(PhosphorIcons.arrowLeft()),
          color: AppConstants.primaryBlack,
        ),
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Account Settings
          _buildSettingsSection(
            title: 'Account',
            children: [
              _buildSettingsItem(
                icon: PhosphorIcons.user(),
                title: 'Edit Profile',
                onTap: () {
                  // Navigate to profile editor
                },
              ),
              _buildSettingsItem(
                icon: PhosphorIcons.lock(),
                title: 'Privacy & Security',
                onTap: () {
                  // Navigate to privacy settings
                },
              ),
              _buildSettingsItem(
                icon: PhosphorIcons.creditCard(),
                title: 'Payment Methods',
                onTap: () {
                  // Navigate to payment methods
                },
              ),
            ],
          ),
          
          // Preferences
          _buildSettingsSection(
            title: 'Preferences',
            children: [
              _buildSettingsItem(
                icon: PhosphorIcons.bell(),
                title: 'Notifications',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                  activeColor: AppConstants.primaryRed,
                ),
              ),
              _buildSettingsItem(
                icon: PhosphorIcons.paintBrush(),
                title: 'Theme',
                subtitle: _darkModeEnabled ? 'Dark' : 'Light',
                onTap: _showThemeSelector,
              ),
              _buildSettingsItem(
                icon: PhosphorIcons.eye(),
                title: 'Show Online Status',
                trailing: Switch(
                  value: _showOnlineStatus,
                  onChanged: (value) {
                    setState(() => _showOnlineStatus = value);
                  },
                  activeColor: AppConstants.primaryRed,
                ),
              ),
              _buildSettingsItem(
                icon: PhosphorIcons.calendar(),
                title: 'Show My Age',
                trailing: Switch(
                  value: _showAge,
                  onChanged: (value) {
                    setState(() => _showAge = value);
                  },
                  activeColor: AppConstants.primaryRed,
                ),
              ),
              _buildSettingsItem(
                icon: PhosphorIcons.mapPin(),
                title: 'Show Distance',
                trailing: Switch(
                  value: _showDistance,
                  onChanged: (value) {
                    setState(() => _showDistance = value);
                  },
                  activeColor: AppConstants.primaryRed,
                ),
              ),
            ],
          ),
          
          // Messages & Stories
          _buildSettingsSection(
            title: 'Messages & Stories',
            children: [
              _buildSettingsItem(
                icon: PhosphorIcons.chatCircle(),
                title: 'Disappearing Messages',
                trailing: Switch(
                  value: _disappearingMessagesEnabled,
                  onChanged: (value) {
                    setState(() => _disappearingMessagesEnabled = value);
                  },
                  activeColor: AppConstants.primaryRed,
                ),
              ),
              if (_disappearingMessagesEnabled)
                Padding(
                  padding: const EdgeInsets.only(left: 56, right: 16),
                  child: Column(
                    children: [
                      Slider(
                        value: _disappearingMessageDuration.toDouble(),
                        min: 1,
                        max: 168,
                        divisions: 167,
                        onChanged: (value) {
                          setState(() => _disappearingMessageDuration = value.toInt());
                        },
                        activeColor: AppConstants.primaryRed,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Duration: $_disappearingMessageDuration hours',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Max 7 days',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: AppConstants.secondaryGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              _buildSettingsItem(
                icon: PhosphorIcons.image(),
                title: 'Stories',
                trailing: Switch(
                  value: _storyEnabled,
                  onChanged: (value) {
                    setState(() => _storyEnabled = value);
                  },
                  activeColor: AppConstants.primaryRed,
                ),
              ),
              if (_storyEnabled)
                Padding(
                  padding: const EdgeInsets.only(left: 56, right: 16),
                  child: Column(
                    children: [
                      Slider(
                        value: _storyDuration.toDouble(),
                        min: 1,
                        max: 48,
                        divisions: 47,
                        onChanged: (value) {
                          setState(() => _storyDuration = value.toInt());
                        },
                        activeColor: AppConstants.primaryRed,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Duration: $_storyDuration hours',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Max 2 days',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: AppConstants.secondaryGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          // Privacy
          _buildSettingsSection(
            title: 'Privacy',
            children: [
              _buildSettingsItem(
                icon: PhosphorIcons.users(),
                title: 'Blocked Users',
                subtitle: '${_blockedUsers.length} users blocked',
                onTap: _showBlockedUsers,
              ),
              _buildSettingsItem(
                icon: PhosphorIcons.eyeSlash(),
                title: 'Restricted Users',
                onTap: () {
                  // Show restricted users
                },
              ),
              _buildSettingsItem(
                icon: PhosphorIcons.shield(),
                title: 'Data & Privacy',
                onTap: () {
                  // Show data privacy
                },
              ),
            ],
          ),
          
          // Support
          _buildSettingsSection(
            title: 'Support',
            children: [
              _buildSettingsItem(
                icon: PhosphorIcons.question(),
                title: 'Help Center',
                onTap: () {
                  // Open help center
                },
              ),
              _buildSettingsItem(
                icon: PhosphorIcons.chatCircleText(),
                title: 'Contact Us',
                onTap: () {
                  // Contact support
                },
              ),
              _buildSettingsItem(
                icon: PhosphorIcons.info(),
                title: 'About KanairoXO',
                onTap: () {
                  // Show about
                },
              ),
              _buildSettingsItem(
                icon: PhosphorIcons.fileText(),
                title: 'Terms & Conditions',
                onTap: () {
                  // Show terms
                },
              ),
            ],
          ),
          
          // Danger Zone
          _buildSettingsSection(
            title: 'Account Actions',
            children: [
              _buildSettingsItem(
                icon: PhosphorIcons.export(),
                title: 'Log Out',
                color: Colors.red,
                onTap: _logout,
              ),
              _buildSettingsItem(
                icon: PhosphorIcons.trash(),
                title: 'Delete Account',
                color: Colors.red,
                onTap: _deleteAccount,
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Version 1.0.0 • © 2024 KanairoXO',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConstants.secondaryGray,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppConstants.secondaryGray,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppConstants.lightGray),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? AppConstants.secondaryGray,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConstants.secondaryGray,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(
                PhosphorIcons.caretRight(),
                size: 16,
                color: AppConstants.secondaryGray,
              ),
          ],
        ),
      ),
    );
  }
}