import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/models/date_model.dart';
import 'package:kanairoxo/services/date_service.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/widgets/glass_card.dart';
import 'package:kanairoxo/screens/couples/plan_date_screen.dart';
import 'package:kanairoxo/screens/couples/book_date_screen.dart';

class DatesScreen extends StatefulWidget {
  const DatesScreen({super.key});

  @override
  State<DatesScreen> createState() => _DatesScreenState();
}

class _DatesScreenState extends State<DatesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateService _dateService = DateService();
  List<DateNight> _upcomingDates = [];
  List<DateNight> _pastDates = [];
  List<DateIdea> _dateJar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final upcoming = await _dateService.getUpcomingDates();
      final past = await _dateService.getPastDates();
      final jar = await _dateService.getDateJar();
      setState(() {
        _upcomingDates = upcoming;
        _pastDates = past;
        _dateJar = jar;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Dates & Aspirations', style: AppTypography.screenTitle),
                  const Spacer(),
                  LiquidGlassButton(
                    size: LiquidButtonSize.sm,
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanDateScreen())).then((_) => _loadData());
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('Plan Date', style: AppTypography.buttonText.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
              indicatorColor: AppColors.primary,
              tabs: const [Tab(text: 'Dates'), Tab(text: 'Aspirations')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _isLoading ? const Center(child: CircularProgressIndicator()) : _buildDatesTab(),
                  const _AspirationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBookADate(),
        const SizedBox(height: 16),
        _buildDateJar(),
        const SizedBox(height: 24),
        Text('Upcoming Dates', style: AppTypography.displayMedium.copyWith(fontSize: 16)),
        const SizedBox(height: 12),
        ..._upcomingDates.map((date) => _DateCard(date: date)),
        const SizedBox(height: 24),
        Text('Past Dates', style: AppTypography.displayMedium.copyWith(fontSize: 16)),
        const SizedBox(height: 12),
        ..._pastDates.map((date) => _DateCard(date: date, isPast: true)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildBookADate() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Book a Curated Date', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Explore partnered restaurants and book a date.', style: AppTypography.bodyMedium),
          const SizedBox(height: 12),
          LiquidGlassButton(
            width: double.infinity,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BookDateScreen()));
            },
            child: Text('Explore Restaurants', style: AppTypography.buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildDateJar() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shuffle_outlined, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text('Date Jar', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          Text('Add ideas, spin when you cannot decide', style: AppTypography.caption),
          const SizedBox(height: 8),
          Text('\${_dateJar.length} ideas in your jar', style: AppTypography.caption),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LiquidGlassButton(
                  size: LiquidButtonSize.md,
                  onPressed: () => _spinJar(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shuffle, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('Spin Jar', style: AppTypography.buttonText),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 14, color: AppColors.primary),
                label: Text('Add Idea', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                onPressed: () => _showAddIdeaSheet(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _spinJar() async {
    try {
      final idea = await _dateService.spinDateJar();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Your next date:', style: AppTypography.caption),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(idea.title, style: AppTypography.displayMedium),
              if (idea.description != null) Text(idea.description!, style: AppTypography.bodyMedium),
            ],
          ),
          actions: [
            LiquidGlassButton(onPressed: () => Navigator.pop(context), child: Text('Let\'s Do It', style: AppTypography.buttonText)),
          ],
        ),
      );
    } catch (e) {}
  }

  void _showAddIdeaSheet() {
    final titleController = TextEditingController();
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
              Text('Add a Date Idea', style: AppTypography.displayMedium),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Idea title...'),
              ),
              const SizedBox(height: 24),
              LiquidGlassButton(
                width: double.infinity,
                onPressed: () async {
                  await _dateService.addDateIdea(titleController.text, 'romantic');
                  Navigator.pop(context);
                  _loadData();
                },
                child: Text('Add to Jar', style: AppTypography.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final DateNight date;
  final bool isPast;
  const _DateCard({required this.date, this.isPast = false});

  @override
  Widget build(BuildContext context) {
    final day = date.date.day.toString();
    final month = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][date.date.month - 1];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.md,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.primaryGlass, borderRadius: AppRadius.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(day, style: AppTypography.displayMedium.copyWith(color: AppColors.primary, fontSize: 16)),
                Text(month, style: AppTypography.caption.copyWith(color: AppColors.primary, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date.title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: isPast ? AppColors.textSecondary : AppColors.textPrimary)),
                if (date.location != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Text(date.location!, style: AppTypography.caption),
                    ],
                  ),
              ],
            ),
          ),
          if (isPast && date.rating == null)
            const Icon(Icons.star_border, size: 18, color: AppColors.textMuted)
          else if (isPast && date.rating != null)
            const Icon(Icons.star, size: 18, color: Color(0xFFFFB800)),
        ],
      ),
    );
  }
}

class _AspirationsTab extends StatelessWidget {
  const _AspirationsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBucketList(),
        const SizedBox(height: 24),
        _buildSharedGoals(),
      ],
    );
  }

  Widget _buildBucketList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Bucket List', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton.icon(icon: const Icon(Icons.add, size: 14), label: const Text('Add'), onPressed: () {}),
          ],
        ),
        // Placeholder for items from API
      ],
    );
  }

  Widget _buildSharedGoals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Shared Goals', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('Add Goal')),
          ],
        ),
        // Placeholder for GoalCard from API
      ],
    );
  }
}
