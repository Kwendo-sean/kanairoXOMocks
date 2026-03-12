import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:kanairoxo/screens/couples/settings_screen.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/services/couple_service.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/widgets/glass_card.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';

class CoupleProfileScreen extends StatefulWidget {
  const CoupleProfileScreen({super.key});

  @override
  State<CoupleProfileScreen> createState() => _CoupleProfileScreenState();
}

class _CoupleProfileScreenState extends State<CoupleProfileScreen> {
  final CoupleService _coupleService = CoupleService();
  CouplesDashboard? _dashboard;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dashboard = await _coupleService.getDashboard();
      if (mounted) {
        setState(() {
          _dashboard = dashboard;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    if (_error != null) return _buildErrorScreen(_error!);
    if (_dashboard == null) return const Scaffold(body: Center(child: Text('Profile not found')));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            _buildSliverHeader(),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 32),
                  _buildNamesAndInfo(),
                  const SizedBox(height: 24),
                  _buildAppreciationWall(),
                  const SizedBox(height: 16),
                  _buildLoveLanguagesCard(),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    final auth = context.read<AuthProvider>();
    final partner = auth.partner;

    return SliverAppBar(
      automaticallyImplyLeading: false, // REMOVED BACK BUTTON
      expandedHeight: 160,
      backgroundColor: AppColors.primary,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: -30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAvatar(auth.user?.profile?.mainProfilePhoto),
                    Container(
                      width: 32, height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.favorite, color: Colors.white, size: 16),
                    ),
                    _buildAvatar(partner?.profile?.mainProfilePhoto),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAvatar(String? url) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: CircleAvatar(
        radius: 36,
        backgroundColor: Colors.grey[200],
        backgroundImage: url != null ? NetworkImage(url) : null,
        child: url == null ? const Icon(Icons.person, color: Colors.grey) : null,
      ),
    );
  }

  Widget _buildNamesAndInfo() {
    final auth = context.read<AuthProvider>();
    final partner = auth.partner;
    final anniversary = _dashboard?.couple.anniversaryDate;
    final sinceStr = anniversary != null ? '${anniversary.day}/${anniversary.month}/${anniversary.year}' : 'Set date';

    return Column(
      children: [
        Text(
          '${auth.user?.firstName ?? ''} & ${partner?.firstName ?? ''}',
          style: AppTypography.displayLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text('Together since $sinceStr', style: AppTypography.caption),
          ],
        ),
      ],
    );
  }

  Widget _buildAppreciationWall() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_outline, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text('Appreciation Wall', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () => _showSendAppreciationSheet(),
                child: Text('Send', style: AppTypography.caption.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Placeholder list
          _buildAppreciationItem('Trevor', 'You made my day yesterday with the surprise coffee!'),
          const Divider(height: 24),
          _buildAppreciationItem('Suki', 'Thank you for always listening to my long stories.'),
        ],
      ),
    );
  }

  Widget _buildAppreciationItem(String name, String message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 12, backgroundColor: AppColors.primaryGlass, child: Text(name[0], style: const TextStyle(fontSize: 10))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
              Text(message, style: AppTypography.caption, maxLines: 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoveLanguagesCard() {
    final auth = context.read<AuthProvider>();
    final partner = auth.partner;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Love Languages', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildPartnerLoveLang(auth.user?.firstName ?? 'Me', 'Physical Touch')),
              const SizedBox(width: 16),
              Expanded(child: _buildPartnerLoveLang(partner?.firstName ?? 'Partner', 'Quality Time')),
            ],
          ),
          const SizedBox(height: 16),
          LiquidGlassButton(
            size: LiquidButtonSize.sm,
            width: double.infinity,
            onPressed: () {},
            child: Text('Take the Quiz', style: AppTypography.buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerLoveLang(String name, String lang) {
    return Column(
      children: [
        Text(name, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.primaryGlass, borderRadius: AppRadius.full),
          child: Text(lang, style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  void _showSendAppreciationSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Send Appreciation', style: AppTypography.displayMedium),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Tell your partner something you appreciate...'),
              ),
              const SizedBox(height: 24),
              LiquidGlassButton(
                width: double.infinity,
                onPressed: () => Navigator.pop(context),
                child: Text('Send', style: AppTypography.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.primary, size: 48),
            const SizedBox(height: 16),
            Text(error, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            LiquidGlassButton(size: LiquidButtonSize.md, onPressed: _loadData, child: Text('Retry', style: AppTypography.buttonText)),
          ],
        ),
      ),
    );
  }
}
