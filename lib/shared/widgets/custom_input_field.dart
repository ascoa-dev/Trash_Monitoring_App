import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

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
        height: SizeUtils.h(context, AppDimensions.inputFieldHeight),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          border: Border.all(
            color: AppColors.accentGreen,
            width: SizeUtils.w(context, AppDimensions.borderWidth),
          ),
          borderRadius: BorderRadius.circular(
            SizeUtils.r(context, AppDimensions.borderRadius),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: SizeUtils.h(context, AppDimensions.inputFieldHeight),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            border: Border.all(
              color:
                  widget.errorText != null
                      ? AppColors.error
                      : AppColors.accentGreen,
              width:
                  widget.errorText != null
                      ? SizeUtils.w(
                        context,
                        AppDimensions.inputBorderWidthError,
                      )
                      : (_focusNode.hasFocus
                          ? SizeUtils.w(
                            context,
                            AppDimensions.inputBorderWidthFocused,
                          )
                          : SizeUtils.w(context, AppDimensions.borderWidth)),
            ),
            borderRadius: BorderRadius.circular(
              SizeUtils.r(context, AppDimensions.borderRadius),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: SizeUtils.r(
                  context,
                  AppDimensions.boxShadowBlurRadius,
                ),
                offset: Offset(
                  SizeUtils.w(context, AppDimensions.boxShadowOffsetX),
                  SizeUtils.h(context, AppDimensions.boxShadowOffsetY),
                ),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: SizeUtils.w(
              context,
              AppDimensions.inputHorizontalPadding,
            ),
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
          SizedBox(
            height: SizeUtils.h(context, AppDimensions.inputErrorSpacing),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: SizeUtils.w(context, AppDimensions.inputErrorSpacing),
            ),
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
