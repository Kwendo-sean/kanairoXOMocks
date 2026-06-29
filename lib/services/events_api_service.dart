import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio_lib;
import '../models/data_models.dart';
import 'api_client.dart';

class EventsApiService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, List<Experience>>> fetchEventFeed() async {
    try {
      final response = await _apiClient.get('api/v1/events/feed/');
      
      final Map<String, List<Experience>> feed = {};
      
      if (response is Map) {
        response.forEach((key, value) {
          if (value is List) {
            feed[key] = value.map((e) => Experience.fromJson(e)).toList();
          }
        });
      }
      
      return feed;
    } catch (e) {
      debugPrint('Event feed load error: $e');
      rethrow;
    }
  }

  // ITEM 2: Use new endpoint /api/v1/events/search/
  Future<List<Experience>> searchEvents(String query) async {
    try {
      final response = await _apiClient.get('api/v1/events/search/', queryParameters: {'q': query});
      List<dynamic> list = [];
      if (response is Map && response['results'] != null) {
        list = response['results'] as List;
      } else if (response is List) {
        list = response;
      }
      return list.map((e) => Experience.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Search error: $e');
      return [];
    }
  }

  Future<List<Experience>> fetchSavedEvents() async {
    try {
      final response = await _apiClient.get('api/v1/events/saved/');
      List<dynamic> list = [];
      if (response is List) {
        list = response;
      } else if (response is Map) {
        list = response['results'] ?? response['events'] ?? [];
      }
      return list.map((e) => Experience.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Saved events load error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> toggleSave(String experienceId) async {
    return await _apiClient.post('api/v1/events/$experienceId/save/', {});
  }

  // Legacy/Other methods kept for compatibility if needed
  Future<Experience> fetchExperienceDetail(String id) async {
    final response = await _apiClient.get('api/v1/events/$id/');
    return Experience.fromJson(response);
  }

  Future<Map<String, dynamic>> registerForExperience({
    required String experienceId,
    int? pricingTierId,
    int numberOfGuests = 0,
    String? notes,
  }) async {
    final body = {
      if (pricingTierId != null) 'pricing_tier': pricingTierId,
      'number_of_guests': numberOfGuests,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    return await _apiClient.post('api/v1/events/$experienceId/register/', body);
  }

  Future<Map<String, dynamic>> joinWaitlist(String experienceId) async {
    return await _apiClient.post('api/v1/events/$experienceId/join-waitlist/', {});
  }

  /// Resolve a kanairoxo.online/e/<short> code into the full event UUID.
  ///
  /// The backend serves the short URL as a 302 to /event/<full uuid>/.
  /// We hit it with followRedirects=false and read the canonical UUID
  /// out of the Location header. Returns null if the short doesn't
  /// match a visible event.
  Future<String?> resolveShortEventCode(String shortCode) async {
    try {
      final response = await _apiClient.dio.get(
        'https://kanairoxo.online/e/$shortCode',
        options: dio_lib.Options(
          followRedirects: false,
          validateStatus: (s) => s != null && (s == 302 || s == 200 || s == 404),
        ),
      );
      final location = response.headers.value('location') ?? '';
      final match = RegExp(r'/event/([0-9a-fA-F-]{36})/').firstMatch(location);
      return match?.group(1);
    } catch (e) {
      debugPrint('resolveShortEventCode failed for $shortCode: $e');
      return null;
    }
  }

  /// GET /api/v1/events/<id>/memories/  — moments tagged to this event.
  Future<List<Map<String, dynamic>>> fetchEventMemories(String eventId) async {
    final response = await _apiClient.get('api/v1/events/$eventId/memories/');
    final raw = (response is Map ? response['results'] : response) ?? [];
    if (raw is List) {
      return raw.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ─── Invite friends + going-with-me ─────────────────────────────────

  Future<Map<String, dynamic>> inviteFriends({
    required String eventId,
    required List<Map<String, String>> recipients,
    String message = '',
  }) async {
    return await _apiClient.post(
      'api/v1/events/$eventId/invite/',
      {'recipients': recipients, 'message': message},
    );
  }

  Future<Map<String, dynamic>> goingWithMe(String eventId) async {
    final response = await _apiClient.get('api/v1/events/$eventId/going-with-me/');
    return response is Map ? Map<String, dynamic>.from(response) : {};
  }

  // ─── URL helpers for embedding backend-rendered assets ──────────────

  /// GET /api/v1/events/<id>/calendar.ics — used by url_launcher to
  /// fire the system "add to calendar" handler.
  String calendarIcsUrl(String eventId) {
    final base = _apiClient.dio.options.baseUrl;
    return '${base}api/v1/events/$eventId/calendar.ics';
  }

  /// Branded share-card image URL. Three formats: story / square / post.
  String shareCardUrl(String eventId, {String format = 'story'}) {
    final base = _apiClient.dio.options.baseUrl;
    return '${base}api/v1/events/$eventId/share-card.png?format=$format';
  }
}
