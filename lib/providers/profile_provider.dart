import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/profile_model.dart';
import '../services/profile_api_service.dart';
import './auth_provider.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileApiService _profileApiService = ProfileApiService();
  User? _currentUser;
  ProfileModel? _myProfile;
  User? _viewedProfile;
  List<User> _savedProfiles = [];
  List<User> _discoveredProfiles = [];
  bool _isLoading = false;
  String? _error;
  bool _isProfileSaved = false;
  
  // Cache busting timestamp
  String _imageVersion = DateTime.now().millisecondsSinceEpoch.toString();

  User? get currentUser => _currentUser;
  ProfileModel? get myProfile => _myProfile;
  User? get viewedProfile => _viewedProfile;
  List<User> get savedProfiles => _savedProfiles;
  List<User> get discoveredProfiles => _discoveredProfiles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isProfileSaved => _isProfileSaved;
  String get imageVersion => _imageVersion;

  void update(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      _currentUser = null;
      _myProfile = null;
      _savedProfiles = [];
      _discoveredProfiles = [];
    }
    notifyListeners();
  }

  void bustImageCache() {
    _imageVersion = DateTime.now().millisecondsSinceEpoch.toString();
    imageCache.clear();
    imageCache.clearLiveImages();
    notifyListeners();
  }

  Future<void> refreshMyProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Parallel fetch for speed
      final results = await Future.wait([
        _profileApiService.getMyProfile(),
        _profileApiService.getProfile(),
      ]);
      
      _currentUser = results[0] as User;
      _myProfile = results[1] as ProfileModel;
      
      // Auto-bust cache on refresh to ensure UI sees new photos
      bustImageCache();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error refreshing profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<User?> loadMyProfile() async {
    if (_isLoading) return _currentUser;
    await refreshMyProfile();
    return _currentUser;
  }

  Future<void> handleLogout() async {
    _currentUser = null;
    _myProfile = null;
    _savedProfiles = [];
    _discoveredProfiles = [];
    notifyListeners();
  }

  Future<void> loadUserProfile(String id) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _viewedProfile = await _profileApiService.getUserProfile(id);
      if (_currentUser?.id != _viewedProfile?.id) {
        await _profileApiService.recordProfileView(id);
      }
      _checkIfProfileSaved(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserProfileUpdate update) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _profileApiService.updateProfile(update);
      await refreshMyProfile();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// New single photo upload handler
  Future<void> uploadProfilePhoto(File file) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newUrl = await _profileApiService.uploadSingleProfilePhoto(file);
      
      // Update local models immediately with the returned URL
      if (_myProfile != null) {
        _myProfile = _myProfile!.copyWith(profilePhotoUrl: newUrl);
      }
      
      // Clear cache and update version to force refresh
      bustImageCache();
      
      // We don't necessarily NEED to re-fetch the full profile if the URL is updated,
      // but it's good practice to keep everything in sync eventually.
      // For immediate response, the local state update is enough.
    } catch (e) {
      _error = e.toString();
      debugPrint('Photo upload error: $e');
      rethrow;
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
      await refreshMyProfile();
    } catch (e) {
      _error = e.toString();
      rethrow;
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
      await refreshMyProfile();
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
      await refreshMyProfile();
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
      await refreshMyProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkIfProfileSaved(String id) async {
    try {
      final saved = await _profileApiService.getSavedProfiles();
      _isProfileSaved = saved.any((user) => user.id == id);
      notifyListeners();
    } catch (e) {
      print('Error checking if profile saved: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
