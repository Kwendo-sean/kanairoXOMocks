import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_client.dart';
import '../models/music/spotify_models.dart';

class SpotifyService {
  static final SpotifyService _instance = SpotifyService._internal();
  factory SpotifyService() => _instance;
  SpotifyService._internal();

  final _api = ApiClient();

  // Get OAuth URL from backend
  Future<String> getAuthUrl() async {
    final response = await _api.get('api/v1/rhythm/spotify/auth-url/');
    return response['auth_url'] as String;
  }

  // Launch Spotify OAuth in browser
  Future<bool> connectSpotify() async {
    try {
      final url = await getAuthUrl();
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Spotify connect error: $e');
      return false;
    }
  }

  // Handle deep link callback
  Future<bool> handleCallback(String code) async {
    try {
      final response = await _api.post('api/v1/rhythm/spotify/connect/', {'code': code});
      return response['success'] == true;
    } catch (e) {
      debugPrint('Callback error: $e');
      return false;
    }
  }

  Future<SpotifyStatus> getStatus() async {
    try {
      final response = await _api.get('api/v1/rhythm/spotify/status/');
      return SpotifyStatus.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return SpotifyStatus(connected: false);
    }
  }

  Future<bool> disconnect() async {
    try {
      await _api.post('api/v1/rhythm/spotify/disconnect/', {});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<TrackModel?> getNowPlaying({String? userId}) async {
    try {
      final path = userId != null
          ? 'api/v1/rhythm/now-playing/$userId/'
          : 'api/v1/rhythm/now-playing/';
      final response = await _api.get(path);
      final track = response['now_playing'];
      if (track == null) return null;
      return TrackModel.fromJson(track as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<MusicProfile?> getMusicProfile({String? userId}) async {
    try {
      final path = userId != null
          ? 'api/v1/rhythm/profile/$userId/'
          : 'api/v1/rhythm/profile/';
      final response = await _api.get(path);
      return MusicProfile.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<MusicCompatibility?> getCompatibility(String userId) async {
    try {
      final response = await _api.get('api/v1/rhythm/compatibility/$userId/');
      return MusicCompatibility.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<bool> syncProfile() async {
    try {
      await _api.post('api/v1/rhythm/sync/', {});
      return true;
    } catch (e) {
      return false;
    }
  }
}
