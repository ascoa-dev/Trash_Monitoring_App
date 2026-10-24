import 'package:flutter_test/flutter_test.dart';
import 'package:we_monitor/shared/drafts/form_draft.dart';

void main() {
  test('draft -> json -> draft round trip keeps everything', () {
    final draft = FormDraft(
      kind: FormDraft.kindCleanup,
      docId: 'abc123',
      savedAt: DateTime.utc(2026, 10, 24, 12, 30),
      peopleCount: 4,
      groupName: 'Beach crew',
      date: '24/10/2026',
      location: 'Limbe, Cameroon',
      locationLatitude: 4.0186,
      locationLongitude: 9.2057,
      locationVerified: true,
      selectedEnvironments: {'Beach'},
      trashItems: {'Plastic bottle': 3, 'Bag': 2},
      basicInfoCompleted: true,
      trashCollectedCompleted: true,
      expandedSection: 'Photos & Videos (Optional)',
      photos: const [
        DraftPhoto(
          path: '/docs/drafts/a.jpg',
          url: 'https://x/a.jpg',
          thumbUrl: 'https://x/a_thumb.jpg',
        ),
        DraftPhoto(path: '/docs/drafts/b.jpg'),
      ],
    );

    final back = FormDraft.decode(draft.encode());

    expect(back.toJson(), draft.toJson());
    expect(back.itemCount, 5);
    expect(back.photos[0].url, 'https://x/a.jpg');
    expect(back.photos[0].thumbUrl, 'https://x/a_thumb.jpg');
    expect(back.photos[1].url, isNull);
    expect(back.hasContent, isTrue);
  });

  test('old draft photos without thumbUrl still decode', () {
    final photo = DraftPhoto.fromJson({'path': '/a.jpg', 'url': 'https://x/a'});
    expect(photo.thumbUrl, isNull);
    expect(photo.url, 'https://x/a');
  });

  test('untouched draft has no content', () {
    final empty = FormDraft(
      kind: FormDraft.kindHotspot,
      docId: 'id',
      savedAt: DateTime.utc(2026),
    );
    expect(FormDraft.decode(empty.encode()).hasContent, isFalse);
  });
}
