import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/event_models.dart';
import '../../widgets/states.dart';
import '../../widgets/surfaces.dart';

/// Everyone who registered for this event, newest first.
///
/// Face descriptors and Cloudinary ids are stripped server-side, so this is
/// deliberately a roster and not a data-management tool.
class EventGuestsScreen extends StatefulWidget {
  const EventGuestsScreen({super.key, required this.event});

  final EventDetail event;

  @override
  State<EventGuestsScreen> createState() => _EventGuestsScreenState();
}

class _EventGuestsScreenState extends State<EventGuestsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<EventGuest> get _visible {
    final guests = [...widget.event.guests]..sort((a, b) {
        final aDate = a.registeredAt;
        final bDate = b.registeredAt;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

    if (_query.isEmpty) return guests;
    final needle = _query.toLowerCase();
    return guests
        .where((guest) =>
            guest.name.toLowerCase().contains(needle) ||
            guest.email.toLowerCase().contains(needle))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Guests'),
            Text(
              '${Format.plural(widget.event.guestCount, 'registration')} · ${widget.event.name}',
              style: AppText.micro,
            ),
          ],
        ),
      ),
      body: widget.event.guests.isEmpty
          ? const StateMessage(
              icon: Icons.person_search_rounded,
              title: 'No registrations yet',
              message:
                  'Share the event QR code so guests can register their face '
                  'and start receiving photos.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (widget.event.guests.length > 6) ...[
                  TextField(
                    controller: _search,
                    onChanged: (value) => setState(() => _query = value.trim()),
                    style: AppText.bodyStrong,
                    decoration: const InputDecoration(
                      hintText: 'Search name or email',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(left: 14, right: 10),
                        child: Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: AppColors.faint,
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(minWidth: 0),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (visible.isEmpty)
                  const StateMessage(
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    message: 'No guest matches that name or email.',
                    compact: true,
                  )
                else
                  for (final guest in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GuestRow(guest: guest),
                    ),
              ],
            ),
    );
  }
}

class _GuestRow extends StatelessWidget {
  const _GuestRow({required this.guest});

  final EventGuest guest;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Avatar(label: guest.name, imageUrl: guest.selfieUrl, size: 44),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.name,
                  style: AppText.bodyStrong.copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  guest.email,
                  style: AppText.micro,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Format.relative(guest.registeredAt), style: AppText.micro),
              const SizedBox(height: 5),
              if (guest.consentGivenAt != null)
                const StatusChip(
                  label: 'Consented',
                  tone: ChipTone.success,
                  icon: Icons.verified_user_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
