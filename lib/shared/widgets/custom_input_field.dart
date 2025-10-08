import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const CustomInputField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.onChanged,
    this.errorText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: AppDimensions.inputFieldHeight,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(
              color: errorText != null ? AppColors.error : AppColors.accent,
              width: AppDimensions.borderWidth,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.inputHorizontalPadding,
          ),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: onChanged,
            // Launch validation via onChanged callback
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              hintStyle: AppTextStyles.inputHint,
            ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: AppDimensions.inputErrorSpacing),
          Padding(
            padding: EdgeInsets.only(left: AppDimensions.inputErrorSpacing),
            child: Text(errorText!, style: AppTextStyles.errorText),
          ),
        ],
      ],
    );
  }
}
