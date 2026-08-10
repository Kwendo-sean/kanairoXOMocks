import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// The three Moments toggles in Settings.
///
/// Stored on-device so they survive leaving the screen, and mirrored to the
/// profile privacy endpoint so the server can enforce the ones that need
/// enforcing (saves / shares). `publicByDefault` is a client-side default for
/// the create-moment screen and is meaningful locally on its own.
class MomentsPrefsData {
  final bool publicByDefault;
  final bool allowSaves;
  final bool allowShares;

  const MomentsPrefsData({
    required this.publicByDefault,
    required this.allowSaves,
    required this.allowShares,
  });
}

class MomentsPrefs {
  static const _kPublic = 'moments_public_by_default';
  static const _kSaves = 'moments_allow_saves';
  static const _kShares = 'moments_allow_shares';

  static Future<MomentsPrefsData> load() async {
    final sp = await SharedPreferences.getInstance();
    return MomentsPrefsData(
      publicByDefault: sp.getBool(_kPublic) ?? true,
      allowSaves: sp.getBool(_kSaves) ?? true,
      allowShares: sp.getBool(_kShares) ?? true,
    );
  }

  static Future<void> save({
    required bool publicByDefault,
    required bool allowSaves,
    required bool allowShares,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kPublic, publicByDefault);
    await sp.setBool(_kSaves, allowSaves);
    await sp.setBool(_kShares, allowShares);
  }

  /// Mirror a single toggle to the backend. Failures are swallowed on purpose:
  /// the local value is already persisted, and a backend that doesn't yet know
  /// the field shouldn't surface an error to the user.
  static Future<void> syncToServer(String field, bool value) async {
    try {
      await ApiClient().patch('api/v1/profiles/me/privacy/', {field: value});
    } catch (e) {
      if (kDebugMode) debugPrint('Moments pref sync skipped ($field): $e');
    }
  }

  /// Default visibility for a newly created moment, as the post screen
  /// expects it.
  static Future<String> defaultVisibility() async {
    final p = await load();
    return p.publicByDefault ? 'Public' : 'Connections';
  }
}
