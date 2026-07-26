import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/event_models.dart';
import '../../data/models/stats_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../../widgets/states.dart';
import '../../widgets/surfaces.dart';
import 'widgets/stat_tile.dart';

/// Delivery analytics per event.
///
/// Uploading is not the finish line — a photo nobody downloaded was never
/// really delivered. This screen answers that question first.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<EventSummary> _events = const [];
  EventSummary? _selected;
  DownloadStats _stats = DownloadStats.empty;
  bool _loading = true;
  bool _loadingStats = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final events = await context.read<AdminRepository>().events();
      if (!mounted) return;

      setState(() {
        _events = events;
        _selected = events.isEmpty ? null : events.first;
      });

      if (_selected != null) await _loadStats(_selected!);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load delivery data.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStats(EventSummary event) async {
    setState(() {
      _selected = event;
      _loadingStats = true;
    });

    try {
      final stats =
          await context.read<AdminRepository>().downloadStats(event.code);
      if (mounted) setState(() => _stats = stats);
    } catch (_) {
      if (mounted) setState(() => _stats = DownloadStats.empty);
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('DELIVERY', style: AppText.eyebrow),
            const SizedBox(height: 3),
            Text('Did photos land?', style: AppText.title.copyWith(fontSize: 19)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.ink,
        backgroundColor: AppColors.surface,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: SkeletonList(count: 3, height: 120),
              )
            : _error != null
                ? ListView(
                    children: [
                      StateMessage(
                        icon: Icons.cloud_off_rounded,
                        title: 'Analytics unavailable',
                        message: _error!,
                        tone: ChipTone.danger,
                        actionLabel: 'Try again',
                        onAction: _load,
                      ),
                    ],
                  )
                : _events.isEmpty
                    ? ListView(
                        children: const [
                          StateMessage(
                            icon: Icons.insights_outlined,
                            title: 'Nothing to measure yet',
                            message:
                                'Create an event and upload a gallery — delivery '
                                'numbers appear as guests start downloading.',
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        children: [
                          _EventPicker(
                            events: _events,
                            selected: _selected,
                            onSelect: _loadStats,
                          ),
                          const SizedBox(height: 20),
                          if (_loadingStats)
                            const ShimmerBox(
                              height: 180,
                              radius: AppTokens.rLg,
                            )
                          else ...[
                            _CoverageCard(stats: _stats),
                            const SizedBox(height: 16),
                            StatGrid(
                              tiles: [
                                StatTile(
                                  label: 'Downloads today',
                                  value: _stats.todayDownloads,
                                  icon: Icons.today_rounded,
                                  caption: 'Since midnight UTC',
                                ),
                                StatTile(
                                  label: 'Downloads total',
                                  value: _stats.allTimeDownloads,
                                  icon: Icons.download_rounded,
                                  caption: 'All time',
                                ),
                                StatTile(
                                  label: 'Guests collected',
                                  value: _stats.uniqueGuestsDownloaded,
                                  icon: Icons.groups_rounded,
                                  tone: ChipTone.success,
                                  caption: 'Unique downloaders',
                                ),
                                StatTile(
                                  label: 'Never opened',
                                  value: _stats.notDownloadedPhotos,
                                  icon: Icons.visibility_off_outlined,
                                  tone: _stats.notDownloadedPhotos > 0
                                      ? ChipTone.warning
                                      : ChipTone.neutral,
                                  caption: 'Photos with no download',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _WeeklyCard(stats: _stats),
                          ],
                        ],
                      ),
      ),
    );
  }
}

class _EventPicker extends StatelessWidget {
  const _EventPicker({
    required this.events,
    required this.selected,
    required this.onSelect,
  });

  final List<EventSummary> events;
  final EventSummary? selected;
  final ValueChanged<EventSummary> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final event = events[index];
          final isSelected = selected?.id == event.id;

          return GestureDetector(
            onTap: () => onSelect(event),
            child: AnimatedContainer(
              duration: AppTokens.fast,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.ink : AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.rPill),
                border: Border.all(
                  color: isSelected ? AppColors.ink : AppColors.border,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Text(
                  event.name,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyStrong.copyWith(
                    fontSize: 12.5,
                    color: isSelected ? Colors.white : AppColors.inkSoft,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CoverageCard extends StatelessWidget {
  const _CoverageCard({required this.stats});

  final DownloadStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.totalPhotos == 0) {
      return const AppCard(
        child: InfoBanner(
          message:
              'No photos uploaded for this event yet, so there is nothing to '
              'deliver.',
          icon: Icons.photo_library_outlined,
        ),
      );
    }

    final percent = stats.coveragePercent;
    final (tone, accent) = switch (percent) {
      >= 70 => (ChipTone.success, AppColors.success),
      >= 35 => (ChipTone.warning, AppColors.warning),
      _ => (ChipTone.danger, AppColors.danger),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('DOWNLOAD COVERAGE', style: AppText.eyebrow),
              ),
              StatusChip(
                label: percent >= 70
                    ? 'Healthy'
                    : percent >= 35
                        ? 'Partial'
                        : 'Low',
                tone: tone,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$percent%', style: AppText.metric.copyWith(color: accent)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '${Format.count(stats.downloadedPhotos)} of '
                  '${Format.count(stats.totalPhotos)} photos collected',
                  style: AppText.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressTrack(percent: percent, color: accent),
          if (percent < 70) ...[
            const SizedBox(height: 14),
            InfoBanner(
              message: percent == 0
                  ? 'No downloads yet. Guests are emailed automatically when '
                      'matching finishes — re-share the QR link if turnout is low.'
                  : 'Some guests have not collected their photos. A reminder '
                      'with the registration link usually lifts this.',
              icon: Icons.lightbulb_outline_rounded,
              tone: tone,
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({required this.stats});

  final DownloadStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.last7Days.isEmpty) return const SizedBox.shrink();

    final peak = stats.peakDay;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('LAST 7 DAYS', style: AppText.eyebrow)),
              Text(
                peak == 0 ? 'No activity' : 'Peak $peak',
                style: AppText.micro,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in stats.last7Days)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            point.count == 0 ? '' : '${point.count}',
                            style: AppText.micro.copyWith(fontSize: 10),
                          ),
                          const SizedBox(height: 5),
                          AnimatedContainer(
                            duration: AppTokens.slow,
                            curve: Curves.easeOutCubic,
                            height: peak == 0
                                ? 3
                                : (point.count / peak * 62).clamp(3, 62),
                            decoration: BoxDecoration(
                              color: point.count == 0
                                  ? AppColors.border
                                  : AppColors.ink,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Format.weekdayFromIso(point.date),
                            style: AppText.micro.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
