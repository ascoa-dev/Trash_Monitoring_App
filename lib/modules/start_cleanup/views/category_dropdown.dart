import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';
import 'package:flutter/material.dart';

class ItemCounterScreen extends StatefulWidget {
  final String title; // e.g. "Most likely to find items"
  final List<String> items; // e.g. ["Grocery bags", "Plastic bottles"]

  const ItemCounterScreen({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<ItemCounterScreen> createState() => _ItemCounterScreenState();
}

class _ItemCounterScreenState extends State<ItemCounterScreen> {
  late List<int> counts;

  @override
  void initState() {
    super.initState();
    counts = List.generate(widget.items.length, (_) => 0);
  }

  void _increment(int index) {
    setState(() => counts[index]++);
  }

  void _decrement(int index) {
    if (counts[index] > 0) setState(() => counts[index]--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          SizeUtils.h(context, AppDimensions.cleanupContentPadding),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: SizeUtils.h(context, AppDimensions.smallSpacing)),

            // Item rows
            ...List.generate(widget.items.length, (index) {
              return Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: SizeUtils.h(
                        context,
                        AppDimensions.cleanupCategoryItemVerticalPadding,
                      ),
                      horizontal: SizeUtils.w(
                        context,
                        AppDimensions.cleanupCategoryItemHorizontalPadding,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      border: Border.all(color: AppColors.grey300),
                      borderRadius: BorderRadius.circular(
                        SizeUtils.r(
                          context,
                          AppDimensions.cleanupCategoryBorderRadius,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Item name
                        Expanded(
                          child: Text(
                            widget.items[index],
                            style: TextStyle(
                              fontSize: SizeUtils.h(
                                context,
                                AppDimensions.cleanupCategoryItemFontSize,
                              ),
                              color: AppColors.black87,
                            ),
                          ),
                        ),

                        // Counter
                        Container(
                          height: SizeUtils.h(
                            context,
                            AppDimensions.cleanupCategoryCounterHeight,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              SizeUtils.r(
                                context,
                                AppDimensions.cleanupCategoryBorderRadius,
                              ),
                            ),
                            border: Border.all(color: AppColors.grey400),
                          ),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.cleanupCounterBg,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(
                                      SizeUtils.r(
                                        context,
                                        AppDimensions
                                            .cleanupCategoryBorderRadius,
                                      ),
                                    ),
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.remove,
                                    size: SizeUtils.r(
                                      context,
                                      AppDimensions.cleanupCategoryIconSize,
                                    ),
                                  ),
                                  color: AppColors.cleanupCounterIcon,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _decrement(index),
                                ),
                              ),
                              Container(
                                width: SizeUtils.w(
                                  context,
                                  AppDimensions.cleanupCategoryCounterWidth,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.pureWhite,
                                ),
                                child: Text(
                                  '${counts[index]}',
                                  style: TextStyle(
                                    fontSize: SizeUtils.h(
                                      context,
                                      AppDimensions
                                          .cleanupCategoryCounterFontSize,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.cleanupCounterBg,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(
                                      SizeUtils.r(
                                        context,
                                        AppDimensions
                                            .cleanupCategoryBorderRadius,
                                      ),
                                    ),
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.add,
                                    size: SizeUtils.r(
                                      context,
                                      AppDimensions.cleanupCategoryIconSize,
                                    ),
                                  ),
                                  color: AppColors.cleanupCounterIcon,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _increment(index),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: SizeUtils.h(
                      context,
                      AppDimensions.cleanupCategoryItemBottomSpacing,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
