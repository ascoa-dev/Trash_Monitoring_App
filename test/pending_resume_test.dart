import 'package:flutter_test/flutter_test.dart';
import 'package:we_monitor/shared/services/pending_upload_service.dart';

void main() {
  final paths = ['a', 'b', 'c', 'd', 'e'];

  Future<({String full, String thumb})?> compress(String path) async =>
      path == 'gone' ? null : (full: '$path.full', thumb: '$path.thumb');

  test('resumes from the first photo without a URL', () async {
    // Photos 1 and 2 went up before the connection dropped.
    final full = {'a': 'url-a', 'b': 'url-b'};
    final thumb = {'a': 'th-a', 'b': 'th-b'};
    final uploadedBases = <String>[];
    var persists = 0;

    final missing = await resumePhotoUploads(
      folder: 'cleanups/doc1',
      localPaths: paths,
      full: full,
      thumb: thumb,
      missing: [],
      persist: () async => persists++,
      compress: compress,
      upload: (folder, base, files) async {
        uploadedBases.add(base);
        return (full: 'url-$base', thumb: 'th-$base');
      },
    );

    expect(missing, 0);
    expect(uploadedBases, ['p2', 'p3', 'p4']); // stable names, from the 3rd
    expect(persists, 3); // saved after every photo
    expect(orderedUrls(paths, full, thumb).full, [
      'url-a',
      'url-b',
      'url-p2',
      'url-p3',
      'url-p4',
    ]);
  });

  test('a failure keeps earlier progress for the next attempt', () async {
    final full = <String, String>{};
    final thumb = <String, String>{};
    Future<({String full, String thumb})> flaky(
      String folder,
      String base,
      ({String full, String thumb}) files,
    ) async {
      if (base == 'p2') throw Exception('network dropped');
      return (full: 'url-$base', thumb: 'th-$base');
    }

    await expectLater(
      resumePhotoUploads(
        folder: 'f',
        localPaths: paths,
        full: full,
        thumb: thumb,
        missing: [],
        persist: () async {},
        compress: compress,
        upload: flaky,
      ),
      throwsException,
    );
    expect(full.keys, ['a', 'b']);
  });

  test('missing photos are reported, skipped and not retried', () async {
    final full = <String, String>{};
    final thumb = <String, String>{};
    final missingList = <String>[];
    Future<int> run() => resumePhotoUploads(
      folder: 'f',
      localPaths: ['a', 'gone', 'c'],
      full: full,
      thumb: thumb,
      missing: missingList,
      persist: () async {},
      compress: compress,
      upload: (folder, base, files) async => (full: base, thumb: base),
    );

    expect(await run(), 1);
    expect(missingList, ['gone']);
    expect(await run(), 0); // already reported once
    expect(orderedUrls(['a', 'gone', 'c'], full, thumb).full, ['p0', 'p2']);
  });
}
