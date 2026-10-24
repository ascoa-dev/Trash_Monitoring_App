import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:we_monitor/app/controllers/pending_cleanups_controller.dart';
import 'package:we_monitor/app/controllers/pending_hotspots_controller.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/media_upload_controller.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/services/snackbar_service.dart';

/// Outcome of one pending entry's upload attempt.
enum PendingResult { uploaded, failed, skipped }

/// Uploads offline cleanups and hotspot reports automatically: on launch, when
/// the app comes back to the foreground, when the network returns, and on a
/// retry timer after a failure. The pending screens' Upload buttons go through
/// the same lock, so an entry is never uploaded twice at once.
class PendingUploadService with WidgetsBindingObserver {
  PendingUploadService._();
  static final instance = PendingUploadService._();

  static const _retryDelay = Duration(minutes: 3);

  static Future<void> _tail = Future.value();
  Timer? _retry;
  bool _started = false;
  bool _running = false;
  bool _again = false;

  /// Runs [task] after any upload already in progress (a simple mutex).
  static Future<T> serialize<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    ever<bool>(Get.find<ConnectivityController>().isOnline, (online) {
      if (online) kick();
    });
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) kick();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) kick();
  }

  /// Uploads everything pending for the signed-in user, quietly. Repeated
  /// calls while running collapse into one more pass.
  Future<void> kick() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    _retry?.cancel();
    var uploaded = 0;
    var failed = 0;
    try {
      do {
        _again = false;
        if (FirebaseAuth.instance.currentUser == null) break;
        if (!await Get.find<ConnectivityController>().checkConnectivity()) {
          break;
        }
        final cleanups = Get.find<PendingCleanupsController>();
        final hotspots = Get.find<PendingHotspotsController>();
        await Future.wait([cleanups.ready, hotspots.ready]);
        final results = [
          ...await cleanups.uploadAll(
            silent: true,
          ),
          ...await hotspots.uploadAll(
            silent: true,
          ),
        ];
        uploaded += results.where((r) => r == PendingResult.uploaded).length;
        failed = results.where((r) => r == PendingResult.failed).length;
      } while (_again);
    } catch (e) {
      debugPrint('[PendingUpload] auto upload stopped: $e');
      failed++;
    } finally {
      _running = false;
    }
    if (uploaded > 0) {
      SnackbarService.success(
        'sync.doneTitle'.tr,
        'sync.doneBody'.trPluralParams('sync.doneBodyPlural', uploaded, {
          'count': '$uploaded',
        }),
      );
    }
    // Connected but the upload still failed (bad signal, server error): try
    // again later instead of waiting for the next network change.
    if (failed > 0) _retry = Timer(_retryDelay, kick);
  }
}

/// Uploads each local photo that has no URL yet, saving after every photo so
/// an interrupted run resumes at the next one. Paths are stable
/// (`<folder>/p<index>.jpg`), so a photo whose upload was cut off mid-way is
/// overwritten on retry instead of left behind as an orphan.
///
/// Photos missing from disk (or unreadable) are recorded in [missing] and
/// skipped; returns how many were newly found missing. Network/storage errors
/// are rethrown so the entry stays pending.
Future<int> resumePhotoUploads({
  required String folder,
  required List<String> localPaths,
  required Map<String, String> full,
  required Map<String, String> thumb,
  required List<String> missing,
  required Future<void> Function() persist,
  @visibleForTesting
  Future<({String full, String thumb})?> Function(String path)? compress,
  @visibleForTesting
  Future<({String full, String thumb})> Function(
    String folder,
    String base,
    ({String full, String thumb}) files,
  )?
  upload,
}) async {
  compress ??= (path) async {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      return await compressJpegPair(file);
    } catch (e) {
      debugPrint('[PendingUpload] unreadable photo $path: $e');
      return null;
    }
  };
  upload ??=
      (folder, base, files) => uploadJpegPair(
        folderPath: folder,
        fullPath: files.full,
        thumbPath: files.thumb,
        baseName: base,
      );
  var newlyMissing = 0;
  for (var i = 0; i < localPaths.length; i++) {
    final path = localPaths[i];
    if (full.containsKey(path) || missing.contains(path)) continue;

    final compressed = await compress(path);
    if (compressed == null) {
      missing.add(path);
      newlyMissing++;
      await persist();
      continue;
    }

    final urls = await upload(folder, 'p$i', compressed);
    full[path] = urls.full;
    thumb[path] = urls.thumb;
    await persist();
  }
  return newlyMissing;
}

/// Photos the form already uploaded while online (keyed by local path), so
/// the pending entry reuses them instead of uploading them a second time.
({Map<String, String> full, Map<String, String> thumb}) alreadyUploaded(
  List<PhotoUpload> photos,
) {
  final done = photos.where((ph) => ph.downloadUrl != null);
  return (
    full: {for (final ph in done) ph.file.path: ph.downloadUrl!},
    thumb: {for (final ph in done) ph.file.path: ph.thumbUrl ?? ph.downloadUrl!},
  );
}

/// Uploaded URLs in the original photo order, skipping missing photos.
({List<String> full, List<String> thumb}) orderedUrls(
  List<String> localPaths,
  Map<String, String> full,
  Map<String, String> thumb,
) {
  final paths = localPaths.where(full.containsKey).toList();
  return (
    full: [for (final p in paths) full[p]!],
    thumb: [for (final p in paths) thumb[p] ?? full[p]!],
  );
}

/// Deletes an entry's local photo copies. Only files inside the app's own
/// drafts folder are touched, never a user's original gallery file.
Future<void> deleteLocalPhotos(List<String> paths) async {
  try {
    final drafts = p.join(
      (await getApplicationDocumentsDirectory()).path,
      'drafts',
    );
    final dirs = <String>{};
    for (final path in paths) {
      if (!p.isWithin(drafts, path)) continue;
      final f = File(path);
      if (f.existsSync()) await f.delete();
      dirs.add(p.dirname(path));
    }
    for (final d in dirs) {
      final dir = Directory(d);
      if (dir.existsSync() && dir.listSync().isEmpty) await dir.delete();
    }
  } catch (e) {
    debugPrint('[PendingUpload] local photo cleanup failed: $e');
  }
}

/// Best-effort removal of photos uploaded for an entry the user discarded.
/// Skipped when the post already exists (its commit went through but the
/// local entry wasn't cleared) or when that can't be checked (offline): a
/// live post must never lose its photos.
Future<void> deleteUploadedPhotos(
  String collection,
  String? docId,
  List<String> urls,
) async {
  if (urls.isEmpty || docId == null) return;
  try {
    final doc = await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .get(const GetOptions(source: Source.server));
    if (doc.exists) return;
  } catch (_) {
    return;
  }
  for (final url in urls) {
    try {
      await FirebaseStorage.instance.refFromURL(url).delete();
    } catch (e) {
      debugPrint('[PendingUpload] could not delete $url: $e');
    }
  }
}
