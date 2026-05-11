import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/models/couple_model.dart';
import 'package:kanairoxo/models/memory_model.dart';

class CoupleService {
  final ApiClient _api = ApiClient();

  /// Helper to safely parse dynamic data into a List
  List<dynamic> _ensureList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) {
      if (data.containsKey('results') && data['results'] is List) {
        return data['results'];
      }
      return (data as Map<String, dynamic>).values.toList();
    }
    return [];
  }

  /// Get couple dashboard data
  Future<CouplesDashboard> getDashboard() async {
    final response = await _api.get('api/v1/couples/dashboard/');
    return CouplesDashboard.fromJson(response);
  }

  /// Get all memories for the couple
  Future<List<Memory>> getMemories({int? limit, String? type}) async {
    final queryParameters = <String, String>{};
    if (limit != null) queryParameters['limit'] = limit.toString();
    if (type != null && type != 'All') queryParameters['type'] = type.toLowerCase();
    
    final response = await _api.get('api/v1/couples/memories/', queryParameters: queryParameters);
    final list = _ensureList(response);
    return list.map((data) => Memory.fromJson(data)).toList();
  }

  /// Update couple details
  Future<Couple> updateCouple({
    String? coupleName,
    DateTime? anniversaryDate,
    String? relationshipStage,
  }) async {
    final response = await _api.patch('api/v1/couples/my-couple/', {
      if (coupleName != null) 'couple_name': coupleName,
      if (anniversaryDate != null)
        'anniversary_date': anniversaryDate.toIso8601String().split('T')[0],
      if (relationshipStage != null) 'relationship_stage': relationshipStage,
    });
    return Couple.fromJson(response);
  }

  /// Relationship Pulse / Check-in
  Future<Map<String, dynamic>> getPulse(String coupleId) async {
    final response = await _api.get('api/v1/couples/$coupleId/checkin/');
    return response is Map<String, dynamic> ? response : {};
  }

  Future<void> submitCheckIn(String coupleId, String mood) async {
    await _api.post('api/v1/couples/$coupleId/checkin/', {
      'mood': mood,
    });
  }

  /// Stats
  Future<Map<String, dynamic>> getStats(String coupleId) async {
    final response = await _api.get('api/v1/couples/$coupleId/stats/');
    return response is Map<String, dynamic> ? response : {};
  }

  /// Spotify
  Future<Map<String, dynamic>> getSpotifyPlaylist(String coupleId) async {
    final response = await _api.get('api/v1/couples/$coupleId/spotify/playlist/');
    return response is Map<String, dynamic> ? response : {};
  }

  Future<void> createSpotifyPlaylist(String coupleId) async {
    await _api.post('api/v1/couples/$coupleId/spotify/playlist/create/', {});
  }

  Future<Map<String, dynamic>?> getPartnerNowPlaying(String coupleId) async {
    try {
      final response = await _api.get('api/v1/couples/$coupleId/spotify/partner-now-playing/');
      return response is Map<String, dynamic> ? response : null;
    } catch (e) {
      return null;
    }
  }

  /// Notifications
  Future<List<dynamic>> getNotifications(String coupleId, {String? type}) async {
    final queryParameters = <String, String>{};
    if (type != null) queryParameters['type'] = type;
    final response = await _api.get('api/v1/couples/$coupleId/notifications/', queryParameters: queryParameters);
    return _ensureList(response);
  }

  Future<void> readAllNotifications(String coupleId) async {
    await _api.post('api/v1/couples/$coupleId/notifications/read-all/', {});
  }

  /// Appreciation
  Future<List<dynamic>> getAppreciations(String coupleId, {int? limit}) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    final response = await _api.get('api/v1/couples/$coupleId/appreciations/', queryParameters: queryParams);
    return _ensureList(response);
  }

  Future<void> sendAppreciation(String coupleId, String message) async {
    await _api.post('api/v1/couples/$coupleId/appreciations/', {
      'message': message,
    });
  }

  /// Spotify Dedication
  Future<void> dedicateSong(String coupleId, String trackName, String artist, String? note) async {
    await _api.post('api/v1/couples/$coupleId/spotify/dedicate/', {
      'track_name': trackName,
      'artist': artist,
      if (note != null) 'note': note,
    });
  }
  
  /// Date Jar / Spinning
  Future<Map<String, dynamic>> spinDateJar(String coupleId, {int? budgetMax, String? vibe, String? locationArea}) async {
    return await _api.post('api/v1/couples/$coupleId/dateideas/spin/', {
      if (budgetMax != null) 'budget_max': budgetMax,
      if (vibe != null) 'vibe': vibe,
      if (locationArea != null) 'location_area': locationArea,
    });
  }

  /// Messages
  Future<List<dynamic>> getMessages(String coupleId) async {
    final response = await _api.get('api/v1/couples/$coupleId/messages/');
    return _ensureList(response);
  }

  Future<void> sendMessage(String coupleId, String content) async {
    await _api.post('api/v1/couples/$coupleId/messages/', {
      'content': content,
    });
  }

  Future<void> thinkingOfYou(String coupleId) async {
    await _api.post('api/v1/couples/$coupleId/thinking-of-you/', {});
  }
}

/// Dashboard data model
class CouplesDashboard {
  final Couple couple;
  final DashboardStats stats;
  final int relationshipPulse;
  final PartnerInfo partner;

  CouplesDashboard({
    required this.couple,
    required this.stats,
    required this.relationshipPulse,
    required this.partner,
  });

  factory CouplesDashboard.fromJson(Map<String, dynamic> json) {
    return CouplesDashboard(
      couple: Couple.fromJson(json['couple'] ?? {}),
      stats: DashboardStats.fromJson(json['stats'] ?? {}),
      relationshipPulse: (json['relationship_pulse'] as num?)?.toInt() ?? 50,
      partner: PartnerInfo.fromJson(json['partner'] ?? {}),
    );
  }
}

class DashboardStats {
  final int memoryCount;
  final int checkinStreak;
  final int dateCount;
  final int aspirationCount;
  final int daysTogether;
  final int daysToAnniversary;

  DashboardStats({
    required this.memoryCount,
    required this.checkinStreak,
    required this.dateCount,
    required this.aspirationCount,
    required this.daysTogether,
    required this.daysToAnniversary,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      memoryCount: (json['memory_count'] ?? json['memories_count']) ?? 0,
      checkinStreak: (json['checkin_streak'] ?? json['check_in_streak']) ?? 0,
      dateCount: (json['date_count'] ?? json['dates_planned']) ?? 0,
      aspirationCount: json['aspiration_count'] ?? 0,
      daysTogether: json['days_together'] ?? 0,
      daysToAnniversary: json['days_to_anniversary'] ?? 0,
    );
  }
}

class PartnerInfo {
  final String id;
  final String name;
  final String? photoUrl;

  PartnerInfo({
    required this.id,
    required this.name,
    this.photoUrl,
  });

  factory PartnerInfo.fromJson(Map<String, dynamic> json) {
    return PartnerInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      photoUrl: json['profile_photo'],
    );
  }
}
