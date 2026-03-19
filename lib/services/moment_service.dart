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

  Future<Moment> getMomentDetail(String id) async {
    final response = await _api.get('api/v1/moments/$id/');
    return Moment.fromJson(response);
  }

  Future<Map<String, dynamic>> toggleLike(String id) async {
    final response = await _api.post('api/v1/moments/$id/like/', {});
    return response; // Expected: { 'liked': bool, 'like_count': int }
  }

  Future<List<dynamic>> getComments(String id) async {
    final response = await _api.get('api/v1/moments/$id/comments/');
    return response is List ? response : (response['results'] ?? []);
  }

  Future<dynamic> addComment(String id, String text) async {
    return await _api.post('api/v1/moments/$id/comments/', {'text': text});
  }

  Future<Moment> createMoment({
    required String caption,
    required String type,
    required File photo,
    String? location,
  }) async {
    final token = await _api.getAccessToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/api/v1/moments/'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['caption'] = caption;
    request.fields['type'] = type;
    if (location != null) request.fields['location_name'] = location;
    
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
