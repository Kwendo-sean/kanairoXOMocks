import 'package:flutter/material.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/services/couple_service.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/providers/auth_provider.dart';

class CoupleProfileScreen extends StatefulWidget {
  const CoupleProfileScreen({super.key});

  @override
  State<CoupleProfileScreen> createState() => _CoupleProfileScreenState();
}

class _CoupleProfileScreenState extends State<CoupleProfileScreen> {
  final CoupleService _coupleService = CoupleService();
  CouplesDashboard? _dashboard;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dashboard == null
              ? const Center(child: Text('Could not load profile.'))
              : _buildProfileContent(context, _dashboard!),
    );
  }

  Widget _buildProfileContent(BuildContext context, CouplesDashboard dashboard) {
    final theme = Theme.of(context);
    final auth = context.read<AuthProvider>();
    final daysTogether = dashboard.couple.anniversaryDate != null
        ? DateTime.now().difference(dashboard.couple.anniversaryDate!).inDays
        : 0;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppConstants.primaryBeige,
          elevation: 0,
          centerTitle: true,
          pinned: true,
          title: Text(
            'Our Space',
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildProfileHeader(theme, auth.user!, auth.partner!, daysTogether),
                const SizedBox(height: 24),
                _buildAffirmationCard(theme, 'Every day with you is my favorite day.'),
                const SizedBox(height: 24),
                _buildJourneySection(theme, dashboard.stats),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(ThemeData theme, User currentUser, User partner, int daysTogether) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 40, backgroundColor: AppConstants.primaryRed.withOpacity(0.2)),
            const SizedBox(width: 12),
            CircleAvatar(radius: 40, backgroundColor: AppConstants.primaryRed.withOpacity(0.2)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${currentUser.firstName} & ${partner.firstName}',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '$daysTogether Days Together',
          style: theme.textTheme.titleMedium?.copyWith(color: AppConstants.secondaryGray),
        ),
      ],
    );
  }

  Widget _buildAffirmationCard(ThemeData theme, String affirmation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstants.primaryRed.withOpacity(0.8), AppConstants.primaryRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          PhosphorIcon(PhosphorIcons.quotes(PhosphorIconsStyle.fill), color: Colors.white, size: 32),
          const SizedBox(height: 16),
          Text(
            affirmation,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneySection(ThemeData theme, DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Our Journey',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildJourneyStat(theme, 'Memories Created', stats.memoryCount.toString(), PhosphorIcons.camera(PhosphorIconsStyle.regular)),
            _buildJourneyStat(theme, 'Dates Planned', stats.dateCount.toString(), PhosphorIcons.calendarHeart(PhosphorIconsStyle.regular)),
          ],
        ),
      ],
    );
  }

  Widget _buildJourneyStat(ThemeData theme, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(icon, color: AppConstants.primaryRed, size: 24),
          const Spacer(),
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: AppConstants.secondaryGray)),
        ],
      ),
    );
  }
}
