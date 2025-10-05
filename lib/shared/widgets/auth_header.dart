import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_typography.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

class AuthHeader extends StatelessWidget {
  final double scale;
  const AuthHeader({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    // Figma reference box (from provided spec): scaled from base constants
    final double baseWidth = SizeUtils.w(
      context,
      AppDimensions.authHeaderBaseWidth * scale,
    );
    final double baseHeight = SizeUtils.h(
      context,
      AppDimensions.authHeaderBaseHeight * scale,
    );

    return SizedBox(
      width: baseWidth,
      height: baseHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Clean Earth main heading
          Positioned(
            left: AppDimensions.zero,
            top: AppDimensions.zero,
            width:
                (AppDimensions.authHeaderBaseWidth -
                    AppDimensions.authHeaderTitleWidthOffset) *
                scale,
            child: Text(
              AppStrings.authHeaderTitle,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: AppTextStyles.heading1(context).copyWith(
                fontSize: SizeUtils.h(
                  context,
                  AppDimensions.authHeaderTitleFontSizeBase * scale,
                ),
                height:
                    SizeUtils.h(
                      context,
                      AppDimensions.authHeaderTitleLineHeightBase * scale,
                    ) /
                    SizeUtils.h(
                      context,
                      AppDimensions.authHeaderTitleFontSizeBase * scale,
                    ),
                letterSpacing: -2 * scale,
              ),
            ),
          ),

          // Logo image (PNG asset replacement)
          Positioned(
            left: SizeUtils.w(
              context,
              AppDimensions.authHeaderLogoLeft * scale,
            ),
            top: SizeUtils.h(context, AppDimensions.authHeaderLogoTop * scale),
            child: SizedBox(
              width: SizeUtils.w(
                context,
                AppDimensions.authHeaderLogoWidth * scale,
              ),
              height: SizeUtils.h(
                context,
                AppDimensions.authHeaderLogoHeight * scale,
              ),
              child: Image.asset(
                // use centralized asset constant
                AppImages.logo,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // "by" text overlay
          Positioned(
            left: SizeUtils.w(context, AppDimensions.authHeaderByLeft * scale),
            top: SizeUtils.h(context, AppDimensions.authHeaderByTop * scale),
            child: Text(
              AppStrings.authHeaderBy,
              style: AppTextStyles.heading1(context).copyWith(
                fontSize: SizeUtils.h(
                  context,
                  AppDimensions.authHeaderByFontSizeBase * scale,
                ),
                fontWeight: FontWeight.w500,
                height:
                    SizeUtils.h(
                      context,
                      AppDimensions.authHeaderByLineHeightBase * scale,
                    ) /
                    SizeUtils.h(
                      context,
                      AppDimensions.authHeaderByFontSizeBase * scale,
                    ),
                letterSpacing: AppTypography.letterSpacingSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
