import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/profile_api_service.dart';
import './auth_provider.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileApiService _profileApiService = ProfileApiService();
  AuthProvider? _authProvider;

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

  void update(AuthProvider authProvider) {
    _authProvider = authProvider;
    if (!authProvider.isAuthenticated) {
      _currentUser = null;
      _savedProfiles = [];
      _discoveredProfiles = [];
    }
    notifyListeners();
  }

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
      _error = null;
    } on AuthException catch (e) {
      _error = e.toString();
      _currentUser = null;
      rethrow; // Rethrow to be caught by the UI layer
    } catch (e) {
      print('❌ Error in loadMyProfile: $e');
      _error = e.toString();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> handleLogout() async {
    _currentUser = null;
    _savedProfiles = [];
    _discoveredProfiles = [];
    notifyListeners();
  }

  Future<void> loadUserProfile(String publicId) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _viewedProfile = await _profileApiService.getUserProfile(publicId);
      if (_currentUser?.publicId != _viewedProfile?.publicId) {
        await _profileApiService.recordProfileView(publicId);
      }
      _checkIfProfileSaved(publicId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserProfileUpdate update) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _profileApiService.updateProfile(update);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadProfilePhotos(List<XFile> images) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _profileApiService.uploadProfilePhotos(images);
      await loadMyProfile(); // Reloads the profile
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reorderProfilePhotos(List<Map<String, dynamic>> photos) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _profileApiService.reorderProfilePhotos(photos);
      await loadMyProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> deleteProfilePhoto(String photoUrl) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _profileApiService.deleteProfilePhoto(photoUrl);
      await loadMyProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setMainProfilePhoto(String photoUrl) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _profileApiService.setMainProfilePhoto(photoUrl);
      await loadMyProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadVoiceIntro(XFile audioFile) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _profileApiService.uploadVoiceIntro(audioFile);
      await loadMyProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteVoiceIntro() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _profileApiService.deleteVoiceIntro();
      await loadMyProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  // ... other methods like search, save, etc. remain the same ...

  Future<void> _checkIfProfileSaved(String publicId) async {
    try {
      final saved = await _profileApiService.getSavedProfiles();
      _isProfileSaved = saved.any((user) => user.publicId == publicId);
      notifyListeners();
    } catch (e) {
      print('Error checking if profile saved: $e');
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
}
