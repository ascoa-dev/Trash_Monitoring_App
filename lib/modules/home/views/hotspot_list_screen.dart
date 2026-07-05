import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/models/hotspot_model.dart';
import 'package:we_monitor/app/routes/app_routes.dart';
import 'package:we_monitor/modules/hotspots/widgets/hotspot_card.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/services/hotspot_service.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';

class HotspotListScreen extends StatefulWidget {
  const HotspotListScreen({super.key});

  @override
  State<HotspotListScreen> createState() => _HotspotListScreenState();
}

class _HotspotListScreenState extends State<HotspotListScreen> {
  List<HotspotModel> _hotspots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await HotspotService.fetchUnresolved(limit: 100);
    if (!mounted) return;
    setState(() {
      _hotspots = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title:
            Text('Hotspot Reports', style: AppTextStyles.heading2(context)),
        leading: BackButton(
          color: AppColors.black87,
          onPressed: () => Get.back(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hotspots.isEmpty
              ? Center(
                  child: Text(
                    'No hotspot reports yet.',
                    style: AppTextStyles.body(context),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        SizeUtils.w(context, AppDimensions.screenPadding),
                    vertical: SizeUtils.h(context, 16),
                  ),
                  itemCount: _hotspots.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: SizeUtils.h(context, 12)),
                  itemBuilder: (context, index) {
                    final h = _hotspots[index];
                    return HotspotCard(
                      hotspot: h,
                      width: double.infinity,
                      onTap: () => Get.toNamed(
                        AppRoutes.hotspotDetail,
                        arguments: h,
                      ),
                    );
                  },
                ),
    );
  }
}
