import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

class ProfileSignOutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ProfileSignOutButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: SizeUtils.w(context, AppDimensions.profileCardWidth),
      child: Material(
        color: AppColors.accentGreen,
        borderRadius: BorderRadius.circular(
          SizeUtils.r(context, AppDimensions.borderRadius),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(
            SizeUtils.r(context, AppDimensions.borderRadius),
          ),
          onTap: onPressed,
          child: Container(
            height: SizeUtils.h(context, AppDimensions.profileSignOutHeight),
            padding: EdgeInsets.symmetric(
              horizontal: SizeUtils.w(
                context,
                AppDimensions.profileSignOutHorizontalPadding,
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                SizedBox(
                  width: SizeUtils.r(
                    context,
                    AppDimensions.profileCardIconSize,
                  ),
                  height: SizeUtils.r(
                    context,
                    AppDimensions.profileCardIconSize,
                  ),
                  child: Center(
                    child: Image.asset(
                      AppImages.signout,
                      width: SizeUtils.r(
                        context,
                        AppDimensions.profileCardIconSize,
                      ),
                      height: SizeUtils.r(
                        context,
                        AppDimensions.profileCardIconSize,
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(
                  width: SizeUtils.w(
                    context,
                    AppDimensions.profileSignOutIconGap,
                  ),
                ),
                const Text(
                  AppStrings.profileSignOut,
                  style: AppTextStyles.profileSignOutText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
