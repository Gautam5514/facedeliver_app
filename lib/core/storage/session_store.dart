import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/app_user.dart';

/// Persists the auth token and cached user in the platform keystore/keychain.
///
/// The token is an HMAC-signed payload with a 7-day expiry, so a stored session
/// silently stops working after a week — every screen already handles the 401
/// by routing back to sign-in.
class SessionStore {
  SessionStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              // first_unlock keeps the token readable after a reboot without
              // the device having to be unlocked again mid-session.
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const _tokenKey = 'fd_auth_token';
  static const _userKey = 'fd_auth_user';

  final FlutterSecureStorage _storage;

  Future<({String token, AppUser user})?> read() async {
    final token = await _storage.read(key: _tokenKey);
    final rawUser = await _storage.read(key: _userKey);
    if (token == null || token.isEmpty || rawUser == null) return null;

    try {
      final user = AppUser.fromJson(
        jsonDecode(rawUser) as Map<String, dynamic>,
      );
      return (token: token, user: user);
    } catch (_) {
      // Corrupt payload (schema change, partial write) — start clean rather
      // than trapping the user on a screen that cannot render.
      await clear();
      return null;
    }
  }

  Future<void> write(String token, AppUser user) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> writeUser(AppUser user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
