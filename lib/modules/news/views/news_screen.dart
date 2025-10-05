import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(SizeUtils.w(context, 16)),
        child: Container(
          color: AppColors.background,
          alignment: Alignment.center,
          child: Text(
            AppStrings.newsTitle,
            style: AppTextStyles.heading1(context),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
