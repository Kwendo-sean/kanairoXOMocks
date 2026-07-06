import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/core/theme/app_icons.dart';
import 'package:kanairoxo/models/profile_model.dart';

/// Full-screen viewer for personal gallery photos.
///
/// Deliberately minimal — a gallery is not a social feed, so there
/// are no like / comment / share buttons here. Just the photo,
/// pinch-zoom, swipe between photos, a counter, and (when viewing
/// your own gallery) a delete action.
///
/// This mirrors how photos read on the discover profile view: clean,
/// full-bleed, chrome fades out of the way.
class GalleryViewerScreen extends StatefulWidget {
  final List<GalleryPhotoModel> photos;
  final int initialIndex;

  /// Non-null when viewing your OWN gallery — enables the delete
  /// action. Callback removes the photo server-side; the viewer pops
  /// if the gallery empties.
  final Future<void> Function(GalleryPhotoModel photo)? onDelete;

  const GalleryViewerScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
    this.onDelete,
  });

  @override
  State<GalleryViewerScreen> createState() => _GalleryViewerScreenState();
}

class _GalleryViewerScreenState extends State<GalleryViewerScreen> {
  late final PageController _controller;
  late List<GalleryPhotoModel> _photos;
  late int _index;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _photos = List.of(widget.photos);
    _index = widget.initialIndex.clamp(0, _photos.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final photo = _photos[_index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete photo?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This removes it from your gallery permanently.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE0708C))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.onDelete?.call(photo);
      if (!mounted) return;
      setState(() {
        _photos.removeAt(_index);
        if (_photos.isEmpty) {
          Navigator.pop(context);
          return;
        }
        _index = _index.clamp(0, _photos.length - 1);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete photo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          // Photo pager — tap toggles chrome, pinch zooms
          PageView.builder(
            controller: _controller,
            itemCount: _photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final url = _photos[i].imageUrl;
              return GestureDetector(
                onTap: () => setState(() => _chromeVisible = !_chromeVisible),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: url.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white24, strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) => PhosphorIcon(
                              AppIcons.gallery,
                              color: Colors.white24, size: 48),
                          )
                        : PhosphorIcon(AppIcons.gallery,
                            color: Colors.white24, size: 48),
                  ),
                ),
              );
            },
          ),

          // Top chrome — close, counter, delete (own gallery only)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _chromeVisible ? 1 : 0,
            child: IgnorePointer(
              ignoring: !_chromeVisible,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 6,
                  left: 8, right: 8, bottom: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                  ),
                ),
                child: Row(children: [
                  IconButton(
                    icon: PhosphorIcon(AppIcons.close, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    '${_index + 1} of ${_photos.length}',
                    style: const TextStyle(
                      color: Colors.white70, fontSize: 13,
                      fontFamily: 'DMSans', fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: PhosphorIcon(AppIcons.delete, color: Colors.white, size: 20),
                      onPressed: _confirmDelete,
                    )
                  else
                    const SizedBox(width: 48),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
