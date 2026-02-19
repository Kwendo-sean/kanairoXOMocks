import 'package:flutter/material.dart';
import 'package:kanairoxo/models/data_models.dart';
import 'package:kanairoxo/models/user_model.dart'; // Added this import
import 'package:kanairoxo/screens/couples/couple_profile_screen.dart';
import 'package:kanairoxo/screens/couples/dates_screen.dart';
import 'package:kanairoxo/screens/couples/memories_screen.dart';
import 'package:kanairoxo/screens/events/events_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/services/couple_service.dart';
import 'package:kanairoxo/widgets/couple_bottom_nav_bar.dart';

// This is now the main container for the couple's experience, with a nav bar.
class CoupleHomeScreen extends StatefulWidget {
  CoupleHomeScreen({super.key});

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

  // The pages for the couple's navigation
  final List<Widget> _screens = [
    const _CoupleDashboardPage(), // The original screen content
    const DatesScreen(),
    const MemoriesEnhancedScreen(),
    EventsScreen(
      onJoinExperience: (Experience experience) {},
      onExperienceSelected: (Experience experience) {},
    ),
    const CoupleProfileScreen(),
  ];

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: _screens,
      ),
      bottomNavigationBar: CoupleBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        // You can customize the long-press action if needed
        onSettingsLongPress: () => print('Settings long pressed on couple screen'),
      ),
    );
  }
}

// The original content of the screen is now its own private widget.
class _CoupleDashboardPage extends StatefulWidget {
  const _CoupleDashboardPage();

  @override
  State<_CoupleDashboardPage> createState() => _CoupleDashboardPageState();
}

class _CoupleDashboardPageState extends State<_CoupleDashboardPage> {
  final CoupleService _coupleService = CoupleService();
  CouplesDashboard? _dashboard;
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
      final dashboard = await _coupleService.getDashboard();
      if (dashboard == null) {
        throw Exception('Received no data from the server.');
      }
      if (mounted) {
        setState(() {
          _dashboard = dashboard;
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
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    // The Scaffold is removed from here and is now in the parent CoupleHomeScreen
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildDashboard(theme, auth),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(
            PhosphorIcons.warningCircle(PhosphorIconsStyle.regular),
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text('Failed to load dashboard'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDashboard,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(ThemeData theme, AuthProvider auth) {
    final dashboard = _dashboard!;
    final partner = auth.partner;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppConstants.primaryBeige,
            elevation: 0,
            pinned: true,
            title: Text(
              dashboard.couple.coupleName ?? 'Us',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppConstants.primaryBlack,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: PhosphorIcon(
                  PhosphorIcons.gear(PhosphorIconsStyle.regular),
                  color: AppConstants.primaryBlack,
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPartnerCard(theme, partner),
                const SizedBox(height: 24),
                _buildPulseCard(theme, dashboard.relationshipPulse),
                const SizedBox(height: 24),
                _buildStatsGrid(theme, dashboard.stats),
                const SizedBox(height: 24),
                _buildMusicSync(theme, dashboard.musicSync),
                const SizedBox(height: 24),
                Text('Quick Actions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppConstants.primaryBlack)),
                const SizedBox(height: 16),
                _buildQuickActions(theme),
                const SizedBox(height: 24),
                Text('Recent Moments', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppConstants.primaryBlack)),
                const SizedBox(height: 16),
                _buildRecentMoments(theme),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerCard(ThemeData theme, User? partner) {
     return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppConstants.primaryRed.withOpacity(0.1),
            child: Text(
              partner?.firstName?.substring(0, 1).toUpperCase() ?? 'P',
              style: theme.textTheme.headlineSmall?.copyWith(color: AppConstants.primaryRed, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(partner?.fullName ?? 'Partner', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppConstants.primaryBlack)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Connected', style: theme.textTheme.bodySmall?.copyWith(color: AppConstants.secondaryGray)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            style: IconButton.styleFrom(backgroundColor: AppConstants.primaryRed, foregroundColor: Colors.white),
            icon: PhosphorIcon(PhosphorIcons.chatCircle(PhosphorIconsStyle.fill), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseCard(ThemeData theme, int pulse) {
    final pulseColor = pulse >= 70 ? Colors.green : pulse >= 40 ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppConstants.primaryRed.withOpacity(0.1), AppConstants.primaryRed.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.primaryRed.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Relationship Pulse', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppConstants.primaryBlack)),
                  const SizedBox(height: 4),
                  Text('How you\'re doing together', style: theme.textTheme.bodySmall?.copyWith(color: AppConstants.secondaryGray)),
                ],
              ),
              PhosphorIcon(PhosphorIcons.heartbeat(PhosphorIconsStyle.fill), size: 32, color: AppConstants.primaryRed),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: CircularProgressIndicator(value: pulse / 100, strokeWidth: 12, backgroundColor: Colors.white.withOpacity(0.3), valueColor: AlwaysStoppedAnimation(pulseColor)),
              ),
              Column(
                children: [
                  Text('$pulse', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, color: AppConstants.primaryBlack)),
                  Text(pulse >= 70 ? 'Thriving' : pulse >= 40 ? 'Growing' : 'Needs Care', style: theme.textTheme.bodyMedium?.copyWith(color: pulseColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme, DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(theme, 'Memories', stats.memoryCount.toString(), PhosphorIcons.camera(PhosphorIconsStyle.regular), Colors.purple),
        _buildStatCard(theme, 'Check-in Streak', '${stats.checkinStreak} days', PhosphorIcons.fire(PhosphorIconsStyle.fill), Colors.orange),
        _buildStatCard(theme, 'Dates Planned', stats.dateCount.toString(), PhosphorIcons.calendarHeart(PhosphorIconsStyle.regular), AppConstants.primaryRed),
        _buildStatCard(theme, 'Aspirations', stats.aspirationCount.toString(), PhosphorIcons.star(PhosphorIconsStyle.fill), Colors.amber),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, String value, PhosphorIconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(icon, color: color, size: 24),
          const Spacer(),
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: AppConstants.secondaryGray)),
        ],
      ),
    );
  }

  Widget _buildMusicSync(ThemeData theme, MusicSync? musicSync) {
    if (musicSync == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PhosphorIcon(PhosphorIcons.spotifyLogo(PhosphorIconsStyle.fill), color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Music & Culture Sync',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppConstants.primaryBlack),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Connect your Spotify account to see your shared music taste!',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppConstants.secondaryGray),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Connect Spotify'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(PhosphorIcons.spotifyLogo(PhosphorIconsStyle.fill), color: Colors.green, size: 32),
              const SizedBox(width: 12),
              Text(
                'Music & Culture Sync',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppConstants.primaryBlack),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMusicInfo(theme, 'Couple Anthem', musicSync.coupleAnthem),
          const SizedBox(height: 16),
          _buildChipList(theme, 'Shared Artists', musicSync.sharedArtists),
          const SizedBox(height: 16),
          _buildChipList(theme, 'Overlapping Genres', musicSync.overlappingGenres),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMusicInfo(ThemeData theme, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppConstants.primaryRed),
        ),
      ],
    );
  }

  Widget _buildChipList(ThemeData theme, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((item) => Chip(
                    label: Text(item),
                    backgroundColor: AppConstants.primaryBeige,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return const Center(child: Text('Quick Actions Placeholder'));
  }

  Widget _buildRecentMoments(ThemeData theme) {
    return const Center(child: Text('Recent Moments Placeholder'));
  }
}
