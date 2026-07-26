import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/billing_models.dart';
import '../../data/models/event_models.dart';
import '../../data/models/stats_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/billing_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/feedback.dart';
import '../../widgets/states.dart';
import '../../widgets/surfaces.dart';
import 'event_guests_screen.dart';
import 'upload_controller.dart';
import 'widgets/stat_tile.dart';

/// Everything an organiser does for one event: share the QR, upload the
/// gallery, watch matching progress, and check delivery.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _picker = ImagePicker();
  late final UploadController _upload =
      UploadController(context.read<AdminRepository>());

  EventDetail? _event;
  DownloadStats _stats = DownloadStats.empty;
  BillingStatus _billing = BillingStatus.none;
  bool _loading = true;
  bool _matching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _upload.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);

    try {
      final event = await context.read<AdminRepository>().event(widget.eventId);
      if (!mounted) return;
      setState(() => _event = event);

      // Delivery stats and billing are secondary — a failure in either must not
      // hide the event itself.
      final extras = await Future.wait([
        context
            .read<AdminRepository>()
            .downloadStats(event.code)
            .catchError((_) => DownloadStats.empty),
        context
            .read<BillingRepository>()
            .status()
            .catchError((_) => BillingStatus.none),
      ]);

      if (!mounted) return;
      setState(() {
        _stats = extras[0] as DownloadStats;
        _billing = extras[1] as BillingStatus;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load this event.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _registrationLink =>
      AppConfig.registrationLink(_event?.code ?? '');

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _registrationLink));
    if (mounted) {
      showSnack(context, 'Registration link copied.', tone: SnackTone.success);
    }
  }

  Future<void> _shareLink() async {
    final event = _event;
    if (event == null) return;

    await SharePlus.instance.share(
      ShareParams(
        text: 'Get your photos from ${event.name}: $_registrationLink',
        subject: 'Your photos from ${event.name}',
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    final event = _event;
    if (event == null) return;

    if (!_billing.hasPlan) {
      showSnack(
        context,
        'Activate a plan before uploading photos.',
        tone: SnackTone.danger,
      );
      return;
    }

    final picked = await _picker.pickMultiImage(limit: 300);
    if (picked.isEmpty || !mounted) return;

    // The server rejects the whole batch if it exceeds the remaining quota, so
    // catch it here where we can say exactly how far over the organiser is.
    final remaining = _billing.remainingUploads;
    if (picked.length > remaining) {
      showSnack(
        context,
        'You selected ${picked.length} photos but only '
        '${Format.count(remaining)} uploads remain this period.',
        tone: SnackTone.danger,
      );
      return;
    }

    final confirmed = await confirmAction(
      context,
      title: 'Upload ${Format.plural(picked.length, 'photo')}?',
      message:
          'Photos are optimised on this device, then uploaded in batches of '
          '${AppConfig.uploadBatchSize}. Face detection and matching run in the '
          'background — guests are emailed automatically when their photos are '
          'ready.',
      confirmLabel: 'Start upload',
      icon: Icons.cloud_upload_rounded,
    );
    if (!confirmed || !mounted) return;

    final success = await _upload.upload(
      eventCode: event.code,
      sourcePaths: picked.map((file) => file.path).toList(growable: false),
    );

    if (!mounted) return;
    if (success) {
      showSnack(context, _upload.summary ?? 'Upload complete.',
          tone: SnackTone.success);
      await _load();
    } else if (_upload.error != null) {
      showSnack(context, _upload.error!, tone: SnackTone.danger);
    }
  }

  Future<void> _startMatching() async {
    final event = _event;
    if (event == null) return;

    setState(() => _matching = true);
    try {
      final message =
          await context.read<AdminRepository>().startMatching(event.code);
      if (mounted) showSnack(context, message, tone: SnackTone.success);
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        // 409 means the worker is already on it — reassurance, not an error.
        showSnack(
          context,
          error.message,
          tone: error.isConflict ? SnackTone.neutral : SnackTone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _matching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: event == null
            ? const Text('Event')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.name,
                    style: AppText.heading,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(event.code, style: AppText.micro),
                ],
              ),
        actions: [
          if (event != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: AppIconButton(
                icon: Icons.ios_share_rounded,
                tooltip: 'Share registration link',
                onPressed: _shareLink,
              ),
            ),
        ],
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: SkeletonList(count: 4, height: 120),
            )
          : _error != null || event == null
              ? StateMessage(
                  icon: Icons.event_busy_rounded,
                  title: 'Event unavailable',
                  message: _error ?? 'This event could not be loaded.',
                  tone: ChipTone.danger,
                  actionLabel: 'Try again',
                  onAction: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.ink,
                  backgroundColor: AppColors.surface,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                    children: [
                      if (event.isProcessing) ...[
                        InfoBanner(
                          title: 'Processing in the background',
                          message:
                              '${Format.plural(event.pendingProcessing, 'photo')} '
                              'queued for face detection'
                              '${event.activeJobs > 0 ? ', ${event.activeJobs} in progress' : ''}. '
                              'Matching starts automatically when the batch '
                              'finishes.',
                          icon: Icons.autorenew_rounded,
                          tone: ChipTone.warning,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (event.failedPhotos > 0) ...[
                        InfoBanner(
                          title:
                              '${Format.plural(event.failedPhotos, 'photo')} failed to process',
                          message:
                              'These have no face data and will never match. '
                              'Re-upload them — the next upload clears the '
                              'failed records automatically.',
                          icon: Icons.error_outline_rounded,
                          tone: ChipTone.danger,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _QrCard(
                        event: event,
                        link: _registrationLink,
                        onCopy: _copyLink,
                        onShare: _shareLink,
                      ),
                      const SizedBox(height: 22),
                      const SectionHeading(
                        eyebrow: 'This event',
                        title: 'Registration & matching',
                      ),
                      const SizedBox(height: 14),
                      StatGrid(
                        tiles: [
                          StatTile(
                            label: 'Guests',
                            value: event.guestCount,
                            icon: Icons.groups_rounded,
                            caption: 'Faces registered',
                          ),
                          StatTile(
                            label: 'Photos',
                            value: event.photoCount,
                            icon: Icons.photo_library_rounded,
                            caption: event.pendingProcessing > 0
                                ? '${event.pendingProcessing} still processing'
                                : 'All processed',
                            tone: event.pendingProcessing > 0
                                ? ChipTone.warning
                                : ChipTone.neutral,
                          ),
                          StatTile(
                            label: 'Matches',
                            value: event.matchCount,
                            icon: Icons.auto_awesome_rounded,
                            tone: ChipTone.success,
                            caption: 'Guest-photo pairs',
                          ),
                          StatTile(
                            label: 'Downloads',
                            value: _stats.allTimeDownloads,
                            icon: Icons.download_rounded,
                            caption:
                                '${_stats.uniqueGuestsDownloaded} guests collected',
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _UploadPanel(
                        controller: _upload,
                        billing: _billing,
                        onPick: _pickAndUpload,
                        onCancel: _upload.cancel,
                      ),
                      const SizedBox(height: 16),
                      _MatchingCard(
                        event: event,
                        busy: _matching,
                        onRun: _startMatching,
                      ),
                      const SizedBox(height: 22),
                      const SectionHeading(
                        eyebrow: 'Delivery',
                        title: 'Did guests get their photos?',
                      ),
                      const SizedBox(height: 14),
                      _DeliveryCard(stats: _stats),
                      const SizedBox(height: 22),
                      AppButton(
                        label: 'View ${Format.plural(event.guestCount, 'guest')}',
                        icon: Icons.groups_rounded,
                        tone: AppButtonTone.neutral,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => EventGuestsScreen(event: event),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

/// The QR card. This is the artefact organisers physically print and display,
/// so it is rendered large, on white, with the code spelled out beneath.
class _QrCard extends StatelessWidget {
  const _QrCard({
    required this.event,
    required this.link,
    required this.onCopy,
    required this.onShare,
  });

  final EventDetail event;
  final String link;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GUEST REGISTRATION', style: AppText.eyebrow),
                    const SizedBox(height: 5),
                    Text(
                      'Share this QR code',
                      style: AppText.title.copyWith(fontSize: 17),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: Format.plural(event.guestCount, 'guest'),
                icon: Icons.groups_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTokens.rMd),
              border: Border.all(color: AppColors.border),
            ),
            child: QrImageView(
              data: link,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.ink,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppTokens.rSm),
            ),
            child: Text(
              link,
              textAlign: TextAlign.center,
              style: AppText.micro.copyWith(fontSize: 11.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Copy link',
                  icon: Icons.link_rounded,
                  tone: AppButtonTone.neutral,
                  size: AppButtonSize.compact,
                  onPressed: onCopy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Share',
                  icon: Icons.ios_share_rounded,
                  size: AppButtonSize.compact,
                  onPressed: onShare,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadPanel extends StatelessWidget {
  const _UploadPanel({
    required this.controller,
    required this.billing,
    required this.onPick,
    required this.onCancel,
  });

  final UploadController controller;
  final BillingStatus billing;
  final VoidCallback onPick;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.cloud_upload_rounded,
                      size: 19,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload the gallery',
                          style: AppText.bodyStrong.copyWith(fontSize: 14.5),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          billing.hasPlan
                              ? '${Format.count(billing.remainingUploads)} uploads left this period'
                              : 'A plan is required before uploading',
                          style: AppText.micro,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (controller.isBusy) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.phaseLabel,
                        style: AppText.bodyStrong.copyWith(fontSize: 13),
                      ),
                    ),
                    Text(
                      '${controller.progress}%',
                      style: AppText.bodyStrong.copyWith(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ProgressTrack(percent: controller.progress),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Cancel upload',
                  tone: AppButtonTone.neutral,
                  size: AppButtonSize.compact,
                  onPressed: onCancel,
                ),
              ] else ...[
                const SizedBox(height: 16),
                AppButton(
                  label: 'Select photos',
                  icon: Icons.add_photo_alternate_outlined,
                  onPressed: billing.hasPlan ? onPick : null,
                ),
                const SizedBox(height: 10),
                Text(
                  'Photos are resized on this device before upload, so a slow '
                  'venue connection is far less painful.',
                  style: AppText.micro.copyWith(height: 1.45),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MatchingCard extends StatelessWidget {
  const _MatchingCard({
    required this.event,
    required this.busy,
    required this.onRun,
  });

  final EventDetail event;
  final bool busy;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final blocked = event.isProcessing || event.guestCount == 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Re-run matching',
                  style: AppText.bodyStrong.copyWith(fontSize: 14.5),
                ),
              ),
              StatusChip(
                label: event.isProcessing ? 'Processing' : 'Idle',
                tone: event.isProcessing ? ChipTone.warning : ChipTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            event.guestCount == 0
                ? 'No guests have registered yet, so there is nothing to match '
                    'photos against.'
                : 'Matching runs automatically after every upload and whenever '
                    'a new guest registers. Run it by hand only if something '
                    'looks out of date.',
            style: AppText.caption.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Run matching now',
            icon: Icons.auto_awesome_rounded,
            tone: AppButtonTone.neutral,
            size: AppButtonSize.compact,
            busy: busy,
            onPressed: blocked ? null : onRun,
          ),
        ],
      ),
    );
  }
}

/// Download analytics: coverage, unique collectors, and a 7-day trend.
class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.stats});

  final DownloadStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.totalPhotos == 0) {
      return const AppCard(
        child: InfoBanner(
          message:
              'Delivery numbers appear once photos are uploaded and guests '
              'start downloading.',
          icon: Icons.insights_outlined,
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${stats.coveragePercent}%',
                style: AppText.metric,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'of photos downloaded at least once',
                  style: AppText.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressTrack(
            percent: stats.coveragePercent,
            color: stats.coveragePercent >= 60
                ? AppColors.success
                : AppColors.ink,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(label: 'Today', value: stats.todayDownloads),
              _MiniStat(label: 'All time', value: stats.allTimeDownloads),
              _MiniStat(label: 'Not yet seen', value: stats.notDownloadedPhotos),
            ],
          ),
          if (stats.last7Days.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('LAST 7 DAYS', style: AppText.eyebrow),
            const SizedBox(height: 12),
            SizedBox(height: 70, child: _TrendBars(points: stats.last7Days)),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Format.count(value),
            style: AppText.bodyStrong.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.micro, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Minimal bar chart — bars carry the shape, the peak carries the scale.
class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final peak = points.fold<int>(0, (max, p) => p.count > max ? p.count : max);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final point in points)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    point.count == 0 ? '' : '${point.count}',
                    style: AppText.micro.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  // A hairline keeps zero-days visible instead of vanishing.
                  Container(
                    height: peak == 0 ? 2 : (point.count / peak * 40).clamp(2, 40),
                    decoration: BoxDecoration(
                      color: point.count == 0
                          ? AppColors.border
                          : AppColors.ink,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Format.weekdayFromIso(point.date),
                    style: AppText.micro.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
