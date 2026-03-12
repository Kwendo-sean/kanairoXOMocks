import 'package:flutter/foundation.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/models/couple_model.dart';
import 'package:kanairoxo/models/memory_model.dart';
import 'package:kanairoxo/models/user_model.dart';

class CoupleService {
  final ApiClient _api = ApiClient();

  /// Helper to safely parse dynamic data into a List
  List<dynamic> _ensureList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) {
      // If it's a paginated response, try to get 'results'
      if (data.containsKey('results') && data['results'] is List) {
        return data['results'];
      }
      // Otherwise fallback to values as requested
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
  Future<List<Memory>> getMemories({int? limit}) async {
    final queryParameters = <String, String>{};
    if (limit != null) queryParameters['limit'] = limit.toString();
    
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

  /// Get partner data
  Future<User?> fetchPartnerData(String coupleId) async {
    try {
      final response = await _api.get('/api/v1/couples/$coupleId/partner/');
      return User.fromJson(response);
    } catch (e) {
      debugPrint('Partner fetch error: $e');
      return null;
    }
  }

  /// Relationship Pulse
  Future<Map<String, dynamic>> getPulse(String coupleId) async {
    final response = await _api.get('api/v1/couples/$coupleId/pulse/');
    return response is Map<String, dynamic> ? response : {};
  }

  Future<void> submitPulse(String coupleId, int moodValue, {String note = ""}) async {
    await _api.post('api/v1/couples/$coupleId/pulse/', {
      'mood_value': moodValue,
      'note': note,
    });
  }

  /// Stats
  Future<Map<String, dynamic>> getStats(String coupleId) async {
    final response = await _api.get('api/v1/couples/$coupleId/stats/');
    return response is Map<String, dynamic> ? response : {};
  }

  /// Daily Prompt
  Future<Map<String, dynamic>> getDailyPrompt() async {
    final response = await _api.get('api/v1/couples/daily-prompt/');
    return response is Map<String, dynamic> ? response : {};
  }

  /// Music Sync
  Future<Map<String, dynamic>> getMusicSync(String coupleId) async {
    final response = await _api.get('api/v1/couples/$coupleId/music-sync/');
    return response is Map<String, dynamic> ? response : {};
  }

  /// Challenges
  Future<List<dynamic>> getChallenges(String coupleId) async {
    final response = await _api.get('api/v1/couples/$coupleId/challenges/');
    return _ensureList(response);
  }

  Future<void> completeChallenge(String coupleId, String challengeId) async {
    await _api.post('api/v1/couples/$coupleId/challenges/$challengeId/complete/', {});
  }

  /// Love Language Quiz
  Future<Map<String, dynamic>> getLoveLanguage(String userId) async {
    final response = await _api.get('api/v1/users/$userId/love-language/');
    return response is Map<String, dynamic> ? response : {};
  }

  Future<Map<String, dynamic>> submitLoveLanguage(String userId, Map<String, int> scores) async {
    return await _api.post('api/v1/users/$userId/love-language/', scores);
  }
}

/// Dashboard data model
class CouplesDashboard {
  final Couple couple;
  final DashboardStats stats;
  final int relationshipPulse;
  final PartnerInfo partner;
  final MusicSync? musicSync;
  final DailyPrompt? dailyPrompt;
  final List<dynamic> challenges;

  CouplesDashboard({
    required this.couple,
    required this.stats,
    required this.relationshipPulse,
    required this.partner,
    this.musicSync,
    this.dailyPrompt,
    this.challenges = const [],
  });

  factory CouplesDashboard.fromJson(Map<String, dynamic> json) {
    return CouplesDashboard(
      couple: Couple.fromJson(json['couple'] ?? {}),
      stats: DashboardStats.fromJson(json['stats'] ?? {}),
      relationshipPulse: (json['relationship_pulse'] as num?)?.toInt() ?? 50,
      partner: PartnerInfo.fromJson(json['partner'] ?? {}),
      musicSync: json['music_sync'] != null ? MusicSync.fromJson(json['music_sync']) : null,
      dailyPrompt: json['daily_prompt'] != null ? DailyPrompt.fromJson(json['daily_prompt']) : null,
      challenges: json['challenges'] is List ? json['challenges'] : [],
    );
  }
}

class DailyPrompt {
  final String id;
  final String text;
  final String category;

  DailyPrompt({required this.id, required this.text, required this.category});

  factory DailyPrompt.fromJson(Map<String, dynamic> json) {
    return DailyPrompt(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
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

class MusicSync {
  final List<String> sharedArtists;
  final List<String> overlappingGenres;
  final String coupleAnthem;

  MusicSync({
    required this.sharedArtists,
    required this.overlappingGenres,
    required this.coupleAnthem,
  });

  factory MusicSync.fromJson(Map<String, dynamic> json) {
    return MusicSync(
      sharedArtists: List<String>.from(json['shared_artists'] ?? []),
      overlappingGenres: List<String>.from(json['overlapping_genres'] ?? []),
      coupleAnthem: json['couple_anthem'] ?? '',
    );
  }
}
