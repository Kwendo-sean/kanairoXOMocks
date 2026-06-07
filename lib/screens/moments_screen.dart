import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/services/moment_service.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/widgets/moments/network_media_preview.dart';
import 'package:kanairoxo/widgets/skeletons.dart';
import 'package:kanairoxo/widgets/moments/comments_bottom_sheet.dart';
import 'package:kanairoxo/widgets/moments/the_drop_widget.dart';
import 'package:kanairoxo/widgets/moments/polaroid_stack.dart';
import 'package:kanairoxo/services/home_widget_service.dart';
import 'package:kanairoxo/widgets/moments/constellation_view.dart';
import 'package:kanairoxo/widgets/moments/kxo_stamp.dart';
import 'package:kanairoxo/services/widget_service.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/screens/moments/creation/moment_creation_flow.dart';
import 'package:kanairoxo/screens/moments/moment_detail_screen.dart';
import 'package:kanairoxo/widgets/modals/report_modal.dart';
import 'package:kanairoxo/utils/swahili_phrases.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  final MomentService _momentService = MomentService();
  
  List<Moment> _allMoments = [];
  DropModel? _dropData;

  bool _isLoading = true;
  String _carouselStyle = 'polaroid';

  final List<String> _subtitles = [
    'Where Nairobi comes alive',
    'The city through your eyes',
    'Real moments, real connections',
    'Life in Nairobi, unfiltered',
    'Your story, your city',
    'Nairobi never sleeps',
    'Captured in the moment',
  ];
  
  late final String _carouselSubtitle;

  @override
  void initState() {
    super.initState();
    _carouselSubtitle = _subtitles[DateTime.now().millisecond % _subtitles.length];
    
    _loadMoments();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStylePreference();
      _loadDropData();
    });
  }

  Future<void> _loadStylePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('carousel_style');
      if (mounted) {
        setState(() {
          _carouselStyle = saved ?? 'polaroid';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carouselStyle = 'polaroid';
        });
      }
    }
  }

  Future<void> _switchStyle(String style) async {
    if (_carouselStyle == style) return;
    
    setState(() => _carouselStyle = style);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('carousel_style', style);
    } catch (e) {
      // Error
    }
  }

  Future<void> _loadMoments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final moments = await _momentService.getMoments();
      if (!mounted) return;
      setState(() {
        _allMoments = moments;
        _isLoading = false;
      });
      WidgetService.refreshAllWidgets(_allMoments, 0, 0);
      // Push the most recent moment to the iOS home-screen widget.
      if (_allMoments.isNotEmpty) {
        unawaited(HomeWidgetService.instance.updateFromMoment(_allMoments.first.toJson()));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDropData() async {
    try {
      final response = await ApiClient.instance.dio.get('/api/v1/moments/drop/');
      if (mounted) {
        setState(() {
          _dropData = DropModel.fromJson(response.data as Map<String, dynamic>);
        });
        if (_dropData != null) {
          WidgetService.updateDropWidget(
              secondsUntilDrop: _dropData!.secondsUntilDrop,
              isLive: _dropData!.status == 'live');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _dropData = null);
      }
    }
  }

  List<Moment> get filteredMoments => _allMoments;

  void openCreateMoment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MomentCreationFlow()),
    );
    if (result == true) {
      _loadMoments();
    }
  }

  void _openMomentViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MomentDetailScreen(
          moments: _allMoments,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      // Body extends behind the translucent app bar so content is partly
      // visible THROUGH the glass as the user scrolls — iOS liquid-glass feel.
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: AppBar(
              backgroundColor: context.bgColor.withOpacity(0.55),
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text('Moments', style: AppTypography.screenTitle.copyWith(color: context.textColor)),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.add_a_photo_outlined, size: 22, color: context.primaryColor),
                  onPressed: openCreateMoment,
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMoments,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Push first item down so it starts BELOW the translucent app bar.
            // (extendBodyBehindAppBar means the body starts at y=0 otherwise.)
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight)),
            SliverToBoxAdapter(
              child: _safeTopSection()),

            if (_dropData?.status != 'live')
              SliverToBoxAdapter(
                child: _buildViewToggle()),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_carouselSubtitle,
                  style: AppTypography.caption.copyWith(
                    color: context.mutedColor,
                    fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center))),

            if (_isLoading && _allMoments.isEmpty)
              SliverToBoxAdapter(child: SizedBox(height: 600, child: Skeleton.feed(context, count: 3)))
            else if (filteredMoments.isEmpty)
              SliverToBoxAdapter(
                child: _buildTagEmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _PolaroidFeedCard(
                    moment: filteredMoments[i],
                    index: i,
                    onTap: () => _openMomentViewer(_allMoments.indexOf(filteredMoments[i]))),
                  childCount: filteredMoments.length)),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: context.borderColor),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2))]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _switchStyle('polaroid'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: _carouselStyle == 'polaroid'
                    ? context.primaryColor
                    : Colors.transparent,
                  borderRadius: 
                    BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_album_outlined,
                      size: 14,
                      color: _carouselStyle == 'polaroid'
                        ? Colors.white
                        : context.mutedColor),
                    const SizedBox(width: 5),
                    Text('Polaroid',
                      style: AppTypography.caption
                        .copyWith(
                          color: _carouselStyle == 
                            'polaroid'
                            ? Colors.white
                            : context.mutedColor,
                          fontWeight: _carouselStyle == 
                            'polaroid'
                            ? FontWeight.w600
                            : FontWeight.w400)),
                  ])),
            ),
            GestureDetector(
              onTap: () => _switchStyle(
                'constellation'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: _carouselStyle == 
                    'constellation'
                    ? context.primaryColor
                    : Colors.transparent,
                  borderRadius: 
                    BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 14,
                      color: _carouselStyle == 
                        'constellation'
                        ? Colors.white
                        : context.mutedColor),
                    const SizedBox(width: 5),
                    Text('Stars',
                      style: AppTypography.caption
                        .copyWith(
                          color: _carouselStyle == 
                            'constellation'
                            ? Colors.white
                            : context.mutedColor,
                          fontWeight: _carouselStyle == 
                            'constellation'
                            ? FontWeight.w600
                            : FontWeight.w400)),
                  ])),
            ),
          ])));
  }
  
  Widget _safeTopSection() {
    try {
      return _buildTopSection();
    } catch (e) {
      return Container(
        height: 200,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.isDark ? context.surfaceColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20)),
        child: Center(child: Icon(
          Icons.photo_library_outlined,
          size: 48, color: context.mutedColor)));
    }
  }

  Widget _buildTopSection() {
    if (_dropData != null && (_dropData!.status == 'live' || _dropData!.secondsUntilDrop > 0)) {
       return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TheDropWidget(
          dropData: _dropData!,
          onRefresh: _loadDropData));
    }

    if (_carouselStyle == 'constellation') {
      return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ConstellationView(
              moments: _allMoments, 
              onTap: (m) => _openMomentViewer(_allMoments.indexOf(m))));
    }

    return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: PolaroidStack(
            moments: _allMoments,
            onTap: (m) => _openMomentViewer(_allMoments.indexOf(m))));
  }

  Widget _buildTagEmptyState() {
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.photo_library_outlined,
                  size: 44, color: context.mutedColor),
              const SizedBox(height: 12),
              Text('No moments yet',
                  style:
                      AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: context.textColor)),
              const SizedBox(height: 6),
              Text('Be the first to share one',
                  style:
                      AppTypography.caption.copyWith(color: context.mutedColor)),
              const SizedBox(height: 16),
              LiquidGlassButton(
                  size: LiquidButtonSize.md,
                  onPressed: openCreateMoment,
                  child: Text('Create Moment', style: AppTypography.buttonText)),
            ])));
  }
}


class _PolaroidFeedCard extends StatefulWidget {
  final Moment moment;
  final int index;
  final VoidCallback onTap;

  const _PolaroidFeedCard({
    required this.moment,
    required this.index,
    required this.onTap,
  });

  @override
  State<_PolaroidFeedCard> createState() => _PolaroidFeedCardState();
}

class _PolaroidFeedCardState extends State<_PolaroidFeedCard> {
  late bool _isLiked;
  late int _likeCount;
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.moment.isLiked;
    _likeCount = widget.moment.likeCount;
    _isSaved = widget.moment.isSaved;
  }

  Future<void> _toggleLike() async {
    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !wasLiked;
      _likeCount += wasLiked ? -1 : 1;
    });
    try {
      await ApiClient.instance.dio.post('/api/v1/moments/${widget.moment.id}/like/', data: {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likeCount += wasLiked ? 1 : -1;
        });
      }
    }
  }

  Future<void> _toggleSave() async {
    final wasSaved = _isSaved;
    setState(() {
      _isSaved = !wasSaved;
    });
    try {
      await ApiClient.instance.dio.post('/api/v1/moments/${widget.moment.id}/save/', data: {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaved = wasSaved;
        });
      }
    }
  }

  Color get _paperColor {
    final seed = widget.moment.id.hashCode;
    final tints = [
      const Color(0xFFFFFDF5),
      const Color(0xFFFFF8F0),
      const Color(0xFFF5FFF5),
      const Color(0xFFF5F5FF),
      const Color(0xFFFFFAFA),
    ];
    return tints[seed.abs() % tints.length];
  }

  @override
  Widget build(BuildContext context) {
    // Alternating rotation for a messy stack look in the feed
    final rotation = (widget.index % 2 == 0 ? 0.025 : -0.025);

    return Center(
      child: Transform.rotate(
        angle: rotation,
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: () => ReportModal.show(context, targetType: 'moment', targetId: widget.moment.id),
          child: Container(
            width: 320,
            margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: _paperColor,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.9),
                  blurRadius: 0,
                  offset: const Offset(-1, -1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: NetworkMediaPreview(
                              url: widget.moment.photoUrl,
                              mediaType: widget.moment.mediaType,
                              fit: BoxFit.cover,
                              autoPlay: widget.index < 2, // only first 2 cards auto-play
                              thumbnailMode: widget.index >= 2,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Transform.rotate(
                            angle: -0.12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                border: Border.all(color: AppColors.primary.withOpacity(0.6), width: 1.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.moment.type.name.toUpperCase(),
                                style: GoogleFonts.caveat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.moment.trackName != null && widget.moment.trackName!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.music_note, size: 12, color: Color(0xFF1DB954)),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(
                                          '${widget.moment.trackName} — ${widget.moment.trackArtist ?? ''}',
                                          style: AppTypography.caption.copyWith(color: const Color(0xFF1DB954), fontSize: 11),
                                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  ),
                                Text(
                                  widget.moment.caption.isNotEmpty ? widget.moment.caption : SwahiliPhrases.getPhrase(widget.moment),
                                  style: GoogleFonts.pacifico(
                                    fontSize: 16,
                                    color: const Color(0xFF2C2C2C),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      widget.moment.userName,
                                      style: GoogleFonts.caveat(fontSize: 14, color: const Color(0xFF444444), fontWeight: FontWeight.w600),
                                    ),
                                    if (widget.moment.location != null) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.location_on_outlined, size: 10, color: Colors.black45),
                                      Text(widget.moment.location!, style: GoogleFonts.caveat(fontSize: 12, color: Colors.black45)),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          KXOStamp(userName: widget.moment.userName, size: 52),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _toggleLike,
                            child: Row(
                              children: [
                                Icon(_isLiked ? Icons.favorite : Icons.favorite_border,
                                  size: 22, color: _isLiked ? AppColors.primary : Colors.black45),
                                const SizedBox(width: 6),
                                Text('$_likeCount', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => CommentsBottomSheet(momentId: widget.moment.id),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline, size: 22, color: Colors.black45),
                                const SizedBox(width: 6),
                                Text('${widget.moment.commentCount}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.more_horiz, color: Colors.black26),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.grey[900],
                                builder: (ctx) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.report, color: Colors.white),
                                      title: const Text('Report', style: TextStyle(color: Colors.white)),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        ReportModal.show(context, targetType: 'moment', targetId: widget.moment.id);
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: _toggleSave,
                            child: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border,
                              size: 22, color: _isSaved ? AppColors.primary : Colors.black45),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
