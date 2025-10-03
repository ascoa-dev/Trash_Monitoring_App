import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_typography.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';

class AuthHeader extends StatelessWidget {
  final double scale;
  const AuthHeader({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    // Figma reference box (from provided spec): scaled from base constants
    final double baseWidth = AppDimensions.authHeaderBaseWidth * scale;
    final double baseHeight = AppDimensions.authHeaderBaseHeight * scale;

    return SizedBox(
      width: baseWidth,
      height: baseHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Clean Earth main heading
          Positioned(
            left: 0,
            top: 0,
            width:
                (AppDimensions.authHeaderBaseWidth -
                    AppDimensions.authHeaderTitleWidthOffset) *
                scale,
            child: Text(
              AppStrings.authHeaderTitle,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: AppTextStyles.heading1.copyWith(
                fontSize: AppDimensions.authHeaderTitleFontSizeBase * scale,
                height:
                    AppDimensions.authHeaderTitleLineHeightBase /
                    (AppDimensions.authHeaderTitleFontSizeBase * scale),
                letterSpacing: -2 * scale,
              ),
            ),
          ),

          // Logo image (PNG asset replacement)
          Positioned(
            left: AppDimensions.authHeaderLogoLeft * scale,
            top: AppDimensions.authHeaderLogoTop * scale,
            child: SizedBox(
              width: AppDimensions.authHeaderLogoWidth * scale,
              height: AppDimensions.authHeaderLogoHeight * scale,
              child: Image.asset(
                // use centralized asset constant
                AppImages.logo,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // "by" text overlay
          Positioned(
            left: AppDimensions.authHeaderByLeft * scale,
            top: AppDimensions.authHeaderByTop * scale,
            child: Text(
              AppStrings.authHeaderBy,
              style: AppTextStyles.heading1.copyWith(
                fontSize: AppDimensions.authHeaderByFontSizeBase * scale,
                fontWeight: FontWeight.w500,
                height:
                    AppDimensions.authHeaderByLineHeightBase /
                    (AppDimensions.authHeaderByFontSizeBase * scale),
                letterSpacing: AppTypography.letterSpacingSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
