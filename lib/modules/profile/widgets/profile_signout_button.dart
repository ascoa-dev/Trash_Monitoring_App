import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

class ProfileSignOutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ProfileSignOutButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.profileCardWidth,
      child: Material(
        color: AppColors.accentGreen,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          onTap: onPressed,
          child: Container(
            height: AppDimensions.profileSignOutHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.profileSignOutHorizontalPadding,
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                SizedBox(
                  width: AppDimensions.profileCardIconSize,
                  height: AppDimensions.profileCardIconSize,
                  child: Center(
                    child: Image.asset(
                      AppImages.signout,
                      width: AppDimensions.profileCardIconSize,
                      height: AppDimensions.profileCardIconSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.profileSignOutIconGap),
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
