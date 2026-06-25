import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/app/controllers/haptic_controller.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

class ProfileActionTile extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color iconColor;

  const ProfileActionTile({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.backgroundColor = AppColors.profileCardBackground,
    this.iconColor = AppColors.textDark,
  }) : assert(
         icon != null || leading != null,
         'Either an icon or a leading widget must be provided.',
       );

  @override
  Widget build(BuildContext context) {
    final Widget leadingWidget = SizedBox(
      width: SizeUtils.r(context, AppDimensions.profileCardIconSize),
      height: SizeUtils.r(context, AppDimensions.profileCardIconSize),
      child: Center(
        child:
            leading ??
            Icon(
              icon!,
              size: SizeUtils.r(context, AppDimensions.profileCardIconSize),
              color: iconColor,
            ),
      ),
    );

    return SizedBox(
      width: SizeUtils.w(context, AppDimensions.profileCardWidth),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            SizeUtils.r(context, AppDimensions.borderRadius),
          ),
          onTap:
              onTap != null
                  ? () {
                    Get.find<HapticController>().selectionClick();
                    onTap!();
                  }
                  : null,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: SizeUtils.h(
                context,
                AppDimensions.profileCardMinHeight,
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: SizeUtils.w(
                context,
                AppDimensions.profileCardPaddingHorizontal,
              ),
              vertical: SizeUtils.h(
                context,
                AppDimensions.profileCardPaddingVertical,
              ),
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(
                SizeUtils.r(context, AppDimensions.borderRadius),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                leadingWidget,
                SizedBox(
                  width: SizeUtils.w(
                    context,
                    AppDimensions.profileCardContentGap,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.profileActionTitle(context),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(
                          height: SizeUtils.h(
                            context,
                            AppDimensions.profileCardLabelSpacing,
                          ),
                        ),
                        Text(
                          subtitle!,
                          style: AppTextStyles.profileActionSubtitle(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
