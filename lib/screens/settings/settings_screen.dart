import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/providers/theme_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/screens/settings/privacy_settings_screen.dart';
import 'package:kanairoxo/screens/settings/notification_settings_screen.dart';
import 'package:kanairoxo/screens/settings/blocked_accounts_screen.dart';
import 'package:kanairoxo/screens/settings/delete_account_screen.dart';
import 'package:kanairoxo/screens/profile/profile_editor_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final bg = context.bgColor;
    final surface = context.surfaceColor;
    final textColor = context.textColor;
    final muted = textColor.withOpacity(0.45);
    final primary = context.primaryColor;
    final divider = context.borderColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular),
            color: textColor, size: 22),
          onPressed: () => Navigator.pop(context)),
        title: Text('Settings',
          style: TextStyle(fontFamily: 'DMSans', fontSize: 17,
            fontWeight: FontWeight.w600, color: textColor)),
        centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [

          // ── Account ──────────────────────────────────────────────────────
          _SectionHeader(label: 'Account', textColor: muted),
          _Group(surface: surface, divider: divider, children: [
            _Tile(
              icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
              label: 'Edit Profile',
              primary: primary, textColor: textColor,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfileEditorScreen(
                  onClose: () => Navigator.pop(context))))),
            _Tile(
              icon: PhosphorIcons.shield(PhosphorIconsStyle.regular),
              label: 'Privacy',
              primary: primary, textColor: textColor,
              onTap: () => Navigator.pushNamed(context, '/settings/privacy')),
            _Tile(
              icon: PhosphorIcons.bell(PhosphorIconsStyle.regular),
              label: 'Notifications',
              primary: primary, textColor: textColor,
              onTap: () => Navigator.pushNamed(context, '/settings/notifications')),
          ]),

          // ── Moments ───────────────────────────────────────────────────────
          _SectionHeader(label: 'Moments', textColor: muted),
          _MomentsPrivacyTile(
            surface: surface, divider: divider,
            textColor: textColor, primary: primary, isDark: isDark),

          // ── Appearance ────────────────────────────────────────────────────
          _SectionHeader(label: 'Appearance', textColor: muted),
          _Group(surface: surface, divider: divider, children: [
            _SwitchTile(
              icon: PhosphorIcons.devices(PhosphorIconsStyle.regular),
              label: 'Follow Device Theme',
              value: themeProvider.followSystem,
              primary: primary, textColor: textColor,
              onChanged: (v) => themeProvider.setFollowSystem(v)),
            if (!themeProvider.followSystem)
              _SwitchTile(
                icon: isDark
                  ? PhosphorIcons.moon(PhosphorIconsStyle.regular)
                  : PhosphorIcons.sun(PhosphorIconsStyle.regular),
                label: 'Dark Mode',
                value: isDark,
                primary: primary, textColor: textColor,
                onChanged: (_) => themeProvider.toggleTheme()),
          ]),

          // ── Safety ────────────────────────────────────────────────────────
          _SectionHeader(label: 'Safety', textColor: muted),
          _Group(surface: surface, divider: divider, children: [
            _Tile(
              icon: PhosphorIcons.prohibit(PhosphorIconsStyle.regular),
              label: 'Blocked Accounts',
              primary: primary, textColor: textColor,
              onTap: () => Navigator.pushNamed(context, '/settings/blocked')),
          ]),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(label: 'About', textColor: muted),
          _Group(surface: surface, divider: divider, children: [
            _Tile(
              icon: PhosphorIcons.bookOpen(PhosphorIconsStyle.regular),
              label: 'Terms of Service',
              primary: primary, textColor: textColor,
              onTap: () {}),
            _Tile(
              icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.regular),
              label: 'Privacy Policy',
              primary: primary, textColor: textColor,
              onTap: () {}),
            _Tile(
              icon: PhosphorIcons.question(PhosphorIconsStyle.regular),
              label: 'Help & Support',
              primary: primary, textColor: textColor,
              onTap: () {}),
            _InfoTile(label: 'Version', value: '1.0.0',
              textColor: textColor, muted: muted),
          ]),

          const SizedBox(height: 12),

          // ── Danger zone ───────────────────────────────────────────────────
          _Group(surface: surface, divider: divider, children: [
            _Tile(
              icon: PhosphorIcons.signOut(PhosphorIconsStyle.regular),
              label: 'Sign Out',
              primary: const Color(0xFF9B111E),
              textColor: const Color(0xFF9B111E),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Sign out?',
                      style: TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel', style: TextStyle(fontFamily: 'DMSans'))),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out',
                          style: TextStyle(color: Color(0xFF9B111E), fontFamily: 'DMSans'))),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  context.read<AuthProvider>().logout();
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                }
              }),
            _Tile(
              icon: PhosphorIcons.trash(PhosphorIconsStyle.regular),
              label: 'Delete Account',
              primary: const Color(0xFF9B111E),
              textColor: const Color(0xFF9B111E),
              onTap: () => Navigator.pushNamed(context, '/settings/delete-account')),
          ]),
        ],
      ),
    );
  }
}

// ── Moments privacy tile ──────────────────────────────────────────────────────

class _MomentsPrivacyTile extends StatefulWidget {
  final Color surface, divider, textColor, primary;
  final bool isDark;
  const _MomentsPrivacyTile({
    required this.surface, required this.divider,
    required this.textColor, required this.primary, required this.isDark});

  @override
  State<_MomentsPrivacyTile> createState() => _MomentsPrivacyTileState();
}

class _MomentsPrivacyTileState extends State<_MomentsPrivacyTile> {
  bool _publicByDefault = true;
  bool _allowSaves = true;
  bool _allowShares = true;

  @override
  Widget build(BuildContext context) {
    return _Group(surface: widget.surface, divider: widget.divider, children: [
      _SwitchTile(
        icon: PhosphorIcons.globe(PhosphorIconsStyle.regular),
        label: 'Public moments by default',
        sublabel: _publicByDefault ? 'Everyone can see your moments' : 'Only connections see your moments',
        value: _publicByDefault,
        primary: widget.primary, textColor: widget.textColor,
        onChanged: (v) => setState(() => _publicByDefault = v)),
      _SwitchTile(
        icon: PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.regular),
        label: 'Allow saves',
        sublabel: 'Let others save your moments',
        value: _allowSaves,
        primary: widget.primary, textColor: widget.textColor,
        onChanged: (v) => setState(() => _allowSaves = v)),
      _SwitchTile(
        icon: PhosphorIcons.shareFat(PhosphorIconsStyle.regular),
        label: 'Allow shares',
        sublabel: 'Let others share your moments',
        value: _allowShares,
        primary: widget.primary, textColor: widget.textColor,
        onChanged: (v) => setState(() => _allowShares = v)),
    ]);
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color textColor;
  const _SectionHeader({required this.label, required this.textColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(label.toUpperCase(),
      style: TextStyle(fontFamily: 'DMSans', fontSize: 11,
        fontWeight: FontWeight.w700, color: textColor, letterSpacing: 0.9)));
}

class _Group extends StatelessWidget {
  final Color surface, divider;
  final List<Widget> children;
  const _Group({required this.surface, required this.divider, required this.children});

  @override
  Widget build(BuildContext context) {
    final List<Widget> separated = [];
    for (int i = 0; i < children.length; i++) {
      separated.add(children[i]);
      if (i < children.length - 1) {
        separated.add(Divider(height: 1, color: divider, indent: 56));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider)),
      child: Column(children: separated));
  }
}

class _Tile extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final Color primary, textColor;
  final VoidCallback onTap;

  const _Tile({
    required this.icon, required this.label,
    required this.primary, required this.textColor,
    required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    leading: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10)),
      child: Center(child: PhosphorIcon(icon, size: 17, color: primary))),
    title: Text(label,
      style: TextStyle(fontFamily: 'DMSans', fontSize: 14,
        fontWeight: FontWeight.w500, color: textColor)),
    trailing: PhosphorIcon(PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
      size: 15, color: textColor.withOpacity(0.3)));
}

class _SwitchTile extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final String? sublabel;
  final bool value;
  final Color primary, textColor;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon, required this.label,
    this.sublabel,
    required this.value, required this.primary, required this.textColor,
    required this.onChanged});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: () => onChanged(!value),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    leading: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10)),
      child: Center(child: PhosphorIcon(icon, size: 17, color: primary))),
    title: Text(label,
      style: TextStyle(fontFamily: 'DMSans', fontSize: 14,
        fontWeight: FontWeight.w500, color: textColor)),
    subtitle: sublabel != null
      ? Text(sublabel!,
          style: TextStyle(fontFamily: 'DMSans', fontSize: 11,
            color: textColor.withOpacity(0.45)))
      : null,
    trailing: Switch(
      value: value,
      onChanged: onChanged,
      activeColor: primary,
      activeTrackColor: primary.withOpacity(0.25),
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.grey.shade300,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap));
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  final Color textColor, muted;
  const _InfoTile({required this.label, required this.value,
    required this.textColor, required this.muted});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Text(label,
        style: TextStyle(fontFamily: 'DMSans', fontSize: 14,
          fontWeight: FontWeight.w500, color: textColor)),
      const Spacer(),
      Text(value,
        style: TextStyle(fontFamily: 'DMSans', fontSize: 13, color: muted)),
    ]));
}
