import 'dart:io';
import 'dart:math' as math;
import 'dart:math' show cos, sin, pi;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/moment.dart';

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
  bool _isDragging = false;
  final GlobalKey _polaroidKey = GlobalKey();

  late AnimationController _dismissController;
  late Animation<double> _dismissOffset;
  late Animation<double> _dismissAngle;
  late Animation<double> _dismissOpacity;

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

  void _onDragStart(DragStartDetails _) {
    setState(() => _isDragging = true);
  }

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
        _isDragging = false;
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
        _isDragging = false;
      });
      _dismissController.reset();
    }
  }

  Future<void> _downloadPolaroid(Moment moment) async {
    try {
      final boundary = _polaroidKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/KanairoXO_${moment.id}.png');
      await file.writeAsBytes(pngBytes);

      await Gal.putImage(file.path);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved to gallery'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      }
    } catch (e) {
      debugPrint('Download error: $e');
    }
  }

  Future<void> _sharePolaroid(Moment moment) async {
    try {
      final boundary = _polaroidKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kanairo_share.png');
      await file.writeAsBytes(pngBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Shared from KanairoXO',
        subject: 'KanairoXO Moment');
        
    } catch (e) {
      debugPrint('Share error: $e');
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
          height: 340,
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
                              dragAngle: 0)));
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

                        return Opacity(
                            opacity: opacity,
                            child: GestureDetector(
                                onHorizontalDragStart: _onDragStart,
                                onHorizontalDragUpdate: _onDragUpdate,
                                onHorizontalDragEnd: _onDragEnd,
                                onTap: () => widget.onTap(visible.last),
                                child: Transform(
                                    transform: Matrix4.identity()
                                      ..rotateZ(angle)
                                      ..translate(offset, 0.0),
                                    alignment: Alignment.center,
                                    child: RepaintBoundary(
                                      key: _polaroidKey,
                                      child: _PolaroidCard(
                                        moment: visible.last,
                                        isTop: true,
                                        dragOffset: offset,
                                        dragAngle: angle)))));
                      }),

                if (!_isDragging)
                  Positioned(
                      bottom: 0,
                      child: Row(children: [
                        Icon(Icons.keyboard_arrow_left,
                            color: AppColors.textMuted.withOpacity(0.4),
                            size: 20),
                        const SizedBox(width: 4),
                        Text('swipe to explore',
                            style: GoogleFonts.caveat(
                                fontSize: 13,
                                color: AppColors.textMuted.withOpacity(0.6))),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_right,
                            color: AppColors.textMuted.withOpacity(0.4),
                            size: 20),
                      ])),
              ])),

      const SizedBox(height: 8),
      
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: visible.isNotEmpty
              ? () => _downloadPolaroid(visible.last)
              : null,
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
                  Icon(
                    Icons.download_outlined,
                    size: 14,
                    color: isDark ? const Color(0xFF9A8F85) : AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('Save',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? const Color(0xFF9A8F85) : AppColors.textMuted,
                      fontWeight: FontWeight.w500)),
                ]))),
          
          const SizedBox(width: 10),
          
          GestureDetector(
            onTap: visible.isNotEmpty
              ? () => _sharePolaroid(visible.last)
              : null,
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
                  Icon(
                    Icons.ios_share_outlined,
                    size: 14,
                    color: isDark ? const Color(0xFF9A8F85) : AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('Share',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? const Color(0xFF9A8F85) : AppColors.textMuted,
                      fontWeight: FontWeight.w500)),
                ]))),
        ]),

      const SizedBox(height: 8),
      Text('${widget.moments.length} moments',
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
}

class _PolaroidCard extends StatelessWidget {
  final Moment moment;
  final bool isTop;
  final double dragOffset;
  final double dragAngle;

  const _PolaroidCard({
    required this.moment,
    required this.isTop,
    required this.dragOffset,
    required this.dragAngle,
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

  Widget _buildKXOStamp(String userName) {
    final color = const Color(0xFF8B1A1A)
      .withOpacity(0.82);
    
    return Transform.rotate(
      angle: -0.10,
      child: SizedBox(
        width: 62, height: 62,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(62, 62),
              painter: KXOStampPainter(
                color: color)),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('KanairoXO',
                  style: GoogleFonts.dancingScript(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1.0)),
                Text('Moments',
                  style: GoogleFonts.dancingScript(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.5,
                    height: 1.2)),
                Container(
                  width: 28, height: 0.7,
                  margin: const EdgeInsets.symmetric(vertical: 1.5),
                  color: color.withOpacity(0.4)),
                Text(
                  userName.length > 7
                    ? userName.substring(0, 7)
                    : userName,
                  style: GoogleFonts.dancingScript(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.3)),
              ]),
          ])));
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
                    child: moment.photoUrl.isNotEmpty &&
                            moment.photoUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: moment.photoUrl,
                            width: 190,
                            height: 190,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _buildPhotoPlaceholder(),
                            placeholder: (_, __) => _buildPhotoLoading())
                        : _buildPhotoPlaceholder()),
                
                Positioned(
                    top: 8,
                    left: 8,
                    child: Transform.rotate(
                        angle: -0.15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
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
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 14),
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                top: -28,
                right: 0,
                child: _buildKXOStamp(
                  moment.userName.isNotEmpty
                    ? moment.userName.split(' ').first
                    : 'Unknown')),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    moment.caption.isNotEmpty
                      ? moment.caption
                      : moment.type.name.isNotEmpty
                        ? moment.type.name
                        : 'Untitled',
                    style: GoogleFonts.pacifico(
                      fontSize: 13,
                      color: const Color(0xFF2C2C2C),
                      height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(
                      moment.userName.isNotEmpty
                        ? moment.userName
                        : 'Unknown',
                      style: GoogleFonts.caveat(
                        fontSize: 11,
                        color: const Color(0xFF555555))),
                    const Spacer(),
                    Text(
                      _formatDate(moment.date),
                      style: GoogleFonts.dancingScript(
                        fontSize: 10,
                        color: const Color(0xFF888888),
                        fontWeight: FontWeight.w600)),
                  ]),
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

  Widget _buildPhotoLoading() {
    return Container(
        width: 190,
        height: 190,
        color: Colors.grey.shade100,
        child: const Center(
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: AppColors.primary)));
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class KXOStampPainter extends CustomPainter {
  final Color color;
  KXOStampPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    
    const dashCount = 32;
    final angleStep = (2 * pi) / dashCount;
    
    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * angleStep;
      final sweepAngle = i % 2 == 0 ? angleStep * 0.55 : angleStep * 0.35;
      final r = radius + (i % 3 == 0 ? 0.4 : -0.2);
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngle,
        sweepAngle,
        false,
        paint..color = color.withOpacity(i % 4 == 0 ? 0.5 : 0.82));
    }
    
    final starR = radius - 7;
    for (int i = 0; i < 6; i++) {
      final a = (i * 60 - 90) * pi / 180;
      final sx = center.dx + starR * cos(a);
      final sy = center.dy + starR * sin(a);
      _drawStar(canvas, Offset(sx, sy), 2.0,
        Paint()..color = color.withOpacity(0.7)..style = PaintingStyle.fill);
    }
  }
  
  void _drawStar(Canvas canvas, Offset c, double s, Paint p) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final a = i * pi / 2 - pi / 4;
      final ia = a + pi / 4;
      if (i == 0) {
        path.moveTo(c.dx + s * cos(a), c.dy + s * sin(a));
      } else {
        path.lineTo(c.dx + s * cos(a), c.dy + s * sin(a));
      }
      path.lineTo(c.dx + s * 0.4 * cos(ia), c.dy + s * 0.4 * sin(ia));
    }
    path.close();
    canvas.drawPath(path, p);
  }
  
  @override
  bool shouldRepaint(KXOStampPainter o) => o.color != color;
}
