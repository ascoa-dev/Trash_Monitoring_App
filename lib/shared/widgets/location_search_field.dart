import 'dart:async';
import 'package:flutter/material.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/constants/app_typography.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/services/google_places_service.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/controllers/haptic_controller.dart';

/// Location search field with autocomplete dropdown
/// Styled to match the custom date picker dropdowns
class LocationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<PlaceDetails>? onPlaceSelected;
  final double topSpacing;
  final String? supportText;
  final bool isError;
  final ValueChanged<String>? onChanged;

  const LocationSearchField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.onPlaceSelected,
    this.topSpacing = AppDimensions.fieldVerticalSpacing,
    this.supportText,
    this.isError = false,
    this.onChanged,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final haptics = Get.find<HapticController>();
  late final FocusNode _focusNode;
  bool _hasFocus = false;
  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      final hasFocus = _focusNode.hasFocus;

      if (mounted) {
        setState(() => _hasFocus = hasFocus);
      }

      if (hasFocus) {
        haptics.selectionClick();
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _removeOverlay();
            setState(() => _suggestions = []);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            left: offset.dx,
            top:
                offset.dy +
                size.height +
                SizeUtils.h(context, AppDimensions.cleanupSpacing4),
            width: size.width,
            child: Material(
              color: AppColors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: SizeUtils.h(
                    context,
                    AppDimensions.citySelectorMaxHeight,
                  ), // ~5 items
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(
                    SizeUtils.r(
                      context,
                      AppDimensions.citySelectorBorderRadius,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blackWithOpacity10,
                      blurRadius: AppDimensions.citySelectorShadowBlurLarge,
                      offset: Offset(
                        0,
                        AppDimensions.citySelectorShadowOffsetYLarge,
                      ),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return InkWell(
                      onTap: () => _onSuggestionTapped(suggestion),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeUtils.w(
                            context,
                            AppDimensions.inputHorizontalPadding,
                          ),
                          vertical: SizeUtils.h(
                            context,
                            AppDimensions.inputContentVerticalPadding,
                          ),
                        ),
                        decoration: BoxDecoration(
                          border:
                              index < _suggestions.length - 1
                                  ? Border(
                                    bottom: BorderSide(
                                      color: AppColors.textHintWithOpacity20,
                                      width: AppDimensions.dividerThickness,
                                    ),
                                  )
                                  : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: SizeUtils.r(
                                context,
                                AppDimensions.smallIconSize,
                              ),
                              color: AppColors.accentGreen,
                            ),
                            SizedBox(
                              width: SizeUtils.w(
                                context,
                                AppDimensions.citySelectorIconSpacing,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    suggestion.mainText,
                                    style: AppTextStyles.body(context).copyWith(
                                      fontSize: SizeUtils.h(
                                        context,
                                        AppDimensions.mediumFontSize,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (suggestion.secondaryText.isNotEmpty) ...[
                                    SizedBox(
                                      height: SizeUtils.h(
                                        context,
                                        AppDimensions.cleanupSpacing4,
                                      ),
                                    ),
                                    Text(
                                      suggestion.secondaryText,
                                      style: AppTextStyles.bodySecondary(
                                        context,
                                      ).copyWith(
                                        fontSize: SizeUtils.h(
                                          context,
                                          AppDimensions.smallFontSize,
                                        ),
                                        color: AppColors.textHint,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _onSearchChanged(String query) {
    // Call parent onChanged callback
    widget.onChanged?.call(query);

    // Debounce the search to avoid excessive API calls
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        _removeOverlay();
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
        return;
      }

      setState(() => _isLoading = true);

      final results = await GooglePlacesService.searchPlaces(
        query,
        maxResults: 3,
      );

      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });

        // Show overlay if we have suggestions
        if (_suggestions.isNotEmpty) {
          _showSuggestionsOverlay();
        } else {
          _removeOverlay();
        }
      }
    });
  }

  Future<void> _onSuggestionTapped(PlaceSuggestion suggestion) async {
    haptics.light();
    // Get detailed place information
    final details = await GooglePlacesService.getPlaceDetails(
      suggestion.placeId,
    );

    if (details != null && mounted) {
      widget.controller.text = details.formattedAddress;
      _removeOverlay();
      setState(() => _suggestions = []);
      _focusNode.unfocus();

      // Notify parent
      widget.onPlaceSelected?.call(details);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: SizeUtils.h(context, widget.topSpacing)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input field
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
                        _hasFocus
                            ? SizeUtils.w(
                              context,
                              AppDimensions.inputBorderWidthFocused,
                            )
                            : SizeUtils.w(
                              context,
                              AppDimensions.inputBorderWidth,
                            ),
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
                    onChanged: _onSearchChanged,
                    style: AppTextStyles.body(context).copyWith(
                      color: AppColors.textPrimary,
                      fontSize: SizeUtils.h(
                        context,
                        AppDimensions.inputFontSize,
                      ),
                      height:
                          SizeUtils.h(
                            context,
                            AppDimensions.locationFieldHeight,
                          ) /
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
                      suffixIcon:
                          _isLoading
                              ? Padding(
                                padding: EdgeInsets.all(
                                  SizeUtils.r(
                                    context,
                                    AppDimensions.locationFieldLoaderPadding,
                                  ),
                                ),
                                child: SizedBox(
                                  width: SizeUtils.r(
                                    context,
                                    AppDimensions.locationFieldLoaderDimensions,
                                  ),
                                  height: SizeUtils.r(
                                    context,
                                    AppDimensions.locationFieldLoaderDimensions,
                                  ),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accentGreen,
                                  ),
                                ),
                              )
                              : Icon(
                                Icons.search,
                                size: SizeUtils.r(
                                  context,
                                  AppDimensions.locationFieldLoaderIconSize,
                                ),
                                color: AppColors.textHint,
                              ),
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: SizeUtils.h(
                          context,
                          AppDimensions.locationFieldLoaderPadding,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Floating label chip
              Positioned(
                left:
                    SizeUtils.w(context, AppDimensions.inputHorizontalPadding) -
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
                          SizeUtils.h(
                            context,
                            AppDimensions.locationFieldTextSize,
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

          // Support text (error or helper text)
          if (widget.supportText != null)
            Padding(
              padding: EdgeInsets.only(
                top: SizeUtils.h(
                  context,
                  AppDimensions.locationFieldErrorPadding,
                ),
                left: SizeUtils.w(
                  context,
                  AppDimensions.inputHorizontalPadding,
                ),
              ),
              child: Text(
                widget.supportText!,
                style: AppTextStyles.errorText(context),
              ),
            ),

          // Note: Suggestions now render in overlay, not inline
        ],
      ),
    );
  }
}
