import 'package:kanairoxo/models/date_model.dart';
import 'package:kanairoxo/services/api_client.dart';

class DateService {
  final ApiClient _api = ApiClient();

  Future<List<DateNight>> getUpcomingDates() async {
    final response = await _api.get('api/v1/couples/dates/upcoming/');
    final data = response;
    
    final list = data is List
        ? data
        : (data is Map ? (data as Map<String, dynamic>).values.toList() : []);
        
    return list.map((data) => DateNight.fromJson(data)).toList();
  }

  Future<List<DateNight>> getPastDates() async {
    final response = await _api.get('api/v1/couples/dates/past/');
    final data = response;
    
    final list = data is List
        ? data
        : (data is Map ? (data as Map<String, dynamic>).values.toList() : []);
        
    return list.map((data) => DateNight.fromJson(data)).toList();
  }

  Future<List<DateIdea>> getDateJar() async {
    final response = await _api.get('api/v1/couples/date-jar/');
    final data = response['ideas'] ?? [];
    
    return (data as List).map((data) => DateIdea.fromJson(data)).toList();
  }

  Future<DateIdea> spinDateJar() async {
    final response = await _api.get('api/v1/couples/date-jar/spin/');
    return DateIdea.fromJson(response['idea']);
  }

  Future<void> addDateIdea(String title, String category) async {
    await _api.post('api/v1/couples/date-jar/', {
      'title': title,
      'category': category,
    });
  }

  Future<void> rateDate(String dateId, int rating) async {
    await _api.post('api/v1/couples/dates/$dateId/rate/', {
      'rating': rating,
    });
  }

  Future<DateNight> createDate(String title, DateTime date, {String? location, String? description}) async {
    final response = await _api.post('api/v1/couples/dates/', {
      'title': title,
      'date': date.toIso8601String(),
      'location': location,
      'description': description,
    });
    return DateNight.fromJson(response);
  }
}
