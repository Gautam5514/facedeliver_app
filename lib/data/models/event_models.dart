/// An event row from `GET /admin/events` — the aggregate adds guest/photo counts.
///
/// `code` is the public identity of an event: QR links, guest registration and
/// every photo/guest lookup key off it. `id` is only used for admin routing.
class EventSummary {
  const EventSummary({
    required this.id,
    required this.name,
    required this.code,
    required this.createdAt,
    required this.guestCount,
    required this.photoCount,
  });

  final String id;
  final String name;
  final String code;
  final DateTime? createdAt;
  final int guestCount;
  final int photoCount;

  factory EventSummary.fromJson(Map<String, dynamic> json) => EventSummary(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        name: (json['name'] as String?)?.trim().isNotEmpty == true
            ? (json['name'] as String).trim()
            : 'Untitled event',
        code: (json['code'] as String? ?? '').trim(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        guestCount: (json['guestCount'] as num?)?.toInt() ?? 0,
        photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
      );
}

/// A registered guest as returned inside the event detail payload.
/// The face descriptor and Cloudinary public id are stripped server-side.
class EventGuest {
  const EventGuest({
    required this.id,
    required this.name,
    required this.email,
    required this.selfieUrl,
    required this.registeredAt,
    required this.consentGivenAt,
  });

  final String id;
  final String name;
  final String email;
  final String? selfieUrl;
  final DateTime? registeredAt;
  final DateTime? consentGivenAt;

  String get initial =>
      name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

  factory EventGuest.fromJson(Map<String, dynamic> json) {
    final selfie = (json['selfieUrl'] as String?)?.trim();
    return EventGuest(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Guest',
      email: (json['email'] as String? ?? '').trim(),
      selfieUrl: selfie?.isNotEmpty == true ? selfie : null,
      registeredAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      consentGivenAt:
          DateTime.tryParse(json['consentGivenAt']?.toString() ?? ''),
    );
  }
}

/// `GET /admin/events/:id` — event plus its live processing state.
class EventDetail {
  const EventDetail({
    required this.id,
    required this.name,
    required this.code,
    required this.createdAt,
    required this.guests,
    required this.photoCount,
    required this.matchCount,
    required this.pendingProcessing,
    required this.activeJobs,
    required this.failedPhotos,
  });

  final String id;
  final String name;
  final String code;
  final DateTime? createdAt;
  final List<EventGuest> guests;
  final int photoCount;
  final int matchCount;

  /// Photos uploaded but not yet picked up by the face-detection worker.
  final int pendingProcessing;

  /// Jobs the worker is actively running right now.
  final int activeJobs;

  /// Photos that exhausted all job attempts — the admin should re-upload them.
  final int failedPhotos;

  int get guestCount => guests.length;

  bool get isProcessing => pendingProcessing > 0 || activeJobs > 0;

  factory EventDetail.fromJson(Map<String, dynamic> json) => EventDetail(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        name: (json['name'] as String?)?.trim().isNotEmpty == true
            ? (json['name'] as String).trim()
            : 'Untitled event',
        code: (json['code'] as String? ?? '').trim(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        guests: ((json['guests'] as List<dynamic>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(EventGuest.fromJson)
            .toList(growable: false),
        photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
        matchCount: (json['matchCount'] as num?)?.toInt() ?? 0,
        pendingProcessing: (json['pendingProcessing'] as num?)?.toInt() ?? 0,
        activeJobs: (json['activeJobs'] as num?)?.toInt() ?? 0,
        failedPhotos: (json['failedPhotos'] as num?)?.toInt() ?? 0,
      );
}
