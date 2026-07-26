import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/app_user.dart';

typedef AuthResult = ({String token, AppUser user});

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  AuthResult _parse(Map<String, dynamic> json) => (
        token: (json['token'] as String? ?? '').trim(),
        user: AppUser.fromJson(
          (json['user'] as Map<String, dynamic>?) ?? const {},
        ),
      );

  /// Guests never set a password — the backend bootstraps a `user` account
  /// from the Guest record created at registration.
  Future<AuthResult> guestLogin(String email) async {
    final json = await _api.post(
      '/auth/guest-login',
      body: {'email': email.trim().toLowerCase()},
    );
    return _parse(json);
  }

  Future<AuthResult> adminLogin({
    required String email,
    required String password,
  }) async {
    final json = await _api.post('/auth/login', body: {
      'email': email.trim().toLowerCase(),
      'password': password,
    });
    return _parse(json);
  }

  /// An invite code is what promotes a signup to the `admin` role; the role
  /// itself is never accepted from the client.
  Future<AuthResult> adminSignup({
    required String name,
    required String email,
    required String password,
    required String inviteCode,
  }) async {
    final json = await _api.post('/auth/signup', body: {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'inviteCode': inviteCode.trim(),
    });
    return _parse(json);
  }

  Future<AppUser> me() async {
    final json = await _api.get('/auth/me');
    return AppUser.fromJson((json['user'] as Map<String, dynamic>?) ?? const {});
  }

  Future<AuthResult> updateProfile({
    required String name,
    String? profileImagePath,
  }) async {
    final form = FormData.fromMap({
      'name': name.trim(),
      if (profileImagePath != null)
        'profileImage': await MultipartFile.fromFile(profileImagePath),
    });

    final json = await _api.multipart('/auth/me', form, method: 'PUT');
    return _parse(json);
  }
}
