import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/models/couple_model.dart';
import 'package:kanairoxo/models/memory_model.dart';

class CoupleService {
  final ApiClient _api = ApiClient();

  /// Get couple dashboard data
  Future<CouplesDashboard> getDashboard() async {
    final response = await _api.get('api/v1/couples/dashboard/');
    return CouplesDashboard.fromJson(response);
  }

  /// Get all memories for the couple
  Future<List<Memory>> getMemories() async {
    final response = await _api.get('api/memories/');
    return (response as List).map((data) => Memory.fromJson(data)).toList();
  }

  /// Update couple details (name, anniversary, stage)
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

  /// Get couple preferences
  Future<CouplePreference> getPreferences() async {
    final response = await _api.get('api/v1/couples/preferences/');
    return CouplePreference.fromJson(response);
  }

  /// Update couple preferences
  Future<CouplePreference> updatePreferences(
      Map<String, dynamic> preferences) async {
    final response = await _api.patch(
      'api/v1/couples/preferences/',
      preferences,
    );
    return CouplePreference.fromJson(response);
  }
}

/// Dashboard data model
class CouplesDashboard {
  final Couple couple;
  final DashboardStats stats;
  final int relationshipPulse;
  final PartnerInfo partner;
  final MusicSync? musicSync;

  CouplesDashboard({
    required this.couple,
    required this.stats,
    required this.relationshipPulse,
    required this.partner,
    this.musicSync,
  });

  factory CouplesDashboard.fromJson(Map<String, dynamic> json) {
    return CouplesDashboard(
      couple: Couple.fromJson(json['couple']),
      stats: DashboardStats.fromJson(json['stats']),
      relationshipPulse: json['relationship_pulse'] ?? 50,
      partner: PartnerInfo.fromJson(json['partner']),
      musicSync: json['music_sync'] != null ? MusicSync.fromJson(json['music_sync']) : null,
    );
  }
}

class DashboardStats {
  final int memoryCount;
  final int checkinStreak;
  final int dateCount;
  final int aspirationCount;

  DashboardStats({
    required this.memoryCount,
    required this.checkinStreak,
    required this.dateCount,
    required this.aspirationCount,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      memoryCount: json['memory_count'] ?? 0,
      checkinStreak: json['checkin_streak'] ?? 0,
      dateCount: json['date_count'] ?? 0,
      aspirationCount: json['aspiration_count'] ?? 0,
    );
  }
}

class PartnerInfo {
  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phoneNumber;

  PartnerInfo({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phoneNumber,
  });

  factory PartnerInfo.fromJson(Map<String, dynamic> json) {
    return PartnerInfo(
      id: json['id'].toString(),
      name: json['name'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'],
      phoneNumber: json['phone_number'],
    );
  }
}

class CouplePreference {
  final int loveLanguageWords;
  final int loveLanguageTime;
  final int loveLanguageGifts;
  final int loveLanguageService;
  final int loveLanguageTouch;
  final bool notifyDailyCheckin;
  final bool notifyNewMemory;
  final bool notifyDateReminder;

  CouplePreference({
    this.loveLanguageWords = 0,
    this.loveLanguageTime = 0,
    this.loveLanguageGifts = 0,
    this.loveLanguageService = 0,
    this.loveLanguageTouch = 0,
    this.notifyDailyCheckin = true,
    this.notifyNewMemory = true,
    this.notifyDateReminder = true,
  });

  factory CouplePreference.fromJson(Map<String, dynamic> json) {
    return CouplePreference(
      loveLanguageWords: json['love_language_words'] ?? 0,
      loveLanguageTime: json['love_language_time'] ?? 0,
      loveLanguageGifts: json['love_language_gifts'] ?? 0,
      loveLanguageService: json['love_language_service'] ?? 0,
      loveLanguageTouch: json['love_language_touch'] ?? 0,
      notifyDailyCheckin: json['notify_daily_checkin'] ?? true,
      notifyNewMemory: json['notify_new_memory'] ?? true,
      notifyDateReminder: json['notify_date_reminder'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'love_language_words': loveLanguageWords,
      'love_language_time': loveLanguageTime,
      'love_language_gifts': loveLanguageGifts,
      'love_language_service': loveLanguageService,
      'love_language_touch': loveLanguageTouch,
      'notify_daily_checkin': notifyDailyCheckin,
      'notify_new_memory': notifyNewMemory,
      'notify_date_reminder': notifyDateReminder,
    };
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
      sharedArtists: List<String>.from(json['shared_artists']),
      overlappingGenres: List<String>.from(json['overlapping_genres']),
      coupleAnthem: json['couple_anthem'],
    );
  }
}
