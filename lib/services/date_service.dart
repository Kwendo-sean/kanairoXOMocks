import 'package:kanairoxo/models/date_model.dart';
import 'package:kanairoxo/services/api_client.dart';

class DateService {
  final ApiClient _api = ApiClient();

  Future<List<DateNight>> getUpcomingDates() async {
    final response = await _api.get('api/v1/couples/dates/upcoming/');
    final list = response is List ? response : [];
    return list.map((data) => DateNight.fromJson(data)).toList();
  }

  Future<List<DateNight>> getPastDates() async {
    final response = await _api.get('api/v1/couples/dates/past/');
    final list = response is List ? response : [];
    return list.map((data) => DateNight.fromJson(data)).toList();
  }

  Future<List<DateIdea>> getDateJar() async {
    final response = await _api.get('api/v1/couples/date-jar/');
    final data = response['ideas'] ?? [];
    return (data as List).map((data) => DateIdea.fromJson(data)).toList();
  }

  Future<DateIdea> spinDateJar({int? budgetMax, String? vibe, String? locationArea}) async {
    final response = await _api.post('api/v1/couples/dateideas/spin/', {
      if (budgetMax != null) 'budget_max': budgetMax,
      if (vibe != null) 'vibe': vibe,
      if (locationArea != null) 'location_area': locationArea,
    });
    return DateIdea.fromJson(response['idea'] ?? response);
  }

  Future<void> addDateIdea(Map<String, dynamic> data) async {
    await _api.post('api/v1/couples/date-jar/', data);
  }

  Future<List<BucketListItem>> getBucketList(String coupleId) async {
    final response = await _api.get('api/v1/couples/$coupleId/bucketlist/');
    final list = response is List ? response : [];
    return list.map((data) => BucketListItem.fromJson(data)).toList();
  }

  Future<void> markBucketItemComplete(String coupleId, String itemId) async {
    await _api.post('api/v1/couples/$coupleId/bucketlist/$itemId/complete/', {});
  }

  Future<void> addBucketItem(String coupleId, Map<String, dynamic> data) async {
    await _api.post('api/v1/couples/$coupleId/bucketlist/', data);
  }

  Future<List<SharedGoal>> getGoals(String coupleId) async {
    final response = await _api.get('api/v1/couples/$coupleId/goals/');
    final list = response is List ? response : [];
    return list.map((data) => SharedGoal.fromJson(data)).toList();
  }

  Future<void> addGoal(String coupleId, Map<String, dynamic> data) async {
    await _api.post('api/v1/couples/$coupleId/goals/', data);
  }
}
