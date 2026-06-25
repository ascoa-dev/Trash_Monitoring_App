import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/app/models/cleanup_model.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/modules/my_cleanups/controllers/my_cleanups_controller.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';
import 'package:ascoa_app/shared/widgets/custom_date_picker.dart';
import 'package:ascoa_app/shared/widgets/floating_label_input_field.dart';

class MyCleanupsScreen extends StatefulWidget {
  const MyCleanupsScreen({super.key});

  @override
  State<MyCleanupsScreen> createState() => _MyCleanupsScreenState();
}

class _MyCleanupsScreenState extends State<MyCleanupsScreen> {
  final TextEditingController _searchController = TextEditingController();

  MyCleanupsController get controller => Get.find<MyCleanupsController>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await CustomDatePicker.show(
      context,
      initialDate: DateTime.now(),
      startDate: DateTime(2023),
      endDate: DateTime(2030),
    );
    if (picked == null) return;
    if (isFrom) {
      controller.setFromDate(picked);
    } else {
      controller.setToDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('My Clean Ups', style: AppTextStyles.heading2(context)),
        leading: BackButton(
          color: AppColors.black87,
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.loadCleanups,
            icon: const Icon(Icons.refresh, color: AppColors.black87),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(
            SizeUtils.w(context, AppDimensions.screenPadding),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FloatingLabelInputField(
                controller: _searchController,
                label: 'Search',
                hint: 'Date, location, or group name',
                suffixIcon: const Icon(Icons.search, color: AppColors.textHint),
                onChanged: controller.setSearchQuery,
              ),
              SizedBox(
                height: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
              ),
              Obx(() {
                return Wrap(
                  spacing: SizeUtils.w(context, AppDimensions.smallSpacing),
                  runSpacing: SizeUtils.h(context, AppDimensions.smallSpacing),
                  children: [
                    _FilterChipButton(
                      label:
                          controller.fromDate.value == null
                              ? 'From date'
                              : _formatDate(controller.fromDate.value!),
                      onTap: () => _pickDate(isFrom: true),
                    ),
                    _FilterChipButton(
                      label:
                          controller.toDate.value == null
                              ? 'To date'
                              : _formatDate(controller.toDate.value!),
                      onTap: () => _pickDate(isFrom: false),
                    ),
                    _FilterChipButton(
                      label: 'Clear',
                      onTap: () {
                        _searchController.clear();
                        controller.clearFilters();
                      },
                    ),
                  ],
                );
              }),
              SizedBox(
                height: SizeUtils.h(context, AppDimensions.cleanupSpacing16),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final cleanups = controller.filteredCleanups;
                  if (cleanups.isEmpty) {
                    return Center(
                      child: Text(
                        'No cleanups match your filters.',
                        style: AppTextStyles.body(context),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: cleanups.length,
                    separatorBuilder:
                        (_, _) => SizedBox(
                          height: SizeUtils.h(
                            context,
                            AppDimensions.cleanupSpacing12,
                          ),
                        ),
                    itemBuilder: (context, index) {
                      return _CleanupCard(cleanup: cleanups[index]);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.calendar_today_outlined, size: 16),
      backgroundColor: AppColors.dialogBackground,
      side: BorderSide.none,
      onPressed: onTap,
    );
  }
}

class _CleanupCard extends StatelessWidget {
  const _CleanupCard({required this.cleanup});

  final CleanupModel cleanup;

  @override
  Widget build(BuildContext context) {
    final items = cleanup.categories.values.fold<int>(
      0,
      (total, categoryItems) =>
          total +
          categoryItems.values.fold(0, (sum, item) => sum + item.quantity),
    );

    return Card(
      color: AppColors.pureWhite,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeUtils.r(context, 8)),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          SizeUtils.w(context, AppDimensions.cleanupSpacing16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    cleanup.groupName,
                    style: AppTextStyles.heading2(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Get.toNamed(
                      AppRoutes.editCleanupTrash,
                      arguments: cleanup,
                    );
                    if (Get.isRegistered<MyCleanupsController>()) {
                      Get.find<MyCleanupsController>().loadCleanups();
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Trash'),
                ),
              ],
            ),
            SizedBox(height: SizeUtils.h(context, AppDimensions.smallSpacing)),
            _InfoRow(icon: Icons.calendar_today_outlined, text: cleanup.date),
            _InfoRow(icon: Icons.location_on_outlined, text: cleanup.location),
            _InfoRow(
              icon: Icons.delete_outline,
              text:
                  '$items items, ${cleanup.totalWeight.toStringAsFixed(3)} KG',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: SizeUtils.h(context, AppDimensions.cleanupSpacing4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textAccent),
          SizedBox(width: SizeUtils.w(context, AppDimensions.smallSpacing)),
          Expanded(child: Text(text, style: AppTextStyles.body(context))),
        ],
      ),
    );
  }
}
