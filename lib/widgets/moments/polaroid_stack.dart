import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/services/polaroid_video_composer.dart';
import 'package:kanairoxo/widgets/moments/network_media_preview.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/moment.dart';
import '../../services/api_client.dart';
import '../safe_network_image.dart';
import 'comments_bottom_sheet.dart';
import 'kxo_stamp.dart';

class PolaroidStack extends StatefulWidget {
  final List<Moment> moments;
  final Function(Moment) onTap;

  const PolaroidStack({
    super.key,
    required this.moments,
    required this.onTap,
  });

  @override
  State<PolaroidStack> createState() => _PolaroidStackState();
}

class _PolaroidStackState extends State<PolaroidStack>
    with TickerProviderStateMixin {
  int _visibleStartIndex = 0;
  double _dragOffset = 0;
  double _dragAngle = 0;
  bool _isExporting = false;  // true while snapshotting — hides action icons
  final GlobalKey _polaroidKey = GlobalKey();

  late AnimationController _dismissController;
  late Animation<double> _dismissOffset;
  late Animation<double> _dismissAngle;
  late Animation<double> _dismissOpacity;

  final Map<String, bool> _likedMap = {};
  final Map<String, int> _likesMap = {};
  final Map<String, bool> _savedMap = {};

  final List<double> _stackAngles = [
    0.02, 
    -0.06, 
    0.09, 
    -0.03, 
    0.05, 
  ];

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _dismissOffset = Tween<double>(begin: 0, end: 400).animate(
        CurvedAnimation(parent: _dismissController, curve: Curves.easeOut));
    _dismissAngle = Tween<double>(begin: 0, end: 0.3).animate(
        CurvedAnimation(parent: _dismissController, curve: Curves.easeOut));
    _dismissOpacity = Tween<double>(begin: 1, end: 0).animate(_dismissController);

    for (final m in widget.moments) {
      _likedMap[m.id] = m.isLiked;
      _likesMap[m.id] = m.likeCount;
      _savedMap[m.id] = m.isSaved;
    }
  }

  @override
  void dispose() {
    _dismissController.dispose();
    super.dispose();
  }

  List<Moment> get _visibleMoments {
    final all = widget.moments;
    if (all.isEmpty) return [];
    final start = _visibleStartIndex % all.length;
    final result = <Moment>[];
    for (int i = 0; i < 5 && i < all.length; i++) {
      result.add(all[(start + i) % all.length]);
    }
    return result.reversed.toList();
  }

  void _onDragStart(DragStartDetails _) {}

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      _dragAngle = _dragOffset * 0.004;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;

    if (_dragOffset.abs() > 80 || velocity.abs() > 300) {
      _animateDismiss();
    } else {
      setState(() {
        _dragOffset = 0;
        _dragAngle = 0;
      });
    }
  }

  Future<void> _animateDismiss() async {
    await _dismissController.forward();
    if (mounted) {
      setState(() {
        _visibleStartIndex = (_visibleStartIndex + 1) % widget.moments.length;
        _dragOffset = 0;
        _dragAngle = 0;
      });
      _dismissController.reset();
    }
  }

  Future<void> _toggleLike(String momentId) async {
    final wasLiked = _likedMap[momentId] ?? false;
    setState(() {
      _likedMap[momentId] = !wasLiked;
      _likesMap[momentId] = (_likesMap[momentId] ?? 0) + (wasLiked ? -1 : 1);
    });
    try {
      await ApiClient.instance.dio.post('/api/v1/moments/$momentId/like/', data: {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _likedMap[momentId] = wasLiked;
          _likesMap[momentId] = (_likesMap[momentId] ?? 0) + (wasLiked ? 1 : -1);
        });
      }
    }
  }

  Future<void> _toggleSave(String momentId) async {
    final wasSaved = _savedMap[momentId] ?? false;
    setState(() {
      _savedMap[momentId] = !wasSaved;
    });
    try {
      await ApiClient.instance.dio.post('/api/v1/moments/$momentId/save/', data: {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _savedMap[momentId] = wasSaved;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moments.isEmpty) {
      return _buildEmptyState();
    }

    final visible = _visibleMoments;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(children: [
      SizedBox(
          height: 380,
          child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                ...visible
                    .asMap()
                    .entries
                    .where((e) => e.key < visible.length - 1)
                    .map((entry) {
                  final stackPos = entry.key;
                  final moment = entry.value;
                  final angle = _stackAngles[stackPos % _stackAngles.length];
                  final offsetY = (visible.length - 1 - stackPos) * -3.0;

                  return Transform(
                      transform: Matrix4.identity()
                        ..rotateZ(angle)
                        ..translate(0.0, offsetY),
                      alignment: Alignment.center,
                      child: Opacity(
                          opacity: 0.7 + (stackPos / visible.length) * 0.3,
                          child: _PolaroidCard(
                              moment: moment,
                              isTop: false,
                              dragOffset: 0,
                              dragAngle: 0,
                              isLiked: _likedMap[moment.id] ?? false,
                              likeCount: _likesMap[moment.id] ?? 0,
                              isSaved: _savedMap[moment.id] ?? false,
                              onLike: () {},
                              onSave: () {},
                              onComment: () {})));
                }),

                if (visible.isNotEmpty)
                  AnimatedBuilder(
                      animation: _dismissController,
                      builder: (context, _) {
                        final isDismissing = _dismissController.isAnimating;
                        final offset = isDismissing
                            ? _dismissOffset.value * (_dragOffset >= 0 ? 1 : -1)
                            : _dragOffset;
                        final angle = isDismissing
                            ? _dismissAngle.value * (_dragOffset >= 0 ? 1 : -1)
                            : _dragAngle + _stackAngles[0];
                        final opacity =
                            isDismissing ? _dismissOpacity.value : 1.0;
                        final topMoment = visible.last;

                        return Opacity(opacity: opacity,
                            child: GestureDetector(
                                onHorizontalDragStart: _onDragStart,
                                onHorizontalDragUpdate: _onDragUpdate,
                                onHorizontalDragEnd: _onDragEnd,
                                onTap: () => widget.onTap(topMoment),
                                child: Transform(
                                    transform: Matrix4.identity()
                                      ..rotateZ(angle)
                                      ..translate(offset, 0.0),
                                    alignment: Alignment.center,
                                    child: RepaintBoundary(
                                      key: _polaroidKey,
                                      child: _PolaroidCard(
                                        moment: topMoment,
                                        isTop: true,
                                        dragOffset: offset,
                                        dragAngle: angle,
                                        isLiked: _likedMap[topMoment.id] ?? false,
                                        likeCount: _likesMap[topMoment.id] ?? 0,
                                        isSaved: _savedMap[topMoment.id] ?? false,
                                        exportMode: _isExporting,
                                        onLike: () => _toggleLike(topMoment.id),
                                        onSave: () => _toggleSave(topMoment.id),
                                        onComment: () => showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => CommentsBottomSheet(momentId: topMoment.id)),
                                      )))));
                      }),
              ])),

      const SizedBox(height: 16),
      
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionButton(
            icon: Icons.download_outlined,
            label: 'Save',
            onTap: visible.isNotEmpty ? () => _downloadPolaroid(visible.last) : null,
            isDark: isDark),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.ios_share_outlined,
            label: 'Share',
            onTap: visible.isNotEmpty ? () => _sharePolaroid(visible.last) : null,
            isDark: isDark),
        ]),

      const SizedBox(height: 8),
      Text('${widget.moments.length} moment${widget.moments.length == 1 ? '' : 's'}',
          style: GoogleFonts.caveat(fontSize: 13, color: AppColors.textMuted)),
    ]);
  }

  Widget _buildEmptyState() {
    return SizedBox(
        height: 280,
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.photo_library_outlined,
              size: 44, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text('No photos yet',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        ])));
  }

  Future<File?> _downloadRemoteFile(String url, String savePath) async {
    try {
      await Dio().download(url, savePath);
      return File(savePath);
    } catch (e) {
      debugPrint('Download remote file error: $e');
      return null;
    }
  }

  Future<void> _downloadPolaroid(Moment moment) async {
    void _toast(String msg, {bool isError = false}) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    }

    try {
      // 1. Snapshot the polaroid frame regardless of media type — that's the
      //    branded image users get. For videos, we ALSO save the raw video.
      final pngBytes = await _snapshotPolaroid();
      final dir = await getTemporaryDirectory();
      final pngFile = File('${dir.path}/KanairoXO_${moment.id}.png');
      await pngFile.writeAsBytes(pngBytes);

      // Permission check
      final ok = await Gal.hasAccess() || await Gal.requestAccess();
      if (!ok) {
        _toast('Allow gallery access to save', isError: true);
        return;
      }

      if (moment.mediaType != 'video') {
        await Gal.putImage(pngFile.path);
        _toast('Polaroid saved to gallery');
        return;
      }

      // Video moment — bake polaroid frame on the SERVER
      _toast('Wrapping video in polaroid…');
      final composedOut = '${dir.path}/KanairoXO_${moment.id}.mp4';
      final composed = await PolaroidVideoComposer.composeForMoment(
        momentId: moment.id, out: composedOut);

      if (composed) {
        await Gal.putVideo(composedOut);
        _toast('Polaroid video saved to gallery');
        return;
      }

      // Server compose failed — fall back: save raw video + polaroid PNG
      final url = moment.photoUrl.startsWith('http')
        ? moment.photoUrl
        : '${ApiConstants.baseUrl}/${moment.photoUrl.replaceAll(RegExp(r'^/'), '')}';
      final rawOut = '${dir.path}/KanairoXO_${moment.id}_raw.mp4';
      final rawFile = await _downloadRemoteFile(url, rawOut);
      if (rawFile != null) await Gal.putVideo(rawFile.path);
      await Gal.putImage(pngFile.path);
      _toast('Saved (server polaroid bake failed)', isError: true);
    } catch (e) {
      debugPrint('Download error: $e');
      _toast('Save failed: $e', isError: true);
    }
  }

  Future<Uint8List> _snapshotPolaroid() async {
    setState(() => _isExporting = true);
    // Wait two frames so the rebuild without actions is committed before capture
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    try {
      final boundary = _polaroidKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _sharePolaroid(Moment moment) async {
    try {
      final pngBytes = await _snapshotPolaroid();
      final dir = await getTemporaryDirectory();
      final pngFile = File('${dir.path}/kanairo_share.png');
      await pngFile.writeAsBytes(pngBytes);

      if (moment.mediaType != 'video') {
        await Share.shareXFiles([XFile(pngFile.path)],
          text: 'Shared from KanairoXO', subject: 'KanairoXO Moment');
        return;
      }

      // Video: bake polaroid frame on the server
      final composedOut = '${dir.path}/kanairo_share.mp4';
      final composed = await PolaroidVideoComposer.composeForMoment(
        momentId: moment.id, out: composedOut);

      if (composed) {
        await Share.shareXFiles([XFile(composedOut)],
          text: 'Shared from KanairoXO', subject: 'KanairoXO Moment');
        return;
      }

      // Fallback: share polaroid PNG only
      await Share.shareXFiles([XFile(pngFile.path)],
        text: 'Shared from KanairoXO', subject: 'KanairoXO Moment');
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;

  const _ActionButton({required this.icon, required this.label, this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1612) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2820) : Colors.grey.shade200)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isDark ? const Color(0xFF9A8F85) : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(label,
              style: AppTypography.caption.copyWith(
                color: isDark ? const Color(0xFF9A8F85) : AppColors.textMuted,
                fontWeight: FontWeight.w500)),
          ])));
  }
}

class _PolaroidCard extends StatelessWidget {
  final Moment moment;
  final bool isTop;
  final double dragOffset;
  final double dragAngle;
  final bool isLiked;
  final int likeCount;
  final bool isSaved;
  final bool exportMode; // when true, hide like/comment/save icons for clean snapshot
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;

  const _PolaroidCard({
    required this.moment,
    required this.isTop,
    required this.dragOffset,
    required this.dragAngle,
    required this.isLiked,
    required this.likeCount,
    required this.isSaved,
    required this.onLike,
    required this.onSave,
    required this.onComment,
    this.exportMode = false,
  });

  Color get _paperColor {
    final seed = moment.id.hashCode;
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
    return Container(
        width: 210,
        decoration: BoxDecoration(color: _paperColor, borderRadius: BorderRadius.circular(3), boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isTop ? 0.30 : 0.15),
              blurRadius: isTop ? 24 : 10,
              offset: Offset(isTop ? dragOffset * 0.05 : 0, isTop ? 10 : 5)),
          BoxShadow(
              color: Colors.white.withOpacity(0.9),
              blurRadius: 0,
              offset: const Offset(-1, -1)),
        ]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Stack(children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      width: 190, height: 190,
                      child: moment.photoUrl.isNotEmpty && moment.photoUrl.startsWith('http')
                        ? NetworkMediaPreview(
                            url: moment.photoUrl,
                            mediaType: moment.mediaType,
                            fit: BoxFit.cover,
                            autoPlay: true)
                        : _buildPhotoPlaceholder())),
                
                Positioned(
                    top: 8,
                    left: 8,
                    child: Transform.rotate(
                        angle: -0.15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.primary.withOpacity(0.7),
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.white.withOpacity(0.3)),
                          child: Text(moment.type.name.toUpperCase(),
                              style: GoogleFonts.caveat(
                                  fontSize: 9,
                                  color: AppColors.primary.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1)),
                        ))),
              ])),
          
          Container(
            width: 190,
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                top: -28,
                right: 0,
                child: KXOStamp(userName: moment.userName)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (moment.trackName != null && moment.trackName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        const Icon(Icons.music_note, size: 10, color: Color(0xFF1DB954)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(
                          '${moment.trackName} — ${moment.trackArtist ?? ''}',
                          style: AppTypography.caption.copyWith(color: const Color(0xFF1DB954), fontSize: 10),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                  Text(
                    moment.caption.isNotEmpty ? moment.caption : moment.type.name,
                    style: GoogleFonts.pacifico(
                      fontSize: 13,
                      color: const Color(0xFF2C2C2C),
                      height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    moment.userName,
                    style: GoogleFonts.caveat(fontSize: 11, color: const Color(0xFF555555))),
                  if (!exportMode) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      GestureDetector(
                        onTap: onLike,
                        child: Row(children: [
                          Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 14, color: isLiked ? AppColors.primary : AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text('$likeCount', style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textMuted)),
                        ])),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onComment,
                        child: Row(children: [
                          const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text('${moment.commentCount}', style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textMuted)),
                        ])),
                      const Spacer(),
                      GestureDetector(
                        onTap: onSave,
                        child: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border,
                          size: 14, color: isSaved ? AppColors.primary : AppColors.textMuted)),
                    ]),
                  ],
                ]),
            ])),
        ]));
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
        width: 190,
        height: 190,
        color: Colors.grey.shade200,
        child: const Center(
            child: Icon(Icons.image_outlined,
                color: Colors.grey, size: 36)));
  }
}
