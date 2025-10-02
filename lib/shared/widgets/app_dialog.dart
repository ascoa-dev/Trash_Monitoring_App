import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';

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
    final size = MediaQuery.of(context).size;
    final double effectiveHeroSize = heroSize ?? AppDimensions.dialogHeroSize;
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
                blurRadius: AppDimensions.prominentBoxShadowBlur,
                offset: const Offset(
                  AppDimensions.boxShadowOffsetX,
                  AppDimensions.boxShadowOffsetY,
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
                topLeft: Radius.circular(AppDimensions.dialogRadius),
                topRight: Radius.circular(AppDimensions.dialogRadius),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.dialogRadius),
                topRight: Radius.circular(AppDimensions.dialogRadius),
              ),
              child: Stack(
                children: [
                  // Internal decorative background (fixed values):
                  // Use Forgot Password top image flipped at the bottom to match design.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: AppDimensions.dialogDecorativeBgOpacity,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationZ(3.1415926535897932),
                        child: Image.asset(
                          'assets/ASCOA/Forgot_Password_Screen_Top.png',
                          width: size.width,
                          height: AppDimensions.dialogDecorativeBgHeight,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.dialogHorizontalPadding,
                        AppDimensions.dialogTopPadding,
                        AppDimensions.dialogHorizontalPadding,
                        AppDimensions.dialogBottomPadding,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heading2.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: AppDimensions.dialogTitleFontSize,
                              height:
                                  AppDimensions.dialogTitleLineHeight /
                                  AppDimensions.dialogTitleFontSize,
                              color: AppColors.textDark,
                              letterSpacing:
                                  AppDimensions.dialogTitleLetterSpacing,
                            ),
                          ),
                          if (effectiveHero != null) ...[
                            SizedBox(height: AppDimensions.smallSpacing * 2),
                            Align(
                              alignment: Alignment.center,
                              child: effectiveHero,
                            ),
                          ],
                          if (body != null && body!.isNotEmpty) ...[
                            SizedBox(height: AppDimensions.smallSpacing * 2),
                            Text(
                              body!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(
                                fontSize: AppDimensions.dialogBodyFontSize,
                                height:
                                    AppDimensions.dialogBodyLineHeight /
                                    AppDimensions.dialogBodyFontSize,
                                color: AppColors.textDark,
                                letterSpacing:
                                    AppDimensions.dialogBodyLetterSpacing,
                              ),
                            ),
                          ],
                          SizedBox(height: AppDimensions.smallSpacing * 3),
                          SizedBox(
                            height: AppDimensions.buttonHeight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: onPrimaryAction,
                              child: Text(
                                primaryActionLabel,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppDimensions.dialogActionFontSize,
                                  height: 20 / 14,
                                  color: AppColors.pureWhite,
                                  letterSpacing:
                                      AppDimensions.dialogButtonLetterSpacing,
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
