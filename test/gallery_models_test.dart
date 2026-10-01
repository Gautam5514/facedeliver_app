import 'package:flutter_test/flutter_test.dart';

import 'package:facedeliver/data/models/gallery_models.dart';

void main() {
  group('GuestGallery.fromJson', () {
    test('parses events, photos and denormalises the event name', () {
      final gallery = GuestGallery.fromJson({
        'guestName': 'Asha',
        'selfieUrl': 'https://cdn.example/selfie.jpg',
        'totalPhotos': 3,
        'events': [
          {
            'eventId': 'sharma-wedding-2026',
            'eventName': 'Sharma Wedding',
            'eventDate': '2026-02-14T00:00:00.000Z',
            'photos': [
              {'id': 'p1', 'url': 'https://cdn.example/1.jpg', 'confidence': 0.9},
              {'id': 'p2', 'url': 'https://cdn.example/2.jpg', 'confidence': 0.8},
            ],
          },
          {
            'eventId': 'office-party',
            'eventName': 'Office Party',
            'photos': [
              {'id': 'p3', 'url': 'https://cdn.example/3.jpg', 'confidence': 0.7},
            ],
          },
        ],
      });

      expect(gallery.guestName, 'Asha');
      expect(gallery.selfieUrl, 'https://cdn.example/selfie.jpg');
      expect(gallery.events, hasLength(2));
      expect(gallery.events.first.eventName, 'Sharma Wedding');
      expect(gallery.events.first.eventDate, isNotNull);
      // Each photo carries its parent event's name for the viewer's label.
      expect(gallery.events.first.photos.first.eventName, 'Sharma Wedding');
      expect(gallery.events.last.photos.single.eventName, 'Office Party');
    });

    test('falls back to safe defaults on missing / malformed fields', () {
      final gallery = GuestGallery.fromJson(const {});
      expect(gallery.guestName, 'Guest');
      expect(gallery.selfieUrl, isNull);
      expect(gallery.totalPhotos, 0);
      expect(gallery.events, isEmpty);
    });

    test('event name falls back to the event id when name is blank', () {
      final gallery = GuestGallery.fromJson({
        'events': [
          {
            'eventId': 'code-only',
            'eventName': '   ',
            'photos': const [],
          },
        ],
      });
      expect(gallery.events.single.eventName, 'code-only');
    });

    test('allPhotos flattens groups in order for viewer swipe navigation', () {
      final gallery = GuestGallery.fromJson({
        'events': [
          {
            'eventId': 'a',
            'eventName': 'A',
            'photos': [
              {'id': 'a1', 'url': 'u', 'confidence': 1},
              {'id': 'a2', 'url': 'u', 'confidence': 1},
            ],
          },
          {
            'eventId': 'b',
            'eventName': 'B',
            'photos': [
              {'id': 'b1', 'url': 'u', 'confidence': 1},
            ],
          },
        ],
      });

      expect(
        gallery.allPhotos.map((p) => p.id).toList(),
        ['a1', 'a2', 'b1'],
      );
    });
  });
}
