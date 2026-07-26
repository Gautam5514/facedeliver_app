import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../core/theme/app_colors.dart' show AppTokens;
import '../../core/theme/app_theme.dart';
import '../../data/models/gallery_models.dart';
import '../../widgets/app_button.dart';
import '../../widgets/feedback.dart';
import 'gallery_controller.dart';

/// Full-screen photo viewer: pinch to zoom, swipe between matches, save to the
/// device library.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.controller,
  });

  final List<GalleryPhoto> photos;
  final int initialIndex;
  final GalleryController controller;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  bool _saving = false;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  GalleryPhoto get _current => widget.photos[_index];

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.controller.savePhoto(_current);
      if (mounted) {
        showSnack(context, 'Saved to your photos.', tone: SnackTone.success);
      }
    } catch (_) {
      if (mounted) {
        showSnack(
          context,
          'Could not save that photo. Check storage permissions.',
          tone: SnackTone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => _chromeVisible = !_chromeVisible),
            child: PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) => setState(() => _index = index),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              loadingBuilder: (_, _) => const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white54),
                  ),
                ),
              ),
              builder: (context, index) => PhotoViewGalleryPageOptions(
                imageProvider:
                    CachedNetworkImageProvider(widget.photos[index].url),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3.5,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: widget.photos[index].id,
                ),
              ),
            ),
          ),

          // Top chrome
          AnimatedOpacity(
            opacity: _chromeVisible ? 1 : 0,
            duration: AppTokens.fast,
            child: IgnorePointer(
              ignoring: !_chromeVisible,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      AppIconButton(
                        icon: Icons.close_rounded,
                        onDark: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppTokens.rPill),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Text(
                            _current.eventName,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.micro.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom chrome
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _chromeVisible ? 1 : 0,
              duration: AppTokens.fast,
              child: IgnorePointer(
                ignoring: !_chromeVisible,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 44, 20, 12),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Text(
                          '${_index + 1} / ${widget.photos.length}',
                          style: AppText.micro.copyWith(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        AppButton(
                          label: 'Save photo',
                          icon: Icons.download_rounded,
                          size: AppButtonSize.compact,
                          expand: false,
                          busy: _saving,
                          onPressed: _save,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
