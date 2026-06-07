import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:kanairoxo/services/api_client.dart';

class CommunitiesService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> mine() async {
    final res = await _api.get('api/v1/communities/');
    final List items = (res is Map ? (res['results'] ?? []) : (res ?? [])) as List;
    return items.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<Map<String, dynamic>> create({
    required String name,
    String description = '',
    int maxMembers = 20,
    File? cover,
  }) async {
    final fields = <String, dynamic>{
      'name': name,
      'description': description,
      'max_members': maxMembers.toString(),
    };
    if (cover != null) {
      fields['cover_image'] = await dio.MultipartFile.fromFile(cover.path,
        filename: cover.path.split(Platform.pathSeparator).last);
    }
    final form = dio.FormData.fromMap(fields);
    final r = await ApiClient.instance.dio.post(
      '/api/v1/communities/',
      data: form,
      options: dio.Options(contentType: 'multipart/form-data'));
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<Map<String, dynamic>> detail(String id) async {
    final res = await _api.get('api/v1/communities/$id/');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<List<Map<String, dynamic>>> members(String id) async {
    final res = await _api.get('api/v1/communities/$id/members/');
    final List items = (res is Map ? (res['results'] ?? []) : []) as List;
    return items.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<List<Map<String, dynamic>>> messages(String id) async {
    final res = await _api.get('api/v1/communities/$id/messages/');
    final List items = (res is Map ? (res['results'] ?? []) : []) as List;
    return items.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<Map<String, dynamic>> send(String id, String body) async {
    final res = await _api.post('api/v1/communities/$id/messages/', {'body': body});
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> previewInvite(String code) async {
    final res = await _api.get('api/v1/communities/invite/$code/preview/');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> joinByCode(String code) async {
    final res = await _api.post('api/v1/communities/invite/$code/join/', {});
    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> leave(String id) async {
    await _api.post('api/v1/communities/$id/leave/', {});
  }

  Future<void> deleteCommunity(String id) async {
    await _api.delete('api/v1/communities/$id/');
  }

  Future<Map<String, dynamic>> regenerateInvite(String id) async {
    final res = await _api.post('api/v1/communities/$id/regenerate-invite/', {});
    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> inviteToEvent(String id, String eventId, {String? note}) async {
    await _api.post('api/v1/communities/$id/invite-to-event/', {
      'event_id': eventId, if (note != null) 'note': note,
    });
  }
}
