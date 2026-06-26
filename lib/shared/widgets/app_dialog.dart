import 'package:flutter/material.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/constants/app_typography.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_images.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/controllers/haptic_controller.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String? body;
  final Widget? hero;
  final IconData? icon;
  final String? imageAsset;
  final double? heroSize;
  final double? iconSize;
  final Color? iconColor;
  final double? imageWidth;
  final double? imageHeight;
  final bool decoratedHero;
  // Decorative background is internal to the widget; callers do not control it.
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;

  const AppDialog({
    super.key,
    required this.title,
    this.body,
    this.hero,
    this.icon,
    this.imageAsset,
    this.heroSize,
    this.iconSize,
    this.iconColor,
    this.imageWidth,
    this.imageHeight,
    this.decoratedHero = true,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final haptics = Get.find<HapticController>();
    final size = MediaQuery.of(context).size;
    final double effectiveHeroSize =
        heroSize ?? SizeUtils.r(context, AppDimensions.dialogHeroSize);
    final double effectiveIconSize = iconSize ?? (effectiveHeroSize * 0.5);

    Widget? effectiveHero = hero;
    if (effectiveHero == null && (icon != null || imageAsset != null)) {
      if (decoratedHero) {
        effectiveHero = Container(
          width: effectiveHeroSize,
          height: effectiveHeroSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.buttonGreen70, AppColors.buttonGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.buttonGreen40,
                blurRadius: SizeUtils.r(
                  context,
                  AppDimensions.prominentBoxShadowBlur,
                ),
                offset: Offset(
                  SizeUtils.w(context, AppDimensions.boxShadowOffsetX),
                  SizeUtils.h(context, AppDimensions.boxShadowOffsetY),
                ),
              ),
            ],
          ),
          child: Center(
            child:
                icon != null
                    ? Icon(
                      icon,
                      size: effectiveIconSize,
                      color: iconColor ?? AppColors.pureWhite,
                    )
                    : Image.asset(
                      imageAsset!,
                      width: effectiveIconSize,
                      height: effectiveIconSize,
                      fit: BoxFit.contain,
                    ),
          ),
        );
      } else {
        // Plain image/icon without decoration
        effectiveHero =
            icon != null
                ? Icon(
                  icon,
                  size: effectiveIconSize,
                  color: iconColor ?? AppColors.textDark,
                )
                : Image.asset(
                  imageAsset!,
                  width: imageWidth ?? effectiveIconSize,
                  height: imageHeight ?? effectiveIconSize,
                  fit: BoxFit.contain,
                );
      }
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: AppColors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: size.width),
          child: Container(
            width: size.width,
            decoration: BoxDecoration(
              color: AppColors.dialogBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                  SizeUtils.r(context, AppDimensions.dialogRadius),
                ),
                topRight: Radius.circular(
                  SizeUtils.r(context, AppDimensions.dialogRadius),
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                  SizeUtils.r(context, AppDimensions.dialogRadius),
                ),
                topRight: Radius.circular(
                  SizeUtils.r(context, AppDimensions.dialogRadius),
                ),
              ),
              child: Stack(
                children: [
                  // Internal decorative background (fixed values):
                  // Use Forgot Password top image flipped at the bottom to match design.
                  Positioned(
                    left: AppDimensions.zero,
                    right: AppDimensions.zero,
                    bottom: AppDimensions.zero,
                    child: Opacity(
                      opacity: AppDimensions.dialogDecorativeBgOpacity,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationZ(3.1415926535897932),
                        child: Image.asset(
                          AppImages.forgotPasswordTop,
                          width: size.width,
                          height: SizeUtils.h(
                            context,
                            AppDimensions.dialogDecorativeBgHeight,
                          ),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        SizeUtils.w(
                          context,
                          AppDimensions.dialogHorizontalPadding,
                        ),
                        SizeUtils.h(context, AppDimensions.dialogTopPadding),
                        SizeUtils.w(
                          context,
                          AppDimensions.dialogHorizontalPadding,
                        ),
                        SizeUtils.h(context, AppDimensions.dialogBottomPadding),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heading2(context).copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: SizeUtils.h(
                                context,
                                AppDimensions.dialogTitleFontSize,
                              ),
                              height:
                                  SizeUtils.h(
                                    context,
                                    AppDimensions.dialogTitleLineHeight,
                                  ) /
                                  SizeUtils.h(
                                    context,
                                    AppDimensions.dialogTitleFontSize,
                                  ),
                              color: AppColors.textDark,
                              letterSpacing: AppTypography.letterSpacingSmall,
                            ),
                          ),
                          if (effectiveHero != null) ...[
                            SizedBox(
                              height: SizeUtils.h(
                                context,
                                AppDimensions.smallSpacing * 2,
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: effectiveHero,
                            ),
                          ],
                          if (body != null && body!.isNotEmpty) ...[
                            SizedBox(
                              height: SizeUtils.h(
                                context,
                                AppDimensions.smallSpacing * 2,
                              ),
                            ),
                            Text(
                              body!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body(context).copyWith(
                                fontSize: SizeUtils.h(
                                  context,
                                  AppDimensions.dialogBodyFontSize,
                                ),
                                height:
                                    SizeUtils.h(
                                      context,
                                      AppDimensions.dialogBodyLineHeight,
                                    ) /
                                    SizeUtils.h(
                                      context,
                                      AppDimensions.dialogBodyFontSize,
                                    ),
                                color: AppColors.textDark,
                                letterSpacing: AppTypography.letterSpacingSmall,
                              ),
                            ),
                          ],
                          SizedBox(
                            height: SizeUtils.h(
                              context,
                              AppDimensions.smallSpacing * 3,
                            ),
                          ),
                          SizedBox(
                            height: SizeUtils.h(
                              context,
                              AppDimensions.buttonHeight,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    SizeUtils.r(
                                      context,
                                      AppDimensions.smallButtonRadius,
                                    ),
                                  ),
                                ),
                              ),
                              onPressed: () {
                                haptics.medium();
                                onPrimaryAction();
                              },
                              child: Text(
                                primaryActionLabel,
                                style: AppTextStyles.body(context).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: SizeUtils.h(
                                    context,
                                    AppDimensions.dialogActionFontSize,
                                  ),
                                  height:
                                      SizeUtils.h(
                                        context,
                                        AppDimensions.dialogActionLineHeight,
                                      ) /
                                      SizeUtils.h(
                                        context,
                                        AppDimensions.dialogActionFontSize,
                                      ),
                                  color: AppColors.pureWhite,
                                  letterSpacing:
                                      AppTypography.letterSpacingSmall,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
