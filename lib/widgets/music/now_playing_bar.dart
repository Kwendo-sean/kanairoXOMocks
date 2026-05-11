import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/music/spotify_models.dart';

class NowPlayingBar extends StatelessWidget {
  final TrackModel track;
  final bool compact;
  
  const NowPlayingBar({
    super.key,
    required this.track,
    this.compact = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1612) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1DB954).withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          // Album art
          if (track.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: track.imageUrl!,
                width: compact ? 32 : 40,
                height: compact ? 32 : 40,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: compact ? 32 : 40,
                  height: compact ? 32 : 40,
                  color: const Color(0xFF1DB954).withOpacity(0.2),
                  child: const Icon(Icons.music_note, size: 16, color: Color(0xFF1DB954)),
                ),
              ),
            )
          else
            Container(
              width: compact ? 32 : 40,
              height: compact ? 32 : 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.music_note, size: 16, color: Color(0xFF1DB954)),
            ),
          
          const SizedBox(width: 10),
          
          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track.name,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 11 : 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track.artist,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: compact ? 9 : 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Playing indicator — 3 animated bars
          const _PlayingIndicator(color: Color(0xFF1DB954)),
        ],
      ),
    );
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
