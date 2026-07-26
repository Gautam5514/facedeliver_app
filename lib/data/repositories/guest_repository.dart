import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/gallery_models.dart';

class GuestRepository {
  GuestRepository(this._api);

  final ApiClient _api;

  /// Unauthenticated: a guest registers by scanning the event QR code.
  /// `eventId` here is the public `Event.code`, not the document id.
  ///
  /// Consent is checked before anything else server-side — sending it as the
  /// string "true" matches how the web form serialises it.
  Future<String> register({
    required String name,
    required String email,
    required String eventCode,
    required String selfiePath,
  }) async {
    final form = FormData.fromMap({
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'eventId': eventCode.trim(),
      'consentGiven': 'true',
      'selfie': await MultipartFile.fromFile(
        selfiePath,
        filename: 'selfie.jpg',
      ),
    });

    final json = await _api.multipart('/guests/register', form);
    return (json['message'] as String?)?.trim().isNotEmpty == true
        ? (json['message'] as String).trim()
        : 'Registration successful.';
  }

  Future<GuestGallery> myGallery() async {
    final json = await _api.get('/guests/matches/me');
    return GuestGallery.fromJson(json);
  }

  /// Resolves a downloadable Cloudinary URL and records the download for the
  /// organiser's delivery analytics.
  Future<String> resolveDownloadUrl(String photoId) async {
    final json = await _api.post('/guests/photos/$photoId/download');
    final url = (json['url'] as String? ?? '').trim();
    if (url.isEmpty) {
      throw StateError('The server did not return a photo URL.');
    }
    return url;
  }

  Future<List<int>> photoBytes(String url) =>
      _api.bytes(url, absoluteUrl: true);

  /// Server builds the archive in memory, so this can take a while on a large
  /// gallery — progress is surfaced to the caller.
  Future<List<int>> downloadAllZip({
    void Function(int received, int total)? onProgress,
  }) =>
      _api.bytes('/guests/photos/download-all', onProgress: onProgress);

  /// Right to erasure: removes selfies, face descriptors, matches and download
  /// history across every event this email registered for.
  Future<String> deleteMyData() async {
    final json = await _api.delete('/guests/me');
    return (json['message'] as String?)?.trim().isNotEmpty == true
        ? (json['message'] as String).trim()
        : 'All your personal data has been permanently deleted.';
  }
}
