import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';

class AuthHeader extends StatelessWidget {
  final double scale;

  const AuthHeader({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    final title = AppStrings.authHeaderTitle; // "Clean Earth"

    final titleStyle = AppTextStyles.heading1(context).copyWith(
      fontSize: AppDimensions.authHeaderTitleFontSizeBase * scale,
      letterSpacing: -1.5 * scale,
      height: 1.1,
    );

    // ── Measure title ──
    final textPainter = TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final double titleWidth = textPainter.width;
    final double logoHeight = AppDimensions.authHeaderLogoHeight * scale;

    // ── Find the x-offset of the letter 'n' ──
    final int nIndex = title.contains('n') ? title.indexOf('n') : 0;

    final boxes = textPainter.getBoxesForSelection(
      TextSelection(baseOffset: nIndex, extentOffset: nIndex + 1),
    );

    final double nOffsetX = boxes.isNotEmpty ? boxes.first.left : 0.0;

    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Clean Earth ──
            Text(title, style: titleStyle, textAlign: TextAlign.left),
            Transform.translate(
              offset: Offset(0, -logoHeight * 0.22),
              child: Padding(
                padding: EdgeInsets.only(left: nOffsetX),
                child: SizedBox(
                  width: (titleWidth - nOffsetX).clamp(0.0, double.infinity),
                  height: logoHeight,
                  child: Stack(
                    alignment: Alignment.topRight,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Image.asset(
                          AppImages.logo,
                          height: logoHeight,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        left: titleWidth * 0.06,
                        top: logoHeight * 0.14,
                        child: Text(
                          AppStrings.authHeaderBy,
                          style: AppTextStyles.heading1(context).copyWith(
                            fontSize:
                                AppDimensions.authHeaderByFontSizeBase * scale,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
