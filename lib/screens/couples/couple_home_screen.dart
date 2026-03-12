import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/models/data_models.dart';
import 'package:kanairoxo/screens/couples/chat_screen.dart';
import 'package:kanairoxo/screens/couples/couple_profile_screen.dart';
import 'package:kanairoxo/screens/couples/dates_screen.dart';
import 'package:kanairoxo/screens/couples/individual_profile_screen.dart';
import 'package:kanairoxo/screens/couples/memories_screen.dart';
import 'package:kanairoxo/screens/events/events_screen.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/services/couple_service.dart';
import 'package:kanairoxo/widgets/couple_bottom_nav_bar.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/widgets/glass_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CoupleHomeScreen extends StatefulWidget {
  const CoupleHomeScreen({super.key});

  @override
  State<CoupleHomeScreen> createState() => _CoupleHomeScreenState();
}

class _CoupleHomeScreenState extends State<CoupleHomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

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

  // FIXED: Corrected the order of screens to match the navbar (Dashboard, Calendar, Memories, Events, Profile)
  final List<Widget> _screens = [
    const _CoupleDashboardPage(),      // 0: Dashboard
    const DatesScreen(),                // 1: Calendar
    const MemoriesEnhancedScreen(),      // 2: Memories
    EventsScreen(                       // 3: Events
      onJoinExperience: (Experience experience) {},
      onExperienceSelected: (Experience experience) {},
    ),
    const CoupleProfileScreen(),        // 4: Profile
  ];

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: _screens,
      ),
      bottomNavigationBar: CoupleBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _CoupleDashboardPage extends StatefulWidget {
  const _CoupleDashboardPage();

  @override
  State<_CoupleDashboardPage> createState() => _CoupleDashboardPageState();
}

class _CoupleDashboardPageState extends State<_CoupleDashboardPage> {
  final CoupleService _coupleService = CoupleService();
  CouplesDashboard? _dashboard;
  Map<String, dynamic>? _pulse;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _dailyPrompt;
  List<dynamic>? _challenges;
  bool _isLoading = true;
  String? _error;

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
      if (authProvider.user == null) {
        throw Exception('User session not found. Please log in again.');
      }

      final dashboard = await _coupleService.getDashboard();
      final String coupleId = authProvider.user!.id;
      
      final results = await Future.wait([
        _coupleService.getPulse(coupleId),
        _coupleService.getStats(coupleId),
        _coupleService.getDailyPrompt(),
        _coupleService.getChallenges(coupleId),
      ]);

      if (mounted) {
        setState(() {
          _dashboard = dashboard;
          _pulse = results[0] as Map<String, dynamic>?;
          _stats = results[1] as Map<String, dynamic>?;
          _dailyPrompt = results[2] as Map<String, dynamic>?;
          _challenges = results[3] as List<dynamic>?;
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_dashboard!.couple.coupleName ?? 'Us', style: AppTypography.screenTitle),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 22, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPulseCard(),
              const SizedBox(height: 12),
              _buildStreakRow(),
              const SizedBox(height: 12),
              _buildDailyPrompt(),
              const SizedBox(height: 12),
              _buildQuickStatsGrid(),
              const SizedBox(height: 12),
              _buildMusicSync(),
              const SizedBox(height: 12),
              _buildChallengesSection(),
              const SizedBox(height: 12),
              _buildRecentMoments(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseCard() {
    if (_pulse == null) return const SizedBox.shrink();
    final bothSubmitted = _pulse!['current_user_submitted'] == true && _pulse!['partner_submitted'] == true;

    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Relationship Pulse', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
              const Icon(Icons.favorite, color: AppColors.primary, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          if (bothSubmitted)
            Text(_pulse!['combined_mood_label'] ?? '', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))
          else
            Text(_pulse!['current_user_submitted'] == true ? 'Waiting for partner...' : 'How are you feeling?', style: AppTypography.bodyMedium),
          if (_pulse!['current_user_submitted'] == false) ...[
            const SizedBox(height: 12),
            LiquidGlassButton(
              size: LiquidButtonSize.md,
              onPressed: () => _showCheckInSheet(),
              child: Text('Check In', style: AppTypography.buttonText),
            ),
          ],
        ],
      ),
    );
  }

  void _showCheckInSheet() {
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
              Text('How are you feeling?', style: AppTypography.displayMedium),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMoodOption(1, Icons.sentiment_very_dissatisfied),
                  _buildMoodOption(2, Icons.sentiment_dissatisfied),
                  _buildMoodOption(3, Icons.sentiment_neutral),
                  _buildMoodOption(4, Icons.sentiment_satisfied),
                  _buildMoodOption(5, Icons.sentiment_very_satisfied),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodOption(int value, IconData icon) {
    return GestureDetector(
      onTap: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await _coupleService.submitPulse(authProvider.user!.id, value);
        Navigator.pop(context);
        _loadDashboard();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, color: AppColors.primary, size: 28),
      ),
    );
  }

  Widget _buildStreakRow() {
    if (_stats == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: _StatMiniCard(
            icon: Icons.local_fire_department_outlined,
            iconColor: const Color(0xFFE85D26),
            value: '${_stats!['checkin_streak'] ?? 0} days',
            label: 'Check-in Streak',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatMiniCard(
            icon: Icons.celebration_outlined,
            iconColor: AppColors.primary,
            value: '${_stats!['days_to_anniversary'] ?? 0} days',
            label: 'To Anniversary',
          ),
        ),
      ],
    );
  }

  Widget _buildDailyPrompt() {
    if (_dailyPrompt == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: AppRadius.md,
        border: Border(
          left: const BorderSide(color: AppColors.primary, width: 4),
          top: BorderSide(color: Colors.white.withOpacity(0.5)),
          right: BorderSide(color: Colors.white.withOpacity(0.5)),
          bottom: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text("Today's Prompt", style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Text(_dailyPrompt!['prompt'] ?? '', style: AppTypography.bodyMedium.copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {},
            child: Row(children: [
              Text('Discuss with partner', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 12, color: AppColors.primary),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    if (_stats == null) return const SizedBox.shrink();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _QuickStatCard(icon: Icons.photo_library_outlined, value: '${_stats!['memory_count'] ?? 0}', label: 'Memories'),
        _QuickStatCard(icon: Icons.local_fire_department_outlined, value: '${_stats!['checkin_streak'] ?? 0} days', label: 'Streak', iconColor: const Color(0xFFE85D26)),
        _QuickStatCard(icon: Icons.calendar_today_outlined, value: '${_stats!['date_count'] ?? 0}', label: 'Dates'),
        _QuickStatCard(icon: Icons.star_outline, value: '${_stats!['appreciations_count'] ?? 0}', label: 'Appreciations'),
      ],
    );
  }

  Widget _buildMusicSync() {
    final sync = _dashboard!.musicSync;
    if (sync == null) return const SizedBox.shrink();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note_outlined, color: Color(0xFF1DB954), size: 16),
              const SizedBox(width: 6),
              Text('Music & Culture Sync', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Couple Anthem', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          Text(sync.coupleAnthem, style: AppTypography.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text('Shared Artists', style: AppTypography.caption),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sync.sharedArtists.map((a) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: AppRadius.full, border: Border.all(color: Colors.grey.shade200)),
              child: Text(a, style: AppTypography.caption),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesSection() {
    if (_challenges == null || _challenges!.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            Text('Couple Challenges', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(onPressed: () {}, child: Text('See All', style: AppTypography.caption.copyWith(color: AppColors.primary))),
          ],
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: _challenges!.length,
            itemBuilder: (context, index) => _ChallengeCard(challenge: _challenges![index]),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMoments() {
    return Column(
      children: [
        Row(
          children: [
            Text('Recent Moments', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(onPressed: () {}, child: Text('See All', style: AppTypography.caption.copyWith(color: AppColors.primary))),
          ],
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (ctx, i) => Container(
              width: 80, height: 80,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(borderRadius: AppRadius.md, border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5)),
              child: const ClipRRect(borderRadius: AppRadius.md, child: Icon(Icons.image, color: Colors.grey)),
            ),
            itemCount: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.primary, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load dashboard', style: AppTypography.bodyLarge),
            const SizedBox(height: 8),
            Text(_error ?? 'An unexpected error occurred', textAlign: TextAlign.center, style: AppTypography.caption),
            const SizedBox(height: 20),
            LiquidGlassButton(size: LiquidButtonSize.md, onPressed: _loadDashboard, child: Text('Retry', style: AppTypography.buttonText)),
          ],
        ),
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatMiniCard({required this.icon, required this.iconColor, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.primaryGlass, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.displayMedium.copyWith(fontSize: 16)),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  const _QuickStatCard({required this.icon, required this.value, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.displayMedium.copyWith(fontSize: 16)),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final dynamic challenge;
  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.star_outline, color: AppColors.primary, size: 18),
            const SizedBox(height: 8),
            Text(challenge['title'] ?? '', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(challenge['description'] ?? '', style: AppTypography.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Text('${challenge['days_left']} days left', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
