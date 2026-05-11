import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
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
        : (response['results'] ?? response['comments'] ?? []);
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

  Future<Moment> createMoment({
    required String caption,
    required String type,
    required File photo,
    String? location,
    int? linkedEventId,
    Map<String, String>? trackData,
  }) async {
    final token = await _api.getAccessToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/api/v1/moments/'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['caption'] = caption;
    request.fields['tag'] = type; // The API uses 'tag' based on Model mapping
    if (location != null) request.fields['location_name'] = location;
    if (linkedEventId != null) request.fields['linked_event'] = linkedEventId.toString();
    
    if (trackData != null) {
      request.fields['track_name'] = trackData['name'] ?? '';
      request.fields['track_artist'] = trackData['artist'] ?? '';
      request.fields['track_image_url'] = trackData['image_url'] ?? '';
      request.fields['track_preview_url'] = trackData['preview_url'] ?? '';
    }
    
    request.files.add(
      await http.MultipartFile.fromPath('photo', photo.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return Moment.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create moment: ${response.body}');
    }
  }
}
