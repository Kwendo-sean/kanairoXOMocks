import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/date_plan_provider.dart';
import '../../models/date_plan_model.dart';
import '../../widgets/liquid_glass_button.dart';

class DatePlannerScreen extends StatefulWidget {
  const DatePlannerScreen({super.key});

  @override
  State<DatePlannerScreen> createState() => _DatePlannerScreenState();
}

class _DatePlannerScreenState extends State<DatePlannerScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DatePlanProvider>();
      provider.reset();
      provider.fetchConnections();
      provider.fetchConfig();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<DatePlanProvider>(
      builder: (context, provider, child) {
        return WillPopScope(
          onWillPop: () async {
            if (provider.currentStep > 0) {
              _prevPage();
              return false;
            }
            return true;
          },
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              centerTitle: true,
              leadingWidth: 100,
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (provider.currentStep > 0)
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                      onPressed: _prevPage,
                    ),
                ],
              ),
              title: Text(
                _getStepTitle(provider.currentStep),
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            body: Column(
              children: [
                _buildProgressBar(provider.currentStep, theme),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StepOneConnection(provider: provider, onNext: _nextPage),
                      _StepTwoDateTime(provider: provider, onNext: _nextPage),
                      _StepThreeVibe(provider: provider, onNext: _nextPage),
                      _StepFourDiscovery(provider: provider, onNext: _nextPage),
                      _StepFiveEvening(provider: provider, onNext: _nextPage),
                      _StepSixConfirmation(provider: provider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(int currentStep, ThemeData theme) {
    return Container(
      height: 3,
      width: double.infinity,
      color: theme.dividerColor.withOpacity(0.1),
      child: Row(
        children: List.generate(6, (index) {
          return Expanded(
            child: Container(
              color: index <= currentStep ? AppColors.themePrimary(context) : Colors.transparent,
            ),
          );
        }),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'The Connection';
      case 1: return 'Date & Time';
      case 2: return 'The Vibe';
      case 3: return 'Discovery';
      case 4: return 'The Evening';
      case 5: return 'Confirmation';
      default: return 'Plan a Date';
    }
  }

  void _nextPage() {
    context.read<DatePlanProvider>().nextStep();
    _pageController.animateToPage(
      context.read<DatePlanProvider>().currentStep,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _prevPage() {
    context.read<DatePlanProvider>().previousStep();
    _pageController.animateToPage(
      context.read<DatePlanProvider>().currentStep,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }
}

// ── SHARED SHIMMER HELPER ───────────────────────────────────────────────────

Widget _shimmerList(BuildContext context, {required double height, int count = 3, Axis scrollDirection = Axis.vertical}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Shimmer.fromColors(
    baseColor: isDark ? Colors.white10 : const Color(0xFFE8E0D0).withOpacity(0.5),
    highlightColor: isDark ? Colors.white24 : Colors.white.withOpacity(0.5),
    child: ListView.builder(
      shrinkWrap: true,
      scrollDirection: scrollDirection,
      itemCount: count,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12, right: 12),
        width: scrollDirection == Axis.horizontal ? 100 : double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(16)
        ),
      ),
    ),
  );
}

// ── STEP 1: THE CONNECTION ──────────────────────────────────────────────────

class _StepOneConnection extends StatelessWidget {
  final DatePlanProvider provider;
  final VoidCallback onNext;

  const _StepOneConnection({required this.provider, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('The Connection', style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                    Text('Who are you taking out?', style: GoogleFonts.cormorantGaramond(fontSize: 18, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withOpacity(0.7))),
                    const SizedBox(height: 32),
                    if (provider.isLoading && provider.connections.isEmpty)
                      SizedBox(height: 152, child: _shimmerList(context, height: 152, scrollDirection: Axis.horizontal))
                    else if (provider.connections.isEmpty)
                      Center(child: Text('No connections found', style: GoogleFonts.dmSans(color: theme.colorScheme.onSurface)))
                    else
                      SizedBox(
                        height: 152,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: provider.connections.length,
                          itemBuilder: (context, index) {
                            final person = provider.connections[index];
                            bool isSelected = provider.currentPlan.personId == person.id;
                            final photoUrl = person.photoUrl;
                            final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
                            
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                provider.updatePlan(
                                  personId: person.id,
                                  personName: person.name,
                                  personPhoto: person.photoUrl,
                                );
                              },
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isSelected ? AppColors.themePrimary(context) : theme.dividerColor, width: isSelected ? 2 : 1),
                                  boxShadow: isSelected ? [BoxShadow(color: AppColors.themePrimary(context).withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))] : [],
                                ),
                                child: Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                          child: hasPhoto
                                            ? CachedNetworkImage(
                                                imageUrl: photoUrl!,
                                                height: 100, width: double.infinity, fit: BoxFit.cover,
                                                errorWidget: (context, url, error) => _buildInitialsAvatar(context, person.name),
                                              )
                                            : _buildInitialsAvatar(context, person.name),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                person.name.split(' ').first,
                                                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: false,
                                              ),
                                              Text(
                                                person.neighborhood ?? 'Nairobi',
                                                style: GoogleFonts.dmSans(fontSize: 11, color: theme.hintColor),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        top: 6, right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.themePrimary(context), borderRadius: BorderRadius.circular(4)),
                                          child: Text("KXO", style: GoogleFonts.cormorantGaramond(color: Colors.white, fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Divider(color: theme.dividerColor),
                    ),

                    Text(
                      "How it works",
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.hintColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHowItWorksStep(context, "1", "Pick your person", "Choose who you want to take out"),
                    const SizedBox(height: 16),
                    _buildHowItWorksStep(context, "2", "Build the evening", "Pick a vibe, venue and package"),
                    const SizedBox(height: 16),
                    _buildHowItWorksStep(context, "3", "Send the request", "They accept, you pay the deposit"),

                    const Spacer(),
                    const SizedBox(height: 24),
                    LiquidGlassButton(
                      width: double.infinity,
                      onPressed: provider.currentPlan.personId != null ? onNext : null,
                      child: const Text('Continue', style: TextStyle(color: Colors.white, fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInitialsAvatar(BuildContext context, String name) {
    return Container(
      height: 100, width: double.infinity,
      color: Theme.of(context).dividerColor.withOpacity(0.1),
      child: Center(child: Text(name.isNotEmpty ? name[0] : '?', style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.themePrimary(context)))),
    );
  }

  Widget _buildHowItWorksStep(BuildContext context, String number, String title, String description) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColors.themePrimary(context).withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.themePrimary(context),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── STEP 2: DATE & TIME ──────────────────────────────────────────────────

class _StepTwoDateTime extends StatefulWidget {
  final DatePlanProvider provider;
  final VoidCallback onNext;

  const _StepTwoDateTime({required this.provider, required this.onNext});

  @override
  State<_StepTwoDateTime> createState() => _StepTwoDateTimeState();
}

class _StepTwoDateTimeState extends State<_StepTwoDateTime> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messageController.text = widget.provider.currentPlan.message ?? '';
  }

  Future<void> _selectDate() async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.provider.currentPlan.preferredDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.themePrimary(context),
              onPrimary: Colors.white,
              onSurface: theme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _selectTime(picked);
    }
  }

  Future<void> _selectTime(DateTime date) async {
    final theme = Theme.of(context);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.provider.currentPlan.preferredDate ?? DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.themePrimary(context),
              onPrimary: Colors.white,
              onSurface: theme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final fullDateTime = DateTime(date.year, date.month, date.day, picked.hour, picked.minute);
      widget.provider.updatePlan(preferredDate: fullDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.provider.currentPlan;
    final theme = Theme.of(context);
    final dateStr = plan.preferredDate != null 
        ? DateFormat('EEEE, MMM d @ h:mm a').format(plan.preferredDate!)
        : 'Select Date & Time';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date & Time', style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          Text('When are we doing this?', style: GoogleFonts.cormorantGaramond(fontSize: 18, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 32),
          
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: plan.preferredDate != null ? AppColors.themePrimary(context) : theme.dividerColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: plan.preferredDate != null ? AppColors.themePrimary(context) : theme.hintColor),
                  const SizedBox(width: 16),
                  Text(
                    dateStr,
                    style: GoogleFonts.dmSans(
                      fontSize: 16, 
                      fontWeight: plan.preferredDate != null ? FontWeight.w600 : FontWeight.w400,
                      color: plan.preferredDate != null ? theme.colorScheme.onSurface : theme.hintColor
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.hintColor.withOpacity(0.5)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          Text('Add a message (optional)', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 4,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'e.g. Can\'t wait to see you!',
              hintStyle: TextStyle(color: theme.hintColor),
              fillColor: theme.cardColor,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.themePrimary(context))),
            ),
            onChanged: (val) => widget.provider.updatePlan(message: val),
          ),

          const Spacer(),
          LiquidGlassButton(
            width: double.infinity,
            onPressed: plan.preferredDate != null ? widget.onNext : null,
            child: const Text('Continue', style: TextStyle(color: Colors.white, fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── STEP 3: THE VIBE ────────────────────────────────────────────────────────

class _StepThreeVibe extends StatelessWidget {
  final DatePlanProvider provider;
  final VoidCallback onNext;

  const _StepThreeVibe({required this.provider, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vibes = [
      {'name': 'Romantic', 'backend': 'romantic', 'sub': 'Intimate & special', 'icon': Icons.favorite_border_rounded},
      {'name': 'Cozy', 'backend': 'cozy', 'sub': 'Low-key & easy', 'icon': Icons.self_improvement_rounded},
      {'name': 'Fun', 'backend': 'fun', 'sub': 'Lively & playful', 'icon': Icons.celebration_outlined},
      {'name': 'Adventurous', 'backend': 'adventurous', 'sub': 'Bold & unexpected', 'icon': Icons.explore_outlined},
      {'name': 'Celebration', 'backend': 'celebration', 'sub': 'Special moments', 'icon': Icons.cake_outlined},
      {'name': 'Spontaneous', 'backend': 'spontaneous', 'sub': 'Go with the flow', 'icon': Icons.auto_awesome_outlined},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The Vibe', style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          Text('What kind of evening?', style: GoogleFonts.cormorantGaramond(fontSize: 18, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                crossAxisSpacing: 16, 
                mainAxisSpacing: 16, 
                childAspectRatio: 1.3
              ),
              itemCount: vibes.length,
              itemBuilder: (context, index) {
                final v = vibes[index];
                bool isSelected = provider.currentPlan.vibe == v['backend'];
                return GestureDetector(
                  onTap: () => provider.updatePlan(vibe: v['backend'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.themePrimary(context).withOpacity(0.04) : theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? AppColors.themePrimary(context) : theme.dividerColor, width: isSelected ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(v['icon'] as IconData, size: 28, color: isSelected ? AppColors.themePrimary(context) : theme.hintColor),
                        const SizedBox(height: 8),
                        Text(v['name'] as String, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? AppColors.themePrimary(context) : theme.colorScheme.onSurface)),
                        Text(v['sub'] as String, style: GoogleFonts.dmSans(fontSize: 11, color: theme.hintColor)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          LiquidGlassButton(
            width: double.infinity,
            onPressed: provider.currentPlan.vibe != null 
              ? () {
                  provider.fetchVenues(provider.currentPlan.vibe);
                  onNext();
                } 
              : null,
            child: const Text('Find Venues', style: TextStyle(color: Colors.white, fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── STEP 4: DISCOVERY ───────────────────────────────────────────────────────

class _StepFourDiscovery extends StatelessWidget {
  final DatePlanProvider provider;
  final VoidCallback onNext;

  const _StepFourDiscovery({required this.provider, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Discovery', style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              Text('Where are you headed?', style: GoogleFonts.cormorantGaramond(fontSize: 18, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withOpacity(0.7))),
              const SizedBox(height: 20),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.dividerColor)),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: theme.hintColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(style: GoogleFonts.dmSans(fontSize: 14, color: theme.colorScheme.onSurface), decoration: InputDecoration(hintText: 'Search for a spot...', hintStyle: TextStyle(color: theme.hintColor), border: InputBorder.none, isDense: true))),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading ? Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: _shimmerList(context, height: 240)) :
          ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: provider.venues.length,
            itemBuilder: (context, index) {
              final venue = provider.venues[index];
              bool isSelected = provider.currentPlan.selectedVenue?.id == venue.id;
              final imageUrl = venue.imageUrl;
              final hasImage = imageUrl != null && imageUrl.isNotEmpty;
              
              return GestureDetector(
                onTap: () => provider.updatePlan(venue: venue),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16), 
                    color: theme.cardColor,
                    border: isSelected ? Border.all(color: AppColors.themePrimary(context), width: 2) : null,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover,
                              errorWidget: (context, url, error) => _buildVenuePlaceholder(context),
                            )
                          : _buildVenuePlaceholder(context),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(venue.name, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                                  const SizedBox(height: 4),
                                  Row(children: [Icon(Icons.location_on_outlined, size: 13, color: theme.hintColor), const SizedBox(width: 4), Text(venue.neighborhood ?? 'Nairobi', style: GoogleFonts.dmSans(fontSize: 12, color: theme.hintColor))]),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.themePrimary(context).withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                                    child: Text(provider.currentPlan.vibe ?? 'Vibe', style: GoogleFonts.dmSans(color: AppColors.themePrimary(context), fontSize: 11, fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                            ),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.themePrimary(context).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(venue.priceRange, style: GoogleFonts.dmSans(color: AppColors.themePrimary(context), fontSize: 14, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: LiquidGlassButton(
            width: double.infinity,
            onPressed: provider.currentPlan.selectedVenue != null 
              ? () {
                  provider.fetchPackages(provider.currentPlan.selectedVenue!.id);
                  onNext();
                } 
              : null,
            child: const Text('Choose Venue', style: TextStyle(color: Colors.white, fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildVenuePlaceholder(BuildContext context) {
    return Container(
      height: 160, width: double.infinity,
      color: Theme.of(context).dividerColor.withOpacity(0.1),
      child: Icon(Icons.restaurant_outlined, color: AppColors.themePrimary(context), size: 40),
    );
  }
}

// ── STEP 5: THE EVENING ─────────────────────────────────────────────────────

class _StepFiveEvening extends StatelessWidget {
  final DatePlanProvider provider;
  final VoidCallback onNext;

  const _StepFiveEvening({required this.provider, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredPackages = provider.packages.where((p) => p.price <= provider.currentPlan.budget).toList();
    final kxoFee = (provider.currentPlan.selectedPackage?.price ?? 0) * (provider.config?.commissionRate ?? 0.1);
    final reservationFee = provider.config?.reservationFee ?? 500.0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The Evening', style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          Text('Build your experience', style: GoogleFonts.cormorantGaramond(fontSize: 18, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 24),
          Center(child: Text('KES ${provider.currentPlan.budget.toInt()}', style: GoogleFonts.cormorantGaramond(fontSize: 40, fontWeight: FontWeight.w600, color: AppColors.themePrimary(context)))),
          Slider(value: provider.currentPlan.budget, min: 1000, max: 20000, divisions: 38, activeColor: AppColors.themePrimary(context), inactiveColor: theme.dividerColor, onChanged: (val) => provider.updatePlan(budget: val)),
          const SizedBox(height: 24),
          Text('Choose a package', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          Expanded(
            child: provider.isLoading ? _shimmerList(context, height: 80) : (filteredPackages.isEmpty ? Center(child: Text('Adjust your budget to see available packages', style: GoogleFonts.dmSans(fontSize: 13, color: theme.hintColor))) :
            ListView.builder(
              itemCount: filteredPackages.length,
              itemBuilder: (context, index) {
                final p = filteredPackages[index];
                bool isSelected = provider.currentPlan.selectedPackage?.id == p.id;
                return GestureDetector(
                  onTap: () => provider.updatePlan(package: p),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: isSelected ? AppColors.themePrimary(context).withOpacity(0.04) : theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? AppColors.themePrimary(context) : theme.dividerColor, width: isSelected ? 2 : 1)),
                    child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)), Text(p.description, style: GoogleFonts.dmSans(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.7)), maxLines: 2)])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('KES ${p.price.toInt()}', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.themePrimary(context))), Text('per couple', style: GoogleFonts.dmSans(fontSize: 11, color: theme.hintColor))])]),
                  ),
                );
              },
            )),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
            child: Column(children: [_row(context, "Package", "KES ${provider.currentPlan.selectedPackage?.price.toInt() ?? 0}"), Divider(color: theme.dividerColor, height: 20), _row(context, "KXO Fee", "KES ${kxoFee.toInt()}"), Divider(color: theme.dividerColor, height: 20), _row(context, "Reservation Deposit", "KES ${reservationFee.toInt()}"), Divider(color: theme.colorScheme.onSurface.withOpacity(0.1), height: 20), _row(context, "Total Due Now", "KES ${reservationFee.toInt()}", bold: true)]),
          ),
          const SizedBox(height: 24),
          LiquidGlassButton(width: double.infinity, onPressed: provider.currentPlan.selectedPackage != null ? onNext : null, child: const Text('Review & Send Request', style: TextStyle(color: Colors.white, fontFamily: 'DMSans', fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String val, {bool bold = false}) {
    final theme = Theme.of(context);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.7))), Text(val, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.w400, color: theme.colorScheme.onSurface))]);
  }
}

// ── STEP 6: CONFIRMATION ────────────────────────────────────────────────────

class _StepSixConfirmation extends StatelessWidget {
  final DatePlanProvider provider;

  const _StepSixConfirmation({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = provider.currentPlan;
    final resFee = provider.config?.reservationFee ?? 500.0;
    final personPhoto = plan.personPhoto;
    final hasPersonPhoto = personPhoto != null && personPhoto.isNotEmpty;
    final venuePhoto = plan.selectedVenue?.imageUrl;
    final hasVenuePhoto = venuePhoto != null && venuePhoto.isNotEmpty;
    final dateStr = plan.preferredDate != null 
        ? DateFormat('EEEE, MMM d @ h:mm a').format(plan.preferredDate!)
        : 'Not Set';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Confirmation', style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          Text('Here\'s your plan', style: GoogleFonts.cormorantGaramond(fontSize: 18, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: theme.cardColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))]),
            child: Column(
              children: [
                Stack(children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), 
                    child: hasVenuePhoto
                      ? CachedNetworkImage(imageUrl: venuePhoto!, height: 140, width: double.infinity, fit: BoxFit.cover)
                      : Container(height: 140, width: double.infinity, color: theme.dividerColor.withOpacity(0.1)),
                  ),
                  Positioned.fill(child: Container(decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)])))),
                  Positioned(bottom: 12, left: 20, child: Text(plan.selectedVenue?.name ?? '', style: GoogleFonts.cormorantGaramond(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600))),
                ]),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 20, 
                        backgroundColor: theme.dividerColor.withOpacity(0.1),
                        backgroundImage: hasPersonPhoto ? NetworkImage(personPhoto!) : null,
                        child: !hasPersonPhoto 
                          ? Text(plan.personName != null && plan.personName!.isNotEmpty ? plan.personName![0] : '?', style: GoogleFonts.cormorantGaramond(fontSize: 18, color: AppColors.themePrimary(context)))
                          : null,
                      ), 
                      const SizedBox(width: 12), 
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Date with ${plan.personName}', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)), Text(plan.vibe ?? '', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.themePrimary(context)))])
                    ]),
                    const SizedBox(height: 16), Divider(color: theme.dividerColor), const SizedBox(height: 16),
                    _confirmRow(context, Icons.calendar_today_rounded, dateStr), const SizedBox(height: 10),
                    _confirmRow(context, Icons.restaurant_outlined, plan.selectedPackage?.name ?? ''), const SizedBox(height: 10),
                    _confirmRow(context, Icons.location_on_outlined, plan.selectedVenue?.neighborhood ?? ''), const SizedBox(height: 10),
                    _confirmRow(context, Icons.wallet_outlined, 'KES ${resFee.toInt()} deposit if accepted'),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Your date request will be sent to ${plan.personName}.', style: GoogleFonts.dmSans(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.7))),
          Text('A reservation deposit of KES ${resFee.toInt()} is charged only if they accept.', textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 12, color: theme.hintColor)),
          const Spacer(),
          LiquidGlassButton(
            width: double.infinity,
            onPressed: () async {
              final success = await provider.sendDateRequest();
              if (success && context.mounted) _showSuccess(context, plan.personName!);
            },
            child: provider.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Send Date Request', style: TextStyle(color: Colors.white, fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(children: [Icon(icon, size: 18, color: theme.hintColor), const SizedBox(width: 12), Expanded(child: Text(text, style: GoogleFonts.dmSans(fontSize: 14, color: theme.colorScheme.onSurface)))]);
  }

  void _showSuccess(BuildContext context, String name) {
    final theme = Theme.of(context);
    showModalBottomSheet(context: context, isDismissible: false, backgroundColor: theme.cardColor, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_) => Container(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.favorite_rounded, color: AppColors.themePrimary(context), size: 48),
        const SizedBox(height: 16), Text('Request Sent', style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 8), Text('We\'ve notified $name. You\'ll hear back soon.', textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.7))),
        const SizedBox(height: 24), TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: Text('Back to Messages', style: TextStyle(color: AppColors.themePrimary(context), fontWeight: FontWeight.bold))),
      ]),
    ));
  }
}
