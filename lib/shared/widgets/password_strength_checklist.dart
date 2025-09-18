import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/shared/controllers/validation_controller.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';

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
        _Rule('At least 8 characters', validation.hasMinLength.value),
        _Rule('Uppercase letter', validation.hasUppercase.value),
        _Rule('Lowercase letter', validation.hasLowercase.value),
        _Rule('Number', validation.hasNumber.value),
        _Rule('Special character (@, !, %, etc.)', validation.hasSpecial.value),
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
              color: rule.met ? AppColors.accentGreen : Colors.transparent,
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
                      color: Colors.white,
                    )
                    : null,
          ),
          const SizedBox(width: AppDimensions.smallSpacing),
          Flexible(
            child: Text(
              rule.label,
              style: AppTextStyles.bodySecondary.copyWith(
                color: color,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
