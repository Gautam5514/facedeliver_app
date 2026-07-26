import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/storage/session_store.dart';
import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';

enum SessionStatus { booting, signedOut, signedIn }

/// Single source of truth for who is signed in.
///
/// The router listens to this, so every sign-in, sign-out and expiry
/// redirects automatically instead of each screen navigating by hand.
class SessionController extends ChangeNotifier {
  SessionController(this._api, this._auth, this._store) {
    _api.tokenProvider = () => _token;
    _api.onUnauthorized = _handleUnauthorized;
  }

  final ApiClient _api;
  final AuthRepository _auth;
  final SessionStore _store;

  SessionStatus _status = SessionStatus.booting;
  AppUser? _user;
  String? _token;

  SessionStatus get status => _status;
  AppUser? get user => _user;
  bool get isSignedIn => _status == SessionStatus.signedIn && _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  /// Restores a stored session on cold start. A stale token is not verified
  /// here — the first authenticated request will 401 and sign the user out,
  /// which keeps launch instant on a slow connection.
  Future<void> bootstrap() async {
    final stored = await _store.read();
    if (stored == null) {
      _set(SessionStatus.signedOut, null, null);
      return;
    }
    _set(SessionStatus.signedIn, stored.user, stored.token);
  }

  Future<void> signInAsGuest(String email) async {
    final result = await _auth.guestLogin(email);
    await _persist(result);
  }

  Future<void> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    final result = await _auth.adminLogin(email: email, password: password);
    await _persist(result);
  }

  Future<void> signUpAsAdmin({
    required String name,
    required String email,
    required String password,
    required String inviteCode,
  }) async {
    final result = await _auth.adminSignup(
      name: name,
      email: email,
      password: password,
      inviteCode: inviteCode,
    );
    await _persist(result);
  }

  Future<void> updateProfile({
    required String name,
    String? profileImagePath,
  }) async {
    final result = await _auth.updateProfile(
      name: name,
      profileImagePath: profileImagePath,
    );
    await _persist(result);
  }

  Future<void> refreshUser() async {
    if (!isSignedIn) return;
    final user = await _auth.me();
    _user = user;
    await _store.writeUser(user);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _store.clear();
    _set(SessionStatus.signedOut, null, null);
  }

  Future<void> _persist(AuthResult result) async {
    await _store.write(result.token, result.user);
    _set(SessionStatus.signedIn, result.user, result.token);
  }

  Future<void> _handleUnauthorized() async {
    if (_status != SessionStatus.signedIn) return;
    await signOut();
  }

  void _set(SessionStatus status, AppUser? user, String? token) {
    _status = status;
    _user = user;
    _token = token;
    notifyListeners();
  }
}
