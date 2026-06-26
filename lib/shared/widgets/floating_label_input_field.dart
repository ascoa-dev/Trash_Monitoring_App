import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_typography.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:get/get.dart';

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
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
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
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
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
    final haptics = Get.find<HapticController>();
    // Focus node is created in initState and updates _hasFocus via listener

    // If controller is disposed, return a basic container to prevent crashes
    if (!_isControllerValid) {
      return Padding(
        padding: EdgeInsets.only(
          top: SizeUtils.h(context, AppDimensions.fieldVerticalSpacing),
        ),
        child: Container(
          width: double.infinity,
          height: SizeUtils.h(context, AppDimensions.inputFieldHeight),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(
              color: AppColors.accentGreen,
              width: SizeUtils.w(context, AppDimensions.inputBorderWidth),
            ),
            borderRadius: BorderRadius.circular(
              SizeUtils.r(context, AppDimensions.smallRadius),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        top: SizeUtils.h(context, widget.topSpacing),
      ), // spacing between stacked fields
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                height: SizeUtils.h(context, AppDimensions.inputFieldHeight),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(
                    color:
                        widget.isError
                            ? AppColors.error
                            : AppColors.accentGreen,
                    width:
                        widget.isError
                            ? SizeUtils.w(
                              context,
                              AppDimensions.inputBorderWidthError,
                            )
                            : (_hasFocus
                                ? SizeUtils.w(
                                  context,
                                  AppDimensions.inputBorderWidthFocused,
                                )
                                : SizeUtils.w(
                                  context,
                                  AppDimensions.inputBorderWidth,
                                )),
                  ),
                  borderRadius: BorderRadius.circular(
                    SizeUtils.w(context, AppDimensions.smallRadius),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeUtils.w(
                      context,
                      AppDimensions.inputHorizontalPadding,
                    ),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    readOnly: widget.readOnly,
                    onTap: () {
                      haptics.selectionClick();
                      widget.onTap?.call();
                    },
                    obscureText: widget.obscure,
                    onChanged: widget.onChanged,
                    keyboardType: widget.keyboardType,
                    textCapitalization: widget.textCapitalization,
                    inputFormatters: widget.inputFormatters,
                    textInputAction: widget.textInputAction,
                    onSubmitted: widget.onSubmitted,
                    onEditingComplete: widget.onEditingComplete,
                    style: AppTextStyles.body(context).copyWith(
                      color: AppColors.textPrimary,
                      fontSize: SizeUtils.h(
                        context,
                        AppDimensions.inputFontSize,
                      ),
                      height:
                          SizeUtils.h(context, 22) /
                          SizeUtils.h(context, AppDimensions.inputFontSize),
                      letterSpacing: AppTypography.letterSpacingSmall,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: AppTextStyles.inputHint(context).copyWith(
                        fontSize: SizeUtils.h(
                          context,
                          AppDimensions.inputFontSize,
                        ),
                        letterSpacing: AppTypography.letterSpacingSmall,
                      ),
                      suffixIcon: widget.suffixIcon,
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: SizeUtils.h(
                          context,
                          AppDimensions.inputContentVerticalPadding,
                        ), // Center text vertically
                      ),
                    ),
                  ),
                ),
              ),
              // Floating label chip
              Positioned(
                left:
                    SizeUtils.w(context, AppDimensions.inputHorizontalPadding) -
                    SizeUtils.w(
                      context,
                      AppDimensions.chipHorizontalPadding,
                    ), // overlap effect
                top: -SizeUtils.h(context, AppDimensions.floatingLabelOffset),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeUtils.w(
                      context,
                      AppDimensions.chipHorizontalPadding,
                    ),
                  ),
                  color: AppColors.background,
                  child: Text(
                    widget.label,
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: SizeUtils.h(
                        context,
                        AppDimensions.floatingLabelFontSize,
                      ),
                      height:
                          SizeUtils.h(
                            context,
                            AppDimensions.floatingLabelLineHeight,
                          ) /
                          SizeUtils.h(
                            context,
                            AppDimensions.floatingLabelFontSize,
                          ),
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
            SizedBox(
              height: SizeUtils.h(context, AppDimensions.inputErrorSpacing),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeUtils.w(
                  context,
                  AppDimensions.inputHorizontalPadding,
                ),
              ),
              child: Text(
                widget.supportText!,
                style: AppTextStyles.bodySecondary(context).copyWith(
                  fontSize: SizeUtils.h(
                    context,
                    AppDimensions.supportTextFontSize,
                  ),
                  height:
                      SizeUtils.h(
                        context,
                        AppDimensions.supportTextLineHeight,
                      ) /
                      SizeUtils.h(context, AppDimensions.supportTextFontSize),
                  color:
                      widget.isError
                          ? AppColors.errorRed
                          : AppColors.textAccent,
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
