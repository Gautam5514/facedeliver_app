import 'dart:io';

import 'package:flutter/foundation.dart';

/// Runtime configuration.
///
/// Override the API host at build time without touching source:
///   flutter run --dart-define=API_BASE_URL=https://api.facedeliver.com/api
class AppConfig {
  const AppConfig._();

  static const String appName = 'FaceDeliver';

  static const String _apiOverride = String.fromEnvironment('API_BASE_URL');

  /// Base URL including the `/api` prefix, matching the Express mount points.
  ///
  /// The Android emulator reaches the host machine on 10.0.2.2, not localhost,
  /// so the dev fallback differs per platform.
  static String get apiBaseUrl {
    if (_apiOverride.isNotEmpty) return _stripTrailingSlash(_apiOverride);
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:5001/api';
    return 'http://localhost:5001/api';
  }

  /// Web origin used to build guest registration links inside QR codes.
  static const String webOrigin = String.fromEnvironment(
    'WEB_ORIGIN',
    defaultValue: 'https://facedeliver.in',
  );

  static String registrationLink(String eventCode) =>
      '$webOrigin/register?eventId=${Uri.encodeComponent(eventCode)}';

  /// Backend deletes all biometric data this many days after an event.
  static const int retentionDays = 10;

  /// The backend caps a single upload request at 300 files; the web client
  /// batches at 30 to stay under the per-minute upload rate limit. Mobile
  /// connections are slower, so we keep the same batch size.
  static const int uploadBatchSize = 30;

  /// Guest ZIP downloads are capped server-side.
  static const int zipPhotoCap = 200;

  static const String supportEmail = 'hellobj16@gmail.com';

  static String _stripTrailingSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}
