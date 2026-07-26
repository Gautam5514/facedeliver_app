import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Three columns of event photos drifting slowly in alternating directions,
/// tilted off-axis. It says "thousands of photos from real events" before a
/// single word of copy is read — which is the whole pitch.
class PhotoWall extends StatefulWidget {
  const PhotoWall({super.key, required this.height});

  final double height;

  @override
  State<PhotoWall> createState() => _PhotoWallState();
}

class _PhotoWallState extends State<PhotoWall>
    with SingleTickerProviderStateMixin {
  static const _columns = <List<String>>[
    ['assets/images/hero_wedding.webp', 'assets/images/feat_qr_scan.webp'],
    ['assets/images/feat_selfie.webp', 'assets/images/hero_college.webp'],
    ['assets/images/hero_birthday.webp', 'assets/images/hero_corporate.webp'],
  ];

  static const double _tileHeight = 168;
  static const double _gap = 10;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 34),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.surfaceAlt),

            // Oversized and rotated so the drifting columns never reveal an
            // edge inside the visible frame.
            Transform.rotate(
              angle: -0.14,
              child: Transform.scale(
                scale: 1.45,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _columns.length; i++) ...[
                        if (i > 0) const SizedBox(width: _gap),
                        Expanded(
                          child: _DriftingColumn(
                            images: _columns[i],
                            // Middle column travels the other way, and each
                            // column starts at a different phase so the wall
                            // never reads as one sliding block.
                            progress: (_controller.value + i * 0.31) % 1,
                            reverse: i.isOdd,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Melt the bottom edge into the page, and knock the whole thing
            // back a little so foreground type stays dominant.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x1AFAFAFA),
                    Color(0x00FAFAFA),
                    Color(0xCCFAFAFA),
                    AppColors.canvas,
                  ],
                  stops: [0.0, 0.28, 0.82, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriftingColumn extends StatelessWidget {
  const _DriftingColumn({
    required this.images,
    required this.progress,
    required this.reverse,
  });

  final List<String> images;
  final double progress;
  final bool reverse;

  static const double _tileHeight = _PhotoWallState._tileHeight;
  static const double _gap = _PhotoWallState._gap;

  @override
  Widget build(BuildContext context) {
    final span = images.length * (_tileHeight + _gap);
    final shift = reverse ? (1 - progress) * span : progress * span;

    return SizedBox(
      height: _tileHeight * 2,
      child: OverflowBox(
        maxHeight: double.infinity,
        alignment: Alignment.topCenter,
        child: Transform.translate(
          offset: Offset(0, -shift),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rendered twice so the translation can wrap seamlessly.
              for (var pass = 0; pass < 3; pass++)
                for (final path in images)
                  Padding(
                    padding: const EdgeInsets.only(bottom: _gap),
                    child: _Tile(path: path),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: _PhotoWallState._tileHeight,
        width: double.infinity,
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          // Sources are 1024², far more than a ~130dp-wide tile needs.
          cacheWidth: 420,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
