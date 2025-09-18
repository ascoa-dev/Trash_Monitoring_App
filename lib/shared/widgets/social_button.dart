import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';

class SocialButton extends StatelessWidget {
  final Widget icon;
  final String? label; // optional
  final Color color;
  final VoidCallback onPressed;

  const SocialButton({
    required this.icon,
    this.label,
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
          color: AppColors.background,
          border: Border.all(
            color: AppColors.accentGreen,
            width: AppDimensions.socialOutlinedBorderWidth,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: AppDimensions.boxShadowBlurRadius,
              offset: Offset(
                AppDimensions.boxShadowOffsetX,
                AppDimensions.boxShadowOffsetY,
              ),
            ),
          ],
        ),
        child:
            (label == null || label!.isEmpty)
                ? Center(
                  child: SizedBox(
                    width: AppDimensions.socialIconContainerSize,
                    height: AppDimensions.socialIconContainerSize,
                    child: icon,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: AppDimensions.socialIconContainerSize,
                      height: AppDimensions.socialIconContainerSize,
                      child: icon,
                    ),
                    SizedBox(width: AppDimensions.socialContentSpacing),
                    Flexible(
                      child: Text(
                        label!,
                        style: AppTextStyles.buttonSocialText,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
