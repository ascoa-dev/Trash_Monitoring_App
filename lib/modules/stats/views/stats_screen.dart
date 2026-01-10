import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:ascoa_app/app/controllers/haptic_controller.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/app/controllers/pending_cleanups_controller.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ascoa_app/modules/stats/controllers/stats_controller.dart';
import 'package:ascoa_app/modules/stats/widgets/waste_chart_widget.dart';
import 'package:ascoa_app/modules/stats/widgets/stats_filter_widget.dart';
import 'package:ascoa_app/modules/stats/widgets/stats_header_widget.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with AutomaticKeepAliveClientMixin {
  late final StatsController controller;
  late final PendingCleanupsController pendingCleanupsController;
  final Map<String, BitmapDescriptor> _circleMarkers = {};

  @override
  void initState() {
    super.initState();
    controller = Get.put(StatsController());
    pendingCleanupsController = Get.find<PendingCleanupsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createCircleMarkers();
    });
  }

  @override
  bool get wantKeepAlive => true;

  /// Create custom circle markers for different environments
  Future<void> _createCircleMarkers() async {
    try {
      debugPrint('[StatsScreen] Starting to create circle markers...');

      _circleMarkers['Freshwater'] = await _createCircleMarker(
        AppColors.statsChartFreshwater,
      );
      debugPrint('[StatsScreen] Created Freshwater marker');

      _circleMarkers['Saltwater'] = await _createCircleMarker(
        AppColors.statsChartSaltwater,
      );
      debugPrint('[StatsScreen] Created Saltwater marker');

      _circleMarkers['Land'] = await _createCircleMarker(
        AppColors.statsChartLand,
      );
      debugPrint('[StatsScreen] Created Land marker');

      _circleMarkers['Inland'] = await _createCircleMarker(
        AppColors.statsChartLand,
      );
      debugPrint('[StatsScreen] Created Inland marker');

      _circleMarkers['default'] = await _createCircleMarker(Colors.red);
      debugPrint('[StatsScreen] Created default marker');

      debugPrint(
        '[StatsScreen] All circle markers created: ${_circleMarkers.length}',
      );

      if (mounted) {
        debugPrint('[StatsScreen] Calling setState to rebuild');
        setState(() {});
      }
    } catch (e, stackTrace) {
      debugPrint('[StatsScreen] Error creating circle markers: $e');
      debugPrint('[StatsScreen] Stack trace: $stackTrace');
    }
  }

  /// Create a circle bitmap descriptor
  Future<BitmapDescriptor> _createCircleMarker(Color color) async {
    final double logicalSize = SizeUtils.r(
      context,
      AppDimensions.statsMarkerSize,
    );
    final double borderWidth = SizeUtils.r(
      context,
      AppDimensions.statsMarkerBorderWidth,
    );

    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int imageSize = (logicalSize * pixelRatio).round();
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(pixelRatio);
    final Paint fillPaint = Paint()..color = color;
    final Paint borderPaint =
        Paint()
          ..color = AppColors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    // Draw circle with border
    final Offset center = Offset(logicalSize / 2, logicalSize / 2);
    final double radius = logicalSize / 2 - borderWidth / 2;

    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, borderPaint);

    final ui.Image image = await recorder.endRecording().toImage(
      imageSize,
      imageSize,
    );

    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Text(
              controller.error.value,
              style: AppTextStyles.statsError(context),
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: StatsHeaderWidget(onRefresh: () => controller.refresh()),
            ),
            SliverToBoxAdapter(
              child: Obx(() {
                if (pendingCleanupsController.pendingCleanups.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildPendingUploadsSection(context);
              }),
            ),

            // Your Activity Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  left: SizeUtils.w(
                    context,
                    AppDimensions.statsPageCardPaddingHorizontal,
                  ),
                  right: SizeUtils.w(
                    context,
                    AppDimensions.statsPageCardPaddingHorizontal,
                  ),
                  top: SizeUtils.h(
                    context,
                    AppDimensions.statsPageActivityCardPaddingVertical,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      AppStrings.statsYourActivity,
                      style: AppTextStyles.statsActivityLabel(context),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _ActivityCard(
                            value: controller.totalCleanups.toString().padLeft(
                              2,
                              '0',
                            ),
                            label: 'Cleanups',
                          ),
                        ),
                        SizedBox(
                          width: SizeUtils.w(
                            context,
                            AppDimensions.statsActivityCardSpacing,
                          ),
                        ),
                        Expanded(
                          child: _ActivityCard(
                            value: controller.totalTrashKg.toString(),
                            label: 'Trash collected',
                            unit: 'KGs',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Chart Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeUtils.w(
                    context,
                    AppDimensions.statsPagePaddingHorizontal,
                  ),
                  vertical: SizeUtils.h(
                    context,
                    AppDimensions.statsPagePaddingVertical,
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: SizeUtils.w(
                          context,
                          AppDimensions.statsPageChartTitlePaddingHorizontal,
                        ),
                        right: SizeUtils.w(
                          context,
                          AppDimensions.statsPageChartTitlePaddingHorizontal,
                        ),
                      ),
                      child: Text(
                        AppStrings.statsChartTitle,
                        style: AppTextStyles.statsChartTitle(context),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      height: SizeUtils.h(
                        context,
                        AppDimensions.statsPagePaddingVertical,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(
                          SizeUtils.r(
                            context,
                            AppDimensions.statsCardBorderRadius,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.1),
                            blurRadius: SizeUtils.r(
                              context,
                              AppDimensions.statsCardShadowBlur,
                            ),
                            offset: Offset(
                              SizeUtils.r(context, AppDimensions.zero),
                              SizeUtils.r(
                                context,
                                AppDimensions.statsCardShadowOffsetY,
                              ),
                            ),
                          ),
                        ],
                      ),
                      child: WasteChartWidget(
                        chartData: controller.getChartData(),
                      ),
                    ),
                    SizedBox(
                      height: SizeUtils.h(
                        context,
                        AppDimensions.statsPagePaddingVertical,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Combined Date and Environment Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeUtils.w(
                    context,
                    AppDimensions.statsPagePaddingHorizontal,
                  ),
                  vertical: SizeUtils.h(
                    context,
                    AppDimensions.statsPagePaddingVertical,
                  ),
                ),
                child: StatsFilterWidget(
                  availableDates: controller.availableDates,
                  fromDate: controller.fromDate.value,
                  toDate: controller.toDate.value,
                  onFromDateChanged: controller.setFromDate,
                  onToDateChanged: controller.setToDate,
                  selectedEnvironments: controller.selectedEnvironments,
                  onEnvironmentToggle: controller.toggleEnvironmentFilter,
                ),
              ),
            ),

            // Map Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(
                  SizeUtils.w(
                    context,
                    AppDimensions.statsPagePaddingHorizontal,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      AppStrings.statsMapTitle,
                      style: AppTextStyles.statsChartTitle(context),
                    ),
                    SizedBox(
                      height: SizeUtils.h(
                        context,
                        AppDimensions.statsPagePaddingVertical,
                      ),
                    ),
                    Text(
                      AppStrings.statsMapSubtitle,
                      style: AppTextStyles.statsMapInfo(context),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: SizeUtils.h(
                        context,
                        AppDimensions.statsMapSpacing,
                      ),
                    ),
                    Container(
                      height: SizeUtils.h(
                        context,
                        AppDimensions.statsMapHeight,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          SizeUtils.r(
                            context,
                            AppDimensions.statsCardBorderRadius,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.1),
                            blurRadius: SizeUtils.r(
                              context,
                              AppDimensions.statsCardShadowBlur,
                            ),
                            offset: Offset(
                              SizeUtils.r(context, AppDimensions.zero),
                              SizeUtils.r(
                                context,
                                AppDimensions.statsCardShadowOffsetY,
                              ),
                            ),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          SizeUtils.r(
                            context,
                            AppDimensions.statsCardBorderRadius,
                          ),
                        ),
                        child: _buildMap(controller),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom padding for navigation bar
            SliverToBoxAdapter(
              child: SizedBox(
                height: SizeUtils.h(context, AppDimensions.statsBottomPadding),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPendingUploadsSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeUtils.w(context, AppDimensions.zero),
        vertical: SizeUtils.h(
          context,
          AppDimensions.statsPendingSectionPaddingVertical,
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeUtils.h(
            context,
            AppDimensions.statsPendingContainerPaddingVertical,
          ),
          vertical: SizeUtils.h(
            context,
            AppDimensions.statsPendingSectionPaddingVertical2,
          ),
        ),
        decoration: BoxDecoration(
          color: AppColors.accentGreen, // green background
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeUtils.w(
              context,
              AppDimensions.statsPendingSectionPaddingHorizontal,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title row
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.pendingUploads,
                    size: SizeUtils.r(
                      context,
                      AppDimensions.statsPendingIconSize,
                    ),
                  ),
                  SizedBox(
                    width: SizeUtils.w(
                      context,
                      AppDimensions.statsPendingIconSpacing,
                    ),
                  ),
                  Text(
                    'Pending Uploads',
                    style: AppTextStyles.inputHint(
                      context,
                    ).copyWith(color: AppColors.white),
                  ),
                ],
              ),
              SizedBox(
                height: SizeUtils.h(
                  context,
                  AppDimensions.statsPendingSectionSpacing,
                ),
              ),
              // Button BELOW the title
              PrimaryButton(
                backgroundColor: AppColors.statsActivityCardBg,
                label: 'Upload pending cleanups',
                labelStyle: AppTextStyles.statsActivityLabelSmall(
                  context,
                ).copyWith(
                  color: AppColors.black87,
                  fontSize: SizeUtils.h(
                    context,
                    AppDimensions.statsPendingButtonFontSize,
                  ),
                ),
                onPressed: () {
                  Get.find<HapticController>().medium();
                  Get.toNamed(AppRoutes.pendingCleanups);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap(StatsController controller) {
    // Center map on Cameroon with better positioning
    const cameroonCenter = LatLng(6.5, 12.5);
    return GoogleMap(
      key: ValueKey(_circleMarkers.length),
      initialCameraPosition: const CameraPosition(
        target: cameroonCenter,
        zoom: 5.3,
      ),
      mapType: MapType.normal,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      markers: _buildMarkers(controller),
      onMapCreated: (GoogleMapController mapController) {
        // Map created
      },
    );
  }

  Set<Marker> _buildMarkers(StatsController controller) {
    final markers = <Marker>{};
    final locations = controller.getLocationData();

    debugPrint(
      '[StatsScreen] Building markers for ${locations.length} locations',
    );

    for (var i = 0; i < locations.length; i++) {
      final location = locations[i];

      debugPrint(
        '[StatsScreen] Location $i: ${location.city}, Env: ${location.environmentType}, '
        'Lat: ${location.latitude}, Lng: ${location.longitude}',
      );

      // Use custom circle markers
      final markerIcon =
          _circleMarkers[location.environmentType] ??
          _circleMarkers['default'] ??
          BitmapDescriptor.defaultMarker;

      markers.add(
        Marker(
          markerId: MarkerId('cleanup_$i'),
          position: LatLng(location.latitude, location.longitude),
          icon: markerIcon,
          onTap: () {
            Get.find<HapticController>().selectionClick();
          },
          infoWindow: InfoWindow(
            title: '${location.date} - ${location.groupName}',
            snippet: '${location.trashKg.toStringAsFixed(3)} KGs collected',
          ),
        ),
      );
    }

    return markers;
  }
}

class _ActivityCard extends StatelessWidget {
  final String value;
  final String label;
  final String? unit;

  const _ActivityCard({required this.value, required this.label, this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: SizeUtils.w(context, AppDimensions.zero),
        right: SizeUtils.w(context, AppDimensions.zero),
        top: SizeUtils.h(context, AppDimensions.statsActivityCardPadding),
        bottom: SizeUtils.h(context, AppDimensions.statsActivityCardPadding),
      ),
      decoration: BoxDecoration(
        color: AppColors.statsActivityCardBg,
        borderRadius: BorderRadius.circular(
          SizeUtils.r(context, AppDimensions.statsCardBorderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.15),
            blurRadius: SizeUtils.r(
              context,
              AppDimensions.statsActivityCardShadowBlur,
            ),
            offset: Offset(
              SizeUtils.r(context, AppDimensions.zero),
              SizeUtils.r(
                context,
                AppDimensions.statsActivityCardShadowOffsetY,
              ),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildWeightText(context, double.parse(value), unit)],
          ),
          Text(
            label,
            style: AppTextStyles.statsActivityLabelSmall(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeightText(BuildContext context, double value, String? unit) {
    if (unit == null) {
      return Text(
        value.round().toString(),
        style: AppTextStyles.statsActivityValue(context),
      );
    }

    final parts = value.toStringAsFixed(3).split('.');

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(parts[0], style: AppTextStyles.statsActivityValue(context)),
        SizedBox(
          width: SizeUtils.w(
            context,
            AppDimensions.statsActivityValueDecimalSpacing,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            bottom: SizeUtils.h(
              context,
              AppDimensions.statsActivityDecimalBottomPadding,
            ),
          ),
          child: Text(
            '.${parts[1]} $unit',
            style: AppTextStyles.statsActivityUnitLabel(context),
          ),
        ),
      ],
    );
  }
}
