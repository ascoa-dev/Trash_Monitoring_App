import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

class AddReportScreen extends StatelessWidget {
  const AddReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.addTitle,
          style: AppTextStyles.heading2(context),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          SizeUtils.w(context, AppDimensions.screenPadding),
          SizeUtils.h(context, AppDimensions.screenPadding),
          SizeUtils.w(context, AppDimensions.screenPadding),
          SizeUtils.h(context, AppDimensions.screenPadding) +
              MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.addReportPlaceholder,
              style: AppTextStyles.body(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
