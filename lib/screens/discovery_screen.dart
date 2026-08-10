import 'dart:async';
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
import 'package:kanairoxo/screens/notification_screen.dart';
import 'package:kanairoxo/screens/singles/profile_preview_screen.dart';
import 'package:kanairoxo/screens/connections/my_connections_screen.dart';
import 'package:kanairoxo/widgets/skeletons.dart';
import 'package:kanairoxo/models/messaging/conversation_model.dart';
import 'package:kanairoxo/screens/messaging/chat_screen.dart';
import 'package:kanairoxo/providers/notification_provider.dart';
import 'package:kanairoxo/screens/messages/date_planner_screen.dart';
import 'package:kanairoxo/utils/constants.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final DiscoveryService _discoveryService = DiscoveryService();
  final ApiClient _apiClient = ApiClient();
  final PageController _pageController = PageController();

  List<DiscoveryItem> _discoveries = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  bool _isProcessingAction = false;

  // Re-checks for new profiles while the "all caught up" state is showing,
  // so the deck comes back on its own instead of needing an app restart.
  Timer? _emptyRetryTimer;
  bool _isRefreshingDeck = false;

  /// The server sent profiles we couldn't read. Distinct from an empty deck:
  /// showing the connections fallback here would blame an empty city for what
  /// is a parsing problem.
  bool _unreadablePayload = false;

  ConnectionContextModel? _contextCard;
  bool _contextLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer to after the first frame so we don't fire notifyListeners()
    // while another widget is mid-build (PageView builds these tabs lazily).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDiscovery();
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emptyRetryTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _quietRefetch();
  }

  Future<void> _initializeDiscovery() async {
    if (!mounted) return;

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
        _unreadablePayload = batch.unrecognisedPayload;
        _currentIndex = 0;
        _isLoading = false;
      });
      if (_pageController.hasClients) _pageController.jumpToPage(0);
      _manageEmptyRetryTimer();

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

  /// While the deck is empty, poll for new profiles every couple of minutes
  /// so the screen recovers by itself (new members, or the 24h pass
  /// cooldown expiring server-side).
  void _manageEmptyRetryTimer() {
    if (_discoveries.isEmpty) {
      _emptyRetryTimer ??= Timer.periodic(
        const Duration(minutes: 2),
        (_) => _quietRefetch(),
      );
    } else {
      _emptyRetryTimer?.cancel();
      _emptyRetryTimer = null;
    }
  }

  /// Refetch without flipping [_isLoading], so the empty state doesn't
  /// flash a skeleton. Swaps back to the deck only when profiles arrive.
  Future<void> _quietRefetch() async {
    if (!mounted || _isLoading || _discoveries.isNotEmpty) return;
    try {
      final response = await _apiClient.get('api/v1/discovery/recommendations/');
      final batch = DiscoveryBatch.fromJson(response);
      if (!mounted) return;
      // Keep the diagnosis current even when the retry also comes back
      // unreadable, so the screen doesn't drift back to "no one left".
      if (batch.discoveries.isEmpty) {
        if (batch.unrecognisedPayload != _unreadablePayload) {
          setState(() => _unreadablePayload = batch.unrecognisedPayload);
        }
        return;
      }
      setState(() {
        _discoveries = batch.discoveries;
        _unreadablePayload = false;
        _currentIndex = 0;
        _error = null;
      });
      if (_pageController.hasClients) _pageController.jumpToPage(0);
      _manageEmptyRetryTimer();
      if (!_discoveries[0].isAd) _loadContextCard(_discoveries[0].id!);
    } catch (_) {
      // Stay on the empty state; the timer retries.
    }
  }

  /// Fire-and-forget: tells the backend this profile was skipped so it
  /// sits out of the deck for 24 hours.
  void _recordPass(DiscoveryItem item) {
    final id = item.id;
    if (id == null || item.isAd) return;
    _apiClient
        .post('api/v1/discovery/action/', {'target_id': id, 'action': 'pass'})
        .catchError((_) => null);
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

    // Reaching the end used to call _initializeDiscovery(), which flips
    // _isLoading and blanks the deck — so you got a loading flash and, if
    // that one request came back empty, the "that's all for today" screen.
    //
    // Wrap to the start instead. At this scale seeing the same people again
    // beats a dead end, and the refetch happens quietly behind the deck so
    // anyone new slots in without the screen ever going blank.
    if (_currentIndex + 1 >= _discoveries.length) {
      setState(() => _currentIndex = 0);
      if (_pageController.hasClients) _pageController.jumpToPage(0);
      _refreshDeckInBackground();
      return;
    }

    setState(() => _currentIndex++);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Refetch without touching _isLoading or clearing what's on screen.
  /// Only swaps the deck when something actually comes back, so a failed or
  /// empty response leaves the user looping over the current set rather than
  /// staring at an empty screen.
  Future<void> _refreshDeckInBackground() async {
    if (_isRefreshingDeck) return;
    _isRefreshingDeck = true;
    try {
      final response = await _apiClient.get('api/v1/discovery/recommendations/');
      final batch = DiscoveryBatch.fromJson(response);
      if (!mounted || batch.discoveries.isEmpty) return;

      // Don't yank the card out from under a thumb mid-swipe.
      if (_currentIndex != 0) return;

      setState(() {
        _discoveries = batch.discoveries;
        _currentIndex = 0;
      });
      if (_pageController.hasClients) _pageController.jumpToPage(0);
      if (!_discoveries[0].isAd) _loadContextCard(_discoveries[0].id!);
    } catch (_) {
      // Keep looping over what we have.
    } finally {
      _isRefreshingDeck = false;
    }
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
      body: _error != null
          ? _buildError()
          : (_discoveries.isEmpty && !_isLoading)
              // An unreadable payload is a bug on our side, not an empty
              // city — don't quietly fall back to the connections list.
              ? (_unreadablePayload ? _buildUnreadable() : _buildEmpty())
              : _buildPageView(),
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
                    onNotNow: () {
                      _recordPass(item);
                      _moveToNextProfile();
                    },
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
      return const SizedBox.shrink();
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
    return _ConnectionsFallbackList(onCheckAgain: _initializeDiscovery);
  }

  /// Profiles came back but none could be read. Says so plainly rather than
  /// pretending there's no one to show.
  Widget _buildUnreadable() {
    final textColor = context.textColor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync_problem_rounded,
                size: 48, color: AppColors.primary.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text("We couldn't read today's profiles",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            const SizedBox(height: 6),
            Text(
                'There are people to show — the app just choked on the '
                'response. This is on us, not you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    height: 1.4,
                    color: textColor.withOpacity(0.55))),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _initializeDiscovery,
              child: const Text('Try again',
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionsFallbackList extends StatefulWidget {
  final Future<void> Function()? onCheckAgain;
  const _ConnectionsFallbackList({this.onCheckAgain});

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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
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
