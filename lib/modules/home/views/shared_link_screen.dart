import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/models/cleanup_model.dart';
import 'package:we_monitor/app/models/hotspot_model.dart';
import 'package:we_monitor/app/routes/app_routes.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/widgets/circular_loader.dart';

/// Loads a cleanup/hotspot opened from a shared link, then swaps itself for
/// the detail screen (offNamed only replaces this screen, not the stack).
/// Arguments: {'type': 'cleanup' | 'hotspot', 'id': String}.
class SharedLinkScreen extends StatefulWidget {
  const SharedLinkScreen({super.key});

  @override
  State<SharedLinkScreen> createState() => _SharedLinkScreenState();
}

class _SharedLinkScreenState extends State<SharedLinkScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final args = Get.arguments as Map;
    final isCleanup = args['type'] == 'cleanup';
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection(isCleanup ? 'cleanups' : 'plastic_hotspots')
              .doc(args['id'] as String)
              .get();
      if (!mounted) return;
      if (!doc.exists) {
        setState(() => _error = AppStrings.deepLinkNotFound);
        return;
      }
      if (isCleanup) {
        final cleanup = CleanupModel.fromFirestore(doc);
        if (cleanup.flagged) {
          setState(() => _error = AppStrings.deepLinkNotFound);
          return;
        }
        Get.offNamed(AppRoutes.cleanupDetail, arguments: cleanup);
      } else {
        final hotspot = HotspotModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
        Get.offNamed(AppRoutes.hotspotDetail, arguments: hotspot);
      }
    } catch (e) {
      debugPrint('[SharedLink] load error: $e');
      if (mounted) setState(() => _error = AppStrings.deepLinkLoadFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: BackButton(
          color: AppColors.black87,
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child:
            _error == null
                ? const CircularInfiniteLoader()
                : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading2(context),
                  ),
                ),
      ),
    );
  }
}
