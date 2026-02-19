import 'package:kanairoxo/models/date_model.dart';
import 'package:kanairoxo/services/api_client.dart';

class DateService {
  final ApiClient _api = ApiClient();

  Future<List<DateNight>> getDates() async {
    final response = await _api.get('api/dates/');
    return (response as List).map((data) => DateNight.fromJson(data)).toList();
  }

  Future<List<DateIdea>> getDateIdeas() async {
    final response = await _api.get('api/dates/ideas/');
    return (response as List).map((data) => DateIdea.fromJson(data)).toList();
  }

  Future<DateNight> createDate(String title, DateTime date, {String? location, String? description}) async {
    final response = await _api.post('api/dates/', {
      'title': title,
      'date': date.toIso8601String(),
      'location': location,
      'description': description,
    });
    return DateNight.fromJson(response);
  }
}
