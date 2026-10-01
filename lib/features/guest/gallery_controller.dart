import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/gallery_models.dart';
import '../../data/repositories/guest_repository.dart';

/// Owns the guest gallery: loading, refreshing, and the two download paths.
///
/// Kept out of the widget so the photo viewer can trigger a save without
/// reaching back into the gallery screen's state.
class GalleryController extends ChangeNotifier {
  GalleryController(this._repository);

  final GuestRepository _repository;

  GuestGallery _gallery = GuestGallery.empty;
  bool _loading = true;
  bool _refreshing = false;
  bool _zipping = false;
  String? _error;

  /// null = "All photos"; otherwise the selected event code.
  String? _selectedEventId;

  GuestGallery get gallery => _gallery;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  bool get zipping => _zipping;
  String? get error => _error;
  String? get selectedEventId => _selectedEventId;

  /// True when the guest has registered but no photo has matched yet — the
  /// common state right after an event, while the worker is still processing.
  bool get isAwaitingPhotos => !_loading && _error == null && _gallery.totalPhotos == 0;

  List<GalleryEventGroup> get visibleGroups => _visibleGroups;

  /// Flat list backing the viewer's swipe order, in the same order as shown.
  List<GalleryPhoto> get visiblePhotos => _visiblePhotos;

  // Derived views are recomputed only when the gallery data or the selected
  // event changes — not on every widget rebuild that reads them.
  List<GalleryEventGroup> _visibleGroups = const [];
  List<GalleryPhoto> _visiblePhotos = const [];

  void _recomputeVisible() {
    _visibleGroups = _selectedEventId == null
        ? _gallery.events
        : _gallery.events
            .where((group) => group.eventId == _selectedEventId)
            .toList(growable: false);
    _visiblePhotos = [for (final group in _visibleGroups) ...group.photos];
  }

  void selectEvent(String? eventId) {
    if (_selectedEventId == eventId) return;
    _selectedEventId = eventId;
    _recomputeVisible();
    notifyListeners();
  }

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _refreshing = true;
    } else {
      _loading = true;
    }
    _error = null;
    notifyListeners();

    try {
      _gallery = await _repository.myGallery();

      // A filter pointing at an event that no longer has photos would show an
      // empty grid with no way back.
      if (_selectedEventId != null &&
          !_gallery.events.any((group) => group.eventId == _selectedEventId)) {
        _selectedEventId = null;
      }
      _recomputeVisible();
    } on ApiException catch (error) {
      // 404 means "registered, nothing matched yet" — an empty state, not a
      // failure worth alarming the guest about.
      if (error.isNotFound) {
        _gallery = GuestGallery.empty;
        _recomputeVisible();
      } else {
        _error = error.message;
      }
    } catch (_) {
      _error = 'Could not load your gallery. Please try again.';
    } finally {
      _loading = false;
      _refreshing = false;
      notifyListeners();
    }
  }

  /// Saves one photo into the device's photo library.
  Future<void> savePhoto(GalleryPhoto photo) async {
    final url = await _repository.resolveDownloadUrl(photo.id);
    final bytes = await _repository.photoBytes(url);

    if (!await Gal.hasAccess()) {
      await Gal.requestAccess();
    }
    await Gal.putImageBytes(
      Uint8List.fromList(bytes),
      album: 'FaceDeliver',
      name: 'facedeliver-${photo.id}',
    );
  }

  /// Downloads every matched photo as a single archive and returns its path,
  /// ready to hand to the share sheet.
  Future<String> downloadArchive({
    void Function(int received, int total)? onProgress,
  }) async {
    _zipping = true;
    notifyListeners();

    try {
      final bytes = await _repository.downloadAllZip(onProgress: onProgress);
      final directory = await getTemporaryDirectory();
      final slug = _gallery.guestName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      final file = File('${directory.path}/${slug.isEmpty ? 'guest' : slug}-event-photos.zip');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } finally {
      _zipping = false;
      notifyListeners();
    }
  }

  Future<String> deleteAllData() => _repository.deleteMyData();
}
