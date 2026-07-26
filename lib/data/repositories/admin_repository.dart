import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/event_models.dart';
import '../models/stats_models.dart';

/// Outcome of one upload batch.
typedef UploadResult = ({int uploadedCount, String message, int remaining});

class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  Future<DashboardStats> dashboardStats() async {
    final json = await _api.get('/admin/dashboard-stats');
    return DashboardStats.fromJson(json);
  }

  Future<List<EventSummary>> events() async {
    final json = await _api.get('/admin/events');
    return ((json['events'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(EventSummary.fromJson)
        .toList(growable: false);
  }

  Future<EventDetail> event(String id) async {
    final json = await _api.get('/admin/events/$id');
    return EventDetail.fromJson(
      (json['event'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Future<EventSummary> createEvent({
    required String name,
    required String code,
  }) async {
    final json = await _api.post('/admin/events', body: {
      'name': name.trim(),
      'code': code.trim(),
    });
    return EventSummary.fromJson(
      (json['event'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// Uploads one batch of photos. The API responds 202 immediately — face
  /// detection and matching run in a background worker, so a fast response
  /// does not mean the photos are ready.
  Future<UploadResult> uploadPhotos({
    required String eventCode,
    required List<String> filePaths,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final form = FormData();
    form.fields.add(MapEntry('eventId', eventCode));
    for (var i = 0; i < filePaths.length; i++) {
      form.files.add(MapEntry(
        'photos',
        await MultipartFile.fromFile(
          filePaths[i],
          filename: 'photo-${DateTime.now().millisecondsSinceEpoch}-$i.jpg',
        ),
      ));
    }

    final json = await _api.multipart(
      '/admin/upload-photos',
      form,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );

    final usage = json['usage'] as Map<String, dynamic>?;
    return (
      uploadedCount: (json['uploadedCount'] as num?)?.toInt() ?? 0,
      message: (json['message'] as String? ?? 'Photos uploaded.').trim(),
      remaining: (usage?['remainingUploads'] as num?)?.toInt() ?? 0,
    );
  }

  /// Forces a re-match for an event. Normally the worker triggers this itself
  /// once every uploaded photo has been processed.
  Future<String> startMatching(String eventCode) async {
    final json = await _api.post(
      '/admin/start-matching',
      body: {'eventId': eventCode},
    );
    return (json['message'] as String? ?? 'Matching complete.').trim();
  }

  Future<DownloadStats> downloadStats(String eventCode) async {
    final json = await _api.get(
      '/admin/download-stats',
      query: {'eventId': eventCode},
    );
    return DownloadStats.fromJson(json);
  }
}
