import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/media_upload_controller.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/drafts/form_draft.dart';

/// Persists in-progress forms (one draft per kind per user) so they survive
/// the OS killing the app. Drafts are JSON strings in a plain Hive box and
/// photos are copied to the documents dir (picker cache can be purged).
class DraftService {
  DraftService._();

  static const String _boxName = 'form_drafts';
  static Box<String>? _box;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static Future<Box<String>> _open() async =>
      _box ??= await Hive.openBox<String>(_boxName);

  static String? _key(String kind) {
    final uid = _uid;
    return uid == null ? null : '$uid:$kind';
  }

  static Future<FormDraft?> load(String kind) async {
    final key = _key(kind);
    if (key == null) return null;
    try {
      final raw = (await _open()).get(key);
      if (raw == null) return null;
      final draft = FormDraft.decode(raw);
      return draft.hasContent ? draft : null;
    } catch (e) {
      debugPrint('[Draft] Corrupt draft dropped: $e');
      await (await _open()).delete(key);
      return null;
    }
  }

  static Future<void> save(FormDraft draft) async {
    final key = _key(draft.kind);
    if (key == null) return;
    try {
      await (await _open()).put(key, draft.encode());
    } catch (e) {
      debugPrint('[Draft] Save failed: $e');
    }
  }

  /// Removes the draft; [deleteFiles] also removes its local photo copies.
  /// Keep the files when they are still referenced (offline-saved pending
  /// cleanup/hotspot).
  static Future<void> clear(
    String kind, {
    String? docId,
    bool deleteFiles = false,
  }) async {
    final key = _key(kind);
    if (key == null) return;
    try {
      await (await _open()).delete(key);
      if (deleteFiles && docId != null) {
        final dir = await _photoDir(kind, docId);
        if (dir.existsSync()) await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[Draft] Clear failed: $e');
    }
  }

  /// Copies a freshly picked photo into the draft folder and returns the
  /// copy. Falls back to the original file if copying fails.
  static Future<File> copyPhoto(String kind, String docId, String src) async {
    if (_uid == null) return File(src);
    try {
      final dir = await _photoDir(kind, docId);
      await dir.create(recursive: true);
      final ext = p.extension(src).isEmpty ? '.jpg' : p.extension(src);
      return await File(src).copy(p.join(dir.path, '${const Uuid().v4()}$ext'));
    } catch (e) {
      debugPrint('[Draft] Photo copy failed: $e');
      return File(src);
    }
  }

  /// Photos worth keeping in a draft (everything not cancelled).
  static List<DraftPhoto> photosOf(MediaUploadController media) =>
      media.photos
          .where((ph) => ph.status != PhotoUploadStatus.cancelled)
          .map(
            (ph) => DraftPhoto(
              path: ph.file.path,
              url: ph.downloadUrl,
              thumbUrl: ph.thumbUrl,
            ),
          )
          .toList();

  /// Re-adds draft photos to [media]; those without an uploaded URL are
  /// queued for upload again when online (same as right after picking).
  static void restorePhotos(
    MediaUploadController media,
    List<DraftPhoto> photos,
    String docId,
  ) {
    final isOnline = Get.find<ConnectivityController>().isOnline.value;
    for (final photo in photos) {
      final file = File(photo.path);
      if (!file.existsSync()) continue;
      final id = media.restorePhoto(
        file,
        uploadedUrl: photo.url,
        thumbUrl: photo.thumbUrl,
      );
      if (photo.url == null && isOnline) media.compressAndUpload(id, docId);
    }
  }

  /// Android may kill the activity while the camera is open; the picked photo
  /// is then only available through retrieveLostData. Adds it to [media].
  static Future<void> recoverLostPhotos(
    String kind,
    String docId,
    MediaUploadController media,
  ) async {
    if (!Platform.isAndroid) return;
    try {
      final lost = await ImagePicker().retrieveLostData();
      final files = lost.files;
      if (lost.isEmpty || files == null || files.isEmpty) return;
      final room = MediaUploadConfig.maxPhotos - media.photoCount;
      final copies = <DraftPhoto>[];
      for (final f in files.take(room < 0 ? 0 : room)) {
        copies.add(
          DraftPhoto(path: (await copyPhoto(kind, docId, f.path)).path),
        );
      }
      restorePhotos(media, copies, docId);
    } catch (e) {
      debugPrint('[Draft] Lost data recovery failed: $e');
    }
  }

  static Future<Directory> _photoDir(String kind, String docId) async {
    final root = await getApplicationDocumentsDirectory();
    return Directory(p.join(root.path, 'drafts', _uid ?? '', kind, docId));
  }
}

/// Debounced writer: listens to the form (and media) controllers and saves a
/// [FormDraft] snapshot. Call [flush] when the app goes to the background.
class DraftAutoSaver {
  DraftAutoSaver({
    required this.kind,
    required this.sources,
    required this.snapshot,
  });

  final String kind;
  final List<Listenable> sources;
  final FormDraft Function() snapshot;

  Timer? _timer;
  bool _active = false;

  void start() {
    if (_active) return;
    _active = true;
    for (final s in sources) {
      s.addListener(_onChange);
    }
  }

  void _onChange() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 400), flush);
  }

  /// Writes the current state now. An untouched (or emptied) form removes the
  /// draft instead of saving it.
  Future<void> flush() async {
    _timer?.cancel();
    if (!_active) return;
    final draft = snapshot();
    if (draft.hasContent) {
      await DraftService.save(draft);
    } else {
      await DraftService.clear(kind, docId: draft.docId, deleteFiles: true);
    }
  }

  void stop() {
    _timer?.cancel();
    if (!_active) return;
    _active = false;
    for (final s in sources) {
      s.removeListener(_onChange);
    }
  }

  /// Stops saving and drops the draft (submit succeeded / user discarded).
  Future<void> finish({bool deleteFiles = true}) async {
    final docId = snapshot().docId;
    stop();
    await DraftService.clear(kind, docId: docId, deleteFiles: deleteFiles);
  }
}
