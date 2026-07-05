import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/models/cleanup_model.dart';
import 'package:we_monitor/app/routes/app_routes.dart';
import 'package:we_monitor/modules/my_cleanups/controllers/my_cleanups_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/widgets/custom_date_picker.dart';
import 'package:we_monitor/shared/widgets/floating_label_input_field.dart';

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
      endDate: DateTime.now(),
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
                final hasFromDate = controller.fromDate.value != null;
                final hasToDate = controller.toDate.value != null;
                return Wrap(
                  spacing: SizeUtils.w(context, AppDimensions.smallSpacing),
                  runSpacing: SizeUtils.h(context, AppDimensions.smallSpacing),
                  children: [
                    _FilterChipButton(
                      label: !hasFromDate
                          ? 'From Date'
                          : _formatDate(controller.fromDate.value!),
                      icon: Icons.calendar_month_outlined,
                      isActive: hasFromDate,
                      onTap: () => _pickDate(isFrom: true),
                    ),
                    _FilterChipButton(
                      label: !hasToDate
                          ? 'To Date'
                          : _formatDate(controller.toDate.value!),
                      icon: Icons.calendar_month_outlined,
                      isActive: hasToDate,
                      onTap: () => _pickDate(isFrom: false),
                    ),
                    if (hasFromDate || hasToDate || controller.searchQuery.value.isNotEmpty)
                      _FilterChipButton(
                        label: 'Clear',
                        icon: Icons.filter_alt_off_outlined,
                        isActive: false,
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
  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(
        icon,
        size: 16,
        color: isActive ? AppColors.pureWhite : AppColors.buttonPrimary,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isActive ? AppColors.pureWhite : AppColors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: isActive ? AppColors.buttonPrimary : AppColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide(
        color: isActive ? AppColors.buttonPrimary : AppColors.grey300,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
      child: InkWell(
        onTap: () {
          Get.toNamed(
            AppRoutes.cleanupDetail,
            arguments: cleanup,
          );
        },
        borderRadius: BorderRadius.circular(SizeUtils.r(context, 8)),
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
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            cleanup.groupName,
                            style: AppTextStyles.heading2(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (cleanup.flagged) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.red.shade200,
                              ),
                            ),
                            child: const Text(
                              'Flagged',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.toNamed(
                        AppRoutes.cleanupDetail,
                        arguments: cleanup,
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.pureWhite),
                    label: const Text('View', style: TextStyle(color: AppColors.pureWhite)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Get.toNamed(
                        AppRoutes.editCleanupTrash,
                        arguments: cleanup,
                      );
                      if (Get.isRegistered<MyCleanupsController>()) {
                        Get.find<MyCleanupsController>().loadCleanups();
                      }
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.pureWhite),
                    label: const Text('Edit Trash', style: TextStyle(color: AppColors.pureWhite)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
