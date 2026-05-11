import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/models/date_model.dart';
import 'package:kanairoxo/services/date_service.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

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
  List<BucketListItem> _bucketList = [];
  List<SharedGoal> _goals = [];
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final coupleId = authProvider.coupleStatus?.coupleId;
      if (coupleId == null) return;

      final results = await Future.wait([
        _dateService.getUpcomingDates(),
        _dateService.getPastDates(),
        _dateService.getDateJar(),
        _dateService.getBucketList(coupleId),
        _dateService.getGoals(coupleId),
      ]);

      setState(() {
        _upcomingDates = results[0] as List<DateNight>;
        _pastDates = results[1] as List<DateNight>;
        _dateJar = results[2] as List<DateIdea>;
        _bucketList = results[3] as List<BucketListItem>;
        _goals = results[4] as List<SharedGoal>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Plans', style: AppTypography.screenTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.themePrimary(context),
          labelColor: AppColors.themePrimary(context),
          unselectedLabelColor: context.mutedColor,
          tabs: const [
            Tab(text: 'Dates'),
            Tab(text: 'Dreams'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildDatesTab(),
              _buildDreamsTab(),
            ],
          ),
    );
  }

  Widget _buildDatesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildExploreOptionsCard(),
        const SizedBox(height: 24),
        _buildDateJarSection(),
        const SizedBox(height: 32),
        _buildSectionHeader('Upcoming Dates'),
        if (_upcomingDates.isEmpty)
          _buildEmptyState(Icons.calendar_today_outlined, "No upcoming dates yet", "Plan something together")
        else
          ..._upcomingDates.map((d) => _DateCard(date: d)),
        const SizedBox(height: 32),
        _buildSectionHeader('Past Dates'),
        if (_pastDates.isEmpty)
          _buildEmptyState(Icons.history, "No past dates yet", "Start making memories")
        else
          ..._pastDates.map((d) => _DateCard(date: d)),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildExploreOptionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.lg,
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Find something to do", style: AppTypography.labelMedium.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text("Browse ideas by vibe, budget, and location", style: AppTypography.caption),
          const SizedBox(height: 16),
          LiquidGlassButton(
            onPressed: () => _showExploreOptionsSheet(),
            child: Text("Explore Options", style: AppTypography.buttonText),
          ),
        ],
      ),
    );
  }

  void _showExploreOptionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ExploreOptionsSheet(),
    );
  }

  Widget _buildDateJarSection() {
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
              Icon(Icons.shuffle, color: AppColors.themePrimary(context), size: 20),
              const SizedBox(width: 8),
              Text('Date Jar', style: AppTypography.labelMedium.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${_dateJar.length.toString()} ideas in your jar', style: AppTypography.caption),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LiquidGlassButton(
                  size: LiquidButtonSize.md,
                  onPressed: () => _showExploreOptionsSheet(), // Spin uses filters too
                  child: Text('Spin Jar', style: AppTypography.buttonText),
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                label: Text('Add Idea', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                onPressed: () => _showAddIdeaSheet(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddIdeaSheet() {
    final titleController = TextEditingController();
    String selectedCategory = 'Romantic';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add Idea", style: AppTypography.screenTitle),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              Text("Category", style: AppTypography.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Romantic', 'Cozy', 'Adventurous', 'Spontaneous'].map((cat) {
                  final isSel = selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary : AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(cat, style: AppTypography.caption.copyWith(color: isSel ? Colors.white : AppColors.primary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              LiquidGlassButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  await _dateService.addDateIdea({'title': titleController.text, 'category': selectedCategory});
                  Navigator.pop(context);
                  _loadData();
                },
                child: Text("Add to List", style: AppTypography.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDreamsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('Bucket List', onAdd: () => _showAddBucketItemSheet()),
        if (_bucketList.isEmpty)
          _buildEmptyState(Icons.list_alt_outlined, "Your bucket list is empty", "Add things you want to do together")
        else
          ..._bucketList.map((item) => _BucketListItemCard(item: item, onRefresh: _loadData)),
        const SizedBox(height: 32),
        _buildSectionHeader('Shared Goals', onAdd: () => _showAddGoalSheet()),
        if (_goals.isEmpty)
          _buildEmptyState(Icons.flag_outlined, "No shared goals yet", "Set something to work toward together")
        else
          ..._goals.map((goal) => _GoalCard(goal: goal)),
        const SizedBox(height: 100),
      ],
    );
  }

  void _showAddBucketItemSheet() {
    final titleController = TextEditingController();
    String selectedCategory = 'Travel';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add to Bucket List", style: AppTypography.screenTitle),
              const SizedBox(height: 16),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 16),
              Text("Category", style: AppTypography.labelMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ['Travel', 'Experience', 'Food', 'Learning'].map((cat) {
                final isSel = selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setModalState(() => selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: isSel ? AppColors.primary : AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(999)),
                    child: Text(cat, style: AppTypography.caption.copyWith(color: isSel ? Colors.white : AppColors.primary)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 24),
              LiquidGlassButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  final cpId = Provider.of<AuthProvider>(context, listen: false).coupleStatus!.coupleId;
                  await _dateService.addBucketItem(cpId, {'title': titleController.text, 'category': selectedCategory});
                  Navigator.pop(context);
                  _loadData();
                },
                child: Text("Add to List", style: AppTypography.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGoalSheet() {
    // Simplified for now
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.labelMedium.copyWith(fontSize: 16)),
        if (onAdd != null)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text("Add", style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
      ],
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(title, style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted)),
          Text(sub, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _ExploreOptionsSheet extends StatefulWidget {
  const _ExploreOptionsSheet();
  @override
  State<_ExploreOptionsSheet> createState() => _ExploreOptionsSheetState();
}

class _ExploreOptionsSheetState extends State<_ExploreOptionsSheet> {
  double _budget = 5000;
  String _vibe = 'romantic';
  String _location = 'Westlands';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What are you in the mood for?", style: AppTypography.screenTitle),
          const SizedBox(height: 24),
          Text("Budget", style: AppTypography.labelMedium),
          Slider(
            value: _budget, min: 500, max: 10000,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _budget = v),
          ),
          Text("Up to KES ${_budget.toInt()}", style: AppTypography.caption),
          const SizedBox(height: 24),
          Text("Vibe", style: AppTypography.labelMedium),
          const SizedBox(height: 8),
          _buildChips([
            {'label': 'Romantic', 'val': 'romantic'},
            {'label': 'Cozy', 'val': 'cozy'},
            {'label': 'Adventurous', 'val': 'adventurous'},
            {'label': 'Fun', 'val': 'fun'},
            {'label': 'Celebration', 'val': 'celebration'},
            {'label': 'Spontaneous', 'val': 'spontaneous'},
          ], _vibe, (v) => setState(() => _vibe = v)),
          const SizedBox(height: 24),
          Text("Location", style: AppTypography.labelMedium),
          const SizedBox(height: 8),
          _buildChips([
            {'label': 'Westlands', 'val': 'Westlands'},
            {'label': 'CBD', 'val': 'CBD'},
            {'label': 'Karen', 'val': 'Karen'},
            {'label': 'Kilimani', 'val': 'Kilimani'},
            {'label': 'Langata', 'val': 'Langata'},
            {'label': 'Anywhere', 'val': 'Anywhere'},
          ], _location, (v) => setState(() => _location = v)),
          const SizedBox(height: 32),
          LiquidGlassButton(
            onPressed: () {
              // Navigate to results
              Navigator.pop(context);
            },
            child: Text("Find Ideas", style: AppTypography.buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildChips(List<Map<String, String>> options, String selected, Function(String) onSel) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: options.map((opt) {
        final isSel = opt['val'] == selected;
        return GestureDetector(
          onTap: () => onSel(opt['val']!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSel ? AppColors.primary : AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: isSel ? AppColors.primary : AppColors.primary.withOpacity(0.2)),
            ),
            child: Text(opt['label']!, style: AppTypography.caption.copyWith(color: isSel ? Colors.white : AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }
}

class _DateCard extends StatelessWidget {
  final DateNight date;
  const _DateCard({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.md,
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: AppRadius.sm),
            child: const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date.title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                Text('${date.location ?? "TBD"} · ${date.formattedDate ?? ""}', style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BucketListItemCard extends StatelessWidget {
  final BucketListItem item;
  final VoidCallback onRefresh;
  const _BucketListItemCard({required this.item, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Assuming logic to check if current user completed their half
    bool userHasCompleted = item.userACompleted; // Needs real mapping
    final photoUrl = item.completionPhoto;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.md,
        border: Border.all(color: item.completed ? AppColors.primary.withOpacity(0.3) : Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final cpId = authProvider.coupleStatus!.coupleId;
              await DateService().markBucketItemComplete(cpId, item.id);
              onRefresh();
            },
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: userHasCompleted ? AppColors.primary : Colors.transparent,
                border: Border.all(color: userHasCompleted ? AppColors.primary : Colors.grey.shade300, width: 2),
              ),
              child: userHasCompleted ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTypography.labelMedium.copyWith(
                  decoration: item.completed ? TextDecoration.lineThrough : null,
                  color: item.completed ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurface,
                )),
                Text(item.category, style: AppTypography.caption),
              ],
            ),
          ),
          if (hasPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: photoUrl!, 
                width: 40, height: 40, 
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(color: Colors.grey.shade100, child: const Icon(Icons.broken_image, size: 20)),
              ),
            ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SharedGoal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: AppRadius.md, border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconForGoalType(goal.type),
              const SizedBox(width: 12),
              Expanded(child: Text(goal.title, style: AppTypography.labelMedium)),
              if (goal.targetDate != null)
                Text(DateFormat('MMM yyyy').format(goal.targetDate!), style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: goal.progressPercent / 100,
            color: AppColors.primary,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${goal.progressPercent.toInt()}% complete", style: AppTypography.caption),
              Text("KES ${goal.currentAmount.toInt()} / ${goal.targetAmount.toInt()}", style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconForGoalType(String type) {
    IconData icon = switch (type) {
      'travel' => Icons.flight_outlined,
      'financial' => Icons.savings_outlined,
      'experience' => Icons.star_outline,
      'home' => Icons.home_outlined,
      _ => Icons.person_outline,
    };
    return Icon(icon, color: AppColors.primary, size: 20);
  }
}
