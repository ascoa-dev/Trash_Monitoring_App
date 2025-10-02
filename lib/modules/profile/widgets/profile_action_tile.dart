import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';

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
      width: AppDimensions.profileCardIconSize,
      height: AppDimensions.profileCardIconSize,
      child: Center(
        child:
            leading ??
            Icon(
              icon!,
              size: AppDimensions.profileCardIconSize,
              color: iconColor,
            ),
      ),
    );

    return SizedBox(
      width: AppDimensions.profileCardWidth,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.profileCardMinHeight,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.profileCardPaddingHorizontal,
              vertical: AppDimensions.profileCardPaddingVertical,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                leadingWidget,
                const SizedBox(width: AppDimensions.profileCardContentGap),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.profileActionTitle),
                      if (subtitle != null) ...[
                        const SizedBox(
                          height: AppDimensions.profileCardLabelSpacing,
                        ),
                        Text(
                          subtitle!,
                          style: AppTextStyles.profileActionSubtitle,
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
