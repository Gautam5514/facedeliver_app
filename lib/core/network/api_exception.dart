/// A failure that already carries a message safe to show the user.
///
/// The Express API answers every error with `{ "error": "..." }`, so the
/// client's job is to surface that string rather than invent its own copy.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.isNetworkError = false});

  final String message;
  final int? statusCode;
  final bool isNetworkError;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isRateLimited => statusCode == 429;

  /// 409 from /admin/start-matching means "already running" — a state, not a
  /// failure the user caused.
  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}
