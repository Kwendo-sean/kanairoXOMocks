import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'dart:convert';

class MomentService {
  final ApiClient _api = ApiClient();

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
    required File photo, // First/main media
    String? location,
    int? linkedEventId,
    Map<String, String>? trackData,
    String? visibility,
  }) async {
    final formData = dio.FormData.fromMap({
      'caption': caption,
      'tag': type,
      'location_name': location,
      'linked_event': linkedEventId,
      'visibility': visibility?.toLowerCase(),
      'photo': await dio.MultipartFile.fromFile(photo.path),
    });

    if (trackData != null) {
      formData.fields.addAll([
        dio.MapEntry('track_name', trackData['name'] ?? ''),
        dio.MapEntry('track_artist', trackData['artist'] ?? ''),
        dio.MapEntry('track_image_url', trackData['image_url'] ?? ''),
        dio.MapEntry('track_preview_url', trackData['preview_url'] ?? ''),
      ]);
    }

    final response = await _api.post('api/v1/moments/', formData);
    return Moment.fromJson(response);
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
    await _api.post('api/v1/moments/$momentId/media/', formData);
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
