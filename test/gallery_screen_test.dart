import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:facedeliver/data/models/gallery_models.dart';
import 'package:facedeliver/data/repositories/guest_repository.dart';
import 'package:facedeliver/features/guest/gallery_screen.dart';

/// A repository that returns a fixed gallery without touching the network,
/// so the grid's lazy layout can be exercised in a widget test.
class _FakeGuestRepository implements GuestRepository {
  _FakeGuestRepository(this._gallery);

  final GuestGallery _gallery;

  @override
  Future<GuestGallery> myGallery() async => _gallery;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

GuestGallery _galleryWith(int photoCount) {
  return GuestGallery.fromJson({
    'guestName': 'Asha',
    'totalPhotos': photoCount,
    'events': [
      {
        'eventId': 'wedding',
        'eventName': 'Wedding',
        'photos': [
          for (var i = 0; i < photoCount; i++)
            {'id': 'p$i', 'url': 'https://cdn.example/$i.jpg', 'confidence': 0.9},
        ],
      },
    ],
  });
}

void main() {
  testWidgets('gallery grid renders lazily without building every tile',
      (tester) async {
    // 40 photos across one event. The old eager layout built all 40 images at
    // once; the lazy sliver should only build the rows near the viewport.
    final repo = _FakeGuestRepository(_galleryWith(40));

    await tester.pumpWidget(
      MaterialApp(
        home: Provider<GuestRepository>.value(
          value: repo,
          child: const GalleryScreen(),
        ),
      ),
    );

    // Let the async load() complete and the grid settle.
    await tester.pumpAndSettle();

    // The screen rendered without throwing (no overflow, no failed layout) and
    // shows the archive banner — proof the data path and grid built.
    expect(find.text('Download everything'), findsOneWidget);

    // Lazy building: the grid is a SliverList that materialises rows on demand,
    // so only a subset of the 40 photos' Hero tiles exist in the tree. If the
    // old eager layout were still in place, all 40 would be built at once.
    final heroCount = find.byType(Hero).evaluate().length;
    expect(heroCount, greaterThan(0),
        reason: 'visible rows should build at least one tile');
    expect(heroCount, lessThan(40),
        reason: 'off-screen tiles should not be built (lazy sliver)');
  });

  testWidgets('empty gallery shows the awaiting-photos state', (tester) async {
    final repo = _FakeGuestRepository(_galleryWith(0));

    await tester.pumpWidget(
      MaterialApp(
        home: Provider<GuestRepository>.value(
          value: repo,
          child: const GalleryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // "No photos yet" appears both as the header subtitle and the empty-state
    // title; the awaiting-photos body copy is unique to the empty state.
    expect(
      find.textContaining('matching runs automatically'),
      findsOneWidget,
    );
  });
}
