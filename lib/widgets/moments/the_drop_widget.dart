import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../utils/constants.dart';
import '../safe_network_image.dart';

class DropModel {
  final String status; // 'live', 'upcoming', 'no_drop'
  final DropData? drop;
  final bool isPostingLocked;
  final int secondsUntilDrop;
  final String? dropTime;

  DropModel({
    required this.status,
    this.drop,
    required this.isPostingLocked,
    required this.secondsUntilDrop,
    this.dropTime,
  });

  factory DropModel.fromJson(Map<String, dynamic> json) {
    return DropModel(
      status: json['status'] ?? 'no_drop',
      drop: json['drop'] != null ? DropData.fromJson(json['drop']) : null,
      isPostingLocked: json['is_posting_locked'] ?? false,
      secondsUntilDrop: json['seconds_until_drop'] ?? 0,
      dropTime: json['drop_time'],
    );
  }
}

class DropData {
  final String id;
  final String title;
  final List<DropMomentModel> moments;
  final int viewCount;

  DropData({
    required this.id,
    required this.title,
    required this.moments,
    required this.viewCount,
  });

  factory DropData.fromJson(Map<String, dynamic> json) {
    return DropData(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'This Week in Nairobi',
      moments: (json['moments'] as List? ?? [])
          .map((m) => DropMomentModel.fromJson(m))
          .toList(),
      viewCount: json['view_count'] ?? 0,
    );
  }
}

class DropMomentModel {
  final String id;
  final String? imageUrl;
  final String caption;
  final String userName;
  final int position;
  final int likesCount;

  DropMomentModel({
    required this.id,
    this.imageUrl,
    required this.caption,
    required this.userName,
    required this.position,
    required this.likesCount,
  });

  factory DropMomentModel.fromJson(Map<String, dynamic> json) {
    return DropMomentModel(
      id: json['id']?.toString() ?? '',
      imageUrl: ApiConstants.fixMediaUrl(json['image_url']),
      caption: json['caption'] ?? '',
      userName: json['user_name'] ?? '',
      position: json['position'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
    );
  }
}

class TheDropWidget extends StatefulWidget {
  final DropModel dropData;
  final VoidCallback onRefresh;

  const TheDropWidget({
    super.key,
    required this.dropData,
    required this.onRefresh,
  });

  @override
  State<TheDropWidget> createState() => _TheDropWidgetState();
}

class _TheDropWidgetState extends State<TheDropWidget> {
  late Timer _countdownTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.dropData.secondsUntilDrop;
    if (_secondsRemaining > 0) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    if (_secondsRemaining > 0) {
      _countdownTimer.cancel();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _countdownTimer.cancel();
            widget.onRefresh(); // reload when live
          }
        });
      }
    });
  }

  String get _formattedCountdown {
    final h = _secondsRemaining ~/ 3600;
    final m = (_secondsRemaining % 3600) ~/ 60;
    final s = _secondsRemaining % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dropData.status == 'live' && widget.dropData.drop != null) {
      return _buildLiveDrop(widget.dropData.drop!);
    }

    if (_secondsRemaining > 0) {
      return _buildCountdown();
    }

    return const SizedBox.shrink();
  }

  // Countdown display before 6pm Friday
  Widget _buildCountdown() {
    return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2)
                ]),
            child: Column(children: [
              Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('THE DROP',
                    style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
              ]),
              const SizedBox(height: 8),
              Text('Friday at 6pm',
                  style: AppTypography.caption.copyWith(color: Colors.white54)),
              const SizedBox(height: 12),
              Text(_formattedCountdown,
                  style: GoogleFonts.dmSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -1)),
              const SizedBox(height: 6),
              Text('until the best of Nairobi drops',
                  style: AppTypography.caption.copyWith(color: Colors.white54)),
            ]))
        .animate()
        .fadeIn(duration: 500.ms);
  }

  // Live drop — magazine style viewer
  Widget _buildLiveDrop(DropData drop) {
    return Column(children: [
      // Header
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle))
                .animate(onPlay: (c) => c.repeat())
                .fadeOut(duration: 800.ms)
                .then()
                .fadeIn(duration: 800.ms),
            const SizedBox(width: 8),
            Text('THE DROP',
                style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 2)),
            const SizedBox(width: 6),
            Text(drop.title,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textMuted)),
            const Spacer(),
            Text('${drop.viewCount} views',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textMuted)),
          ])),

      const SizedBox(height: 12),

      // Horizontal scroll of top 10
      SizedBox(
          height: 280,
          child: PageView.builder(
              controller: PageController(viewportFraction: 0.85),
              itemCount: drop.moments.length,
              itemBuilder: (ctx, i) {
                final m = drop.moments[i];
                return _DropMomentCard(moment: m, rank: i + 1);
              })),

      // If posting is locked
      if (widget.dropData.isPostingLocked)
        Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: AppColors.primaryGlass,
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.lock_outline, size: 14, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Posting opens in 1 hour',
                  style: AppTypography.caption.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ])),
    ]);
  }
}

class _DropMomentCard extends StatelessWidget {
  final DropMomentModel moment;
  final int rank;

  const _DropMomentCard({required this.moment, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(children: [
              // Photo
              Positioned.fill(
                  child: SafeNetworkImage(
                      url: moment.imageUrl, fit: BoxFit.cover)),

              // Gradient
              Positioned.fill(
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [
                    0.4,
                    1.0
                  ],
                              colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8)
                  ])))),

              // Rank number
              Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child: Center(
                          child: Text('$rank',
                              style: AppTypography.labelMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13))))),

              // Info at bottom
              Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(moment.userName,
                            style: AppTypography.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(moment.caption,
                            style: AppTypography.caption
                                .copyWith(color: Colors.white70),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ])),
            ])));
  }
}
