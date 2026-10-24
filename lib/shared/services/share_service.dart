import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:we_monitor/app/models/achievement.dart';
import 'package:we_monitor/app/models/cleanup_model.dart';
import 'package:we_monitor/app/models/hotspot_model.dart';
import 'package:we_monitor/shared/analytics/analytics_service.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_images.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/services/snackbar_service.dart';
import 'package:we_monitor/shared/utils/deep_link.dart';
import 'package:we_monitor/shared/utils/image_utils.dart';
import 'package:we_monitor/shared/widgets/share_cards.dart';

/// Renders a branded card off-screen to a PNG and opens the native share sheet
/// with the image plus a message. Pass the tapped button's [context] so iPad
/// can anchor the share popover.
class ShareService {
  ShareService._();

  static bool _busy = false;

  /// [c] must have an id (saved online); offline-only cleanups have no link.
  static Future<void> shareCleanup(BuildContext context, CleanupModel c) {
    final items = c.categories.values.fold<int>(
      0,
      (t, cat) => t + cat.values.fold(0, (s, i) => s + i.quantity),
    );
    final kg = _kg(c.totalWeight);
    final message = AppStrings.shareCleanupMessage
        .replaceAll('{kg}', kg)
        .replaceAll('{items}', '$items')
        .replaceAll(
          '{location}',
          c.location.isEmpty ? AppStrings.shareUnknownLocation : c.location,
        )
        .replaceAll('{link}', cleanupShareUrl(c.id ?? ''))
        .replaceAll('{download}', appDownloadUrl);
    return _share(
      context,
      type: 'cleanup',
      message: message,
      photoUrls: _photoCandidates(c.photoUrls, c.thumbUrls),
      build:
          (photo) => CleanupShareCard(
            photo: photo,
            weight: kg,
            items: items,
            volunteers: c.peopleCount,
            environment: c.environment,
            location: c.location,
            date: c.date,
            groupName: c.groupName,
          ),
    );
  }

  /// Loads the saved cleanup (just submitted online) and shares it.
  static Future<void> shareCleanupById(BuildContext context, String id) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('cleanups').doc(id).get();
      if (!context.mounted) return;
      await shareCleanup(context, CleanupModel.fromFirestore(doc));
    } catch (e) {
      debugPrint('ShareService.shareCleanupById error: $e');
      SnackbarService.show(
        SnackbarMessage.error(
          AppStrings.shareFailedTitle,
          AppStrings.shareFailedBody,
        ),
      );
    }
  }

  static Future<void> shareHotspot(BuildContext context, HotspotModel h) {
    final message = AppStrings.shareHotspotMessage
        .replaceAll(
          '{location}',
          h.locationName.isEmpty
              ? AppStrings.shareUnknownLocation
              : h.locationName,
        )
        .replaceAll('{link}', hotspotShareUrl(h.id))
        .replaceAll('{download}', appDownloadUrl);
    return _share(
      context,
      type: 'hotspot',
      message: message,
      photoUrls: _photoCandidates(h.photoUrls, h.thumbUrls),
      build:
          (photo) => HotspotShareCard(
            photo: photo,
            location: h.locationName,
            date: _date(h.createdAt),
          ),
    );
  }

  static Future<void> shareAchievement(
    BuildContext context,
    AchievementDef def,
    int level,
  ) {
    final message = AppStrings.shareAchievementMessage
        .replaceAll('{title}', def.title)
        .replaceAll('{level}', '$level')
        .replaceAll('{download}', appDownloadUrl);
    final description = AppStrings.shareCardAchievementDescription
        .replaceAll('{threshold}', '${def.thresholds[level - 1]}')
        .replaceAll('{unit}', def.unit.isEmpty ? '' : ' ${def.unit}')
        .replaceAll('{metric}', def.metric);
    return _share(
      context,
      type: 'achievement',
      message: message,
      photoUrls: const [],
      build:
          (_) => AchievementShareCard(
            title: def.title,
            level: level,
            icon: def.icon,
            color: def.color,
            description: description,
          ),
    );
  }

  // ---- internals ----

  static String _kg(double w) {
    final s = w.toStringAsFixed(w >= 100 ? 0 : 1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  static String _date(DateTime? d) =>
      d == null ? '' : '${d.day}/${d.month}/${d.year}';

  /// Full photo first (sharper at 1080px), thumbnail as a fallback.
  static List<String> _photoCandidates(
    List<String>? full,
    List<String>? thumbs,
  ) {
    if (full == null || full.isEmpty) return const [];
    return {full[0], ImageUtils.thumbOrFull(full, thumbs, 0)}.toList();
  }

  static Future<ImageProvider?> _loadPhoto(
    BuildContext context,
    List<String> urls,
  ) async {
    for (final url in urls) {
      final provider = ResizeImage(
        CachedNetworkImageProvider(url),
        width: 1080,
      );
      try {
        await precacheImage(
          provider,
          context,
        ).timeout(const Duration(seconds: 15));
        return provider;
      } catch (e) {
        debugPrint('ShareService: photo failed ($url): $e');
      }
    }
    return null; // card falls back to the gradient design
  }

  static Rect? _origin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static Future<void> _share(
    BuildContext context, {
    required String type,
    required String message,
    required List<String> photoUrls,
    required Widget Function(ImageProvider? photo) build,
  }) async {
    if (_busy) return;
    _busy = true;
    final origin = _origin(context);
    final overlay = Overlay.of(context, rootOverlay: true);
    final boundaryKey = GlobalKey();
    OverlayEntry? entry;
    try {
      final photo = await _loadPhoto(context, photoUrls);
      if (!context.mounted) return;
      await precacheImage(const AssetImage(AppImages.logo), context);
      if (!context.mounted) return;

      entry = OverlayEntry(
        builder:
            (ctx) => Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.buttonGreen,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            AppStrings.sharePreparing,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // The card, parked far off-screen but still painted.
                Positioned(
                  left: -5000,
                  top: 0,
                  width: shareCardSize.width,
                  height: shareCardSize.height,
                  child: MediaQuery(
                    data: MediaQuery.of(
                      ctx,
                    ).copyWith(textScaler: TextScaler.noScaling),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: RepaintBoundary(
                        key: boundaryKey,
                        child: build(photo),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      );
      overlay.insert(entry);
      // Let the card lay out, paint and decode its images.
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) throw StateError('PNG encoding returned null');

      final dir = await getTemporaryDirectory();
      final path = p.join(
        dir.path,
        'we_monitor_share_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await File(path).writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      entry.remove();
      entry = null;

      Analytics.track(AnalyticsEvents.shareTapped, {'type': type});
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'image/png')],
          text: message,
          subject: AppStrings.shareSubject,
          sharePositionOrigin: origin,
        ),
      );
    } catch (e, st) {
      debugPrint('ShareService error: $e\n$st');
      SnackbarService.show(
        SnackbarMessage.error(
          AppStrings.shareFailedTitle,
          AppStrings.shareFailedBody,
        ),
      );
    } finally {
      entry?.remove();
      _busy = false;
    }
  }
}
