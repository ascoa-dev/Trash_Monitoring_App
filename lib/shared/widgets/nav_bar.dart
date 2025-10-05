import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavItemData> _items = [
    _NavItemData(
      assetPath: AppImages.navHome,
      semanticLabel: AppStrings.homeTitle,
    ),
    _NavItemData(
      assetPath: AppImages.navStats,
      semanticLabel: AppStrings.statsTitle,
    ),
    _NavItemData(
      assetPath: AppImages.navAdd,
      semanticLabel: AppStrings.addTitle,
    ),
    _NavItemData(
      assetPath: AppImages.navNews,
      semanticLabel: AppStrings.newsTitle,
    ),
    _NavItemData(
      assetPath: AppImages.navProfile,
      semanticLabel: AppStrings.profileTitle,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: SizeUtils.w(context, AppDimensions.navBarHorizontalPadding),
          right: SizeUtils.w(context, AppDimensions.navBarHorizontalPadding),
          bottom: SizeUtils.h(context, AppDimensions.navBarBottomOffset),
        ),
        child: Container(
          height: SizeUtils.h(context, AppDimensions.navBarHeight),
          padding: EdgeInsets.symmetric(
            horizontal: SizeUtils.w(
              context,
              AppDimensions.navBarInnerHorizontalPadding,
            ),
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(
              SizeUtils.r(context, AppDimensions.navBarBorderRadius),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                offset: Offset(
                  AppDimensions.zero,
                  SizeUtils.h(context, AppDimensions.navBarShadowOffsetYLarge),
                ),
                blurRadius: SizeUtils.r(
                  context,
                  AppDimensions.navBarShadowBlurLarge,
                ),
                spreadRadius: SizeUtils.r(
                  context,
                  AppDimensions.navBarShadowSpreadLarge,
                ),
              ),
              BoxShadow(
                color: AppColors.shadowMedium,
                offset: Offset(
                  AppDimensions.zero,
                  SizeUtils.h(context, AppDimensions.navBarShadowOffsetYSmall),
                ),
                blurRadius: SizeUtils.r(
                  context,
                  AppDimensions.navBarShadowBlurSmall,
                ),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final bool isCenter = index == 2;
              final bool isSelected = !isCenter && index == currentIndex;
              return _NavBarButton(
                data: _items[index],
                isSelected: isSelected,
                isCenter: isCenter,
                onTap: () => onTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarButton extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final bool isCenter;
  final VoidCallback onTap;

  const _NavBarButton({
    required this.data,
    required this.isSelected,
    required this.isCenter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double targetWidth;
    final double targetHeight;
    if (isCenter) {
      targetWidth = SizeUtils.w(context, AppDimensions.navBarCenterButtonWidth);
      targetHeight = SizeUtils.h(
        context,
        AppDimensions.navBarCenterButtonHeight,
      );
    } else {
      final double size =
          isSelected
              ? SizeUtils.r(
                context,
                AppDimensions.navBarActiveIconContainerSize,
              )
              : SizeUtils.r(context, AppDimensions.navBarIconContainerSize);
      targetWidth = size;
      targetHeight = size;
    }

    final double iconWidth =
        isCenter
            ? SizeUtils.w(context, AppDimensions.navBarCenterButtonWidth)
            : SizeUtils.r(context, AppDimensions.navBarIconSize);
    final double iconHeight =
        isCenter
            ? SizeUtils.h(context, AppDimensions.navBarCenterButtonHeight)
            : SizeUtils.r(context, AppDimensions.navBarIconSize);

    final Color backgroundColor =
        isCenter
            ? AppColors.transparent
            : isSelected
            ? AppColors.navBarSelectedBackground
            : AppColors.transparent;

    final BorderRadius borderRadius =
        isCenter
            ? BorderRadius.zero
            : BorderRadius.circular(
              SizeUtils.r(context, AppDimensions.navBarIconContainerSize) / 2,
            );

    return Expanded(
      child: Semantics(
        label: data.semanticLabel,
        selected: isSelected,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox.expand(
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: targetWidth,
                height: targetHeight,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: borderRadius,
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  data.assetPath,
                  width: iconWidth,
                  height: iconHeight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String assetPath;
  final String semanticLabel;

  const _NavItemData({required this.assetPath, required this.semanticLabel});
}
