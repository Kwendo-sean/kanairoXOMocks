import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Pushes the most-recent moment's still image to the iOS home-screen widget.
///
/// iOS widgets can only render static SwiftUI Images — no AVPlayer, no
/// real video. So for video moments we ship the server-extracted first-frame
/// thumbnail and let the Swift widget overlay a small play badge on it.
///
/// The image is written into the App Group container under a known filename
/// (`latest_moment.jpg`) that the widget extension reads on every timeline
/// refresh. The Flutter side also calls `updateWidget` to nudge WidgetKit so
/// the widget redraws within a few seconds instead of waiting for the next
/// budgeted refresh.
class HomeWidgetService {
  HomeWidgetService._();
  static final instance = HomeWidgetService._();

  static const _appGroupId = 'group.com.kanairoxo.kanairoxo';
  static const _iosWidgetName = 'KanairoMomentWidget';
  static const _androidWidgetName = 'KanairoMomentWidgetProvider';
  static const _imageKey = 'latest_moment_image_path';
  static const _captionKey = 'latest_moment_caption';
  static const _isVideoKey = 'latest_moment_is_video';

  bool _initialised = false;

  Future<void> _ensureInit() async {
    if (_initialised) return;
    await HomeWidget.setAppGroupId(_appGroupId);
    _initialised = true;
  }

  /// Call after the moments feed loads (or after a successful post).
  /// [moment] is the most recent moment map as returned by /api/v1/moments/.
  Future<void> updateFromMoment(Map<String, dynamic>? moment) async {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    if (moment == null) return;

    try {
      await _ensureInit();

      final mediaType = (moment['media_type'] ?? 'image').toString();
      final isVideo = mediaType == 'video';

      // For videos we want the server-extracted first frame so the widget
      // shows the photo with a play badge. Fall back to media_url for photos.
      String? imageUrl;
      if (isVideo) {
        imageUrl = (moment['thumbnail_url'] ?? '').toString();
        if (imageUrl.isEmpty) imageUrl = (moment['media_url'] ?? '').toString();
      } else {
        imageUrl = (moment['media_url'] ?? '').toString();
      }
      if (imageUrl == null || imageUrl.isEmpty) return;

      final localPath = await _downloadToAppGroup(imageUrl);
      if (localPath == null) return;

      await HomeWidget.saveWidgetData<String>(_imageKey, localPath);
      await HomeWidget.saveWidgetData<String>(
        _captionKey, (moment['caption'] ?? '').toString());
      await HomeWidget.saveWidgetData<bool>(_isVideoKey, isVideo);

      await HomeWidget.updateWidget(
        name: _androidWidgetName, iOSName: _iosWidgetName);
    } catch (e) {
      if (kDebugMode) debugPrint('HomeWidget update failed: $e');
    }
  }

  /// Downloads the image and writes it to the App Group container so the
  /// widget extension (which is a separate process) can read it.
  Future<String?> _downloadToAppGroup(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;

      // home_widget exposes the App Group directory on iOS; on Android it
      // writes to the regular shared prefs file location.
      final dir = await getApplicationDocumentsDirectory();
      final out = File(p.join(dir.path, 'latest_moment.jpg'));
      await out.writeAsBytes(res.bodyBytes);
      return out.path;
    } catch (e) {
      if (kDebugMode) debugPrint('download failed: $e');
      return null;
    }
  }
}
