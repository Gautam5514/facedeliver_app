import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/event_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/feedback.dart';
import '../../widgets/states.dart';
import '../../widgets/surfaces.dart';
import 'widgets/create_event_sheet.dart';
import 'widgets/event_row.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _search = TextEditingController();

  List<EventSummary> _events = const [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final events = await context.read<AdminRepository>().events();
      if (mounted) setState(() => _events = events);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load your events.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createEvent() async {
    final created = await showModalBottomSheet<EventSummary>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateEventSheet(),
    );
    if (created == null || !mounted) return;

    showSnack(context, '“${created.name}” is live.', tone: SnackTone.success);
    await _load();
    if (mounted && created.id.isNotEmpty) {
      context.push(Routes.adminEvent(created.id));
    }
  }

  List<EventSummary> get _visible {
    if (_query.isEmpty) return _events;
    final needle = _query.toLowerCase();
    return _events
        .where((event) =>
            event.name.toLowerCase().contains(needle) ||
            event.code.toLowerCase().contains(needle))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('WORKSPACE', style: AppText.eyebrow),
            const SizedBox(height: 3),
            Text('Events', style: AppText.title.copyWith(fontSize: 19)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AppIconButton(
              icon: Icons.add_rounded,
              tooltip: 'Create event',
              onPressed: _createEvent,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.ink,
        backgroundColor: AppColors.surface,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: SkeletonList(count: 4),
              )
            : _error != null
                ? ListView(
                    children: [
                      StateMessage(
                        icon: Icons.cloud_off_rounded,
                        title: 'Events unavailable',
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
                      if (_events.length > 4) ...[
                        TextField(
                          controller: _search,
                          onChanged: (value) =>
                              setState(() => _query = value.trim()),
                          style: AppText.bodyStrong,
                          decoration: InputDecoration(
                            hintText: 'Search by name or code',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 14, right: 10),
                              child: Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: AppColors.faint,
                              ),
                            ),
                            prefixIconConstraints:
                                const BoxConstraints(minWidth: 0),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_events.isEmpty)
                        StateMessage(
                          icon: Icons.event_available_rounded,
                          title: 'No events yet',
                          message:
                              'An event gives you a QR code for guests to '
                              'register with, and a gallery to upload into.',
                          actionLabel: 'Create your first event',
                          onAction: _createEvent,
                        )
                      else if (visible.isEmpty)
                        const StateMessage(
                          icon: Icons.search_off_rounded,
                          title: 'No matches',
                          message: 'No event matches that name or code.',
                          compact: true,
                        )
                      else ...[
                        for (final event in visible)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: EventRow(
                              event: event,
                              onTap: () =>
                                  context.push(Routes.adminEvent(event.id)),
                            ),
                          ),
                        const SizedBox(height: 10),
                        AppButton(
                          label: 'Create event',
                          icon: Icons.add_rounded,
                          tone: AppButtonTone.neutral,
                          onPressed: _createEvent,
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}
