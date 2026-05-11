import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../models/moment.dart';

class WidgetService {
  static Future<void> updateMomentsWidget(List<Moment> moments) async {
    try {
      final withPhotos = moments
          .where((m) =>
              m.photoUrl.isNotEmpty &&
              m.photoUrl.startsWith('http'))
          .toList();

      if (withPhotos.isNotEmpty) {
        final latest = withPhotos.first;
        final url = latest.photoUrl;

        try {
          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            final decoded = img.decodeImage(response.bodyBytes);
            if (decoded != null) {
              final resized = img.copyResize(
                decoded,
                width: 600,
                height: 600,
                interpolation: img.Interpolation.linear);
              
              final compressed = img.encodeJpg(resized, quality: 85);
              
              final dir = await getApplicationDocumentsDirectory();
              final file = File('${dir.path}/widget_moment_0.jpg');
              await file.writeAsBytes(compressed);

              await HomeWidget.saveWidgetData<String>('moment_photo_0', file.path);
              
              final caption = latest.caption.isNotEmpty
                  ? latest.caption
                  : latest.type.name.isNotEmpty
                      ? latest.type.name
                      : 'Moment';
              await HomeWidget.saveWidgetData<String>('moment_caption_0', caption);
            }
          }
        } catch (e) {
          debugPrint('Widget photo error: $e');
          await HomeWidget.saveWidgetData<String>('moment_photo_0', '');
        }
      } else {
        await HomeWidget.saveWidgetData<String>('moment_photo_0', '');
        await HomeWidget.saveWidgetData<String>('moment_caption_0', '');
      }

      await HomeWidget.updateWidget(
          androidName: 'MomentsWidgetProvider', iOSName: 'MomentsWidget');
    } catch (e) {
      debugPrint('Moments widget error: $e');
    }
  }

  static Future<void> updateDropWidget({
    required int secondsUntilDrop,
    required bool isLive,
    String? dropTitle,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('seconds_until_drop', secondsUntilDrop);
      await HomeWidget.saveWidgetData<bool>('is_live', isLive);
      await HomeWidget.saveWidgetData<String>(
          'drop_title', dropTitle ?? 'This Week in Nairobi');

      final h = secondsUntilDrop ~/ 3600;
      final m = (secondsUntilDrop % 3600) ~/ 60;
      final s = secondsUntilDrop % 60;
      final formatted = isLive
          ? 'LIVE NOW'
          : '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

      await HomeWidget.saveWidgetData<String>('countdown_text', formatted);

      await HomeWidget.updateWidget(
          androidName: 'DropWidgetProvider', iOSName: 'DropWidget');
    } catch (e) {
      debugPrint('Drop widget error: $e');
    }
  }

  static Future<void> updateActivityWidget({
    required int connections,
    required int notifications,
    required int newMoments,
  }) async {
    try {
      await HomeWidget.saveWidgetData('connections_count', connections);
      await HomeWidget.saveWidgetData('notifications_count', notifications);
      await HomeWidget.saveWidgetData('moments_count', newMoments);
      await HomeWidget.updateWidget(
          androidName: 'ActivityWidgetProvider', iOSName: 'ActivityWidget');
    } catch (e) {
      debugPrint('Activity widget error: $e');
    }
  }

  static Future<void> refreshAllWidgets(
      List<Moment> moments, int unreadNotifs, int newConnections) async {
    await updateMomentsWidget(moments);
    await updateActivityWidget(
        connections: newConnections,
        notifications: unreadNotifs,
        newMoments: moments.take(24).length);
  }
}
