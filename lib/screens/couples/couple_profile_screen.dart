import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:kanairoxo/screens/couples/settings_screen.dart';
import 'package:kanairoxo/services/couple_service.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class CoupleProfileScreen extends StatefulWidget {
  const CoupleProfileScreen({super.key});

  @override
  State<CoupleProfileScreen> createState() => _CoupleProfileScreenState();
}

class _CoupleProfileScreenState extends State<CoupleProfileScreen> {
  final CoupleService _coupleService = CoupleService();
  CouplesDashboard? _dashboard;
  List<dynamic> _appreciations = [];
  Map<String, dynamic>? _spotifyPlaylist;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final coupleId = authProvider.coupleStatus?.coupleId;
      if (coupleId == null) return;

      final results = await Future.wait([
        _coupleService.getDashboard(),
        _coupleService.getAppreciations(coupleId, limit: 3),
        _coupleService.getSpotifyPlaylist(coupleId),
      ]);

      setState(() {
        _dashboard = results[0] as CouplesDashboard;
        _appreciations = results[1] as List<dynamic>;
        _spotifyPlaylist = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAppreciationWall(),
                  const SizedBox(height: 24),
                  _buildLoveLanguagesCard(),
                  const SizedBox(height: 24),
                  _buildSpotifyCard(),
                  const SizedBox(height: 24),
                  _buildMilestonesTimeline(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userA = authProvider.coupleUsers?[0];
    final userB = authProvider.coupleUsers?[1];

    return Container(
      height: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, Color(0xFFB22222)],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8, right: 16,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 130, height: 80,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          child: _buildHeaderAvatar(userA?.profile?.mainProfilePhoto),
                        ),
                        Positioned(
                          top: 26, left: 45,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 2),
                            ),
                            child: const Icon(Icons.favorite, color: AppColors.primary, size: 16),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: _buildHeaderAvatar(userB?.profile?.mainProfilePhoto),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _dashboard!.couple.coupleName ?? 'Us',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'CormorantGaramond',
                      fontSize: 22, fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dashboard!.couple.anniversaryDate != null
                      ? 'Together since ${DateFormat("MMMM d, yyyy").format(_dashboard!.couple.anniversaryDate!)}'
                      : 'Set your anniversary',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAvatar(String? url) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: CachedNetworkImage(
        imageUrl: url ?? '',
        imageBuilder: (ctx, img) => CircleAvatar(radius: 36, backgroundImage: img),
        placeholder: (ctx, url) => const CircleAvatar(radius: 36, backgroundColor: Colors.white24, child: Icon(Icons.person_outline, color: Colors.white70, size: 28)),
        errorWidget: (ctx, url, err) => const CircleAvatar(radius: 36, backgroundColor: Colors.white24, child: Icon(Icons.person_outline, color: Colors.white70, size: 28)),
      ),
    );
  }

  Widget _buildAppreciationWall() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_outline, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text("Appreciation Wall", style: AppTypography.labelMedium.copyWith(fontSize: 16)),
            const Spacer(),
            TextButton(
              onPressed: () => _showSendAppreciationSheet(),
              child: Text("Send", style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._appreciations.map((app) => _buildAppreciationNote(app)),
        if (_appreciations.isEmpty)
          Text("No appreciations yet. Send some love!", style: AppTypography.caption),
      ],
    );
  }

  Widget _buildAppreciationNote(dynamic app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF2A2218) : const Color(0xFFFFF9F0),
        borderRadius: AppRadius.sm,
        border: Border.all(color: context.isDark ? const Color(0xFF4A3E2A) : const Color(0xFFEDD9A3), width: 1),
      ),
      child: Row(
        children: [
          CachedNetworkImage(
            imageUrl: app['sender_photo'] ?? '',
            imageBuilder: (ctx, img) => CircleAvatar(radius: 14, backgroundImage: img),
            errorWidget: (ctx, url, err) => CircleAvatar(radius: 14, backgroundColor: AppColors.primary.withOpacity(0.1), child: const Icon(Icons.person_outline, size: 14, color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app['sender_name'] ?? 'Partner', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
                Text(app['message'] ?? '', style: AppTypography.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSendAppreciationSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Send Appreciation", style: AppTypography.screenTitle),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Say something kind...', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              LiquidGlassButton(
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  await _coupleService.sendAppreciation(auth.coupleStatus!.coupleId, controller.text);
                  Navigator.pop(ctx);
                  _loadData();
                },
                child: Text("Send", style: AppTypography.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoveLanguagesCard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userA = authProvider.coupleUsers?[0];
    final userB = authProvider.coupleUsers?[1];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.lg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildUserLoveLanguage(userA)),
              const Icon(Icons.compare_arrows_outlined, color: AppColors.textMuted, size: 20),
              Expanded(child: _buildUserLoveLanguage(userB)),
            ],
          ),
          if (userA?.profile?.specialMessage == null || userB?.profile?.specialMessage == null) ...[
            const SizedBox(height: 16),
            LiquidGlassButton(
              size: LiquidButtonSize.sm,
              onPressed: () {},
              child: Text("Take the Quiz", style: AppTypography.buttonText),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserLoveLanguage(User? user) {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl: user?.profile?.mainProfilePhoto ?? '',
          imageBuilder: (ctx, img) => CircleAvatar(radius: 20, backgroundImage: img),
          placeholder: (ctx, url) => const CircleAvatar(radius: 20, child: Icon(Icons.person, size: 20)),
        ),
        const SizedBox(height: 4),
        Text(user?.firstName ?? 'Partner', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Text(
            user?.profile?.specialMessage ?? 'Not set',
            style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSpotifyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.lg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.green),
              const SizedBox(width: 8),
              Text("Our Shared Sounds", style: AppTypography.labelMedium.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          if (_spotifyPlaylist != null) ...[
             Text(_spotifyPlaylist!['name'] ?? 'Our Playlist', style: AppTypography.labelMedium),
             const SizedBox(height: 12),
          ],
          LiquidGlassButton(
            size: LiquidButtonSize.sm,
            onPressed: () => _showDedicateSongSheet(),
            child: Text("Dedicate a Song", style: AppTypography.buttonText),
          ),
        ],
      ),
    );
  }

  void _showDedicateSongSheet() {
    final trackCtrl = TextEditingController();
    final artistCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Dedicate a Song", style: AppTypography.screenTitle),
              const SizedBox(height: 16),
              TextField(controller: trackCtrl, decoration: const InputDecoration(labelText: 'Track Name')),
              const SizedBox(height: 8),
              TextField(controller: artistCtrl, decoration: const InputDecoration(labelText: 'Artist')),
              const SizedBox(height: 8),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)')),
              const SizedBox(height: 24),
              LiquidGlassButton(
                onPressed: () async {
                  if (trackCtrl.text.isEmpty || artistCtrl.text.isEmpty) return;
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  await _coupleService.dedicateSong(auth.coupleStatus!.coupleId, trackCtrl.text, artistCtrl.text, noteCtrl.text);
                  Navigator.pop(ctx);
                },
                child: Text("Dedicate", style: AppTypography.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilestonesTimeline() {
    // Milestones logic...
    final milestones = [
      {'label': 'Matched', 'date': _dashboard!.couple.createdAt, 'icon': Icons.favorite},
      if (_dashboard!.couple.anniversaryDate != null)
        {'label': 'Anniversary', 'date': _dashboard!.couple.anniversaryDate!, 'icon': Icons.celebration},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Milestones", style: AppTypography.labelMedium.copyWith(fontSize: 16)),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: milestones.length,
            itemBuilder: (ctx, i) {
              final ms = milestones[i];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: AppRadius.md,
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(ms['icon'] as IconData, color: AppColors.primary, size: 14),
                        const SizedBox(width: 6),
                        Text(ms['label'] as String, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM d, yyyy').format(ms['date'] as DateTime), style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
