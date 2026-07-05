import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/models/cleanup_model.dart';
import 'package:we_monitor/app/routes/app_routes.dart';
import 'package:we_monitor/modules/home/widgets/cleanup_card.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/services/cleanup_public_service.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';

class CleanupListScreen extends StatefulWidget {
  const CleanupListScreen({super.key});

  @override
  State<CleanupListScreen> createState() => _CleanupListScreenState();
}

class _CleanupListScreenState extends State<CleanupListScreen> {
  List<CleanupModel> _cleanups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await CleanupPublicService.fetchPublic(limit: 100);
    if (!mounted) return;
    setState(() {
      _cleanups = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Community Cleanups',
          style: AppTextStyles.heading2(context),
        ),
        leading: BackButton(
          color: AppColors.black87,
          onPressed: () => Get.back(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cleanups.isEmpty
              ? Center(
                  child: Text(
                    'No community cleanups yet.',
                    style: AppTextStyles.body(context),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        SizeUtils.w(context, AppDimensions.screenPadding),
                    vertical: SizeUtils.h(context, 16),
                  ),
                  itemCount: _cleanups.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: SizeUtils.h(context, 12)),
                  itemBuilder: (context, index) {
                    final c = _cleanups[index];
                    return CleanupCard(
                      cleanup: c,
                      width: double.infinity,
                      onTap: () => Get.toNamed(
                        AppRoutes.cleanupDetail,
                        arguments: c,
                      ),
                    );
                  },
                ),
    );
  }
}
