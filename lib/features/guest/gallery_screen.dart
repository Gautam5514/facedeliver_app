import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/gallery_models.dart';
import '../../data/repositories/guest_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/feedback.dart';
import '../../widgets/states.dart';
import '../../widgets/surfaces.dart';
import 'gallery_controller.dart';
import 'photo_viewer_screen.dart';

/// The guest's personal gallery — every photo they appear in, grouped by event.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late final GalleryController _controller =
      GalleryController(context.read<GuestRepository>())..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _shareArchive() async {
    try {
      final path = await _controller.downloadArchive();
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'My photos from FaceDeliver',
        ),
      );
    } catch (error) {
      if (mounted) {
        showSnack(
          context,
          error.toString().replaceFirst('Exception: ', ''),
          tone: SnackTone.danger,
        );
      }
    }
  }

  void _openViewer(GalleryPhoto photo) {
    final photos = _controller.visiblePhotos;
    final index = photos.indexWhere((item) => item.id == photo.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoViewerScreen(
          photos: photos,
          initialIndex: index < 0 ? 0 : index,
          controller: _controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final gallery = _controller.gallery;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => _controller.load(refresh: true),
            color: AppColors.ink,
            backgroundColor: AppColors.surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  toolbarHeight: 64,
                  backgroundColor: AppColors.canvas,
                  automaticallyImplyLeading: false,
                  titleSpacing: 20,
                  title: _Header(gallery: gallery),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: AppIconButton(
                        icon: Icons.settings_outlined,
                        tooltip: 'Account & privacy',
                        onPressed: () => context.push(Routes.guestAccount),
                      ),
                    ),
                  ],
                  bottom: gallery.events.length > 1
                      ? PreferredSize(
                          preferredSize: const Size.fromHeight(52),
                          child: _EventFilterBar(controller: _controller),
                        )
                      : null,
                ),
                if (_controller.loading)
                  const SliverToBoxAdapter(child: _GallerySkeleton())
                else if (_controller.error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: StateMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Unable to load gallery',
                      message: _controller.error!,
                      tone: ChipTone.danger,
                      actionLabel: 'Try again',
                      onAction: () => _controller.load(refresh: true),
                    ),
                  )
                else if (_controller.isAwaitingPhotos)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _AwaitingPhotos(),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: _ArchiveBanner(
                      controller: _controller,
                      onShare: _shareArchive,
                    ),
                  ),
                  for (final group in _controller.visibleGroups)
                    ..._eventSlivers(group),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _eventSlivers(GalleryEventGroup group) {
    final showHeader = _controller.selectedEventId == null &&
        _controller.gallery.events.length > 1;

    return [
      if (showHeader)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            child: Row(
              children: [
                EventMonogram(label: group.eventName, size: 34),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.eventName,
                        style: AppText.bodyStrong,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Format.plural(group.photos.length, 'photo')}'
                        '${group.eventDate == null ? '' : ' · ${Format.date(group.eventDate)}'}',
                        style: AppText.micro,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
      else
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: _PhotoMosaic(photos: group.photos, onOpen: _openViewer),
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.gallery});

  final GuestGallery gallery;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Avatar(
          label: gallery.guestName,
          imageUrl: gallery.selfieUrl,
          size: 40,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                gallery.guestName,
                style: AppText.bodyStrong.copyWith(fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                gallery.totalPhotos == 0
                    ? 'No photos yet'
                    : '${Format.count(gallery.totalPhotos)} photos matched',
                style: AppText.micro,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Horizontal event filter, shown only when a guest attended more than one.
class _EventFilterBar extends StatelessWidget {
  const _EventFilterBar({required this.controller});

  final GalleryController controller;

  @override
  Widget build(BuildContext context) {
    final gallery = controller.gallery;

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        children: [
          _chip(
            label: 'All photos',
            count: gallery.totalPhotos,
            selected: controller.selectedEventId == null,
            onTap: () => controller.selectEvent(null),
          ),
          for (final group in gallery.events)
            _chip(
              label: group.eventName,
              count: group.photos.length,
              selected: controller.selectedEventId == group.eventId,
              onTap: () => controller.selectEvent(group.eventId),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppTokens.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.surface,
            borderRadius: BorderRadius.circular(AppTokens.rPill),
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyStrong.copyWith(
                    fontSize: 12.5,
                    color: selected ? Colors.white : AppColors.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '$count',
                style: AppText.micro.copyWith(
                  fontSize: 11,
                  color: selected ? Colors.white70 : AppColors.faint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-column mosaic. Heights vary by a hash of the photo id so the layout is
/// visually alive but never reshuffles between rebuilds.
///
/// Built as a lazy sliver: photos are laid out as a sequence of two-up rows
/// (one tile per column) and only the rows near the viewport are instantiated.
/// A large wedding gallery can hold hundreds of matched photos — building every
/// [CachedNetworkImage] up front spiked memory and stalled the first frame, so
/// the grid is materialised on demand as the guest scrolls instead.
class _PhotoMosaic extends StatelessWidget {
  const _PhotoMosaic({required this.photos, required this.onOpen});

  final List<GalleryPhoto> photos;
  final ValueChanged<GalleryPhoto> onOpen;

  static double _aspect(String id) {
    final sum = id.codeUnits.fold<int>(0, (total, unit) => total + unit);
    return switch (sum % 3) {
      0 => 0.74,
      1 => 1.0,
      _ => 1.32,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Alternate the two columns so the mosaic stays balanced, then pair them
    // up into rows the sliver can build lazily. Column 0 takes even indices,
    // column 1 the odd ones — the same distribution as before, just row-wise.
    final rowCount = (photos.length + 1) ~/ 2;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, row) {
          final leftIndex = row * 2;
          final rightIndex = leftIndex + 1;
          final left = photos[leftIndex];
          final right = rightIndex < photos.length ? photos[rightIndex] : null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PhotoTile(
                    photo: left,
                    aspect: _aspect(left.id),
                    onTap: () => onOpen(left),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: right == null
                      ? const SizedBox.shrink()
                      : _PhotoTile(
                          photo: right,
                          aspect: _aspect(right.id),
                          onTap: () => onOpen(right),
                        ),
                ),
              ],
            ),
          );
        },
        childCount: rowCount,
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.aspect,
    required this.onTap,
  });

  final GalleryPhoto photo;
  final double aspect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // A tile is roughly half the screen wide. Decode the bitmap to that width
    // (in physical pixels) rather than the source's full resolution — a
    // wedding photo is several thousand pixels wide, and decoding hundreds of
    // them at full size is the difference between a smooth grid and an
    // out-of-memory crash.
    final media = MediaQuery.of(context);
    final tileWidth = (media.size.width / 2) * media.devicePixelRatio;
    final decodeWidth = tileWidth.clamp(1.0, 1080.0).round();

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: photo.id,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppTokens.rLg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: AspectRatio(
            aspectRatio: aspect,
            child: CachedNetworkImage(
              imageUrl: photo.url,
              fit: BoxFit.cover,
              memCacheWidth: decodeWidth,
              fadeInDuration: AppTokens.normal,
              placeholder: (_, _) => const ColoredBox(
                color: AppColors.surfaceAlt,
              ),
              errorWidget: (_, _, _) => const ColoredBox(
                color: AppColors.surfaceAlt,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.ghost,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Prominent "download everything" affordance — the single action most guests
/// come here for.
class _ArchiveBanner extends StatelessWidget {
  const _ArchiveBanner({required this.controller, required this.onShare});

  final GalleryController controller;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final total = controller.gallery.totalPhotos;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.folder_zip_outlined,
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
                    'Download everything',
                    style: AppText.bodyStrong.copyWith(fontSize: 13.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${Format.plural(total, 'photo')} as one archive',
                    style: AppText.micro,
                  ),
                ],
              ),
            ),
            AppButton(
              label: controller.zipping ? 'Preparing' : 'Get ZIP',
              size: AppButtonSize.compact,
              expand: false,
              busy: controller.zipping,
              onPressed: onShare,
            ),
          ],
        ),
      ),
    );
  }
}

/// Registered, but the organiser has not delivered anything yet.
class _AwaitingPhotos extends StatelessWidget {
  const _AwaitingPhotos();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StateMessage(
            icon: Icons.hourglass_top_rounded,
            title: 'No photos yet',
            message:
                'Your face is registered. As soon as the organiser uploads the '
                'gallery, matching runs automatically and your photos appear '
                'here — we will email you too.',
            compact: true,
          ),
          const SizedBox(height: 4),
          const InfoBanner(
            message:
                'Pull down to refresh. Matching a large wedding album can take '
                'a little while after the upload finishes.',
            icon: Icons.swipe_down_rounded,
          ),
        ],
      ),
    );
  }
}

class _GallerySkeleton extends StatelessWidget {
  const _GallerySkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          const ShimmerBox(height: 74, radius: AppTokens.rLg),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: const [
                    ShimmerBox(height: 210, radius: AppTokens.rLg),
                    SizedBox(height: 12),
                    ShimmerBox(height: 150, radius: AppTokens.rLg),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: const [
                    ShimmerBox(height: 150, radius: AppTokens.rLg),
                    SizedBox(height: 12),
                    ShimmerBox(height: 210, radius: AppTokens.rLg),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
