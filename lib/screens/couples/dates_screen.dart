import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/models/date_model.dart';
import 'package:kanairoxo/services/date_service.dart';
import 'package:kanairoxo/screens/couples/plan_date_screen.dart';

class DatesScreen extends StatefulWidget {
  const DatesScreen({super.key});

  @override
  State<DatesScreen> createState() => _DatesScreenState();
}

class _DatesScreenState extends State<DatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateService _dateService = DateService();
  late Future<List<DateNight>> _upcomingDatesFuture;
  late Future<List<DateIdea>> _dateIdeasFuture;
  late Future<List<DateNight>> _pastDatesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    _upcomingDatesFuture = _dateService.getDates();
    _dateIdeasFuture = _dateService.getDateIdeas();
    _pastDatesFuture = _dateService.getDates(); // This should be filtered for past dates
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date Nights',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppConstants.primaryBlack,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PlanDateScreen()),
                      ).then((_) => _loadData());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: PhosphorIcon(
                      PhosphorIcons.plus(PhosphorIconsStyle.bold),
                      size: 18,
                    ),
                    label: const Text('Plan Date'),
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppConstants.primaryRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppConstants.secondaryGray,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Ideas'),
                  Tab(text: 'Past'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUpcomingDates(theme),
                  _buildDateIdeas(theme),
                  _buildPastDates(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingDates(ThemeData theme) {
    return FutureBuilder<List<DateNight>>(
      future: _upcomingDatesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No upcoming dates.'));
        } else {
          final upcomingDates = snapshot.data!.where((date) => date.date.isAfter(DateTime.now())).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: upcomingDates.length,
            itemBuilder: (context, index) {
              final date = upcomingDates[index];
              return _buildDateCard(
                theme,
                date.title,
                date.date.toString(),
                date.location ?? '',
                PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                AppConstants.primaryRed,
              );
            },
          );
        }
      },
    );
  }

  Widget _buildDateIdeas(ThemeData theme) {
    return FutureBuilder<List<DateIdea>>(
      future: _dateIdeasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No date ideas.'));
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final idea = snapshot.data![index];
              return _buildIdeaCard(
                theme,
                idea.title,
                idea.description ?? '',
                PhosphorIcons.lightbulb(PhosphorIconsStyle.regular),
                Colors.orange,
              );
            },
          );
        }
      },
    );
  }

  Widget _buildPastDates(ThemeData theme) {
    return FutureBuilder<List<DateNight>>(
      future: _pastDatesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No past dates.'));
        } else {
          final pastDates = snapshot.data!.where((date) => date.date.isBefore(DateTime.now())).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: pastDates.length,
            itemBuilder: (context, index) {
              final date = pastDates[index];
              return _buildPastDateCard(
                theme,
                date.title,
                date.date.toString(),
                '',
              );
            },
          );
        }
      },
    );
  }

  Widget _buildDateCard(
      ThemeData theme,
      String title,
      String dateTime,
      String location,
      PhosphorIconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: PhosphorIcon(icon, size: 28, color: color),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppConstants.secondaryGray,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIcons.mapPin(PhosphorIconsStyle.regular),
                      size: 14,
                      color: AppConstants.secondaryGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppConstants.secondaryGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PhosphorIcon(
            PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
            color: AppConstants.secondaryGray,
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaCard(
      ThemeData theme,
      String title,
      String subtitle,
      PhosphorIconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: PhosphorIcon(icon, size: 24, color: color),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppConstants.secondaryGray,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: PhosphorIcon(
              PhosphorIcons.plus(PhosphorIconsStyle.regular),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastDateCard(
      ThemeData theme,
      String title,
      String date,
      String rating,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppConstants.secondaryGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rating,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PhosphorIcon(
            PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
            color: AppConstants.secondaryGray,
          ),
        ],
      ),
    );
  }
}
