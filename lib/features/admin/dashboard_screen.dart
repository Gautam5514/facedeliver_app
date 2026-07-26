import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/billing_models.dart';
import '../../data/models/stats_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/billing_repository.dart';
import '../../state/session_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/states.dart';
import '../../widgets/surfaces.dart';
import 'widgets/event_row.dart';
import 'widgets/quota_card.dart';
import 'widgets/stat_tile.dart';

/// Organiser home: totals, upload capacity, and the fastest route back into a
/// recent event.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats _stats = DashboardStats.empty;
  BillingStatus _billing = BillingStatus.none;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);

    try {
      // Billing failing must not blank the dashboard — stats are the point.
      final results = await Future.wait([
        context.read<AdminRepository>().dashboardStats(),
        context
            .read<BillingRepository>()
            .status()
            .catchError((_) => BillingStatus.none),
      ]);

      if (!mounted) return;
      setState(() {
        _stats = results[0] as DashboardStats;
        _billing = results[1] as BillingStatus;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load your dashboard.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ORGANISER', style: AppText.eyebrow),
            const SizedBox(height: 3),
            Text(
              user == null ? 'Dashboard' : 'Hello, ${user.name.split(' ').first}',
              style: AppText.title.copyWith(fontSize: 19),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.push(Routes.adminProfile),
              child: Avatar(
                label: user?.name ?? 'A',
                imageUrl: user?.profileImageUrl,
                size: 40,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.ink,
        backgroundColor: AppColors.surface,
        child: _loading
            ? const _DashboardSkeleton()
            : _error != null
                ? ListView(
                    children: [
                      StateMessage(
                        icon: Icons.cloud_off_rounded,
                        title: 'Dashboard unavailable',
                        message: _error!,
                        tone: ChipTone.danger,
                        actionLabel: 'Try again',
                        onAction: _load,
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: [
                      QuotaCard(
                        billing: _billing,
                        onManage: () => context.go(Routes.adminBilling),
                      ),
                      const SizedBox(height: 22),
                      const SectionHeading(
                        eyebrow: 'At a glance',
                        title: 'Across all your events',
                      ),
                      const SizedBox(height: 14),
                      StatGrid(
                        tiles: [
                          StatTile(
                            label: 'Events',
                            value: _stats.totalEvents,
                            icon: Icons.event_rounded,
                            caption: 'Created by you',
                          ),
                          StatTile(
                            label: 'Guests',
                            value: _stats.totalGuests,
                            icon: Icons.groups_rounded,
                            caption: 'Registered faces',
                          ),
                          StatTile(
                            label: 'Photos',
                            value: _stats.totalPhotos,
                            icon: Icons.photo_library_rounded,
                            caption: 'Uploaded to galleries',
                          ),
                          StatTile(
                            label: 'Matches',
                            value: _stats.totalMatches,
                            icon: Icons.auto_awesome_rounded,
                            tone: ChipTone.success,
                            caption: _stats.totalGuests == 0
                                ? 'Waiting for guests'
                                : '${_stats.matchesPerGuest.toStringAsFixed(1)} per guest',
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      SectionHeading(
                        eyebrow: 'Recent',
                        title: 'Your latest events',
                        action: _stats.recentEvents.isEmpty
                            ? null
                            : GestureDetector(
                                onTap: () => context.go(Routes.adminEvents),
                                child: Text(
                                  'View all',
                                  style: AppText.bodyStrong.copyWith(
                                    fontSize: 13,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 14),
                      if (_stats.recentEvents.isEmpty)
                        StateMessage(
                          icon: Icons.event_available_rounded,
                          title: 'No events yet',
                          message:
                              'Create your first event to generate a guest QR '
                              'code and start collecting registrations.',
                          compact: true,
                          actionLabel: 'Create an event',
                          onAction: () => context.go(Routes.adminEvents),
                        )
                      else
                        for (final event in _stats.recentEvents)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: EventRow(
                              event: event,
                              onTap: () =>
                                  context.push(Routes.adminEvent(event.id)),
                            ),
                          ),
                      const SizedBox(height: 8),
                      AppButton(
                        label: 'Go to events',
                        icon: Icons.arrow_forward_rounded,
                        tone: AppButtonTone.neutral,
                        onPressed: () => context.go(Routes.adminEvents),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: const [
        ShimmerBox(height: 148, radius: AppTokens.rLg),
        SizedBox(height: 22),
        ShimmerBox(width: 160, height: 18),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: ShimmerBox(height: 108, radius: AppTokens.rLg)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBox(height: 108, radius: AppTokens.rLg)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: ShimmerBox(height: 108, radius: AppTokens.rLg)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBox(height: 108, radius: AppTokens.rLg)),
          ],
        ),
        SizedBox(height: 26),
        SkeletonList(count: 3),
      ],
    );
  }
}
