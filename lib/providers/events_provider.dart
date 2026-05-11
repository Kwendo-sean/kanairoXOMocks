// lib/providers/events_provider.dart
import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../services/events_api_service.dart';
import './auth_provider.dart';

class EventsProvider with ChangeNotifier {
  final EventsApiService _eventsApiService = EventsApiService();
  List<Experience> _experiences = [];
  List<Experience> _featuredExperiences = [];
  List<ExperienceCategory> _categories = [];
  bool _isLoading = false;
  String? _error;
  bool _hasInitialData = false;

  List<Experience> get experiences => _experiences;
  List<Experience> get featuredExperiences => _featuredExperiences;
  List<ExperienceCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasInitialData => _hasInitialData;
  String? get error => _error;

  void update(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      _experiences = [];
      _featuredExperiences = [];
      _categories = [];
      _hasInitialData = false;
      notifyListeners();
    } else {
      // Prefetch data when authenticated if not already loaded
      if (!_hasInitialData && !_isLoading) {
        prefetch();
      }
    }
  }

  Future<void> prefetch() async {
    // Fire and forget individual loads to populate lists in background
    fetchCategories();
    fetchExperiences();
  }

  Future<void> fetchExperiences({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    if (refresh) _error = null;
    notifyListeners();

    try {
      // Run in parallel for speed
      final results = await Future.wait([
        _eventsApiService.fetchExperiences(),
        _eventsApiService.fetchFeaturedExperiences(),
      ]);
      
      _experiences = results[0];
      _featuredExperiences = results[1];
      _hasInitialData = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching experiences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    try {
      _categories = await _eventsApiService.fetchCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<Experience> fetchExperienceDetail(String id) async {
    return await _eventsApiService.fetchExperienceDetail(id);
  }

  Future<Map<String, dynamic>> saveExperience(String experienceId) async {
    return await _eventsApiService.saveExperience(experienceId);
  }

  Future<bool> loadMoreExperiences() async {
    // TODO: Implement pagination
    return false;
  }

  Future<Map<String, dynamic>> joinWaitlist(String experienceId) async {
    try {
      final result = await _eventsApiService.joinWaitlist(experienceId);
      return {'success': true, ...result};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> registerForExperience(
      {required String experienceId}) async {
    try {
      final result =
          await _eventsApiService.registerForExperience(experienceId: experienceId);
      return {'success': true, ...result};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> checkHostingEligibility() async {
    try {
      final response = await _eventsApiService.checkHostingEligibility();

      return {
        'eligible': response['eligible'],
        'requirements': response['requirements'],
        'trust_score': response['trust_score'],
      };
    } catch (e) {
      debugPrint('Error checking hosting eligibility: $e');
      return {
        'eligible': false,
        'requirements': [],
        'error': 'Failed to check eligibility',
      };
    }
  }

  Future<Map<String, dynamic>> hostEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await _eventsApiService.hostEvent(eventData);

      // Parse the event from response
      final eventJson = response['event'];
      final event = Experience.fromJson(eventJson);

      // Add to local list
      _experiences.insert(0, event);

      notifyListeners();

      return {
        'success': true,
        'event': event,
        'message': 'Event created successfully',
      };
    } catch (e) {
      debugPrint('Error hosting event: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<List<Map<String, dynamic>>> getTicketTemplates() async {
    try {
      return await _eventsApiService.getTicketTemplates();
    } catch (e) {
      debugPrint('Error getting ticket templates: $e');
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
