import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:we_monitor/app/models/cleanup_model.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_images.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/widgets/user_byline.dart';
import 'package:we_monitor/shared/widgets/fullscreen_image_viewer.dart';

class CleanupDetailScreen extends StatefulWidget {
  const CleanupDetailScreen({super.key});

  @override
  State<CleanupDetailScreen> createState() => _CleanupDetailScreenState();
}

class _CleanupDetailScreenState extends State<CleanupDetailScreen> {
  late final CleanupModel cleanup;
  late final PageController _photoController;
  int _photoIndex = 0;
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    cleanup = Get.arguments as CleanupModel;
    _photoController = PageController();
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _openInGoogleMaps() async {
    final lat = cleanup.locationLatitude;
    final lng = cleanup.locationLongitude;
    if (lat == null || lng == null) return;
    final Uri mapUri;
    if (Platform.isIOS) {
      mapUri = Uri.parse('https://maps.apple.com/?q=$lat,$lng');
    } else {
      mapUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    }
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri);
    } else {
      await launchUrl(
        Uri.parse('https://www.google.com/maps?q=$lat,$lng'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  int get _totalItems => cleanup.categories.values
      .expand((cat) => cat.values)
      .fold(0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    final hasCoords =
        cleanup.locationLatitude != null && cleanup.locationLongitude != null;
    final hasPhotos = cleanup.photoUrls?.isNotEmpty == true;
    final photos = cleanup.photoUrls ?? [];
    final pad = SizeUtils.w(context, AppDimensions.screenPadding);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Community Cleanup',
          style: AppTextStyles.heading2(context),
        ),
        leading: BackButton(
          color: AppColors.black87,
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team name + people count
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cleanup.groupName,
                    style: AppTextStyles.heading2(context),
                  ),
                  SizedBox(height: SizeUtils.h(context, 4)),
                  UserByline(userId: cleanup.userId),
                  SizedBox(height: SizeUtils.h(context, 4)),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 16),
                      SizedBox(width: SizeUtils.w(context, 4)),
                      Text(
                        '${cleanup.peopleCount} people',
                        style: AppTextStyles.bodySecondary(context),
                      ),
                      SizedBox(width: SizeUtils.w(context, 16)),
                      const Icon(Icons.calendar_today_outlined, size: 14),
                      SizedBox(width: SizeUtils.w(context, 4)),
                      Text(
                        cleanup.date,
                        style: AppTextStyles.bodySecondary(context),
                      ),
                    ],
                  ),
                  if (cleanup.location.isNotEmpty) ...[
                    SizedBox(height: SizeUtils.h(context, 4)),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14),
                        SizedBox(width: SizeUtils.w(context, 4)),
                        Expanded(
                          child: Text(
                            cleanup.location,
                            style: AppTextStyles.bodySecondary(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Map
            if (hasCoords) ...[
              SizedBox(height: SizeUtils.h(context, 12)),
              SizedBox(
                height: SizeUtils.h(context, 220, useContentHeight: false),
                width: double.infinity,
                child: GoogleMap(
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      cleanup.locationLatitude!,
                      cleanup.locationLongitude!,
                    ),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('cleanup'),
                      position: LatLng(
                        cleanup.locationLatitude!,
                        cleanup.locationLongitude!,
                      ),
                      infoWindow: InfoWindow(title: cleanup.groupName),
                    ),
                  },
                  zoomControlsEnabled: false,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: pad,
                  vertical: SizeUtils.h(context, 8),
                ),
                child: OutlinedButton.icon(
                  onPressed: _openInGoogleMaps,
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Open in Google Maps'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.buttonPrimary,
                    side: BorderSide(color: AppColors.buttonPrimary),
                  ),
                ),
              ),
            ],

            // Weight + item count summary
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 8, pad, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(SizeUtils.r(context, 12)),
                ),
                padding: EdgeInsets.all(SizeUtils.w(context, 14)),
                child: Row(
                  children: [
                    Expanded(
                      child: _summaryTile(
                        context,
                        '${cleanup.totalWeight.toStringAsFixed(2)} kg',
                        'Total weight',
                        Icons.scale_outlined,
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppColors.grey400),
                    Expanded(
                      child: _summaryTile(
                        context,
                        '$_totalItems',
                        'Items collected',
                        Icons.recycling_outlined,
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppColors.grey400),
                    Expanded(
                      child: _summaryTile(
                        context,
                        cleanup.environment,
                        'Environment',
                        Icons.terrain_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category accordions
            if (cleanup.categories.isNotEmpty) ...[
              SizedBox(height: SizeUtils.h(context, 16)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: Text(
                  'Items Collected',
                  style: AppTextStyles.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: SizeUtils.h(context, 8)),
              ...cleanup.categories.entries.map(
                (entry) =>
                    _buildCategoryAccordion(context, entry.key, entry.value),
              ),
            ],

            // Notes
            if (cleanup.notes != null && cleanup.notes!.isNotEmpty) ...[
              SizedBox(height: SizeUtils.h(context, 8)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: AppTextStyles.body(
                        context,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: SizeUtils.h(context, 4)),
                    Text(
                      cleanup.notes!,
                      style: AppTextStyles.bodySecondary(context),
                    ),
                  ],
                ),
              ),
            ],

            // Photos
            if (hasPhotos) ...[
              SizedBox(height: SizeUtils.h(context, 16)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: Text(
                  'Photos',
                  style: AppTextStyles.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: SizeUtils.h(context, 8)),
              SizedBox(
                height: SizeUtils.h(
                  context,
                  AppDimensions.homeScreenHighlightCarouselHeight,
                  useContentHeight: false,
                ),
                child: PageView.builder(
                  controller: _photoController,
                  padEnds: false,
                  physics: const ClampingScrollPhysics(),
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _photoIndex = i),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: pad,
                        right:
                            index == photos.length - 1
                                ? pad
                                : SizeUtils.w(context, 8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          SizeUtils.r(
                            context,
                            AppDimensions.homeScreenHighlightCardRadius,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () => FullscreenImageViewer.show(
                            context,
                            imageUrl: photos[index],
                            placeholderAsset: AppImages.hotspotPlaceholder,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: photos[index],
                            fit: BoxFit.cover,
                            memCacheWidth: 1080,
                            placeholder:
                                (c, s) =>
                                    Container(color: AppColors.cardBackground),
                            errorWidget:
                                (c, s, e) => Container(
                                  color: const Color(0xFFEFF6E5),
                                  child: Center(
                                    child: Image.asset(
                                      AppImages.hotspotPlaceholder,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (photos.length > 1) ...[
                SizedBox(height: SizeUtils.h(context, 8)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    photos.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _photoIndex ? 12 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color:
                            i == _photoIndex
                                ? AppColors.accentGreen
                                : AppColors.grey400,
                      ),
                    ),
                  ),
                ),
              ],
            ],

            SizedBox(height: SizeUtils.h(context, 32)),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.accentGreen),
        SizedBox(height: SizeUtils.h(context, 4)),
        Text(
          value,
          style: AppTextStyles.body(
            context,
          ).copyWith(fontWeight: FontWeight.bold, fontSize: 13),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: AppTextStyles.bodySecondary(context).copyWith(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCategoryAccordion(
    BuildContext context,
    String category,
    Map<String, CleanupItem> items,
  ) {
    final expanded = _expandedCategories.contains(category);
    final pad = SizeUtils.w(context, AppDimensions.screenPadding);
    final catTotal = items.values.fold(0.0, (s, i) => s + i.totalWeight);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(SizeUtils.r(context, 12)),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(SizeUtils.r(context, 12)),
              onTap:
                  () => setState(() {
                    if (expanded) {
                      _expandedCategories.remove(category);
                    } else {
                      _expandedCategories.add(category);
                    }
                  }),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeUtils.w(context, 12),
                  vertical: SizeUtils.h(context, 10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: AppTextStyles.body(
                              context,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${items.length} items · ${catTotal.toStringAsFixed(2)} kg',
                            style: AppTextStyles.bodySecondary(context),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.black,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...[
              const Divider(height: 1),
              ...items.entries.map(
                (e) => Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeUtils.w(context, 12),
                    vertical: SizeUtils.h(context, 8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: AppTextStyles.bodySecondary(context),
                        ),
                      ),
                      Text(
                        '×${e.value.quantity}',
                        style: AppTextStyles.bodySecondary(context),
                      ),
                      SizedBox(width: SizeUtils.w(context, 12)),
                      Text(
                        '${e.value.totalWeight.toStringAsFixed(2)} kg',
                        style: AppTextStyles.bodySecondary(
                          context,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
