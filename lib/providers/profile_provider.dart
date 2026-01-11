// lib/providers/profile_provider.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/profile_api_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileApiService _profileApiService = ProfileApiService();

  User? _currentUser;
  User? _viewedProfile;
  List<User> _savedProfiles = [];
  List<User> _discoveredProfiles = [];
  bool _isLoading = false;
  String? _error;
  bool _isProfileSaved = false;

  User? get currentUser => _currentUser;
  User? get viewedProfile => _viewedProfile;
  List<User> get savedProfiles => _savedProfiles;
  List<User> get discoveredProfiles => _discoveredProfiles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isProfileSaved => _isProfileSaved;

  // Available options for forms
  List<Map<String, String>> get neighborhoods => _profileApiService.getNeighborhoods();
  List<Map<String, String>> get lifeStages => _profileApiService.getLifeStages();
  List<Map<String, String>> get socialCircles => _profileApiService.getSocialCircles();
  List<Map<String, String>> get connectionFrequencies => _profileApiService.getConnectionFrequencies();
  List<Map<String, String>> get visibilityOptions => _profileApiService.getVisibilityOptions();
  List<String> get commonInterests => _profileApiService.getCommonInterests();

  Future<void> loadMyProfile() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _profileApiService.getMyProfile();
    } catch (e) {
      _error = e.toString();
      print('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserProfile(String publicId) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _viewedProfile = await _profileApiService.getUserProfile(publicId);

      // Record view if it's not the current user's profile
      if (_currentUser?.publicId != _viewedProfile?.publicId) {
        await _profileApiService.recordProfileView(publicId);
      }

      // Check if profile is saved
      _checkIfProfileSaved(publicId);
    } catch (e) {
      _error = e.toString();
      print('Error loading user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkIfProfileSaved(String publicId) async {
    try {
      final saved = await _profileApiService.getSavedProfiles();
      _isProfileSaved = saved.any((user) => user.publicId == publicId);
      notifyListeners();
    } catch (e) {
      print('Error checking if profile saved: $e');
    }
  }

  Future<void> updateProfile(UserProfileUpdate update) async {
    if (_isLoading || _currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _profileApiService.updateProfile(update);
    } catch (e) {
      _error = e.toString();
      print('Error updating profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSavedProfiles() async {
    try {
      _savedProfiles = await _profileApiService.getSavedProfiles();
      notifyListeners();
    } catch (e) {
      print('Error loading saved profiles: $e');
    }
  }

  Future<void> searchProfiles({
    String? query,
    String? neighborhood,
    String? lifeStage,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _discoveredProfiles = await _profileApiService.searchProfiles(
        query: query,
        neighborhood: neighborhood,
        lifeStage: lifeStage,
      );
    } catch (e) {
      _error = e.toString();
      print('Error searching profiles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleSaveProfile(String publicId) async {
    try {
      if (_isProfileSaved) {
        final success = await _profileApiService.unsaveProfile(publicId);
        if (success) {
          _isProfileSaved = false;
          _savedProfiles.removeWhere((user) => user.publicId == publicId);
          notifyListeners();
          return true;
        }
      } else {
        final success = await _profileApiService.saveProfile(publicId);
        if (success) {
          _isProfileSaved = true;
          if (_viewedProfile != null) {
            _savedProfiles.add(_viewedProfile!);
          }
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error toggling save profile: $e');
      return false;
    }
  }

  Future<void> discoverProfiles() async {
    try {
      _discoveredProfiles = await _profileApiService.searchProfiles(limit: 20);
      notifyListeners();
    } catch (e) {
      print('Error discovering profiles: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearViewedProfile() {
    _viewedProfile = null;
    _isProfileSaved = false;
    notifyListeners();
  }

  // Helper methods
  String getNeighborhoodLabel(String? value) {
    if (value == null) return '';
    final neighborhood = neighborhoods.firstWhere(
          (n) => n['value'] == value,
      orElse: () => {'label': value},
    );
    return neighborhood['label']!;
  }

  String getLifeStageLabel(String? value) {
    if (value == null) return '';
    final lifeStage = lifeStages.firstWhere(
          (l) => l['value'] == value,
      orElse: () => {'label': value},
    );
    return lifeStage['label']!;
  }

  String getSocialCircleLabel(String? value) {
    if (value == null) return '';
    final socialCircle = socialCircles.firstWhere(
          (s) => s['value'] == value,
      orElse: () => {'label': value},
    );
    return socialCircle['label']!;
  }

  String getConnectionFrequencyLabel(String? value) {
    if (value == null) return '';
    final frequency = connectionFrequencies.firstWhere(
          (f) => f['value'] == value,
      orElse: () => {'label': value},
    );
    return frequency['label']!;
  }

  String getVisibilityLabel(String? value) {
    if (value == null) return '';
    final visibility = visibilityOptions.firstWhere(
          (v) => v['value'] == value,
      orElse: () => {'label': value},
    );
    return visibility['label']!;
  }
}