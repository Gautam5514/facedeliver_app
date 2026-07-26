import 'event_models.dart';

/// `GET /admin/dashboard-stats` — totals across every event this admin owns.
class DashboardStats {
  const DashboardStats({
    required this.totalEvents,
    required this.totalGuests,
    required this.totalPhotos,
    required this.totalMatches,
    required this.recentEvents,
  });

  final int totalEvents;
  final int totalGuests;
  final int totalPhotos;
  final int totalMatches;
  final List<EventSummary> recentEvents;

  static const empty = DashboardStats(
    totalEvents: 0,
    totalGuests: 0,
    totalPhotos: 0,
    totalMatches: 0,
    recentEvents: [],
  );

  /// Average matched photos per registered guest — the number that tells an
  /// organiser whether matching actually worked.
  double get matchesPerGuest =>
      totalGuests == 0 ? 0 : totalMatches / totalGuests;

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalEvents: (json['totalEvents'] as num?)?.toInt() ?? 0,
        totalGuests: (json['totalGuests'] as num?)?.toInt() ?? 0,
        totalPhotos: (json['totalPhotos'] as num?)?.toInt() ?? 0,
        totalMatches: (json['totalMatches'] as num?)?.toInt() ?? 0,
        recentEvents: ((json['recentEvents'] as List<dynamic>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(EventSummary.fromJson)
            .toList(growable: false),
      );
}

class TrendPoint {
  const TrendPoint({required this.date, required this.count});

  final String date; // yyyy-MM-dd, UTC
  final int count;

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
        date: (json['date'] as String? ?? '').trim(),
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

/// `GET /admin/download-stats?eventId=CODE` — delivery analytics, which is the
/// only signal that guests actually received their photos.
class DownloadStats {
  const DownloadStats({
    required this.todayDownloads,
    required this.allTimeDownloads,
    required this.totalPhotos,
    required this.downloadedPhotos,
    required this.notDownloadedPhotos,
    required this.uniqueGuestsDownloaded,
    required this.coveragePercent,
    required this.last7Days,
  });

  final int todayDownloads;
  final int allTimeDownloads;
  final int totalPhotos;
  final int downloadedPhotos;
  final int notDownloadedPhotos;
  final int uniqueGuestsDownloaded;
  final int coveragePercent;
  final List<TrendPoint> last7Days;

  static const empty = DownloadStats(
    todayDownloads: 0,
    allTimeDownloads: 0,
    totalPhotos: 0,
    downloadedPhotos: 0,
    notDownloadedPhotos: 0,
    uniqueGuestsDownloaded: 0,
    coveragePercent: 0,
    last7Days: [],
  );

  int get peakDay =>
      last7Days.fold(0, (max, point) => point.count > max ? point.count : max);

  factory DownloadStats.fromJson(Map<String, dynamic> json) => DownloadStats(
        todayDownloads: (json['todayDownloads'] as num?)?.toInt() ?? 0,
        allTimeDownloads: (json['allTimeDownloads'] as num?)?.toInt() ?? 0,
        totalPhotos: (json['totalPhotos'] as num?)?.toInt() ?? 0,
        downloadedPhotos: (json['downloadedPhotos'] as num?)?.toInt() ?? 0,
        notDownloadedPhotos: (json['notDownloadedPhotos'] as num?)?.toInt() ?? 0,
        uniqueGuestsDownloaded:
            (json['uniqueGuestsDownloaded'] as num?)?.toInt() ?? 0,
        coveragePercent: (json['downloadCoveragePercent'] as num?)?.toInt() ?? 0,
        last7Days: ((json['last7Days'] as List<dynamic>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(TrendPoint.fromJson)
            .toList(growable: false),
      );
}
