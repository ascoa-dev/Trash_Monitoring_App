import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';

class CustomInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final ValueChanged<bool>? onFocusChange;

  const CustomInputField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.onChanged,
    this.errorText,
    this.onFocusChange,
    super.key,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  late FocusNode _focusNode;
  bool get _isControllerValid {
    try {
      // Try to access the controller's value to check if it's disposed
      widget.controller.value;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If controller is disposed, return a basic container to prevent crashes
    if (!_isControllerValid) {
      return Container(
        width: double.infinity,
        height: AppDimensions.inputFieldHeight,
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          border: Border.all(
            color: AppColors.accentGreen,
            width: AppDimensions.borderWidth,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: AppDimensions.inputFieldHeight,
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            border: Border.all(
              color:
                  widget.errorText != null
                      ? AppColors.error
                      : AppColors.accentGreen,
              width:
                  widget.errorText != null
                      ? AppDimensions.inputBorderWidthError
                      : (_focusNode.hasFocus
                          ? AppDimensions.inputBorderWidthFocused
                          : AppDimensions.borderWidth),
            ),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: AppDimensions.boxShadowBlurRadius,
                offset: Offset(
                  AppDimensions.boxShadowOffsetX,
                  AppDimensions.boxShadowOffsetY,
                ),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.inputHorizontalPadding,
          ),
          alignment: Alignment.centerLeft,
          child: TextField(
            focusNode: _focusNode,
            controller: widget.controller,
            obscureText: widget.obscure,
            onChanged: widget.onChanged,
            // Launch validation via onChanged callback
            decoration: InputDecoration(
              hintText: widget.hint,
              border: InputBorder.none,
              hintStyle: AppTextStyles.inputHint,
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          SizedBox(height: AppDimensions.inputErrorSpacing),
          Padding(
            padding: EdgeInsets.only(left: AppDimensions.inputErrorSpacing),
            child: Text(widget.errorText!, style: AppTextStyles.errorText),
          ),
        ],
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (widget.onFocusChange != null) {
        widget.onFocusChange!(_focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
