import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/app/routes/app_routes.dart';
import 'package:we_monitor/modules/achievements/achievements_controller.dart';
import 'package:we_monitor/modules/hotspots/controllers/hotspot_report_controller.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/media_upload_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/drafts/form_draft.dart';
import 'package:we_monitor/shared/services/draft_service.dart';
import 'package:we_monitor/shared/widgets/draft_dialogs.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/services/location_validator.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/widgets/circular_upload_progress.dart';
import 'package:we_monitor/shared/widgets/image_picker_dialog.dart';
import 'package:we_monitor/shared/widgets/location_picker_field.dart';

class HotspotReportScreen extends StatefulWidget {
  const HotspotReportScreen({super.key});

  @override
  State<HotspotReportScreen> createState() => _HotspotReportScreenState();
}

class _HotspotReportScreenState extends State<HotspotReportScreen>
    with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  late final DraftAutoSaver _saver;

  // Bumped after a draft is restored so the location field rebuilds.
  int _restoreKey = 0;

  HotspotReportController get controller => Get.find<HotspotReportController>();

  @override
  void initState() {
    super.initState();
    _saver = DraftAutoSaver(
      kind: FormDraft.kindHotspot,
      sources: [controller, controller.mediaUploadController],
      snapshot: controller.toDraft,
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDraft());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saver.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _saver.flush();
    }
  }

  /// Offers to restore a saved draft, then starts auto-saving.
  Future<void> _initDraft() async {
    final draft = await DraftService.load(FormDraft.kindHotspot);
    if (!mounted) return;
    if (draft != null) {
      final restore = await showDraftRestoreDialog(context, draft);
      if (!mounted) return;
      if (restore) {
        controller.applyDraft(draft);
        setState(() => _restoreKey++);
      } else {
        await DraftService.clear(
          FormDraft.kindHotspot,
          docId: draft.docId,
          deleteFiles: true,
        );
      }
    }
    _saver.start();
    await DraftService.recoverLostPhotos(
      FormDraft.kindHotspot,
      controller.hotspotDocId,
      controller.mediaUploadController,
    );
  }

  /// Back: leave silently when untouched, otherwise ask.
  Future<void> _handleExit() async {
    if (controller.toDraft().hasContent) {
      final choice = await showDraftExitDialog(context);
      if (!mounted) return;
      switch (choice) {
        case DraftExitChoice.stay:
          return;
        case DraftExitChoice.keep:
          await _saver.flush();
        case DraftExitChoice.discard:
          await _saver.finish();
      }
    }
    _saver.stop();
    Get.back();
  }

  Future<void> _pickImages() async {
    final media = controller.mediaUploadController;
    if (!media.canAddMore) {
      _showSnack(
        'Maximum ${MediaUploadConfig.maxPhotos} photos allowed',
        AppColors.errorRed,
      );
      return;
    }

    final remaining = MediaUploadConfig.maxPhotos - media.photoCount;
    final ImageSource? source = await Get.dialog<ImageSource?>(
      const ImagePickerDialog(),
    );
    if (source == null) return;

    List<XFile> picked = [];
    if (source == ImageSource.camera) {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (file != null) {
        picked = [file];
      }
    } else {
      picked = await _picker.pickMultiImage(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
        limit: remaining,
      );
    }
    if (picked.isEmpty) return;

    final files = <File>[
      for (final image in picked.take(remaining))
        await DraftService.copyPhoto(
          FormDraft.kindHotspot,
          controller.hotspotDocId,
          image.path,
        ),
    ];
    await controller.addPhotos(files);

    final isOnline = Get.find<ConnectivityController>().isOnline.value;
    if (isOnline) {
      for (final file in files) {
        final photo = media.photos.firstWhere((p) => p.file.path == file.path);
        media.compressAndUpload(photo.id, controller.hotspotDocId);
      }
    }

    _showSnack(
      isOnline
          ? '${files.length} photo(s) uploading...'
          : '${files.length} photo(s) saved for offline upload.',
      AppColors.info,
    );
  }

  Future<void> _submit() async {
    Get.find<HapticController>().medium();
    final picked = controller.pickedLocation;
    if (picked != null && !picked.verified) {
      final rechecked = await LocationValidator.reverify(picked);
      if (!mounted) return;
      if (rechecked == null) {
        controller.setLocationError(AppStrings.selectLocationInCameroon);
        _showSnack(AppStrings.selectLocationInCameroon, AppColors.errorRed);
        return;
      }
      controller.setPickedLocation(rechecked);
    }
    final id = await controller.submit();
    if (!mounted) return;
    if (id == null) {
      _showSnack(
        'Failed to save hotspot report. Please check the form.',
        AppColors.errorRed,
      );
      return;
    }

    final wasOnline = Get.find<ConnectivityController>().isOnline.value;
    _showSnack(
      wasOnline
          ? 'Hotspot report saved.'
          : 'Hotspot saved offline. It will upload when you are online.',
      AppColors.success,
    );
    // Offline-saved hotspots still reference the draft's photo copies.
    await _saver.finish(deleteFiles: wasOnline);
    Get.offAllNamed(AppRoutes.home);
    if (wasOnline) {
      AchievementsController.checkAfterActivity();
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text(
            'Report Plastic Hotspot',
            style: AppTextStyles.heading2(context),
          ),
          leading: BackButton(color: AppColors.black87, onPressed: _handleExit),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              SizeUtils.w(context, AppDimensions.screenPadding),
            ),
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final media = controller.mediaUploadController;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add the hotspot location and up to ${MediaUploadConfig.maxPhotos} photos.',
                      style: AppTextStyles.body(context),
                    ),
                    SizedBox(
                      height: SizeUtils.h(
                        context,
                        AppDimensions.cleanupSpacing20,
                      ),
                    ),
                    LocationPickerField(
                      key: ValueKey(_restoreKey),
                      value: controller.pickedLocation,
                      onChanged: controller.setPickedLocation,
                      onError: controller.setLocationError,
                      errorText: controller.locationError,
                    ),
                    SizedBox(
                      height: SizeUtils.h(
                        context,
                        AppDimensions.cleanupSpacing20,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: media.canAddMore ? _pickImages : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonGreen,
                        disabledBackgroundColor: AppColors.grey400,
                      ),
                      child: Text(
                        AppStrings.uploadImagesButton,
                        style: AppTextStyles.buttonPrimaryText(
                          context,
                        ).copyWith(color: AppColors.pureWhite),
                      ),
                    ),
                    if (controller.photosError != null) ...[
                      SizedBox(
                        height: SizeUtils.h(
                          context,
                          AppDimensions.inputErrorSpacing,
                        ),
                      ),
                      Text(
                        controller.photosError!,
                        style: AppTextStyles.bodySecondary(
                          context,
                        ).copyWith(color: AppColors.errorRed),
                      ),
                    ],
                    SizedBox(
                      height: SizeUtils.h(
                        context,
                        AppDimensions.cleanupSpacing16,
                      ),
                    ),
                    _PhotoGrid(media: media),
                    SizedBox(
                      height: SizeUtils.h(
                        context,
                        AppDimensions.cleanupSpacing24,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: controller.isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonGreen,
                        disabledBackgroundColor: AppColors.grey400,
                      ),
                      child: Text(
                        controller.isSubmitting ? 'SAVING...' : 'SAVE HOTSPOT',
                        style: AppTextStyles.saveCleanUpText(
                          context,
                        ).copyWith(color: AppColors.pureWhite),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.media});

  final MediaUploadController media;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: media,
      builder: (context, _) {
        if (!media.hasPhotos) return const SizedBox.shrink();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: media.photoCount <= 3 ? media.photoCount : 2,
            crossAxisSpacing: SizeUtils.w(
              context,
              AppDimensions.cleanupSpacing12,
            ),
            mainAxisSpacing: SizeUtils.h(
              context,
              AppDimensions.cleanupSpacing12,
            ),
          ),
          itemCount: media.photos.length,
          itemBuilder: (context, index) {
            final photo = media.photos[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(SizeUtils.r(context, 8)),
                  child: Image.file(
                    photo.file,
                    fit: BoxFit.cover,
                    cacheWidth: 300,
                  ),
                ),
                if (photo.status == PhotoUploadStatus.compressing ||
                    photo.status == PhotoUploadStatus.uploading)
                  Container(
                    color: AppColors.black54,
                    child: Center(
                      child: CircularUploadProgress(
                        size: SizeUtils.r(
                          context,
                          AppDimensions.circularLoaderSize,
                        ),
                        progress: photo.progress,
                        activeColor: AppColors.loaderActive,
                        trackColor: AppColors.loaderTrack,
                        strokeWidth: SizeUtils.r(
                          context,
                          AppDimensions.circularLoaderStrokeWidth,
                        ),
                        gap: SizeUtils.r(
                          context,
                          AppDimensions.circularLoaderGap,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                    ),
                    onPressed: () => media.removePhoto(photo.id),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
