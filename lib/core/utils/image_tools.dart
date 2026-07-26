import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Image preparation shared by the selfie flow and the organiser upload flow.
///
/// Compression happens on the device for two reasons: the API rejects selfies
/// over 10 MB and event photos over 20 MB, and a venue's Wi-Fi is usually the
/// slowest link in the chain. The worker downsizes to 1920 px server-side
/// anyway, so sending anything larger is wasted bandwidth.
class ImageTools {
  const ImageTools._();

  static const int _selfieMaxEdge = 1280;
  static const int _photoMaxEdge = 1920;

  /// A selfie only needs enough detail for face descriptor extraction.
  static Future<String> prepareSelfie(String sourcePath) =>
      _compress(sourcePath, maxEdge: _selfieMaxEdge, quality: 88);

  /// Event photos keep more quality — guests download and keep these.
  static Future<String> prepareEventPhoto(String sourcePath) =>
      _compress(sourcePath, maxEdge: _photoMaxEdge, quality: 82);

  static Future<String> _compress(
    String sourcePath, {
    required int maxEdge,
    required int quality,
  }) async {
    final directory = await getTemporaryDirectory();
    final target =
        '${directory.path}/fd-${DateTime.now().microsecondsSinceEpoch}-'
        '${sourcePath.hashCode.abs()}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      target,
      quality: quality,
      minWidth: maxEdge,
      minHeight: maxEdge,
      // HEIC from an iPhone would otherwise reach the server as-is; the face
      // pipeline expects a decodable JPEG.
      format: CompressFormat.jpeg,
      keepExif: false,
    );

    // Compression can fail on an unusual codec — sending the original is far
    // better than failing the upload outright.
    return result?.path ?? sourcePath;
  }

  /// Best-effort cleanup of files this class wrote into the temp directory.
  static Future<void> discard(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // A leftover temp file is harmless — the OS reclaims it.
      }
    }
  }
}
