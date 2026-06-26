import 'package:ascoa_app/modules/admin/controllers/admin_controller.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
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
        title: const Text('Admin Management'),
      ),
      body: Obx(() {
        if (!controller.isCurrentUserAdmin.value) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Only admins can manage admin access.',
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
              title: 'Current admins',
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search admins by name or email',
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
                        tooltip: 'Remove admin',
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.snackBarErrorAccent,
                        onPressed: () => controller.removeAdmin(admin.uid),
                      ),
                    ),
                  ),
                  if (controller.filteredAdmins.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No admins match this search.'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Add admin',
              child: Column(
                children: [
                  TextField(
                    controller: userSearchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_search_outlined),
                      hintText: 'Search users by name or email',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: controller.onUserSearchChanged,
                  ),
                  const SizedBox(height: 12),
                  if (controller.isSearching.value)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Searching...'),
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
                        label: const Text('Add'),
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
