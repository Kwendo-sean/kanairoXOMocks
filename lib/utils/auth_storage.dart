import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = 'device_id';

  static Future<String> getOrCreateDeviceId() async {
    String? deviceId = await _storage.read(key: _deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }
    return deviceId;
  }
}
