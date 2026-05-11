import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/music/spotify_models.dart';
import '../../services/spotify_service.dart';
import '../../widgets/safe_network_image.dart';

class SpotifyConnectScreen extends StatefulWidget {
  const SpotifyConnectScreen({super.key});

  @override
  State<SpotifyConnectScreen> createState() => _SpotifyConnectScreenState();
}

class _SpotifyConnectScreenState extends State<SpotifyConnectScreen> {
  SpotifyStatus? _status;
  MusicProfile? _musicProfile;
  TrackModel? _nowPlaying;
  bool _isLoading = true;
  bool _isConnecting = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _loadMusicData();
  }

  Future<void> _loadStatus() async {
    final status = await SpotifyService().getStatus();
    if (mounted) {
      setState(() {
        _status = status;
        if (_status?.connected != true) {
          _isLoading = false;
        }
      });
    }
  }

  Future<void> _loadMusicData() async {
    final results = await Future.wait([
      SpotifyService().getMusicProfile(),
      SpotifyService().getNowPlaying(),
    ]);
    if (mounted) {
      setState(() {
        _musicProfile = results[0] as MusicProfile?;
        _nowPlaying = results[1] as TrackModel?;
        _isLoading = false;
      });
    }
  }

  Future<void> _connect() async {
    setState(() => _isConnecting = true);
    final launched = await SpotifyService().connectSpotify();
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Could not open Spotify'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating));
    }
    if (mounted) {
      setState(() => _isConnecting = false);
      _loadStatus();
      _loadMusicData();
    }
  }

  Future<void> _disconnect() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Disconnect Spotify?'),
              content: const Text(
                  'Your music profile and compatibility scores will be removed.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Disconnect',
                        style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirm == true) {
      await SpotifyService().disconnect();
      await _loadStatus();
      setState(() {
        _musicProfile = null;
        _nowPlaying = null;
      });
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    await SpotifyService().syncProfile();
    await _loadMusicData();
    setState(() => _isSyncing = false);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAF7F4);
    final surfaceColor = isDark ? const Color(0xFF1C1612) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A0808);
    final mutedColor =
        isDark ? const Color(0xFF9A8F85) : const Color(0xFF9A8F85);
    final borderColor =
        isDark ? const Color(0xFF2E2820) : const Color(0xFFEDE5DC);
    final primaryColor =
        isDark ? const Color(0xFFC0394B) : const Color(0xFF8B1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Your Sound',
            style: AppTypography.screenTitle.copyWith(color: textColor)),
      ),
      body: _isLoading
          ? const Center(
              child: PulsingGlassPlaceholder(width: 200, height: 200, borderRadius: 24))
          : _status?.connected == true
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    _buildConnectedPill(
                        surfaceColor, borderColor, mutedColor, primaryColor),
                    const SizedBox(height: 28),
                    _buildNowPlaying(
                        surfaceColor, borderColor, textColor, mutedColor),
                    const SizedBox(height: 28),
                    _buildGenresLine(mutedColor, textColor),
                    const SizedBox(height: 28),
                    _buildArtistsStrip(mutedColor, primaryColor, borderColor),
                    const SizedBox(height: 28),
                    _buildTopTracks(
                        surfaceColor, borderColor, textColor, mutedColor),
                    const SizedBox(height: 32),
                    _buildSyncFooter(borderColor, mutedColor, primaryColor),
                    const SizedBox(height: 20),
                  ]))
              : _buildDisconnected(
                  surfaceColor, textColor, borderColor, primaryColor),
    );
  }

  Widget _buildConnectedPill(Color surfaceColor, Color borderColor,
      Color mutedColor, Color primaryColor) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Color(0xFF1DB954), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('Spotify · ${_status?.spotifyUser ?? ""}',
                style: AppTypography.caption
                    .copyWith(color: mutedColor, fontSize: 12)),
            const SizedBox(width: 12),
            GestureDetector(
                onTap: _disconnect,
                child: Text('Disconnect',
                    style: AppTypography.caption.copyWith(
                        color: primaryColor.withOpacity(0.6),
                        fontSize: 11))),
          ]))
    ]);
  }

  Widget _buildNowPlaying(Color surfaceColor, Color borderColor,
      Color textColor, Color mutedColor) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor)),
        child: _nowPlaying != null
            ? Row(children: [
                Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ]),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SafeNetworkImage(
                          url: _nowPlaying!.imageUrl,
                          fit: BoxFit.cover,
                          width: 72,
                          height: 72,
                        ))),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Now Playing',
                          style: AppTypography.caption.copyWith(
                              color: const Color(0xFF1DB954),
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(_nowPlaying!.name,
                          style: AppTypography.labelMedium.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(_nowPlaying!.artist,
                          style: AppTypography.caption
                              .copyWith(color: mutedColor, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ])),
                const _PlayingIndicator(color: Color(0xFF1DB954)),
              ])
            : Row(children: [
                _AlbumArtPlaceholder(),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Nothing playing',
                      style: TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: mutedColor)),
                  const SizedBox(height: 4),
                  Text('Open Spotify to see\nyour track here',
                      style: AppTypography.caption.copyWith(
                          color: mutedColor.withOpacity(0.6),
                          fontSize: 11)),
                ]),
              ]));
  }

  Widget _buildGenresLine(Color mutedColor, Color textColor) {
    if (_musicProfile?.topGenres.isNotEmpty == true) {
      return Column(children: [
        Text('YOUR SOUND',
            style: AppTypography.caption
                .copyWith(color: mutedColor, fontSize: 9, letterSpacing: 3)),
        const SizedBox(height: 8),
        Text(_musicProfile!.topGenres.take(4).join(' · '),
            style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 22,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                color: textColor,
                height: 1.2),
            textAlign: TextAlign.center),
      ]);
    }
    return const SizedBox.shrink();
  }

  Widget _buildArtistsStrip(
      Color mutedColor, Color primaryColor, Color borderColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TOP ARTISTS',
          style: AppTypography.caption
              .copyWith(color: mutedColor, fontSize: 9, letterSpacing: 3)),
      const SizedBox(height: 12),
      SizedBox(
          height: 80,
          child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _musicProfile?.topArtists.take(8).length ?? 0,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (ctx, i) {
                final artist = _musicProfile!.topArtists[i];
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withOpacity(0.1),
                          border: Border.all(color: borderColor)),
                      child: ClipOval(
                        child: SafeNetworkImage(
                          url: artist.imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: Center(
                              child: Text(artist.name[0].toUpperCase(),
                                  style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18))),
                        ),
                      )),
                  const SizedBox(height: 6),
                  SizedBox(
                      width: 56,
                      child: Text(artist.name,
                          style: AppTypography.caption
                              .copyWith(color: mutedColor, fontSize: 10),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                ]);
              })),
    ]);
  }

  Widget _buildTopTracks(Color surfaceColor, Color borderColor, Color textColor,
      Color mutedColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TOP TRACKS',
          style: AppTypography.caption
              .copyWith(color: mutedColor, fontSize: 9, letterSpacing: 3)),
      const SizedBox(height: 12),
      ...(_musicProfile?.topTracks.take(5).toList() ?? [])
          .asMap()
          .entries
          .map((entry) {
        final i = entry.key;
        final track = entry.value;
        return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor)),
            child: Row(children: [
              SizedBox(
                  width: 20,
                  child: Text('${i + 1}',
                      style: AppTypography.caption.copyWith(
                          color: mutedColor.withOpacity(0.5),
                          fontSize: 11))),
              const SizedBox(width: 10),
              ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SafeNetworkImage(
                    url: track.imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  )),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(track.name,
                        style: AppTypography.caption.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(track.artist,
                        style: AppTypography.caption
                            .copyWith(color: mutedColor, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ])),
            ]));
      }).toList(),
    ]);
  }

  Widget _buildSyncFooter(
      Color borderColor, Color mutedColor, Color primaryColor) {
    return Column(children: [
      Divider(color: borderColor, height: 1),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
            _musicProfile?.lastSynced != null
                ? 'Synced ${_timeAgo(_musicProfile!.lastSynced!)}'
                : 'Not yet synced',
            style:
                AppTypography.caption.copyWith(color: mutedColor, fontSize: 11)),
        GestureDetector(
            onTap: _isSyncing ? null : _syncNow,
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(999)),
                child: _isSyncing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: PulsingGlassPlaceholder(borderRadius: 999))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.refresh, size: 14, color: mutedColor),
                        const SizedBox(width: 4),
                        Text('Sync',
                            style: AppTypography.caption
                                .copyWith(color: mutedColor, fontSize: 12)),
                      ]))),
      ]),
    ]);
  }

  Widget _buildDisconnected(
      Color surface, Color text, Color borderColor, Color primaryColor) {
    return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF1DB954).withOpacity(0.3))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: const Color(0xFF1DB954),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.music_note,
                              color: Colors.white, size: 24)),
                      const SizedBox(width: 12),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Spotify',
                                style: AppTypography.labelMedium.copyWith(
                                    color: text, fontWeight: FontWeight.w700)),
                            Text('Music integration',
                                style: AppTypography.caption
                                    .copyWith(color: AppColors.textMuted)),
                          ]),
                    ]),
                    const SizedBox(height: 20),
                    Text(
                        'Connect Spotify to unlock music compatibility with your matches.',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textMuted, height: 1.5)),
                    const SizedBox(height: 20),
                    const _FeatureRow(
                        icon: Icons.people_outline,
                        label: 'Music compatibility with every match'),
                    const SizedBox(height: 10),
                    const _FeatureRow(
                        icon: Icons.music_note_outlined,
                        label: 'Show what you\'re listening to on your profile'),
                    const SizedBox(height: 10),
                    const _FeatureRow(
                        icon: Icons.playlist_add,
                        label: 'Shared playlists with your partner'),
                    const SizedBox(height: 24),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: _isConnecting ? null : _connect,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1DB954),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999))),
                            child: _isConnecting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: PulsingGlassPlaceholder(borderRadius: 999))
                                : Text('Connect Spotify',
                                    style: AppTypography.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)))),
                  ])),
        ]));
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.primary.withOpacity(0.7)),
      const SizedBox(width: 10),
      Expanded(
          child: Text(label,
              style:
                  AppTypography.caption.copyWith(color: AppColors.textMuted))),
    ]);
  }
}

class _AlbumArtPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
            color: const Color(0xFF1DB954).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFF1DB954).withOpacity(0.2))),
        child: Icon(Icons.music_note,
            color: const Color(0xFF1DB954).withOpacity(0.4), size: 28));
  }
}

class _PlayingIndicator extends StatefulWidget {
  final Color color;
  const _PlayingIndicator({required this.color});
  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 100),
      )..repeat(reverse: true),
    );
    _animations = _controllers
        .map((c) => Tween(begin: 3.0, end: 14.0).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        3,
        (i) => AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) => Container(
            width: 3,
            height: _animations[i].value,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
