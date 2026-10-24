import 'package:we_monitor/modules/admin/controllers/admin_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminController());
    final userSearchController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text('admin.title'.tr),
      ),
      body: Obx(() {
        if (!controller.isCurrentUserAdmin.value) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'admin.adminsOnly'.tr,
                style: AppTextStyles.heading2(context),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: 'admin.currentAdmins'.tr,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'admin.searchAdmins'.tr,
                      border: OutlineInputBorder(),
                    ),
                    onChanged:
                        (value) => controller.adminSearchQuery.value = value,
                  ),
                  const SizedBox(height: 12),
                  ...controller.filteredAdmins.map(
                    (admin) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        admin.displayName.isNotEmpty
                            ? admin.displayName
                            : admin.email,
                      ),
                      subtitle: Text(admin.email),
                      trailing: IconButton(
                        tooltip: 'admin.removeAdmin'.tr,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.snackBarErrorAccent,
                        onPressed: () => controller.removeAdmin(admin.uid),
                      ),
                    ),
                  ),
                  if (controller.filteredAdmins.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('admin.noAdminMatch'.tr),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'admin.addAdmin'.tr,
              child: Column(
                children: [
                  TextField(
                    controller: userSearchController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person_search_outlined),
                      hintText: 'admin.searchUsers'.tr,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: controller.onUserSearchChanged,
                  ),
                  const SizedBox(height: 12),
                  if (controller.isSearching.value)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('admin.searching'.tr),
                      ),
                    ),
                  ...controller.userResults.map(
                    (user) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${user.firstName} ${user.lastName}'.trim().isNotEmpty
                            ? '${user.firstName} ${user.lastName}'.trim()
                            : user.email,
                      ),
                      subtitle: Text(user.email),
                      trailing: TextButton.icon(
                        onPressed: () => controller.addAdmin(user),
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        label: Text('admin.add'.tr),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading2(context)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
