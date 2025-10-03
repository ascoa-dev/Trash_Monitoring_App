import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_typography.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';

/// FloatingLabelInputField replicates the Figma absolute label effect:
/// A bordered container with a small label chip overlapping the top border
/// and optional supporting text (error or helper) below.
class FloatingLabelInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final String? supportText; // error or helper
  final bool isError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<bool>? onFocusChange;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final double topSpacing;

  const FloatingLabelInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.supportText,
    this.isError = false,
    this.onChanged,
    this.onFocusChange,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
    this.onEditingComplete,
    this.topSpacing = AppDimensions.fieldVerticalSpacing,
  });

  @override
  State<FloatingLabelInputField> createState() =>
      _FloatingLabelInputFieldState();
}

class _FloatingLabelInputFieldState extends State<FloatingLabelInputField> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;
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
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _hasFocus = _focusNode.hasFocus);
        if (widget.onFocusChange != null) {
          widget.onFocusChange!(_focusNode.hasFocus);
        }
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Focus node is created in initState and updates _hasFocus via listener

    // If controller is disposed, return a basic container to prevent crashes
    if (!_isControllerValid) {
      return Padding(
        padding: const EdgeInsets.only(top: AppDimensions.fieldVerticalSpacing),
        child: Container(
          width: double.infinity,
          height: AppDimensions.inputFieldHeight,
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(
              color: AppColors.accentGreen,
              width: AppDimensions.inputBorderWidth,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        top: widget.topSpacing,
      ), // spacing between stacked fields
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                height: AppDimensions.inputFieldHeight,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(
                    color:
                        widget.isError
                            ? AppColors.error
                            : AppColors.accentGreen,
                    width:
                        widget.isError
                            ? AppDimensions.inputBorderWidthError
                            : (_hasFocus
                                ? AppDimensions.inputBorderWidthFocused
                                : AppDimensions.inputBorderWidth),
                  ),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.smallRadius,
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.inputHorizontalPadding,
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    obscureText: widget.obscure,
                    onChanged: widget.onChanged,
                    keyboardType: widget.keyboardType,
                    textCapitalization: widget.textCapitalization,
                    inputFormatters: widget.inputFormatters,
                    textInputAction: widget.textInputAction,
                    onSubmitted: widget.onSubmitted,
                    onEditingComplete: widget.onEditingComplete,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: AppDimensions.inputFontSize,
                      height: 22 / AppDimensions.inputFontSize,
                      letterSpacing: AppTypography.letterSpacingSmall,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: AppTextStyles.inputHint.copyWith(
                        fontSize: AppDimensions.inputFontSize,
                        letterSpacing: AppTypography.letterSpacingSmall,
                      ),
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              // Floating label chip
              Positioned(
                left:
                    AppDimensions.inputHorizontalPadding -
                    AppDimensions.chipHorizontalPadding, // overlap effect
                top: -AppDimensions.floatingLabelOffset,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.chipHorizontalPadding,
                  ),
                  color: AppColors.background,
                  child: Text(
                    widget.label,
                    style: AppTextStyles.body.copyWith(
                      fontSize: AppDimensions.floatingLabelFontSize,
                      height: 16 / AppDimensions.floatingLabelFontSize,
                      color: AppColors.textAccent,
                      letterSpacing: AppTypography.letterSpacingSmall,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.supportText != null) ...[
            const SizedBox(height: AppDimensions.inputErrorSpacing),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.inputHorizontalPadding,
              ),
              child: Text(
                widget.supportText!,
                style: AppTextStyles.bodySecondary.copyWith(
                  fontSize: AppDimensions.supportTextFontSize,
                  height: 16 / AppDimensions.supportTextFontSize,
                  color:
                      widget.isError ? AppColors.error : AppColors.textAccent,
                  letterSpacing: AppTypography.letterSpacingSmall,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
