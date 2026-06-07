import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'dart:io';
import 'package:dio/dio.dart' as dio;

class MomentService {
  final ApiClient _api = ApiClient();

  Future<void> deleteMoment(String id) async {
    await _api.delete('api/v1/moments/$id/');
  }


  Future<List<Moment>> getMoments({String? type}) async {
    final queryParams = type != null ? {'type': type} : <String, String>{};
    final response = await _api.get('api/v1/moments/', queryParameters: queryParams);
    
    final List data = response is List 
        ? response 
        : (response['results'] ?? []);
        
    return data.map((json) => Moment.fromJson(json)).toList();
  }

  Future<List<Moment>> getSavedMoments() async {
    final response = await _api.get('api/v1/moments/saved/');
    List list = [];
    if (response is List) {
      list = response;
    } else if (response is Map) {
      list = response['results'] ?? response['saved_moments'] ?? [];
    }
    return list.map((m) {
      final momentData = (m is Map && m.containsKey('moment')) ? m['moment'] : m;
      return Moment.fromJson(momentData as Map<String, dynamic>);
    }).toList();
  }

  Future<Moment> getMomentDetail(String id) async {
    final response = await _api.get('api/v1/moments/$id/');
    return Moment.fromJson(response);
  }

  Future<Map<String, dynamic>> toggleLike(String id) async {
    final response = await _api.post('api/v1/moments/$id/like/', {});
    return response;
  }

  Future<Map<String, dynamic>> toggleSave(String id) async {
    final response = await _api.post('api/v1/moments/$id/save/', {});
    return response;
  }

  Future<List<dynamic>> getComments(String id) async {
    final response = await _api.get('api/v1/moments/$id/comments/');
    final List list = response is List 
        ? response 
        : (response['results'] ?? []);
    return list;
  }

  Future<dynamic> addComment(String id, String text) async {
    return await _api.post('api/v1/moments/$id/comments/', {'text': text});
  }

  Future<dynamic> postComment(String id, String text) => addComment(id, text);

  Future<List<LinkedEvent>> getLinkableEvents() async {
    try {
      final response = await _api.get('api/v1/moments/linkable-events/');
      final List data = response is List ? response : (response['results'] ?? []);
      return data.map((e) => LinkedEvent.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // --- NEW ENDPOINTS FOR ROLLOUT ---

  Future<Moment> createMoment({
    required String caption,
    required String type,
    required File photo, // First/main media (image or video file)
    String mediaType = 'image', // 'image' | 'video'
    String? location,
    int? linkedEventId,
    Map<String, String>? trackData,
    String? visibility,
    String filterId = 'none',
    double trimStart = 0,
    double trimDuration = 0,
  }) async {
    final fileName = photo.path.split(Platform.pathSeparator).last;
    final upload = await dio.MultipartFile.fromFile(photo.path, filename: fileName);

    final formData = dio.FormData.fromMap({
      'caption': caption,
      'type': type,
      'media_type': mediaType,
      'location_string': location ?? '',
      if (linkedEventId != null) 'linked_event': linkedEventId,
      'is_public': (visibility == null || visibility.toLowerCase() == 'public') ? 'true' : 'false',
      'visibility': (visibility == null || visibility.toLowerCase() == 'public') ? 'public' : 'connections',
      'filter': filterId,
      if (mediaType == 'video' && trimDuration > 0) ...{
        'trim_start': trimStart.toStringAsFixed(3),
        'trim_duration': trimDuration.toStringAsFixed(3),
      },
      // Use 'video' field for videos, 'photo' for images. Backend routes both to raw_upload.
      if (mediaType == 'video') 'video': upload else 'photo': upload,
    });

    if (trackData != null) {
      formData.fields.addAll([
        MapEntry('track_name', trackData['name'] ?? ''),
        MapEntry('track_artist', trackData['artist'] ?? ''),
        MapEntry('track_image_url', trackData['image_url'] ?? ''),
        MapEntry('track_preview_url', trackData['preview_url'] ?? ''),
      ]);
    }

    final response = await ApiClient.instance.dio.post(
      'api/v1/moments/',
      data: formData,
      options: dio.Options(contentType: 'multipart/form-data'),
    );
    return Moment.fromJson(response.data);
  }

  Future<void> attachMedia({
    required String momentId,
    required File file,
    required String mediaType,
    required int position,
    int? durationMs,
  }) async {
    final formData = dio.FormData.fromMap({
      'file': await dio.MultipartFile.fromFile(file.path),
      'media_type': mediaType,
      'position': position,
      'duration_ms': durationMs,
    });
    
    await ApiClient.instance.dio.post(
      'api/v1/moments/$momentId/media/',
      data: formData,
      options: dio.Options(contentType: 'multipart/form-data'),
    );
  }

  Future<void> saveDraft(Map<String, dynamic> payload) async {
    await _api.post('api/v1/moments/drafts/', payload);
  }

  Future<void> scheduleMoment(DateTime publishAt, Map<String, dynamic> payload) async {
    await _api.post('api/v1/moments/schedule/', {
      'publish_at': publishAt.toIso8601String(),
      'payload': payload,
    });
  }
}
