import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/controllers/pending_hotspots_controller.dart';
import 'package:we_monitor/app/models/pending_hotspot_model.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';

class PendingHotspotsScreen extends GetView<PendingHotspotsController> {
  const PendingHotspotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Pending Hotspots', style: AppTextStyles.heading2(context)),
        leading: BackButton(
          color: AppColors.black87,
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.pendingHotspots.isEmpty) {
          return Center(
            child: Text(
              'No pending hotspot reports',
              style: AppTextStyles.body(context),
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(
                  SizeUtils.w(context, AppDimensions.screenPadding),
                ),
                itemCount: controller.pendingHotspots.length,
                separatorBuilder:
                    (_, _) => SizedBox(
                      height: SizeUtils.h(
                        context,
                        AppDimensions.cleanupSpacing12,
                      ),
                    ),
                itemBuilder: (context, index) {
                  final hotspot = controller.pendingHotspots[index];
                  return _HotspotCard(hotspot: hotspot);
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(
                  SizeUtils.w(context, AppDimensions.screenPadding),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.uploadAll,
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(
                      'Upload All (${controller.pendingHotspots.length})',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonGreen,
                      foregroundColor: AppColors.pureWhite,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _HotspotCard extends StatelessWidget {
  const _HotspotCard({required this.hotspot});

  final PendingHotspotModel hotspot;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PendingHotspotsController>();
    final isUploading = controller.uploadingId.value == hotspot.localId;
    return Card(
      color: AppColors.pureWhite,
      child: Padding(
        padding: EdgeInsets.all(
          SizeUtils.w(context, AppDimensions.cleanupSpacing16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hotspot.location, style: AppTextStyles.heading2(context)),
            SizedBox(height: SizeUtils.h(context, AppDimensions.smallSpacing)),
            Text(
              '${hotspot.localPhotoPaths.length} photos • Saved ${hotspot.savedAt.day}/${hotspot.savedAt.month}/${hotspot.savedAt.year}',
              style: AppTextStyles.body(context),
            ),
            if (hotspot.uploadError != null)
              Text(
                hotspot.uploadError!,
                style: AppTextStyles.bodySecondary(
                  context,
                ).copyWith(color: AppColors.errorRed),
              ),
            SizedBox(
              height: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        isUploading
                            ? null
                            : () => controller.deleteHotspot(hotspot),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ),
                SizedBox(
                  width: SizeUtils.w(context, AppDimensions.smallSpacing),
                ),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        isUploading
                            ? null
                            : () => controller.uploadHotspot(hotspot),
                    icon:
                        isUploading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.cloud_upload),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonGreen,
                      foregroundColor: AppColors.pureWhite,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
