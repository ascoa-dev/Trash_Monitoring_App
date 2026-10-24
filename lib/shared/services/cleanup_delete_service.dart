import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:we_monitor/app/models/cached_cleanup_model.dart';
import 'package:we_monitor/app/models/cleanup_model.dart';
import 'package:we_monitor/modules/achievements/achievements_controller.dart';
import 'package:we_monitor/modules/my_cleanups/controllers/my_cleanups_controller.dart';
import 'package:we_monitor/modules/stats/controllers/stats_controller.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/services/cleanup_public_service.dart';
import 'package:we_monitor/shared/services/snackbar_service.dart';
import 'package:we_monitor/shared/widgets/app_dialog.dart';

/// Owner-side cleanup deletion. Storage photos are removed server-side by a
/// Cloud Function when the doc is deleted, so the client does not touch them.
class CleanupDeleteService {
  CleanupDeleteService._();

  /// Confirms, deletes and refreshes local state. Returns true if deleted.
  static Future<bool> confirmAndDelete(
    BuildContext context,
    CleanupModel cleanup,
  ) async {
    final id = cleanup.id;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (id == null || uid == null || cleanup.userId != uid) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder:
          (ctx) => AppDialog(
            title: AppStrings.deleteCleanupTitle,
            body: AppStrings.deleteCleanupBody,
            icon: Icons.delete_outline_rounded,
            decoratedHero: true,
            primaryActionLabel: AppStrings.deleteCleanupAction,
            onPrimaryAction: () => Navigator.of(ctx).pop(true),
            secondaryActions: [
              AppDialogAction(
                label: AppStrings.deleteCleanupCancel,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ],
          ),
    );
    if (confirmed != true) return false;

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      batch.delete(db.collection('cleanups').doc(id));
      batch.update(db.collection('users').doc(uid), {
        'cleanups': FieldValue.arrayRemove([id]),
      });
      await batch.commit();
    } catch (e) {
      debugPrint('[CleanupDelete] failed: $e');
      SnackbarService.error('Error', AppStrings.deleteCleanupFailed);
      return false;
    }

    await _clearLocal(id);
    SnackbarService.success('Deleted', AppStrings.deleteCleanupSuccess);
    // Recalculate achievements/score from the remaining data.
    AchievementsController.checkAfterActivity();
    return true;
  }

  static Future<void> _clearLocal(String id) async {
    try {
      if (Hive.isBoxOpen('cached_cleanups')) {
        await Hive.box<CachedCleanupModel>('cached_cleanups').delete(id);
      }
    } catch (e) {
      debugPrint('[CleanupDelete] cache clear failed: $e');
    }
    for (final tag in <String?>[null, 'stats_controller']) {
      if (Get.isRegistered<StatsController>(tag: tag)) {
        Get.find<StatsController>(tag: tag).removeCleanup(id);
      }
    }
    if (Get.isRegistered<MyCleanupsController>()) {
      Get.find<MyCleanupsController>().removeLocal(id);
    }
    CleanupPublicService.changes.value++; // home / public lists reload
  }
}
