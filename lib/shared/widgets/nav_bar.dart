import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';

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
        padding: const EdgeInsets.only(
          left: AppDimensions.navBarHorizontalPadding,
          right: AppDimensions.navBarHorizontalPadding,
          bottom: AppDimensions.navBarBottomOffset,
        ),
        child: Container(
          height: AppDimensions.navBarHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.navBarInnerHorizontalPadding,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(
              AppDimensions.navBarBorderRadius,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowLight,
                offset: Offset(0, AppDimensions.navBarShadowOffsetYLarge),
                blurRadius: AppDimensions.navBarShadowBlurLarge,
                spreadRadius: AppDimensions.navBarShadowSpreadLarge,
              ),
              BoxShadow(
                color: AppColors.shadowMedium,
                offset: Offset(0, AppDimensions.navBarShadowOffsetYSmall),
                blurRadius: AppDimensions.navBarShadowBlurSmall,
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
      targetWidth = AppDimensions.navBarCenterButtonWidth;
      targetHeight = AppDimensions.navBarCenterButtonHeight;
    } else {
      final double size =
          isSelected
              ? AppDimensions.navBarActiveIconContainerSize
              : AppDimensions.navBarIconContainerSize;
      targetWidth = size;
      targetHeight = size;
    }

    final double iconWidth =
        isCenter
            ? AppDimensions.navBarCenterButtonWidth
            : AppDimensions.navBarIconSize;
    final double iconHeight =
        isCenter
            ? AppDimensions.navBarCenterButtonHeight
            : AppDimensions.navBarIconSize;

    final Color backgroundColor =
        isCenter
            ? AppColors.transparent
            : isSelected
            ? AppColors.navBarSelectedBackground
            : AppColors.transparent;

    final BorderRadius borderRadius =
        isCenter
            ? BorderRadius.zero
            : BorderRadius.circular(AppDimensions.navBarIconContainerSize / 2);

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
