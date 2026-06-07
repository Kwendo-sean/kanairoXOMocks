import 'dart:io';
import 'package:dio/dio.dart';
import 'package:kanairoxo/services/api_client.dart';

/// Talks to the server-side polaroid video baker.
/// 1. GET /api/v1/moments/<id>/polaroid-video/  → returns URL of baked MP4
/// 2. Downloads that MP4 to [out]
/// 3. Returns true on success
class PolaroidVideoComposer {
  static Future<bool> composeForMoment({
    required String momentId,
    required String out,
  }) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/api/v1/moments/$momentId/polaroid-video/',
        queryParameters: {'refresh': '1'});
      final url = res.data is Map ? res.data['url'] as String? : null;
      if (url == null) return false;

      await Dio().download(url, out);
      return File(out).existsSync() && await File(out).length() > 0;
    } catch (_) {
      return false;
    }
  }
}
