import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/app/routes/app_routes.dart';
import 'package:we_monitor/modules/hotspots/controllers/hotspot_report_controller.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/media_upload_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/widgets/circular_upload_progress.dart';
import 'package:we_monitor/shared/widgets/location_search_field.dart';

class HotspotReportScreen extends StatefulWidget {
  const HotspotReportScreen({super.key});

  @override
  State<HotspotReportScreen> createState() => _HotspotReportScreenState();
}

class _HotspotReportScreenState extends State<HotspotReportScreen> {
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  HotspotReportController get controller => Get.find<HotspotReportController>();

  @override
  void initState() {
    super.initState();
    _locationController.addListener(() {
      controller.setLocation(_locationController.text);
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack(AppStrings.enableLocationServices, AppColors.warning);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack(AppStrings.locationPermissionDenied, AppColors.errorRed);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      controller.setCoordinates(position.latitude, position.longitude);
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
        _locationController.text = address;
      } else {
        _locationController.text =
            'Lat ${position.latitude.toStringAsFixed(5)}, Lng ${position.longitude.toStringAsFixed(5)}';
      }
    } catch (e) {
      _showSnack(AppStrings.locationFetchFailed, AppColors.errorRed);
    }
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
    final picked = await _picker.pickMultiImage(
      imageQuality: 100,
      limit: remaining,
    );
    if (picked.isEmpty) return;

    final files =
        picked.take(remaining).map((image) => File(image.path)).toList();
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
    Get.offAllNamed(AppRoutes.home);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Report Plastic Hotspot',
          style: AppTextStyles.heading2(context),
        ),
        leading: BackButton(
          color: AppColors.black87,
          onPressed: () => Get.back(),
        ),
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
                  ElevatedButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(
                      Icons.my_location,
                      color: AppColors.pureWhite,
                    ),
                    label: Text(
                      AppStrings.useMyLocation,
                      style: AppTextStyles.buttonPrimaryText(
                        context,
                      ).copyWith(color: AppColors.pureWhite),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                    ),
                  ),
                  SizedBox(
                    height: SizeUtils.h(
                      context,
                      AppDimensions.cleanupSpacing16,
                    ),
                  ),
                  LocationSearchField(
                    controller: _locationController,
                    label: AppStrings.locationLabel,
                    hint: AppStrings.searchForLocation,
                    onPlaceSelected: (details) {
                      controller.setCoordinates(
                        details.latLng.latitude,
                        details.latLng.longitude,
                      );
                    },
                    supportText: controller.locationError,
                    isError: controller.locationError != null,
                    onChanged: controller.setLocation,
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
                  child: Image.file(photo.file, fit: BoxFit.cover),
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
