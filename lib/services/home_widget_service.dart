import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'package:path/path.dart' as p;
import '../models/data_models.dart';

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
  static const _upcomingEventsKey = 'upcoming_events_json';
  static const _userNameKey = 'latest_moment_user_name';

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
      await HomeWidget.saveWidgetData<String>(
        _userNameKey, (moment['user_name'] ?? moment['username'] ?? '').toString());

      await HomeWidget.updateWidget(
        name: _androidWidgetName, iOSName: _iosWidgetName);
    } catch (e) {
      if (kDebugMode) debugPrint('HomeWidget update failed: $e');
    }
  }

  /// Call after the events feed loads. Pushes the soonest few upcoming
  /// experiences (future `startDateTime`) to the medium-sized widget, which
  /// renders them as a compact agenda instead of the latest-moment polaroid.
  Future<void> updateFromUpcomingEvents(List<Experience> events) async {
    if (!Platform.isIOS && !Platform.isAndroid) return;

    try {
      await _ensureInit();

      final upcoming = events.where((e) => e.isUpcoming).toList()
        ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

      final payload = upcoming
          .take(3)
          .map((e) => {
                'title': e.title,
                'venue': e.venueName,
                'startDate': e.startDateTime.millisecondsSinceEpoch / 1000,
              })
          .toList();

      await HomeWidget.saveWidgetData<String>(
          _upcomingEventsKey, jsonEncode(payload));
      await HomeWidget.updateWidget(
        name: _androidWidgetName, iOSName: _iosWidgetName);
    } catch (e) {
      if (kDebugMode) debugPrint('HomeWidget upcoming-events update failed: $e');
    }
  }

  /// Downloads the image and writes it to the App Group container so the
  /// widget extension (which runs as a separate, separately-sandboxed
  /// process) can read it. The app's own Documents directory is NOT visible
  /// to the extension — only files placed in the shared App Group container
  /// are.
  Future<String?> _downloadToAppGroup(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;

      final dirPath = await _sharedContainerPath();
      if (dirPath == null) return null;

      final out = File(p.join(dirPath, 'latest_moment.jpg'));
      await out.parent.create(recursive: true);
      await out.writeAsBytes(res.bodyBytes);
      return out.path;
    } catch (e) {
      if (kDebugMode) debugPrint('download failed: $e');
      return null;
    }
  }

  /// On iOS this is the shared App Group container (the only place both the
  /// app and the widget extension can read/write). Android widgets run in
  /// the same process/sandbox as the app, so the regular documents directory
  /// is fine there.
  Future<String?> _sharedContainerPath() async {
    if (Platform.isIOS) {
      return PathProviderFoundation()
          .getContainerPath(appGroupIdentifier: _appGroupId);
    }
    return (await getApplicationDocumentsDirectory()).path;
  }
}
