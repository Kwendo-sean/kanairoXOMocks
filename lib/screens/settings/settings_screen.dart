import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bg = context.bgColor;
    final surface = context.surfaceColor;
    final textColor = context.textColor;
    final primary = context.primaryColor;
    final divider = context.borderColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor, size: 22),
          onPressed: () => Navigator.pop(context)),
        title: Text('Settings',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: textColor)),
        centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
            child: Text('Appearance',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.5),
                letterSpacing: 0.8))),
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: divider)),
            child: Column(children: [
              _SettingsTile(
                icon: Icons.phone_android_outlined,
                title: 'Follow Device Theme',
                subtitle: themeProvider.followSystem
                    ? 'Matches your device setting'
                    : 'Using manual setting',
                trailing: Switch(
                  value: themeProvider.followSystem,
                  onChanged: (v) => themeProvider.setFollowSystem(v),
                  activeColor: primary,
                  activeTrackColor: primary.withOpacity(0.3),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300),
                onTap: () => themeProvider.setFollowSystem(!themeProvider.followSystem)),
              if (!themeProvider.followSystem) ...[
                Divider(height: 1, color: divider),
                _SettingsTile(
                  icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: isDark ? 'Dark theme is on' : 'Light theme is on',
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => themeProvider.toggleTheme(),
                    activeColor: primary,
                    activeTrackColor: primary.withOpacity(0.3),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300),
                  onTap: () => themeProvider.toggleTheme()),
              ],
            ])),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: divider)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme Preview',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
                const SizedBox(height: 12),
                Row(children: [
                  _ColorDot(color: primary, label: 'Brand Red'),
                  const SizedBox(width: 12),
                  _ColorDot(
                    color: isDark ? const Color(0xFFF5EFE6) : const Color(0xFFFAF7F4),
                    label: isDark ? 'Cream Text' : 'Beige BG',
                    hasBorder: !isDark),
                  const SizedBox(width: 12),
                  _ColorDot(
                    color: isDark ? const Color(0xFF1C1612) : const Color(0xFFFFFFFF),
                    label: 'Surface',
                    hasBorder: true),
                ]),
              ])),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: divider)),
            child: Row(children: [
              Icon(Icons.settings_outlined, size: 18, color: textColor.withOpacity(0.3)),
              const SizedBox(width: 12),
              Text('More settings coming soon',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: textColor.withOpacity(0.4))),
            ])),
        ]));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = context.textColor;
    final primary = context.primaryColor;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: primary)),
      title: Text(title,
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor)),
      subtitle: Text(subtitle,
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          color: textColor.withOpacity(0.5))),
      trailing: trailing);
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool hasBorder;

  const _ColorDot({
    required this.color,
    required this.label,
    this.hasBorder = false});

  @override
  Widget build(BuildContext context) {
    final textColor = context.textColor;
    return Column(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: hasBorder ? Border.all(color: textColor.withOpacity(0.15), width: 1) : null)),
      const SizedBox(height: 4),
      Text(label,
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 9,
          color: textColor.withOpacity(0.5))),
    ]);
  }
}
