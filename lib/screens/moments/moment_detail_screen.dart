import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/moment.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/moment_service.dart';
import '../../widgets/moments/comments_bottom_sheet.dart';
import '../../widgets/moments/kxo_stamp.dart';
import '../../utils/constants.dart';

class MomentDetailScreen extends StatefulWidget {
  final List<Moment> moments;
  final int initialIndex;

  const MomentDetailScreen({
    super.key,
    required this.moments,
    required this.initialIndex,
  });

  @override
  State<MomentDetailScreen> createState() => _MomentDetailScreenState();
}

class _MomentDetailScreenState extends State<MomentDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late List<Moment> _localMoments;
  final MomentService _momentService = MomentService();
  
  AudioPlayer? _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _localMoments = List.from(widget.moments);
    
    // Autoplay for the initial index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAudio(_currentIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stopAudio();
    super.dispose();
  }

  Future<void> _startAudio(int index) async {
    await _stopAudio();
    
    final moment = _localMoments[index];
    final url = moment.trackPreviewUrl;
    
    if (url != null && url.isNotEmpty) {
      _player = AudioPlayer();
      try {
        await _player!.setUrl(url);
        await _player!.setVolume(0.7);
        _player!.play();
        
        _player!.playerStateStream.listen((state) {
          if (mounted) {
            setState(() {
              _isPlaying = state.playing;
            });
          }
        });
      } catch (e) {
        debugPrint("Error playing audio: $e");
      }
    }
  }

  Future<void> _stopAudio() async {
    if (_player != null) {
      await _player!.stop();
      await _player!.dispose();
      _player = null;
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  void _togglePlayPause() {
    if (_player != null) {
      if (_isPlaying) {
        _player!.pause();
      } else {
        _player!.play();
      }
    }
  }

  Future<void> _handleLike(int index) async {
    final moment = _localMoments[index];
    final isLiked = !moment.isLikedByMe;

    setState(() {
      _localMoments[index] = Moment(
        id: moment.id,
        userName: moment.userName,
        userAvatarUrl: moment.userAvatarUrl,
        eventName: moment.eventName,
        date: moment.date,
        type: moment.type,
        photoUrl: moment.photoUrl,
        caption: moment.caption,
        location: moment.location,
        likesCount: isLiked ? moment.likesCount + 1 : moment.likesCount - 1,
        commentsCount: moment.commentsCount,
        isLikedByMe: isLiked,
        isSavedByMe: moment.isSavedByMe,
        trackName: moment.trackName,
        trackArtist: moment.trackArtist,
        trackImageUrl: moment.trackImageUrl,
        trackPreviewUrl: moment.trackPreviewUrl,
        linkedEvent: moment.linkedEvent,
      );
    });

    try {
      await _momentService.toggleLike(moment.id);
    } catch (e) {
      setState(() {
        _localMoments[index] = moment;
      });
    }
  }

  void _showComments(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CinematicCommentsSheet(
        momentId: _localMoments[index].id,
      ),
    ).then((_) {
      _refreshMoment(index);
    });
  }

  Future<void> _refreshMoment(int index) async {
    try {
      final updated = await _momentService.getMomentDetail(_localMoments[index].id);
      if (mounted) {
        setState(() {
          _localMoments[index] = updated;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing moment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _localMoments.length,
            onPageChanged: (i) {
              setState(() => _currentIndex = i);
              _startAudio(i);
            },
            itemBuilder: (context, index) {
              return _MomentPageView(
                moment: _localMoments[index],
                onLike: () => _handleLike(index),
                onComment: () => _showComments(index),
                isPlaying: _currentIndex == index && _isPlaying,
                onToggleAudio: _togglePlayPause,
              );
            },
          ),
          
          // Layer 4: Back Button
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                padding: const EdgeInsets.all(20),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentPageView extends StatefulWidget {
  final Moment moment;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final bool isPlaying;
  final VoidCallback onToggleAudio;

  const _MomentPageView({
    required this.moment,
    required this.onLike,
    required this.onComment,
    required this.isPlaying,
    required this.onToggleAudio,
  });

  @override
  State<_MomentPageView> createState() => _MomentPageViewState();
}

class _MomentPageViewState extends State<_MomentPageView> {
  bool _isCaptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const primaryRed = Color(0xFF9B111E);

    return Stack(
      children: [
        // Layer 1: Full bleed photo
        Positioned.fill(
          child: Hero(
            tag: 'moment_${widget.moment.id}',
            child: CachedNetworkImage(
              imageUrl: widget.moment.photoUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Event Chip on photo
        if (widget.moment.linkedEvent != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.white, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    widget.moment.linkedEvent!.title,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Layer 2: Gradient overlay (bottom only)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 320,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF1A1A1A).withOpacity(0.92),
                ],
              ),
            ),
          ),
        ),

        // Layer 3: Content overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 32 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mini now-playing bar
                if (widget.moment.trackName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.music_note_rounded, color: primaryRed, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "${widget.moment.trackName} · ${widget.moment.trackArtist}",
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onToggleAudio,
                          child: Icon(
                            widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                // C. Username row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: (widget.moment.userAvatarUrl != null && widget.moment.userAvatarUrl!.isNotEmpty)
                          ? NetworkImage(ApiConstants.fixMediaUrl(widget.moment.userAvatarUrl))
                          : null,
                      backgroundColor: Colors.white24,
                      child: (widget.moment.userAvatarUrl == null || widget.moment.userAvatarUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.moment.userName,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // Replacement: Using KXOStamp instead of the KXO box
                    KXOStamp(
                      userName: widget.moment.userName,
                      color: Colors.white.withOpacity(0.85),
                      size: 56,
                      rotateAngle: -0.12,
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // B. Caption
                GestureDetector(
                  onTap: () => setState(() => _isCaptionExpanded = !_isCaptionExpanded),
                  child: Text(
                    widget.moment.caption,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: _isCaptionExpanded ? null : 2,
                    overflow: _isCaptionExpanded ? null : TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),

                // A. Action row
                Row(
                  children: [
                    // Like
                    GestureDetector(
                      onTap: widget.onLike,
                      child: Row(
                        children: [
                          Icon(
                            widget.moment.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                            color: widget.moment.isLikedByMe ? primaryRed : Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.moment.likesCount}',
                            style: const TextStyle(fontFamily: 'DMSans', color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Comment
                    GestureDetector(
                      onTap: widget.onComment,
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.moment.commentsCount}',
                            style: const TextStyle(fontFamily: 'DMSans', color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Share
                    const Icon(Icons.ios_share, color: Colors.white, size: 22),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CinematicCommentsSheet extends StatefulWidget {
  final String momentId;
  const _CinematicCommentsSheet({required this.momentId});

  @override
  State<_CinematicCommentsSheet> createState() => _CinematicCommentsSheetState();
}

class _CinematicCommentsSheetState extends State<_CinematicCommentsSheet> {
  final _ctrl = TextEditingController();
  bool _sending = false;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await MomentService().getComments(widget.momentId);
      if (mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _post() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await MomentService().postComment(widget.momentId, text);
      _ctrl.clear();
      await _load();
      if (mounted) setState(() => _sending = false);
    } catch (e) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryRed = Color(0xFF9B111E);
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.5, 0.85],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Comments",
                    style: TextStyle(
                      fontFamily: 'CormorantGaramond',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Comment List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryRed))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final c = _comments[index];
                          final userPhoto = c['user_photo'] as String?;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: (userPhoto != null && userPhoto.isNotEmpty)
                                      ? NetworkImage(ApiConstants.fixMediaUrl(userPhoto))
                                      : null,
                                  backgroundColor: Colors.white10,
                                  child: (userPhoto == null || userPhoto.isEmpty)
                                      ? const Icon(Icons.person, size: 16, color: Colors.white38)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['user_name'] ?? 'User',
                                        style: const TextStyle(
                                          fontFamily: 'DMSans',
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        c['text'] ?? '',
                                        style: TextStyle(
                                          fontFamily: 'DMSans',
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              
              // Comment input bar
              Container(
                padding: EdgeInsets.fromLTRB(
                  16, 
                  10, 
                  16, 
                  10 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.person, size: 16, color: Colors.white38),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        style: const TextStyle(fontFamily: 'DMSans', color: Colors.white, fontSize: 13),
                        cursorColor: primaryRed,
                        decoration: InputDecoration(
                          hintText: "Add a comment...",
                          hintStyle: TextStyle(fontFamily: 'DMSans', color: Colors.white.withOpacity(0.4), fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded),
                      onPressed: _ctrl.text.trim().isEmpty || _sending ? null : _post,
                      color: _ctrl.text.trim().isEmpty 
                          ? Colors.white.withOpacity(0.3) 
                          : primaryRed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
