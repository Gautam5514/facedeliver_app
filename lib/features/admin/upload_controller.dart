import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/image_tools.dart';
import '../../data/repositories/admin_repository.dart';

enum UploadPhase { idle, preparing, uploading, done }

/// Drives a photo upload session: compress on device, then send in batches.
///
/// Batching matters. The API accepts up to 300 files per request but rate-limits
/// uploads to 30 requests a minute, and a venue's connection drops often — a
/// failed batch of 30 costs far less than a failed batch of 300.
class UploadController extends ChangeNotifier {
  UploadController(this._repository);

  final AdminRepository _repository;

  CancelToken? _cancelToken;

  UploadPhase phase = UploadPhase.idle;
  int totalPhotos = 0;
  int preparedPhotos = 0;
  int uploadedPhotos = 0;

  /// 0–100 across the whole session, not just the current batch.
  int progress = 0;
  String? error;
  String? summary;

  bool get isBusy =>
      phase == UploadPhase.preparing || phase == UploadPhase.uploading;

  String get phaseLabel => switch (phase) {
        UploadPhase.preparing => 'Optimising $preparedPhotos of $totalPhotos',
        UploadPhase.uploading => 'Uploading $uploadedPhotos of $totalPhotos',
        UploadPhase.done => 'Upload complete',
        UploadPhase.idle => '',
      };

  Future<bool> upload({
    required String eventCode,
    required List<String> sourcePaths,
  }) async {
    if (isBusy || sourcePaths.isEmpty) return false;

    _cancelToken = CancelToken();
    totalPhotos = sourcePaths.length;
    preparedPhotos = 0;
    uploadedPhotos = 0;
    progress = 0;
    error = null;
    summary = null;
    phase = UploadPhase.preparing;
    notifyListeners();

    final prepared = <String>[];

    try {
      // Phase 1 — compress. Sequential on purpose: encoding several full-size
      // photos at once spikes memory on mid-range phones.
      for (final path in sourcePaths) {
        if (_cancelToken?.isCancelled ?? false) throw _CancelledUpload();
        prepared.add(await ImageTools.prepareEventPhoto(path));
        preparedPhotos++;
        // Preparation is the first 25% of the session.
        progress = ((preparedPhotos / totalPhotos) * 25).round();
        notifyListeners();
      }

      // Phase 2 — send in batches.
      phase = UploadPhase.uploading;
      notifyListeners();

      const batchSize = AppConfig.uploadBatchSize;
      var lastMessage = '';

      for (var start = 0; start < prepared.length; start += batchSize) {
        if (_cancelToken?.isCancelled ?? false) throw _CancelledUpload();

        final batch = prepared.sublist(
          start,
          (start + batchSize).clamp(0, prepared.length),
        );
        final batchStart = start;

        final result = await _repository.uploadPhotos(
          eventCode: eventCode,
          filePaths: batch,
          cancelToken: _cancelToken,
          onProgress: (sent, total) {
            if (total <= 0) return;
            final within = sent / total * batch.length;
            progress =
                (25 + ((batchStart + within) / totalPhotos) * 75).round().clamp(0, 100);
            notifyListeners();
          },
        );

        uploadedPhotos += result.uploadedCount == 0
            ? batch.length
            : result.uploadedCount;
        lastMessage = result.message;
        notifyListeners();
      }

      progress = 100;
      phase = UploadPhase.done;
      summary = lastMessage.isEmpty
          ? '$uploadedPhotos photos uploaded. Matching runs in the background.'
          : lastMessage;
      notifyListeners();
      return true;
    } on _CancelledUpload {
      error = 'Upload cancelled.';
      phase = UploadPhase.idle;
      notifyListeners();
      return false;
    } on DioException catch (exception) {
      error = exception.type == DioExceptionType.cancel
          ? 'Upload cancelled.'
          : 'Upload failed. Please try again.';
      phase = UploadPhase.idle;
      notifyListeners();
      return false;
    } catch (exception) {
      error = exception.toString().replaceFirst('Exception: ', '');
      phase = UploadPhase.idle;
      notifyListeners();
      return false;
    } finally {
      // Compressed copies live in the temp directory; the originals in the
      // photo library are untouched.
      ImageTools.discard(prepared);
      _cancelToken = null;
    }
  }

  void cancel() {
    _cancelToken?.cancel('cancelled by user');
    notifyListeners();
  }

  void reset() {
    phase = UploadPhase.idle;
    totalPhotos = 0;
    preparedPhotos = 0;
    uploadedPhotos = 0;
    progress = 0;
    error = null;
    summary = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('screen closed');
    super.dispose();
  }
}

class _CancelledUpload implements Exception {}
