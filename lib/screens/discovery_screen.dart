import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/models/discovery_models.dart';
import 'package:kanairoxo/models/connection_context_model.dart';
import 'package:kanairoxo/services/discovery_service.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/widgets/profile_card.dart';
import 'package:kanairoxo/widgets/discovery/ad_card.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/screens/notification_screen.dart';
import 'package:kanairoxo/screens/singles/profile_preview_screen.dart';
import 'package:kanairoxo/screens/connections/my_connections_screen.dart';
import 'package:kanairoxo/widgets/skeletons.dart';
import 'package:kanairoxo/models/messaging/conversation_model.dart';
import 'package:kanairoxo/screens/messaging/chat_screen.dart';
import 'package:kanairoxo/providers/notification_provider.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:kanairoxo/screens/messages/date_planner_screen.dart';
import 'package:kanairoxo/utils/constants.dart';

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

  List<DiscoveryItem> _discoveries = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  bool _isProcessingAction = false;

  ConnectionContextModel? _contextCard;
  bool _contextLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Defer to after the first frame so we don't fire notifyListeners()
    // while another widget is mid-build (PageView builds these tabs lazily).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDiscovery();
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeDiscovery() async {
    if (!mounted) return;

    // GATE: Check profile completion
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    if (profileProvider.myProfile == null) {
      await profileProvider.refreshMyProfile();
    }
    
    final completion = profileProvider.myProfile?.completionPercentage ?? 0;
    if (completion < 70) {
      setState(() {
        _isLoading = false;
        _discoveries = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.get('api/v1/discovery/recommendations/');
      final batch = DiscoveryBatch.fromJson(response);
      
      if (!mounted) return;
      setState(() {
        _discoveries = batch.discoveries;
        _currentIndex = 0;
        _isLoading = false;
      });
      
      if (_discoveries.isNotEmpty && !_discoveries[0].isAd) {
        _loadContextCard(_discoveries[0].id!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load discoveries. Please try again.';
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

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (!_discoveries[index].isAd) {
      _loadContextCard(_discoveries[index].id!);
    } else {
      setState(() {
        _contextCard = null;
      });
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

  Future<void> _openChat() async {
    final item = _discoveries[_currentIndex];
    if (item.isAd) return;
    
    final userId = item.id;
    if (userId == null) return;
    
    try {
      final response = await _apiClient.post(
        'api/v1/messaging/start/',
        {'user_id': userId});
      
      if (!mounted) return;
      
      final conv = ConversationModel.fromJson(response['conversation']);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open chat')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = context.bgColor;
    final textColor = context.textColor;
    final primaryColor = context.primaryColor;
    final notificationProvider = context.watch<NotificationProvider>();
    final unreadCount = notificationProvider.unreadCount;
    final profileProvider = context.watch<ProfileProvider>();
    final completion = profileProvider.myProfile?.completionPercentage ?? 0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Discover', style: AppTypography.screenTitle.copyWith(color: textColor)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.group_outlined, color: textColor, size: 22),
            tooltip: 'My connections',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyConnectionsScreen())),
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: textColor, size: 22),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                    child: Center(
                      child: Text(unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: completion < 70 
        ? _buildGate(completion)
        : _error != null
              ? _buildError()
              : (_discoveries.isEmpty && !_isLoading)
                  ? _buildEmpty()
                  : _buildPageView(),
    );
  }

  Widget _buildGate(int completion) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.white24),
            const SizedBox(height: 24),
            Text('Complete your profile', style: AppTypography.displaySmall.copyWith(color: Colors.white)),
            const SizedBox(height: 12),
            Text('Your profile is $completion% complete. Reach 70% to start discovering people.', 
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white70)),
            const SizedBox(height: 32),
            LinearProgressIndicator(
              value: completion / 100,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(AppConstants.primaryRed),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 48),
            LiquidGlassButton(
              onPressed: () => Navigator.pushNamed(context, '/profile_editor'),
              child: const Text('Finish Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageView() {
    if (_isLoading && _discoveries.isEmpty) {
      return Skeleton.profileCard(context);
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: _discoveries.length,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final item = _discoveries[index];

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                if (!item.isAd && item.explanation != null)
                  _buildExplanation(item.explanation!),
                
                if (item.isAd)
                  AdCard(ad: item, onNext: _moveToNextProfile)
                else
                  ProfileCard(
                    profile: DiscoveryProfile.fromJson(item.profileDetails),
                    compatibilityScore: item.overallScore,
                    compatibilityText: item.compatibilityText,
                    explanation: item.explanation ?? '',
                    onNotNow: _moveToNextProfile,
                    onMessage: _openChat,
                    onTap: () {
                      final pid = item.id;
                      if (pid != null) {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ProfilePreviewScreen(userId: pid),
                        ));
                      }
                    },
                    onConnectionSuccess: () {
                      Future.delayed(const Duration(seconds: 1), _moveToNextProfile);
                    },
                  ),
                
                const SizedBox(height: 16),
                if (!item.isAd) _buildContextCard(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExplanation(String text) {
     return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF1C1612) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: context.isDark ? const Color(0xFF2E2820) : Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_outlined, size: 16, color: context.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: context.isDark ? const Color(0xFF7A6E66) : AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextCard() {
    if (_contextLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_contextCard == null) return const SizedBox.shrink();

    final c = _contextCard!;
    switch (c.type) {
      case ContextType.sharedEvent:
      case ContextType.nextEvent:
        return _ctxEventCard(c);
      case ContextType.moments:
        return _ctxMomentsCard(c);
      case ContextType.hotspots:
        return _ctxHotspotsCard(c);
      case ContextType.music:
      case ContextType.musicTeaser:
        return _ctxMusicCard(c);
      case ContextType.unknown:
        return const SizedBox.shrink();
    }
  }

  Widget _ctxShell({required IconData icon, required String label, required Widget body}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: context.primaryColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: context.primaryColor, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.6)),
          ]),
          const SizedBox(height: 10),
          body,
        ],
      ),
    );
  }

  Widget _ctxEventCard(ConnectionContextModel c) {
    final ev = SharedEventData.fromMap(c.data);
    final cover = ev.coverImageUrl ?? '';
    return _ctxShell(
      icon: Icons.event,
      label: c.type == ContextType.nextEvent ? 'YOU MAY BOTH BE GOING TO' : "YOU'RE BOTH GOING TO",
      body: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 64, height: 64,
              child: cover.isNotEmpty
                ? Image.network(cover, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: context.borderColor))
                : Container(color: context.borderColor,
                    child: Icon(Icons.event, color: context.mutedColor))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ev.title, style: TextStyle(color: context.textColor, fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(ev.date, style: TextStyle(color: context.mutedColor, fontSize: 11)),
              Text(ev.location, style: TextStyle(color: context.mutedColor, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
        ],
      ),
    );
  }

  Widget _ctxMomentsCard(ConnectionContextModel c) {
    final md = MomentsData.fromMap(c.data);
    if (md.photos.isEmpty) return const SizedBox.shrink();
    return _ctxShell(
      icon: Icons.photo_library_outlined,
      label: 'RECENT MOMENTS',
      body: SizedBox(
        height: 84,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: md.photos.length.clamp(0, 6),
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final p = md.photos[i];
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 84, height: 84,
                child: p.imageUrl.isNotEmpty
                  ? Image.network(p.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: context.borderColor))
                  : Container(color: context.borderColor)),
            );
          }),
      ),
    );
  }

  Widget _ctxHotspotsCard(ConnectionContextModel c) {
    final h = HotspotsData.fromMap(c.data);
    return _ctxShell(
      icon: Icons.place_outlined,
      label: h.sameNeighborhood ? "YOU'RE BOTH IN ${h.neighborhood.toUpperCase()}" : 'COMMON HOTSPOTS',
      body: Wrap(
        spacing: 8, runSpacing: 8,
        children: h.hotspots.take(8).map((spot) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: context.borderColor)),
          child: Text(spot, style: TextStyle(color: context.textColor, fontSize: 12)),
        )).toList()),
    );
  }

  Widget _ctxMusicCard(ConnectionContextModel c) {
    final track = c.data['track_name']?.toString() ?? '';
    final artist = c.data['artist']?.toString() ?? '';
    if (track.isEmpty) return const SizedBox.shrink();
    return _ctxShell(
      icon: Icons.music_note,
      label: 'BOTH LISTEN TO',
      body: Text('$track${artist.isNotEmpty ? " — $artist" : ""}',
        style: TextStyle(color: context.textColor, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error ?? 'An error occurred'),
          TextButton(onPressed: _initializeDiscovery, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return _ConnectionsFallbackList();
  }
}

class _ConnectionsFallbackList extends StatefulWidget {
  @override
  State<_ConnectionsFallbackList> createState() => _ConnectionsFallbackListState();
}

class _ConnectionsFallbackListState extends State<_ConnectionsFallbackList> {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _connections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    try {
      final response = await _api.get('api/v1/connections/');
      final List<dynamic> data = response is List ? response : (response['results'] ?? []);
      if (mounted) {
        setState(() {
          _connections = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _photoOf(Map<String, dynamic> c) {
    final other = c['other_user'] ?? c['user'] ?? {};
    return ApiConstants.fixMediaUrl(other['photo_url'] ?? other['profile_photo'] ?? other['avatar']);
  }

  String _nameOf(Map<String, dynamic> c) {
    final other = c['other_user'] ?? c['user'] ?? {};
    return other['display_name'] ?? other['name'] ?? other['full_name'] ?? 'User';
  }

  String? _idOf(Map<String, dynamic> c) {
    final other = c['other_user'] ?? c['user'] ?? {};
    return (other['id'] ?? other['public_id'])?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    const accent = Color(0xFF9B111E);

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: accent));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('NOTHING NEW · CHECK BACK SOON',
            style: TextStyle(
              fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w700,
              color: accent, letterSpacing: 1.8)),
          const SizedBox(height: 4),
          Container(width: 24, height: 2, color: accent),
          const SizedBox(height: 20),
          Text("That's all for today",
            style: TextStyle(
              fontFamily: 'DMSans', color: textColor, fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text("New people drop in tomorrow. In the meantime — your connections:",
            style: TextStyle(
              fontFamily: 'DMSans', color: textColor.withOpacity(0.55), fontSize: 13, height: 1.4)),
          const SizedBox(height: 20),
          Expanded(
            child: _connections.isEmpty
              ? Center(child: Text("You haven't connected with anyone yet.",
                  style: TextStyle(
                    fontFamily: 'DMSans', color: textColor.withOpacity(0.55), fontSize: 13)))
              : GridView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.78),
                  itemCount: _connections.length,
                  itemBuilder: (ctx, i) {
                    final c = _connections[i];
                    final name = _nameOf(c);
                    final photo = _photoOf(c);
                    final id = _idOf(c);
                    final placeholder = isDark ? const Color(0xFF1C1612) : Colors.white;
                    return GestureDetector(
                      onTap: () {
                        if (id != null) {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ProfilePreviewScreen(userId: id)));
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
                            blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(fit: StackFit.expand, children: [
                            if (photo != null && photo.isNotEmpty)
                              Image.network(photo, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: placeholder,
                                  child: Icon(Icons.person, color: textColor.withOpacity(0.3), size: 48)))
                            else
                              Container(color: placeholder,
                                child: Icon(Icons.person, color: textColor.withOpacity(0.3), size: 48)),
                            Positioned(left: 0, right: 0, bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)])),
                                child: Text(name,
                                  style: const TextStyle(
                                    fontFamily: 'DMSans', color: Colors.white,
                                    fontSize: 14, fontWeight: FontWeight.w600),
                                  maxLines: 1, overflow: TextOverflow.ellipsis))),
                          ]),
                        ),
                      ),
                    );
                  }),
          ),
        ],
      ),
    );
  }
}
