import 'package:we_monitor/shared/i18n/tr_params.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/constants/app_images.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/services/snackbar_service.dart';
import 'package:we_monitor/shared/widgets/primary_button.dart';
import 'package:we_monitor/app/controllers/haptic_controller.dart';

class DeleteRequestScreen extends StatefulWidget {
  const DeleteRequestScreen({super.key});

  @override
  State<DeleteRequestScreen> createState() => _DeleteRequestScreenState();
}

class _DeleteRequestScreenState extends State<DeleteRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  String? _requestType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_requestType == null) {
      SnackbarService.error(AppStrings.errorTitle, 'profile.selectRequestTypeError'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('profile.notAuthenticated'.tr);
      }

      await FirebaseFirestore.instance.collection('delete_requests').add({
        'email': (user.email ?? '').trim().toLowerCase(),
        'userId': user.uid,
        'requestType': _requestType,
        'resolved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.find<HapticController>().medium();
      SnackbarService.success(
        'profile.requestSubmittedTitle'.tr,
        'profile.requestSubmittedBody'.trp({'type': _requestType == 'Account Deletion' ? 'profile.accountDeletionName'.tr : 'profile.dataDeletionName'.tr}),
      );

      // Go back to the profile screen
      Get.back();
    } catch (e) {
      Get.find<HapticController>().heavy();
      debugPrint('Error submitting delete request: $e');
      SnackbarService.error(
        'profile.submissionFailedTitle'.tr,
        'profile.submissionFailedBody'.tr,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = SizeUtils.w(context, AppDimensions.screenPadding);
    final hasEmail = _emailController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'profile.deleteScreenTitle'.tr,
          style: AppTextStyles.heading2(context),
        ),
        leading: BackButton(
          color: AppColors.black87,
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: !hasEmail
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(pad),
                  child: Text(
                    AppStrings.deleteRequestNoEmail,
                    style: AppTextStyles.bodySecondary(context),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    AppImages.logo,
                    height: SizeUtils.h(context, 70),
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),

                  // Heading
                  Text(
                    'profile.deleteHeading'.tr,
                    style: AppTextStyles.heading2(
                      context,
                    ).copyWith(fontSize: SizeUtils.h(context, 20)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    'profile.deleteIntro'.tr,
                    style: AppTextStyles.bodySecondary(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Email Field (Read-only / Prefilled)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'profile.yourEmail'.tr,
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    style: AppTextStyles.bodySecondary(
                      context,
                    ).copyWith(color: Colors.grey[600]),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Request Type Dropdown
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'profile.requestTypeLabel'.tr,
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _requestType,
                    style: AppTextStyles.body(context),
                    icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'profile.selectRequestType'.tr,
                      hintStyle: AppTextStyles.bodySecondary(context),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Account Deletion',
                        child: Text('profile.accountDeletionOption'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'Data Deletion',
                        child: Text('profile.dataDeletionOption'.tr),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _requestType = val;
                      });
                    },
                    validator:
                        (val) =>
                            val == null ? 'profile.selectRequestTypeValidator'.tr : null,
                  ),
                  const SizedBox(height: 24),

                  // Warning Box (Red/rose styled alert like the web app)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFBE123C).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFBE123C),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'profile.warningTitle'.tr,
                                style: AppTextStyles.body(context).copyWith(
                                  color: const Color(0xFFBE123C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'profile.warningBody'.tr,
                                style: AppTextStyles.bodySecondary(
                                  context,
                                ).copyWith(
                                  color: const Color(0xFFBE123C),
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PrimaryButton(
                        label: 'profile.submitDeletion'.tr,
                        onPressed: _submitRequest,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
