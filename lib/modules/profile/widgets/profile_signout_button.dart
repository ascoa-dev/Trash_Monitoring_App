import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_images.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';

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
          onTap: () {
            Get.find<HapticController>().light();
            onPressed();
          },
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
                Text(
                  AppStrings.profileSignOut,
                  style: AppTextStyles.profileSignOutText(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
