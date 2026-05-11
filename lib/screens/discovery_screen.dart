import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/models/discovery_models.dart';
import 'package:kanairoxo/models/connection_context_model.dart';
import 'package:kanairoxo/models/music/spotify_models.dart';
import 'package:kanairoxo/services/discovery_service.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/services/spotify_service.dart';
import 'package:kanairoxo/widgets/profile_card.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/widgets/music/music_compat_chip.dart';
import 'package:kanairoxo/screens/notification_screen.dart';
import 'package:kanairoxo/models/messaging/conversation_model.dart';
import 'package:kanairoxo/screens/messaging/chat_screen.dart';
import 'package:kanairoxo/screens/music/spotify_connect_screen.dart';
import 'package:kanairoxo/providers/notification_provider.dart';
import 'package:kanairoxo/screens/messages/date_planner_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  final DiscoveryService _discoveryService = DiscoveryService();
  final ApiClient _apiClient = ApiClient();
  final PageController _pageController = PageController();

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  DiscoverySession? _currentSession;
  List<DiscoveryItem> _discoveries = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  bool _isProcessingAction = false;

  ConnectionContextModel? _contextCard;
  bool _contextLoading = false;
  
  final Map<String, MusicCompatibility> _musicCompat = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.5, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _initializeDiscovery();
    
    // Initial fetch for notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeDiscovery() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_currentSession == null) {
        try {
          final session = await _discoveryService.startDiscoverySession();
          if (!mounted) return;
          setState(() {
            _currentSession = session;
          });
        } catch (e) {
          try {
            final sessions = await _discoveryService.getMySessions();
            final activeSessions = sessions.where((s) => s.isActive).toList();
            if (activeSessions.isNotEmpty) {
              if (!mounted) return;
              setState(() {
                _currentSession = activeSessions.first;
              });
            } else {
              throw Exception('Could not start or find a discovery session.');
            }
          } catch (e2) {
            rethrow;
          }
        }
      }

      if (_currentSession != null) {
        try {
          final batch = await _discoveryService.getDiscoveryBatch(
            _currentSession!.sessionId,
            batchSize: 10,
          );
          if (!mounted) return;
          setState(() {
            _discoveries = batch.discoveries;
            _currentIndex = 0;
            _isLoading = false;
          });
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
          if (_discoveries.isNotEmpty) {
            final profile = _getProfileAtIndex(0);
            if (profile != null) {
              _loadContextCard(profile.userId);
              _loadMusicCompat(profile.userId);
            }
          }
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _error = 'Failed to load discoveries. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadContextCard(String targetUserId) async {
    setState(() {
      _contextCard = null;
      _contextLoading = true;
    });
    final context = await _discoveryService.getConnectionContext(targetUserId);
    if (!mounted) return;
    setState(() {
      _contextCard = context;
      _contextLoading = false;
    });
  }

  Future<void> _loadMusicCompat(String userId) async {
    try {
      final compat = await SpotifyService().getCompatibility(userId);
      if (compat != null && mounted) {
        setState(() {
          _musicCompat[userId] = compat;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    final profile = _getProfileAtIndex(index);
    if (profile != null) {
      _loadContextCard(profile.userId);
      _loadMusicCompat(profile.userId);
    }
  }

  void _moveToNextProfile() {
    if (_isProcessingAction || !mounted) return;
    setState(() {
      _currentIndex++;
      if (_currentIndex >= _discoveries.length) {
        _initializeDiscovery();
      } else if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  DiscoveryProfile? _getProfileAtIndex(int index) {
    if (index >= _discoveries.length) return null;
    final item = _discoveries[index];
    if (item.isProfile && item.profileDetails.isNotEmpty) {
      try {
        return DiscoveryProfile.fromJson(item.profileDetails);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> _openChat() async {
    final profile = _getProfileAtIndex(_currentIndex);
    final userId = profile?.userId.toString();
    
    if (userId == null) return;
    
    try {
      final response = await _apiClient.post(
        'api/v1/messaging/start/',
        {'user_id': userId});
      
      if (!mounted) return;
      
      final conv = ConversationModel.fromJson(
        response['conversation']
          as Map<String, dynamic>);
      
      Navigator.push(context,
        MaterialPageRoute(
          builder: (_) =>
            ChatScreen(conversation: conv)));
    } catch (e) {
      debugPrint('Chat error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(
          content: const Text('Could not open chat'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = context.bgColor;
    final textColor = context.textColor;
    final primaryColor = context.primaryColor;
    final notificationProvider = context.watch<NotificationProvider>();
    final unreadCount = notificationProvider.unreadCount;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Discover', style: AppTypography.screenTitle.copyWith(color: textColor)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: textColor,
                  size: 22,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _error != null
              ? _buildError()
              : (_discoveries.isEmpty && !_isLoading)
                  ? _buildEmpty()
                  : _buildPageView(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.primaryColor),
            const SizedBox(height: 12),
            Text(_error ?? 'An error occurred', textAlign: TextAlign.center, style: AppTypography.bodyMedium.copyWith(color: context.textColor)),
            const SizedBox(height: 12),
            LiquidGlassButton(
              size: LiquidButtonSize.md,
              onPressed: _initializeDiscovery,
              child: Text('Try Again', style: AppTypography.buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined, 
              size: 64, 
              color: AppColors.themePrimary(context).withOpacity(0.3)
            ),
            const SizedBox(height: 24),
            Text(
              'no more todayyy', 
              style: AppTypography.displayMedium.copyWith(
                color: context.textColor, 
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "plan a date/ go for an event", 
              style: AppTypography.bodyMedium.copyWith(
                color: context.mutedColor,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            LiquidGlassButton(
              width: double.infinity,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DatePlannerScreen()),
                );
              },
              child: Text('Plan a Date', style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            LiquidGlassButton(
              width: double.infinity,
              variant: LiquidButtonVariant.outline,
              onPressed: () {
                // Explore Events action
              },
              child: Text('Explore Events', style: AppTypography.buttonText.copyWith(color: context.textColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If loading first batch, show a quiet empty state instead of a spinner
    if (_isLoading && _discoveries.isEmpty) {
      return const SizedBox.shrink();
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: _discoveries.length,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final profile = _getProfileAtIndex(index);
        if (profile == null) return const SizedBox.shrink();

        final discoveryItem = _discoveries[index];

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                if (discoveryItem.explanation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1612) : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E2820) : Colors.grey.shade200,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            size: 16,
                            color: isDark ? const Color(0xFFC0394B) : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              discoveryItem.explanation,
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF7A6E66) : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Stack(
                  children: [
                    SlideTransition(
                      position: _slideAnimation,
                      child: ProfileCard(
                        profile: profile,
                        compatibilityScore: discoveryItem.overallScore,
                        compatibilityText: discoveryItem.compatibilityText,
                        explanation: discoveryItem.explanation,
                        onNotNow: _moveToNextProfile,
                        onMessage: _openChat,
                        onConnectionSuccess: () {
                          Future.delayed(const Duration(seconds: 1), _moveToNextProfile);
                        },
                      ),
                    ),
                    if (_musicCompat[profile.userId] != null && _musicCompat[profile.userId]!.score > 0)
                      Positioned(
                        top: 12, left: 12,
                        child: MusicCompatChip(
                          score: _musicCompat[profile.userId]!.score))
                  ],
                ),
                const SizedBox(height: 16),
                _buildContextCard(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContextCard() {
    if (_contextLoading) {
      return const _ContextCardShimmer();
    }
    if (_contextCard == null) {
      return const SizedBox.shrink();
    }
    
    return switch (_contextCard!.type) {
      ContextType.sharedEvent => 
        _SharedEventCard(
          data: SharedEventData.fromMap(_contextCard!.data),
          onTap: () {} // navigateToEvent logic
        ),
      
      ContextType.music => 
        _MusicCompatibilityCard(
          targetUserName: _getProfileAtIndex(_currentIndex)?.firstName ?? ''),

      ContextType.moments =>
        _MomentsPreviewCard(
          data: MomentsData.fromMap(_contextCard!.data),
          userName: _getProfileAtIndex(_currentIndex)?.firstName ?? 'them',
          onPhotoTap: (index) {} // openMomentViewer logic
        ),
      
      ContextType.hotspots =>
        _HotspotsCard(
          data: HotspotsData.fromMap(_contextCard!.data)
        ),
      
      ContextType.nextEvent =>
        _NextEventCard(
          data: NextEventData.fromMap(_contextCard!.data),
          userName: _getProfileAtIndex(_currentIndex)?.firstName ?? 'them',
          onTap: () {} // navigateToEvent logic
        ),
      
      ContextType.musicTeaser =>
        _MusicTeaserCard(data: _contextCard!.data),
      
      _ => const SizedBox.shrink(),
    };
  }
}

class _ContextCardShimmer extends StatefulWidget {
  const _ContextCardShimmer();

  @override
  State<_ContextCardShimmer> createState() => _ContextCardShimmerState();
}

class _ContextCardShimmerState extends State<_ContextCardShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: context.isDark ? context.surfaceColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor.withOpacity(0.1)),
        ),
      ),
    );
  }
}

class _SharedEventCard extends StatelessWidget {
  final SharedEventData data;
  final VoidCallback onTap;
  
  const _SharedEventCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2))]),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16)),
            child: SafeNetworkImage(
              url: data.coverImageUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover)),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.celebration_outlined, size: 13, color: context.primaryColor),
                  const SizedBox(width: 4),
                  Text('You are both going to this',
                    style: AppTypography.caption.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 4),
                Text(data.title,
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: context.textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 11, color: context.mutedColor),
                  const SizedBox(width: 3),
                  Text(data.date, style: AppTypography.caption.copyWith(color: context.mutedColor)),
                  const SizedBox(width: 8),
                  if (data.location.isNotEmpty) ...[
                    Icon(Icons.location_on_outlined, size: 11, color: context.mutedColor),
                    const SizedBox(width: 3),
                    Expanded(child: Text(data.location,
                      style: AppTypography.caption.copyWith(color: context.mutedColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
                  ],
                ]),
              ]))),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.chevron_right, color: context.mutedColor, size: 18)),
        ])));
  }
}

class _MomentsPreviewCard extends StatelessWidget {
  final MomentsData data;
  final String userName;
  final Function(int) onPhotoTap;
  
  const _MomentsPreviewCard({required this.data, required this.userName, required this.onPhotoTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.photo_library_outlined, size: 14, color: context.primaryColor),
            const SizedBox(width: 6),
            Text('Recent moments from $userName',
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: context.textColor)),
            const Spacer(),
            Text('${data.totalMoments} total',
              style: AppTypography.caption.copyWith(color: context.mutedColor)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            ...data.photos.asMap().entries.map((e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: e.key < data.photos.length - 1 ? 6 : 0),
                child: GestureDetector(
                  onTap: () => onPhotoTap(e.key),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: SafeNetworkImage(url: e.value.imageUrl, fit: BoxFit.cover))))))),
            ...List.generate(3 - data.photos.length, (_) =>
              Expanded(child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.isDark ? context.borderColor : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10)),
                  ))))),
          ]),
        ]));
  }
}

class _HotspotsCard extends StatelessWidget {
  final HotspotsData data;
  const _HotspotsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.location_on_outlined, size: 14, color: context.primaryColor),
            const SizedBox(width: 6),
            Expanded(child: Text(
              data.sameNeighborhood
                ? 'You might cross paths in ${data.neighborhood}'
                : 'Spots between you both',
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: context.textColor))),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.hotspots.map((spot) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.themePrimaryGlass(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: context.primaryColor.withValues(alpha: 0.15))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_outlined, size: 12, color: context.primaryColor),
                    const SizedBox(width: 4),
                    Text(spot,
                      style: AppTypography.caption.copyWith(
                        color: context.primaryColor,
                        fontWeight: FontWeight.w500)),
                  ]))).toList()),
        ]));
  }
}

class _NextEventCard extends StatelessWidget {
  final NextEventData data;
  final String userName;
  final VoidCallback onTap;
  
  const _NextEventCard({required this.data, required this.userName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2))]),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16)),
            child: SafeNetworkImage(
              url: data.coverImageUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover)),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.event_outlined, size: 13, color: context.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    data.isHosting ? '$userName is hosting' : '$userName is going to',
                    style: AppTypography.caption.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 4),
                Text(data.title,
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: context.textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 11, color: context.mutedColor),
                  const SizedBox(width: 3),
                  Text(data.date, style: AppTypography.caption.copyWith(color: context.mutedColor)),
                  const SizedBox(width: 8),
                  Icon(Icons.people_outline, size: 11, color: context.mutedColor),
                  const SizedBox(width: 3),
                  Text('${data.attendeeCount} going', style: AppTypography.caption.copyWith(color: context.mutedColor)),
                ]),
              ]))),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.chevron_right, color: context.mutedColor, size: 18)),
        ])));
  }
}

class _MusicTeaserCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MusicTeaserCard({required this.data});
  
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.isDark ? context.surfaceColor.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.music_note_outlined, size: 16, color: context.primaryColor),
                const SizedBox(width: 6),
                Text(data['title'] ?? 'Music Compatibility',
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: context.textColor)),
              ]),
              const SizedBox(height: 6),
              Text(data['subtitle'] ?? '', style: AppTypography.caption.copyWith(color: context.mutedColor)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _MusicConnectButton(
                  icon: Icons.music_note,
                  label: 'Spotify',
                  color: const Color(0xFF1DB954),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpotifyConnectScreen())))),
                const SizedBox(width: 10),
                Expanded(child: _MusicConnectButton(
                  icon: Icons.music_note,
                  label: 'Apple Music',
                  color: const Color(0xFFFC3C44),
                  onTap: () => _showComingSoon(context, 'Apple Music'))),
              ]),
            ]))));
  }

  void _showComingSoon(BuildContext context, String service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$service integration coming soon', style: AppTypography.caption.copyWith(color: Colors.white)),
        backgroundColor: AppColors.themePrimary(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2)));
  }
}

class _MusicConnectButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  
  const _MusicConnectButton({required this.icon, required this.label, required this.color, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
          ])));
  }
}

class MusicPlaceholderData {
  static const String compatibilityLabel = 'Strong Music Match';
  static const int compatibilityScore = 78;
  static const List<String> sharedArtists = ['Sauti Sol', 'Bien', 'Khaligraph Jones'];
  static const List<String> sharedGenres = ['Afropop', 'RnB', 'Hip Hop'];
  static const String currentlyPlaying = 'Midnight Train — Sauti Sol';
}

class _MusicCompatibilityCard extends StatelessWidget {
  final String targetUserName;
  const _MusicCompatibilityCard({required this.targetUserName});
  
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.isDark ? context.surfaceColor.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.music_note_outlined, size: 15, color: Color(0xFF1DB954))),
                const SizedBox(width: 8),
                Text('Music Compatibility', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: context.textColor)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.themePrimaryGlass(context),
                    borderRadius: BorderRadius.circular(999)),
                  child: Text('${MusicPlaceholderData.compatibilityScore}% match',
                    style: AppTypography.caption.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: context.isDark ? context.borderColor.withValues(alpha: 0.3) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.borderColor)),
                child: Row(children: [
                  const Icon(Icons.graphic_eq_outlined, size: 14, color: Color(0xFF1DB954)),
                  const SizedBox(width: 6),
                  Text('Recently played: ', style: AppTypography.caption.copyWith(color: context.mutedColor)),
                  Expanded(child: Text(MusicPlaceholderData.currentlyPlaying,
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: context.textColor),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis)),
                ])),
              const SizedBox(height: 12),
              Text('Artists you both love', style: AppTypography.caption.copyWith(color: context.mutedColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: MusicPlaceholderData.sharedArtists.map((artist) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DB954).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.2))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.headphones_outlined, size: 11, color: Color(0xFF1DB954)),
                        const SizedBox(width: 4),
                        Text(artist, style: AppTypography.caption.copyWith(color: const Color(0xFF1DB954), fontWeight: FontWeight.w500)),
                      ]))).toList()),
              const SizedBox(height: 10),
              Text('Shared genres', style: AppTypography.caption.copyWith(color: context.mutedColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: MusicPlaceholderData.sharedGenres.map((genre) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: context.isDark ? context.borderColor : Colors.grey.shade100, borderRadius: BorderRadius.circular(999)),
                    child: Text(genre, style: AppTypography.caption.copyWith(color: context.textColor, fontWeight: FontWeight.w500))))
                  .toList()),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.2))),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 13, color: Colors.amber.shade700),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Connect your music to see real compatibility data',
                    style: AppTypography.caption.copyWith(color: Colors.amber.shade700, fontSize: 10))),
                ])),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpotifyConnectScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DB954).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.25))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.music_note, size: 13, color: Color(0xFF1DB954)),
                        const SizedBox(width: 5),
                        Text('Spotify', style: AppTypography.caption.copyWith(color: const Color(0xFF1DB954), fontWeight: FontWeight.w600)),
                      ])))),
                const SizedBox(width: 8),
                Expanded(child: GestureDetector(
                  onTap: () => _showComingSoon(context, 'Apple Music'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFC3C44).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFC3C44).withValues(alpha: 0.25))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.music_note, size: 13, color: Color(0xFFFC3C44)),
                        const SizedBox(width: 5),
                        Text('Apple Music', style: AppTypography.caption.copyWith(color: const Color(0xFFFC3C44), fontWeight: FontWeight.w600)),
                      ])))),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$service integration coming soon', style: AppTypography.caption.copyWith(color: Colors.white)),
        backgroundColor: AppColors.themePrimary(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2)));
  }
}
