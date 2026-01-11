// lib/providers/events_provider.dart
import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../services/events_api_service.dart';

class EventsProvider with ChangeNotifier {
  final EventsApiService _eventsApiService = EventsApiService();

  List<Experience> _experiences = [];
  List<Experience> _featuredExperiences = [];
  bool _isLoading = false;
  String? _error;

  List<Experience> get experiences => _experiences;
  List<Experience> get featuredExperiences => _featuredExperiences;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchExperiences() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // For now, use sample data
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      // Use your sample experiences
      final sampleExperiences = <Experience>[]; // Placeholder
      _experiences = sampleExperiences;
      _featuredExperiences = sampleExperiences.take(3).toList();
    } catch (e) {
      _error = e.toString();
      print('Error fetching experiences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadMoreExperiences() async {
    // TODO: Implement loadMoreExperiences
    await Future.delayed(const Duration(seconds: 1));
    return false;
  }

  Future<Map<String, dynamic>> joinWaitlist(String experienceId) async {
    // TODO: Implement joinWaitlist
    await Future.delayed(const Duration(seconds: 1));
    return {'success': true, 'position': 1};
  }

  Future<Map<String, dynamic>> registerForExperience(
      {required String experienceId}) async {
    // TODO: Implement registerForExperience
    await Future.delayed(const Duration(seconds: 1));
    return {'success': true};
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}