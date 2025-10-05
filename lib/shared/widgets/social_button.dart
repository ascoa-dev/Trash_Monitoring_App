import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

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
        height: SizeUtils.h(context, AppDimensions.buttonHeight),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(
            color: AppColors.accentGreen,
            width: SizeUtils.w(
              context,
              AppDimensions.socialOutlinedBorderWidth,
            ),
          ),
          borderRadius: BorderRadius.circular(
            SizeUtils.r(context, AppDimensions.borderRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: SizeUtils.r(
                context,
                AppDimensions.boxShadowBlurRadius,
              ),
              offset: Offset(
                SizeUtils.w(context, AppDimensions.boxShadowOffsetX),
                SizeUtils.h(context, AppDimensions.boxShadowOffsetY),
              ),
            ),
          ],
        ),
        child:
            (label == null || label!.isEmpty)
                ? Center(
                  child: SizedBox(
                    width: SizeUtils.r(
                      context,
                      AppDimensions.socialIconContainerSize,
                    ),
                    height: SizeUtils.r(
                      context,
                      AppDimensions.socialIconContainerSize,
                    ),
                    child: icon,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: SizeUtils.r(
                        context,
                        AppDimensions.socialIconContainerSize,
                      ),
                      height: SizeUtils.r(
                        context,
                        AppDimensions.socialIconContainerSize,
                      ),
                      child: icon,
                    ),
                    SizedBox(
                      width: SizeUtils.w(
                        context,
                        AppDimensions.socialContentSpacing,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        label!,
                        style: AppTextStyles.buttonSocialText(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
