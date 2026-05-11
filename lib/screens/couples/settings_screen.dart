import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = context.isDark;
    final bg = context.bgColor;
    final surface = context.surfaceColor;
    final textColor = context.textColor;
    final primary = context.primaryColor;
    final divider = context.borderColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel('Appearance', textColor),
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: divider),
            ),
            child: Column(children: [
              _SettingsTile(
                icon: Icons.phone_android_outlined,
                title: 'Follow Device Theme',
                subtitle: themeProvider.followSystem
                    ? 'Matches your device setting'
                    : 'Using manual setting',
                primary: primary,
                textColor: textColor,
                trailing: Switch(
                  value: themeProvider.followSystem,
                  onChanged: (v) => themeProvider.setFollowSystem(v),
                  activeColor: primary,
                  activeTrackColor: primary.withOpacity(0.3),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                ),
                onTap: () => themeProvider.setFollowSystem(!themeProvider.followSystem),
              ),
              if (!themeProvider.followSystem) ...[
                Divider(height: 1, color: divider),
                _SettingsTile(
                  icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: isDark ? 'Dark theme is on' : 'Light theme is on',
                  primary: primary,
                  textColor: textColor,
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => themeProvider.toggleTheme(),
                    activeColor: primary,
                    activeTrackColor: primary.withOpacity(0.3),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300,
                  ),
                  onTap: () => themeProvider.toggleTheme(),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Profile', textColor),
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: divider),
            ),
            child: Column(children: [
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile Picture',
                primary: primary,
                textColor: textColor,
                trailing: Icon(Icons.chevron_right, size: 18, color: textColor.withOpacity(0.4)),
                onTap: () {},
              ),
              Divider(height: 1, color: divider),
              _SettingsTile(
                icon: Icons.calendar_today_outlined,
                title: 'Edit Anniversary Date',
                primary: primary,
                textColor: textColor,
                trailing: Icon(Icons.chevron_right, size: 18, color: textColor.withOpacity(0.4)),
                onTap: () {},
              ),
              Divider(height: 1, color: divider),
              _SettingsTile(
                icon: Icons.edit_outlined,
                title: 'Edit Couple Display Name',
                primary: primary,
                textColor: textColor,
                trailing: Icon(Icons.chevron_right, size: 18, color: textColor.withOpacity(0.4)),
                onTap: () {},
              ),
            ]),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Preferences', textColor),
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: divider),
            ),
            child: _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notification Preferences',
              primary: primary,
              textColor: textColor,
              trailing: Icon(Icons.chevron_right, size: 18, color: textColor.withOpacity(0.4)),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Account', textColor),
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: divider),
            ),
            child: ListTile(
              onTap: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.logout, size: 18, color: primary),
              ),
              title: Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor.withOpacity(0.5),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  final Color primary;
  final Color textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.trailing,
    required this.onTap,
    required this.primary,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                color: textColor.withOpacity(0.5),
              ),
            )
          : null,
      trailing: trailing,
    );
  }
}
