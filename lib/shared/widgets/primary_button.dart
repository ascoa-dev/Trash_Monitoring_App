import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double? fixedWidth;
  final double? fixedHeight;
  final Color? backgroundColor;
  final TextStyle? labelStyle;

  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.fixedWidth,
    this.fixedHeight,
    this.backgroundColor,
    this.labelStyle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scaledHeight =
        fixedHeight ?? SizeUtils.h(context, AppDimensions.buttonHeight);
    return SizedBox(
      width: fixedWidth ?? double.infinity,
      height: scaledHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.buttonGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              SizeUtils.r(context, AppDimensions.borderRadius),
            ),
          ),
          minimumSize: Size(fixedWidth ?? double.infinity, scaledHeight),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: labelStyle ?? AppTextStyles.buttonPrimaryText(context),
        ),
      ),
    );
  }
}
