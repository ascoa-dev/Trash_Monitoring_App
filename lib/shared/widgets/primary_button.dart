import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double? fixedWidth;
  final double? fixedHeight;

  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.fixedWidth,
    this.fixedHeight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fixedWidth ?? double.infinity,
      height: fixedHeight ?? AppDimensions.buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          minimumSize: Size(
            fixedWidth ?? double.infinity,
            fixedHeight ?? AppDimensions.buttonHeight,
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: AppTextStyles.buttonPrimaryText),
      ),
    );
  }
}
