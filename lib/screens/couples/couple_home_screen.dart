import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/models/data_models.dart';
import 'package:kanairoxo/models/memory_model.dart';
import 'package:kanairoxo/screens/couples/chat_screen.dart';
import 'package:kanairoxo/screens/couples/couple_profile_screen.dart';
import 'package:kanairoxo/screens/couples/dates_screen.dart';
import 'package:kanairoxo/screens/couples/memories_screen.dart';
import 'package:kanairoxo/screens/events/events_screen.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/services/couple_service.dart';
import 'package:kanairoxo/widgets/couple_bottom_nav_bar.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class CoupleHomeScreen extends StatefulWidget {
  const CoupleHomeScreen({super.key});

  @override
  State<CoupleHomeScreen> createState() => _CoupleHomeScreenState();
}

class _CoupleHomeScreenState extends State<CoupleHomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _CoupleDashboardPage(onNavigate: _onItemTapped), // 0: Home
      const DatesScreen(),                             // 1: Plans
      const MemoriesEnhancedScreen(),                  // 2: Memories
      EventsScreen(                                    // 3: Events
        onJoinExperience: (Experience experience) {},
        onExperienceSelected: (Experience experience) {},
      ),
      const CoupleProfileScreen(),                     // 4: Us
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If not on the first tab, go to the first tab instead of exiting
        if (_currentIndex != 0) {
          _onItemTapped(0);
          return;
        }

        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        exit(0);
      },
      child: Scaffold(
        backgroundColor: context.bgColor,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: screens,
        ),
        bottomNavigationBar: CoupleBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class _CoupleDashboardPage extends StatefulWidget {
  final Function(int) onNavigate;
  const _CoupleDashboardPage({required this.onNavigate});

  @override
  State<_CoupleDashboardPage> createState() => _CoupleDashboardPageState();
}

class _CoupleDashboardPageState extends State<_CoupleDashboardPage> {
  final CoupleService _coupleService = CoupleService();
  CouplesDashboard? _dashboard;
  Map<String, dynamic>? _pulse;
  Map<String, dynamic>? _spotifyPlaylist;
  Map<String, dynamic>? _partnerNowPlaying;
  List<Memory> _recentMemories = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedMood;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final coupleId = authProvider.coupleStatus?.coupleId;
      
      if (coupleId == null) {
        throw Exception('Couple session not found.');
      }

      final results = await Future.wait([
        _coupleService.getDashboard(),
        _coupleService.getPulse(coupleId),
        _coupleService.getSpotifyPlaylist(coupleId),
        _coupleService.getPartnerNowPlaying(coupleId),
        _coupleService.getMemories(limit: 4),
      ]);

      if (mounted) {
        setState(() {
          _dashboard = results[0] as CouplesDashboard;
          _pulse = results[1] as Map<String, dynamic>;
          _spotifyPlaylist = results[2] as Map<String, dynamic>;
          _partnerNowPlaying = results[3] as Map<String, dynamic>?;
          _recentMemories = results[4] as List<Memory>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return _buildErrorState();
    }
    if (_dashboard == null) {
      return const Center(child: Text('No data available'));
    }

    final iconColor = context.textColor;
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Home', style: AppTypography.screenTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: iconColor),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: iconColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeroSection(),
              _buildPulseCard(),
              const SizedBox(height: 16),
              _buildStreakCard(),
              const SizedBox(height: 16),
              _buildSpotifyCard(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 32),
              _buildRecentMemories(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userA = authProvider.coupleUsers?[0];
    final userB = authProvider.coupleUsers?[1];

    return Center(
      child: Column(
        children: [
          const SizedBox(height: 24),
          SizedBox(
            width: 120, height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  child: _buildAvatar(userA?.profile?.mainProfilePhoto, userA?.firstName ?? 'User'),
                ),
                Positioned(
                  right: 0,
                  child: _buildAvatar(userB?.profile?.mainProfilePhoto, userB?.firstName ?? 'User'),
                ),
                Positioned(
                  top: 20, left: 42,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.favorite, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _dashboard!.couple.coupleName ?? 'Us',
            style: AppTypography.displayLarge.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  _dashboard!.couple.anniversaryDate != null
                    ? 'Together for ${_dashboard!.stats.daysTogether} days'
                    : 'Set your anniversary',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, String name) {
    final hasValidUrl = url != null && url.isNotEmpty && (url.startsWith('http') || url.startsWith('https'));
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: hasValidUrl
          ? CachedNetworkImage(
              imageUrl: url,
              imageBuilder: (ctx, img) => CircleAvatar(radius: 32, backgroundImage: img),
              placeholder: (ctx, url) => CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.person_outline, color: AppColors.primary, size: 28),
              ),
              errorWidget: (ctx, url, err) => CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24)),
              ),
            )
          : CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24)),
            ),
    );
  }

  Widget _buildPulseCard() {
    final yourCheckin = _pulse?['your_checkin'];
    final partnerCheckin = _pulse?['partner_checkin'];
    final partnerName = _dashboard?.partner.name ?? 'Partner';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.lg,
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (yourCheckin == null) ...[
            Text('How are you feeling today?', style: AppTypography.labelMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: ["Happy", "Content", "Tired", "Stressed", "Romantic"].map((mood) {
                final isSelected = _selectedMood == mood;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      mood,
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            LiquidGlassButton(
              onPressed: _selectedMood == null ? null : () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await _coupleService.submitCheckIn(authProvider.coupleStatus!.coupleId, _selectedMood!);
                _loadDashboard();
              },
              child: Text('Check In', style: AppTypography.buttonText),
            ),
          ] else if (partnerCheckin == null) ...[
            const Icon(Icons.favorite, color: AppColors.primary, size: 20),
            const SizedBox(height: 8),
            Text('Waiting for $partnerName...', style: AppTypography.labelMedium),
            Text('You checked in as $yourCheckin', style: AppTypography.caption),
          ] else ...[
            const Icon(Icons.favorite, color: AppColors.primary, size: 20),
            const SizedBox(height: 8),
            Text(_pulse?['combined_label'] ?? 'Feeling connected', style: AppTypography.labelMedium),
            Text(_pulse?['suggestion'] ?? 'Keep the romance alive!', style: AppTypography.caption),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.md,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            '${_dashboard!.stats.checkinStreak}',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text('day streak', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSpotifyCard() {
    final playlist = _spotifyPlaylist;
    final hasPlaylist = playlist != null && playlist['id'] != null;
    final coverUrl = playlist != null ? playlist['cover_url'] as String? : null;
    final hasValidCover = coverUrl != null && coverUrl.isNotEmpty && (coverUrl.startsWith('http') || coverUrl.startsWith('https'));
    final partnerName = _dashboard?.partner.name ?? 'Partner';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.lg,
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPlaylist) ...[
            Row(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.md,
                  child: hasValidCover
                    ? CachedNetworkImage(
                        imageUrl: coverUrl,
                        width: 52, height: 52,
                        fit: BoxFit.cover,
                        errorWidget: (ctx, url, err) => Container(color: Colors.grey.shade100, child: const Icon(Icons.music_note)),
                      )
                    : Container(color: Colors.grey.shade100, width: 52, height: 52, child: const Icon(Icons.music_note)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(playlist['name'] ?? 'Our Playlist', style: AppTypography.labelMedium),
                      if (playlist['last_track'] != null)
                        Text(
                          '${playlist['last_track']['name']} · ${playlist['last_track']['artist']}',
                          style: AppTypography.caption,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Text('Create your playlist', style: AppTypography.labelMedium),
            const SizedBox(height: 12),
            LiquidGlassButton(
              size: LiquidButtonSize.sm,
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await _coupleService.createSpotifyPlaylist(authProvider.coupleStatus!.coupleId);
                _loadDashboard();
              },
              child: Text('Create Now', style: AppTypography.buttonText),
            ),
          ],
          const Divider(height: 32),
          Row(
            children: [
              const Icon(Icons.headphones, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                _partnerNowPlaying != null
                  ? '$partnerName is listening to ${_partnerNowPlaying!['track_name']}'
                  : 'Nothing playing right now',
                style: AppTypography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _QuickAction(
          icon: Icons.calendar_today_outlined,
          label: 'Plan Date',
          onTap: () => widget.onNavigate(1),
        ),
        const SizedBox(width: 12),
        _QuickAction(
          icon: Icons.add_photo_alternate_outlined,
          label: 'Add Memory',
          onTap: () => widget.onNavigate(2),
        ),
        const SizedBox(width: 12),
        _QuickAction(
          icon: Icons.favorite_border,
          label: 'Appreciate',
          onTap: () => _openAppreciationBottomSheet(),
        ),
      ],
    );
  }

  void _openAppreciationBottomSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Send Appreciation', style: AppTypography.screenTitle),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Say something kind...',
                  border: OutlineInputBorder(borderRadius: AppRadius.md),
                ),
              ),
              const SizedBox(height: 24),
              LiquidGlassButton(
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await _coupleService.sendAppreciation(authProvider.coupleStatus!.coupleId, controller.text);
                  Navigator.pop(ctx);
                },
                child: Text('Send', style: AppTypography.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentMemories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Recent Memories", style: AppTypography.labelMedium.copyWith(fontSize: 16)),
              TextButton(
                onPressed: () => widget.onNavigate(2),
                child: Text("See All", style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: _recentMemories.isEmpty
            ? _buildEmptyMemories()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _recentMemories.length,
                itemBuilder: (ctx, index) => _PolaroidCard(memory: _recentMemories[index], index: index),
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyMemories() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (ctx, index) => Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 28),
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Theme.of(ctx).dividerColor),
        ),
        child: Center(
          child: Text(
            index == 1 ? "Your story\nstarts here" : "",
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(fontSize: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.primary, size: 48),
          const SizedBox(height: 16),
          Text('Failed to load home', style: AppTypography.bodyLarge),
          const SizedBox(height: 8),
          Text(_error ?? 'Error', textAlign: TextAlign.center, style: AppTypography.caption),
          const SizedBox(height: 20),
          LiquidGlassButton(onPressed: _loadDashboard, child: Text('Retry', style: AppTypography.buttonText)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.themePrimary(context).withOpacity(0.08),
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.themePrimary(context).withOpacity(0.15)),
            ),
            child: Icon(icon, color: AppColors.themePrimary(context), size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PolaroidCard extends StatelessWidget {
  final Memory memory;
  final int index;
  const _PolaroidCard({required this.memory, required this.index});

  @override
  Widget build(BuildContext context) {
    final photoUrl = memory.photo;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty && (photoUrl.startsWith('http') || photoUrl.startsWith('https'));

    return Transform.rotate(
      angle: index.isOdd ? 0.03 : -0.02,
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 28),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: hasPhoto
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    width: 98, height: 98,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(color: Colors.grey.shade100),
                    errorWidget: (ctx, url, err) => Container(color: Colors.grey.shade100, child: const Icon(Icons.photo_outlined, size: 20)),
                  )
                : Container(color: Colors.grey.shade100, width: 98, height: 98, child: const Icon(Icons.photo_outlined, size: 20)),
            ),
            const SizedBox(height: 4),
            Text(
              memory.title,
              style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic),
              maxLines: 1, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
