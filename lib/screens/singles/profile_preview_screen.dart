import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/models/connection_models.dart';
import 'package:kanairoxo/models/messaging/conversation_model.dart';
import 'package:kanairoxo/models/music/spotify_models.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/services/spotify_service.dart';
import 'package:kanairoxo/screens/messaging/chat_screen.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/widgets/music/now_playing_bar.dart';
import 'package:kanairoxo/widgets/music/music_compat_chip.dart';
import 'package:kanairoxo/providers/connection_provider.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/utils/feature_flags.dart';

class ProfilePreviewScreen extends StatefulWidget {
  final String userId;
  final String? requestId;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool isConnected;

  const ProfilePreviewScreen({
    super.key,
    required this.userId,
    this.requestId,
    this.onAccept,
    this.onDecline,
    this.isConnected = false,
  });

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen> {
  final ApiClient apiClient = ApiClient();
  ProfilePreviewModel? _profile;
  bool _loading = true;
  bool _responding = false;
  
  // Logic exactly matching ProfileCard.dart
  String? _connectionStatus;
  bool _isInitiator = false;

  TrackModel? _nowPlaying;
  MusicCompatibility? _musicCompat;
  MusicProfile? _musicProfile;

  @override
  void initState() {
    super.initState();
    _connectionStatus = widget.isConnected ? 'mutual' : 'none';
    _loadProfile();
    _checkConnectionStatus();
    _loadMusicData();
  }

  // Same checkConnectionStatus logic as ProfileCard
  Future<void> _checkConnectionStatus() async {
    try {
      final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
      final result = await connectionProvider.checkConnectionStatus(widget.userId);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            if (data['exists'] == true) {
              _connectionStatus = data['connection_type'];
              _isInitiator = data['is_initiator'] ?? false;
            } else {
              _connectionStatus = 'none';
              _isInitiator = false;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Status check error: $e');
    }
  }

  Future<void> _loadProfile() async {
    if (mounted) setState(() => _loading = true);
    try {
      final response = await apiClient.get('api/v1/profiles/${widget.userId}/preview/');
      if (mounted) {
        setState(() {
          _profile = ProfilePreviewModel.fromJson(response);
          
          // CRITICAL: Sync local connection status from the profile load immediately
          // but only if we don't have a better status from the manual check yet
          if (_connectionStatus == 'none' || _connectionStatus == null) {
            if (_profile!.isConnected) {
              _connectionStatus = 'mutual';
            } else if (_profile!.hasPendingRequest) {
              _connectionStatus = 'pending';
              _isInitiator = _profile!.receivedRequestId == null;
            }
          }
          
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMusicData() async {
    if (!FeatureFlags.spotifyEnabled) return;
    final service = SpotifyService();
    try {
      final results = await Future.wait([
        service.getNowPlaying(userId: widget.userId),
        service.getCompatibility(widget.userId),
        service.getMusicProfile(userId: widget.userId),
      ]);

      if (mounted) {
        setState(() {
          _nowPlaying = results[0] as TrackModel?;
          _musicCompat = results[1] as MusicCompatibility?;
          _musicProfile = results[2] as MusicProfile?;
        });
      }
    } catch (e) {
      debugPrint('Error loading music data: $e');
    }
  }

  Future<void> _handleAccept() async {
    final reqId = widget.requestId ?? _profile?.receivedRequestId;
    if (reqId == null) return;

    setState(() => _responding = true);
    try {
      final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
      final result = await connectionProvider.acceptConnection(reqId, targetUserId: widget.userId);
      
      if (result['success'] == true) {
        setState(() {
          _connectionStatus = 'mutual';
          _responding = false;
        });
        widget.onAccept?.call();
      } else {
        throw Exception(result['error'] ?? 'Failed to accept');
      }
    } catch (e) {
      setState(() => _responding = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _handleConnect() async {
    setState(() => _responding = true);
    try {
      final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
      final result = await connectionProvider.quickConnect(widget.userId);
      
      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          // Exactly matching logic for already connected users
          if (data is Map && (data['status'] == 'already_connected' || data['connection_status'] == 'connected')) {
            _connectionStatus = 'mutual';
          } else {
            _connectionStatus = 'pending';
            _isInitiator = true;
          }
          _responding = false;
        });
      } else if (result['status'] == 'already_connected') {
        setState(() {
          _connectionStatus = 'mutual';
          _responding = false;
        });
      } else {
        throw Exception(result['error'] ?? 'Failed to connect');
      }
    } catch (e) {
      setState(() => _responding = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _openChat() async {
    final userId = widget.userId;
    try {
      final response = await apiClient.post(
        'api/v1/messaging/start/',
        {'user_id': userId});
      if (!mounted) return;
      final convData = response['conversation'] as Map<String, dynamic>;
      final conv = ConversationModel.fromJson(convData);
      Navigator.push(context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: conv)));
    } catch (e) {
      debugPrint('Open chat error: $e');
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: (_loading && _profile == null)
          ? _buildSkeleton()
          : _profile == null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildSkeleton() {
    return Stack(
      children: [
        PulsingGlassPlaceholder(height: MediaQuery.of(context).size.height),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final p = _profile!;
    final name = '${p.firstName} ${p.lastName}'.trim();
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // FIXED BACKGROUND PHOTO
        Positioned.fill(
          child: (p.mainProfilePhotoUrl != null && p.mainProfilePhotoUrl!.isNotEmpty)
              ? SafeNetworkImage(url: p.mainProfilePhotoUrl, fit: BoxFit.cover)
              : Container(
                  color: Colors.grey.shade900,
                  child: Center(
                    child: Text(
                      p.firstName.isNotEmpty ? p.firstName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
        ),

        // SCRIM FOR TOP READABILITY
        Positioned(
          top: 0, left: 0, right: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.5), Colors.transparent],
              ),
            ),
          ),
        ),

        // MAIN SCROLLABLE AREA
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Spacer to keep the face visible
            SliverToBoxAdapter(
              child: SizedBox(height: screenHeight * 0.45),
            ),
            
            // Name and Headline (floating over photo)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.displayLarge.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 16)],
                      ),
                    ),
                    if (p.headline.isNotEmpty)
                      Text(
                        p.headline,
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          shadows: [Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 8)],
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildInfoBadge(Icons.location_on_outlined, p.neighborhoodDisplay),
                  ],
                ),
              ),
            ),

            // GLASS CONTENT CARD
            SliverToBoxAdapter(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (FeatureFlags.spotifyEnabled && _nowPlaying != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: NowPlayingBar(track: _nowPlaying!, compact: true),
                          ),

                        if (FeatureFlags.spotifyEnabled && _musicCompat != null && _musicCompat!.score > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: MusicCompatChip(
                              score: _musicCompat!.score,
                              sharedGenres: _musicCompat!.sharedGenres,
                            ),
                          ),

                        _buildSectionTitle('About'),
                        Text(
                          p.bio.isNotEmpty ? p.bio : 'No bio provided.',
                          style: AppTypography.bodyLarge.copyWith(color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 32),

                        if (FeatureFlags.spotifyEnabled && _musicProfile != null && _musicProfile!.topArtists.isNotEmpty) ...[
                          _buildSectionTitle('Vibes With'),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: _musicProfile!.topArtists.take(5).map((a) => _buildGlassChip(a.name)).toList(),
                          ),
                          const SizedBox(height: 32),
                        ],

                        if (p.interests.isNotEmpty) ...[
                          _buildSectionTitle('Interests'),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: p.interests.map((i) => _buildGlassChip(i)).toList(),
                          ),
                          const SizedBox(height: 32),
                        ],

                        if (p.moments.isNotEmpty) ...[
                          _buildSectionTitle('Moments'),
                          const SizedBox(height: 12),
                          GridView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1,
                            ),
                            itemCount: p.moments.length,
                            itemBuilder: (ctx, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SafeNetworkImage(url: p.moments[i].imageUrl, fit: BoxFit.cover),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // TOP BACK BUTTON
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            ),
          ),
        ),

        // STICKY BOTTOM GLASS ACTION BAR
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: _buildActionButtons(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    // EXACT SAME LOGIC AS PROFILECARD.DART
    if (_connectionStatus == 'mutual' || _connectionStatus == 'connected') {
      return LiquidGlassButton(
        size: LiquidButtonSize.xl,
        width: double.infinity,
        onPressed: _openChat,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 22, color: Colors.white),
            const SizedBox(width: 10),
            Text('Message', style: AppTypography.buttonText.copyWith(fontSize: 16)),
          ],
        ),
      );
    }

    if (_connectionStatus == 'pending' && !_isInitiator) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: (widget.onDecline != null && !_responding) ? widget.onDecline : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Center(
                  child: Text('Decline', style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: LiquidGlassButton(
              size: LiquidButtonSize.xl,
              onPressed: _responding ? null : _handleAccept,
              child: _responding
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite, size: 22, color: Colors.white),
                        const SizedBox(width: 10),
                        Text('Accept', style: AppTypography.buttonText.copyWith(fontSize: 16)),
                      ],
                    ),
            ),
          ),
        ],
      );
    }

    if (_connectionStatus == 'pending' && _isInitiator) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Text('Request Sent', style: AppTypography.labelMedium.copyWith(color: Colors.white70, fontWeight: FontWeight.w600)),
        ),
      );
    }

    // Default: 'none'
    return LiquidGlassButton(
      size: LiquidButtonSize.xl,
      width: double.infinity,
      onPressed: _responding ? null : _handleConnect,
      child: _responding
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, size: 22, color: Colors.white),
                const SizedBox(width: 10),
                Text('Connect', style: AppTypography.buttonText.copyWith(fontSize: 16)),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTypography.labelMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGlassChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppConstants.primaryRed),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.white54),
          const SizedBox(height: 16),
          Text('Could not load profile', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
          const SizedBox(height: 24),
          LiquidGlassButton(onPressed: _loadProfile, child: Text('Retry', style: AppTypography.buttonText)),
        ],
      ),
    );
  }
}
