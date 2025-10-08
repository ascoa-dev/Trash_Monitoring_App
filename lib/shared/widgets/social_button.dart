import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';

class SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: AppDimensions.buttonHeight,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.accent, width: 3),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: AppDimensions.socialIconContainerSize,
              height: AppDimensions.socialIconContainerSize,
              child: icon,
            ),
            SizedBox(width: AppDimensions.socialContentSpacing),
            Text(label, style: AppTextStyles.buttonSocialText),
          ],
        ),
      ),
    );
  }
}
