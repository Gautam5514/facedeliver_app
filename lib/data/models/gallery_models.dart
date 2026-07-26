/// One matched photo in a guest's personal gallery.
class GalleryPhoto {
  const GalleryPhoto({
    required this.id,
    required this.url,
    required this.confidence,
    required this.eventName,
  });

  final String id;
  final String url;
  final double confidence;

  /// Denormalised from the parent group so the viewer can label each photo
  /// without carrying the group around.
  final String eventName;

  factory GalleryPhoto.fromJson(
    Map<String, dynamic> json, {
    required String eventName,
  }) {
    return GalleryPhoto(
      id: (json['id'] ?? '').toString(),
      url: (json['url'] as String? ?? '').trim(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      eventName: eventName,
    );
  }
}

/// Photos grouped by the event they were shot at.
class GalleryEventGroup {
  const GalleryEventGroup({
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.photos,
  });

  final String eventId;
  final String eventName;
  final DateTime? eventDate;
  final List<GalleryPhoto> photos;

  factory GalleryEventGroup.fromJson(Map<String, dynamic> json) {
    final eventId = (json['eventId'] ?? '').toString();
    final eventName = (json['eventName'] as String?)?.trim().isNotEmpty == true
        ? (json['eventName'] as String).trim()
        : eventId;

    return GalleryEventGroup(
      eventId: eventId,
      eventName: eventName,
      eventDate: DateTime.tryParse(json['eventDate']?.toString() ?? ''),
      photos: ((json['photos'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((photo) => GalleryPhoto.fromJson(photo, eventName: eventName))
          .toList(growable: false),
    );
  }
}

class GuestGallery {
  const GuestGallery({
    required this.guestName,
    required this.selfieUrl,
    required this.totalPhotos,
    required this.events,
  });

  final String guestName;
  final String? selfieUrl;
  final int totalPhotos;
  final List<GalleryEventGroup> events;

  static const empty = GuestGallery(
    guestName: 'Guest',
    selfieUrl: null,
    totalPhotos: 0,
    events: [],
  );

  /// Flat, newest-first list used by the photo viewer's swipe navigation.
  List<GalleryPhoto> get allPhotos =>
      [for (final group in events) ...group.photos];

  factory GuestGallery.fromJson(Map<String, dynamic> json) {
    final selfie = (json['selfieUrl'] as String?)?.trim();
    return GuestGallery(
      guestName: (json['guestName'] as String?)?.trim().isNotEmpty == true
          ? (json['guestName'] as String).trim()
          : 'Guest',
      selfieUrl: selfie?.isNotEmpty == true ? selfie : null,
      totalPhotos: (json['totalPhotos'] as num?)?.toInt() ?? 0,
      events: ((json['events'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GalleryEventGroup.fromJson)
          .toList(growable: false),
    );
  }
}
