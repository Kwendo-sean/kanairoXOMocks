import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = 'device_id';
  static const _userIdKey = 'user_id';
  static const _userCacheKey = 'cached_user_data';
  
  static String? _cachedUserId;

  static Future<String> getOrCreateDeviceId() async {
    String? deviceId = await _storage.read(key: _deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }
    return deviceId;
  }

  static String? getCachedUserId() {
    return _cachedUserId;
  }

  static Future<void> saveUserId(String userId) async {
    _cachedUserId = userId;
    await _storage.write(key: _userIdKey, value: userId);
  }

  static Future<void> loadUserId() async {
    _cachedUserId = await _storage.read(key: _userIdKey);
  }

  static Future<void> setCachedUserId(String userId) async {
    _cachedUserId = userId;
  }

  static Future<void> saveUser(User user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _storage.write(key: _userCacheKey, value: userJson);
    } catch (e) {
      // Ignore cache errors
    }
  }

  static Future<User?> getCachedUser() async {
    try {
      final userJson = await _storage.read(key: _userCacheKey);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      // Ignore cache errors
    }
    return null;
  }

  static Future<void> clearAll() async {
    _cachedUserId = null;
    await _storage.deleteAll();
  }
}
