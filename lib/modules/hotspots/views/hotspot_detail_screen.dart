import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:we_monitor/app/models/hotspot_model.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_images.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/widgets/user_byline.dart';
import 'package:we_monitor/modules/profile/widgets/full_image_overlay.dart';

class HotspotDetailScreen extends StatefulWidget {
  const HotspotDetailScreen({super.key});

  @override
  State<HotspotDetailScreen> createState() => _HotspotDetailScreenState();
}

class _HotspotDetailScreenState extends State<HotspotDetailScreen> {
  late final HotspotModel hotspot;
  late final PageController _photoController;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    hotspot = Get.arguments as HotspotModel;
    _photoController = PageController();
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _openInGoogleMaps() async {
    final lat = hotspot.latitude;
    final lng = hotspot.longitude;
    if (lat == null || lng == null) return;
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else {
      await launchUrl(
        Uri.parse('https://www.google.com/maps?q=$lat,$lng'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  String _formatDate() {
    final dt = hotspot.createdAt;
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')} '
        '${_monthName(dt.month)} ${dt.year}';
  }

  String _monthName(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][m];

  @override
  Widget build(BuildContext context) {
    final hasCoords = hotspot.latitude != null && hotspot.longitude != null;
    final hasPhotos = hotspot.photoUrls.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Hotspot Report', style: AppTextStyles.heading2(context)),
        leading: BackButton(
          color: AppColors.black87,
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasCoords) ...[
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
                    target: LatLng(hotspot.latitude!, hotspot.longitude!),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('hotspot'),
                      position: LatLng(hotspot.latitude!, hotspot.longitude!),
                      infoWindow: InfoWindow(
                        title: hotspot.locationName.isNotEmpty
                            ? hotspot.locationName
                            : 'Hotspot',
                      ),
                    ),
                  },
                  zoomControlsEnabled: false,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      SizeUtils.w(context, AppDimensions.screenPadding),
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
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeUtils.w(context, AppDimensions.screenPadding),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: SizeUtils.h(context, 12)),
                  if (hotspot.locationName.isNotEmpty)
                    Text(
                      hotspot.locationName,
                      style: AppTextStyles.body(context)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  if (_formatDate().isNotEmpty) ...[
                    SizedBox(height: SizeUtils.h(context, 4)),
                    Text(
                      _formatDate(),
                      style: AppTextStyles.bodySecondary(context),
                    ),
                  ],
                  SizedBox(height: SizeUtils.h(context, 6)),
                  UserByline(userId: hotspot.userId),
                  if (hotspot.notes != null && hotspot.notes!.isNotEmpty) ...[
                    SizedBox(height: SizeUtils.h(context, 12)),
                    Text(
                      'Notes',
                      style: AppTextStyles.body(context)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: SizeUtils.h(context, 4)),
                    Text(
                      hotspot.notes!,
                      style: AppTextStyles.bodySecondary(context),
                    ),
                  ],
                  SizedBox(height: SizeUtils.h(context, 20)),
                ],
              ),
            ),
            if (hasPhotos) ...[
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
                  itemCount: hotspot.photoUrls.length,
                  onPageChanged: (i) => setState(() => _photoIndex = i),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: SizeUtils.w(
                          context,
                          AppDimensions.screenPadding,
                        ),
                        right: index == hotspot.photoUrls.length - 1
                            ? SizeUtils.w(context, AppDimensions.screenPadding)
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
                          onTap: () => FullImageOverlay.show(
                            context,
                            imageUrl: hotspot.photoUrls[index],
                            placeholderAsset: AppImages.hotspotPlaceholder,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: hotspot.photoUrls[index],
                            fit: BoxFit.cover,
                            placeholder: (c, s) => Container(
                              color: AppColors.cardBackground,
                            ),
                            errorWidget: (c, s, e) => Container(
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
              if (hotspot.photoUrls.length > 1) ...[
                SizedBox(height: SizeUtils.h(context, 8)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    hotspot.photoUrls.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _photoIndex ? 12 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: i == _photoIndex
                            ? AppColors.accentGreen
                            : AppColors.grey400,
                      ),
                    ),
                  ),
                ),
              ],
            ] else ...[
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeUtils.w(context, AppDimensions.screenPadding),
                ),
                child: Container(
                  height: SizeUtils.h(context, 160, useContentHeight: false),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6E5),
                    borderRadius: BorderRadius.circular(
                      SizeUtils.r(
                        context,
                        AppDimensions.homeScreenHighlightCardRadius,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      AppImages.hotspotPlaceholder,
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: SizeUtils.h(context, 32)),
          ],
        ),
      ),
    );
  }
}
