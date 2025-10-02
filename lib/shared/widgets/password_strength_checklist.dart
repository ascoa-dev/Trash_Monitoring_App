import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/shared/controllers/validation_controller.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';

class PasswordStrengthChecklist extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  const PasswordStrengthChecklist({
    super.key,
    this.padding = const EdgeInsets.only(top: AppDimensions.inputErrorSpacing),
  });

  @override
  Widget build(BuildContext context) {
    final validation = Get.find<ValidationController>();
    return Obx(() {
      final items = [
        _Rule(AppStrings.passwordRuleMinLength, validation.hasMinLength.value),
        _Rule(AppStrings.passwordRuleUppercase, validation.hasUppercase.value),
        _Rule(AppStrings.passwordRuleLowercase, validation.hasLowercase.value),
        _Rule(AppStrings.passwordRuleNumber, validation.hasNumber.value),
        _Rule(AppStrings.passwordRuleSpecial, validation.hasSpecial.value),
      ];
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((r) => _RuleRow(rule: r)).toList(),
        ),
      );
    });
  }
}

class _Rule {
  final String label;
  final bool met;
  _Rule(this.label, this.met);
}

class _RuleRow extends StatelessWidget {
  final _Rule rule;
  const _RuleRow({required this.rule});
  @override
  Widget build(BuildContext context) {
    final color = rule.met ? AppColors.accentGreen : AppColors.error;
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.checklistItemSpacing),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: AppDimensions.statusDotSize,
            height: AppDimensions.statusDotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rule.met ? AppColors.accentGreen : AppColors.transparent,
              border: Border.all(
                color: color,
                width: AppDimensions.statusDotBorderWidth,
              ),
            ),
            child:
                rule.met
                    ? const Icon(
                      Icons.check,
                      size: AppDimensions.statusIconSize,
                      color: AppColors.pureWhite,
                    )
                    : null,
          ),
          const SizedBox(width: AppDimensions.smallSpacing),
          Flexible(
            child: Text(
              rule.label,
              style: AppTextStyles.bodySecondary.copyWith(
                color: color,
                fontSize: AppDimensions.checklistFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
