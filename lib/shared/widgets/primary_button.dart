import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          minimumSize: Size(double.infinity, AppDimensions.buttonHeight),
        ),
        onPressed: onPressed,
        child: Text(label, style: AppTextStyles.buttonPrimaryText),
      ),
    );
  }
}
