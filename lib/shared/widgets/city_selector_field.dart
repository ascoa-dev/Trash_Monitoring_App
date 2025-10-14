import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cities_controller.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_typography.dart';
import '../utils/size_utils.dart';

/// CitySelectorField with Material Design 3 styling and fuzzy search
class CitySelectorField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? supportText;
  final bool isError;
  final Function(String)? onChanged;
  final double topSpacing;

  const CitySelectorField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.supportText,
    this.isError = false,
    this.onChanged,
    this.topSpacing = AppDimensions.fieldVerticalSpacing,
  });

  @override
  State<CitySelectorField> createState() => _CitySelectorFieldState();
}

class _CitySelectorFieldState extends State<CitySelectorField> {
  final CitiesController _citiesController = Get.find<CitiesController>();
  final List<String> _filteredCities = [];
  late final FocusNode _focusNode;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text;
    final suggestions = _citiesController.getCitySuggestions(query);
    setState(() {
      _filteredCities.clear();
      _filteredCities.addAll(suggestions);
    });
    _updateOverlay();
    if (widget.onChanged != null) {
      widget.onChanged!(widget.controller.text);
    }
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() => _hasFocus = _focusNode.hasFocus);
    }
    if (_focusNode.hasFocus) {
      // When refocusing, use current input to filter suggestions
      // Only show all cities if input is empty
      final query = widget.controller.text;
      final suggestions =
          query.isEmpty
              ? _citiesController.cityNames()
              : _citiesController.getCitySuggestions(query);
      setState(() {
        _filteredCities.clear();
        _filteredCities.addAll(suggestions);
      });
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    return OverlayEntry(
      builder:
          (context) => Positioned(
            width: SizeUtils.w(context, AppDimensions.citySelectorMaxWidth),
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(AppDimensions.zero, size.height),
              child: Material(
                elevation: AppDimensions.zero,
                color: AppColors.transparent,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: SizeUtils.h(
                      context,
                      AppDimensions.citySelectorMaxHeight,
                    ),
                    minHeight: SizeUtils.h(
                      context,
                      AppDimensions.citySelectorMinHeight,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowMedium,
                        offset: Offset(
                          AppDimensions.zero,
                          AppDimensions.citySelectorShadowOffsetYSmall,
                        ),
                        blurRadius: AppDimensions.citySelectorShadowBlurSmall,
                      ),
                      BoxShadow(
                        color: AppColors.shadowLight,
                        offset: Offset(
                          AppDimensions.zero,
                          AppDimensions.citySelectorShadowOffsetYLarge,
                        ),
                        blurRadius: AppDimensions.citySelectorShadowBlurLarge,
                        spreadRadius: AppDimensions.citySelectorShadowSpread,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(
                      SizeUtils.r(
                        context,
                        AppDimensions.citySelectorBorderRadius,
                      ),
                    ),
                  ),
                  child:
                      _filteredCities.isEmpty
                          ? _buildEmptyState()
                          : _buildMenuList(),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildMenuList() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        SizeUtils.r(context, AppDimensions.citySelectorBorderRadius),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(
          vertical: SizeUtils.h(context, AppDimensions.citySelectorPadding),
        ),
        itemCount: _filteredCities.length,
        itemBuilder: (context, index) => _buildMenuItem(_filteredCities[index]),
      ),
    );
  }

  Widget _buildMenuItem(String city) {
    return InkWell(
      onTap: () {
        widget.controller.text = city;
        _focusNode.unfocus();
        if (widget.onChanged != null) widget.onChanged!(city);
      },
      child: Container(
        height: SizeUtils.h(context, AppDimensions.citySelectorItemHeight),
        padding: EdgeInsets.symmetric(
          vertical: SizeUtils.h(context, AppDimensions.citySelectorItemPadding),
        ),
        child: Row(
          children: [
            SizedBox(
              width: SizeUtils.w(context, AppDimensions.citySelectorIconSize),
              height: SizeUtils.h(context, AppDimensions.citySelectorIconSize),
            ),
            SizedBox(
              width: SizeUtils.w(
                context,
                AppDimensions.citySelectorIconSpacing,
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  city,
                  style: AppTextStyles.body(context).copyWith(
                    fontSize: SizeUtils.h(
                      context,
                      AppDimensions.citySelectorTextSize,
                    ),
                    height:
                        SizeUtils.h(
                          context,
                          AppDimensions.citySelectorTextLineHeight,
                        ) /
                        SizeUtils.h(
                          context,
                          AppDimensions.citySelectorTextSize,
                        ),
                    color: AppColors.textPrimary,
                    letterSpacing: AppDimensions.citySelectorTextLetterSpacing,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: AppDimensions.one.toInt(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final showCustomMessage = _citiesController.allowCustomCities;
    return Container(
      padding: EdgeInsets.all(
        SizeUtils.w(context, AppDimensions.citySelectorEmptyPadding),
      ),
      child: Text(
        showCustomMessage
            ? _citiesController.customCitiesWarning
            : AppStrings.citySelectorNoCitiesFound,
        style: AppTextStyles.inputHint(context).copyWith(
          fontSize: SizeUtils.h(context, AppDimensions.inputFontSize),
          letterSpacing: AppTypography.letterSpacingSmall,
          color: showCustomMessage ? AppColors.error : AppColors.textAccent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: SizeUtils.h(context, widget.topSpacing)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompositedTransformTarget(
            link: _layerLink,
            child: Stack(
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
                    padding: EdgeInsets.only(
                      left: SizeUtils.w(
                        context,
                        AppDimensions.inputHorizontalPadding,
                      ),
                      right: SizeUtils.w(context, 48),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
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
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left:
                      SizeUtils.w(
                        context,
                        AppDimensions.inputHorizontalPadding,
                      ) -
                      SizeUtils.w(context, AppDimensions.chipHorizontalPadding),
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
                            SizeUtils.h(context, 16) /
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
                      SizeUtils.h(context, 16) /
                      SizeUtils.h(context, AppDimensions.supportTextFontSize),
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
