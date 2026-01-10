import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ascoa_app/app/controllers/haptic_controller.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

/// Avatar crop screen with resizable square crop area and live circular preview
///
/// Returns a File (cropped square image) via Navigator.pop on save,
/// or null if user cancels.
class AvatarCropScreen extends StatefulWidget {
  final File imageFile;
  final int outputSize;

  const AvatarCropScreen({
    super.key,
    required this.imageFile,
    this.outputSize = 600,
  });

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen>
    with TickerProviderStateMixin {
  MaterialCroppableImageController? _controller;
  final haptics = Get.find<HapticController>();
  bool _isFrench = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _isFrench = Get.locale?.languageCode == 'fr';
    _prepareController();
  }

  Future<void> _prepareController() async {
    try {
      final imageProvider = FileImage(widget.imageFile);
      final initialData = await CroppableImageData.fromImageProvider(
        imageProvider,
        cropPathFn: aabbCropShapeFn,
      );

      final controller = MaterialCroppableImageController(
        vsync: this,
        imageProvider: imageProvider,
        data: initialData,
        cropShapeFn: aabbCropShapeFn,
        allowedAspectRatios: const [CropAspectRatio(width: 1, height: 1)],
        enabledTransformations: const [
          Transformation.panAndScale,
          Transformation.resize,
          Transformation.rotate,
        ],
      );

      controller.setViewportScale(shouldNotify: false);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    } catch (e) {
      _showError(e.toString());
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textBlack,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildCropper(context)),
            _buildControls(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCropper(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final controller = _controller!;

    return Padding(
      padding: EdgeInsets.all(
        SizeUtils.h(context, AppDimensions.avatarCropPadding),
      ),
      child: AnimatedCroppableImageViewport(
        controller: controller,
        gesturePadding: SizeUtils.h(context, AppDimensions.avatarCropPadding),
        overlayOpacityAnimation: const AlwaysStoppedAnimation(1.0),
        shouldLightenOnTransform: false,
        cropHandlesBuilder:
            (context) => _AvatarImageCropperHandles(
              controller: controller,
              gesturePadding: SizeUtils.h(
                context,
                AppDimensions.avatarCropPadding,
              ),
            ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final TextStyle buttonStyle = AppTextStyles.buttonPrimaryText(
      context,
    ).copyWith(
      fontSize: SizeUtils.h(context, AppDimensions.dialogBodyFontSize),
    );
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeUtils.w(context, AppDimensions.avatarCropPadding * 1.0),
        vertical: SizeUtils.h(context, AppDimensions.smallSpacing),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              haptics.selectionClick(); // 🔔 cancel navigation
              Navigator.of(context).pop();
            },
            child: Text(
              _isFrench
                  ? AppStrings.avatarPickerCancelFrench
                  : AppStrings.avatarPickerCancel,
              style: buttonStyle.copyWith(color: AppColors.primary),
            ),
          ),
          IconButton(
            onPressed: () {
              haptics.selectionClick(); // 🔔 tool tap
              _rotateClockwise();
            },
            icon: Icon(
              Icons.rotate_right,
              color: AppColors.primary,
              size: SizeUtils.r(context, AppDimensions.avatarEditButtonSize),
            ),
            tooltip: _isFrench ? 'Pivoter' : 'Rotate',
          ),
          TextButton(
            onPressed: _onSave,
            child: Text(
              _isFrench
                  ? AppStrings.avatarCropSaveFrench
                  : AppStrings.avatarCropSave,
              style: buttonStyle.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    haptics.light();
    final controller = _controller;
    if (controller == null) {
      _showError('Controller not ready');
      return;
    }

    if (!controller.data.isNormalized) {
      _showError('Crop outside image bounds');
      return;
    }

    // Show loading
    Get.dialog(
      PopScope(
        canPop: false,
        child: const Center(child: CircularProgressIndicator()),
      ),
      barrierDismissible: false,
    );

    try {
      final CropImageResult result = await controller.crop();
      final Uint8List imageBytes = await _encodePng(result.uiImage);

      // Dismiss loading
      Get.back();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/cropped_${const Uuid().v4()}.png');
      await file.writeAsBytes(imageBytes);

      // Return file to caller
      if (mounted) {
        haptics.medium();
        Navigator.of(context).pop(file);
      }
    } catch (e) {
      // Dismiss loading if still showing
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      _showError(e.toString());
    }
  }

  void _rotateClockwise() {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    try {
      controller.onRotateCCW();
    } catch (e) {
      debugPrint('Rotate failed: $e');
    }
  }

  void _showError(String details) {
    haptics.heavy();
    Get.snackbar(
      _isFrench ? 'Erreur' : 'Error',
      _isFrench
          ? AppStrings.avatarCropFailedFrench
          : AppStrings.avatarCropFailed,
      backgroundColor: AppColors.error,
      colorText: AppColors.pureWhite,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
    debugPrint('Crop error: $details');
  }

  Future<Uint8List> _encodePng(ui.Image image) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final double targetSize = widget.outputSize.toDouble();
    final Rect dstRect = Rect.fromLTWH(0, 0, targetSize, targetSize);
    final Paint paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(image, srcRect, dstRect, paint);

    final ui.Image resized = await recorder.endRecording().toImage(
      widget.outputSize,
      widget.outputSize,
    );
    image.dispose();

    final ByteData? byteData = await resized.toByteData(
      format: ui.ImageByteFormat.png,
    );
    resized.dispose();

    if (byteData == null) {
      throw Exception('Failed to encode image');
    }

    return byteData.buffer.asUint8List();
  }
}

class _AvatarImageCropperHandles extends StatelessWidget {
  const _AvatarImageCropperHandles({
    required this.controller,
    required this.gesturePadding,
  });

  final MaterialCroppableImageController controller;
  final double gesturePadding;

  @override
  Widget build(BuildContext context) {
    return CroppableImageGestureDetector(
      controller: controller,
      gesturePadding: gesturePadding,
      showGestureHandlesOn: const [CropShapeType.aabb],
      child: ListenableBuilder(
        listenable: controller,
        builder:
            (context, _) =>
                CustomPaint(painter: _AvatarHandlesPainter(controller.data)),
      ),
    );
  }
}

class _AvatarHandlesPainter extends CustomPainter {
  _AvatarHandlesPainter(this.data);

  final CroppableImageData data;

  @override
  void paint(Canvas canvas, Size size) {
    final path = data.cropShape.getTransformedPathForSize(size).toUiPath();
    final Rect cropRect = path.getBounds();

    final Path fullPath = Path()..addRect(Offset.zero & size);
    // Use shared textBlack color with alpha to match app palette
    final Paint overlayPaint =
        Paint()..color = AppColors.textBlack.withAlpha((0.55 * 255).round());
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, path),
      overlayPaint,
    );

    final double circleRadius = math.min(cropRect.width, cropRect.height) / 2.0;
    final Rect circleRect = Rect.fromCircle(
      center: cropRect.center,
      radius: circleRadius,
    );
    final Path squarePath = Path()..addRect(cropRect);
    final Path circlePath = Path()..addOval(circleRect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, squarePath, circlePath),
      Paint()..color = AppColors.textBlack.withAlpha((0.35 * 255).round()),
    );

    final Paint borderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppDimensions.avatarCropLineWidth
          ..color = AppColors.primary;
    canvas.drawPath(path, borderPaint);

    final Paint gridPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppDimensions.one
          ..color = AppColors.pureWhite.withAlpha((0.4 * 255).round());
    canvas.drawLine(
      Offset(cropRect.left + cropRect.width / 3, cropRect.top),
      Offset(cropRect.left + cropRect.width / 3, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left + 2 * cropRect.width / 3, cropRect.top),
      Offset(cropRect.left + 2 * cropRect.width / 3, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + cropRect.height / 3),
      Offset(cropRect.right, cropRect.top + cropRect.height / 3),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + 2 * cropRect.height / 3),
      Offset(cropRect.right, cropRect.top + 2 * cropRect.height / 3),
      gridPaint,
    );

    final Paint cornerPaint =
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill;
    const double cornerSize = AppDimensions.avatarCropCornerSize;
    const double cornerThickness = AppDimensions.avatarCropCornerThickness;

    void drawCorner(double left, double top, bool right, bool bottom) {
      final double cornerLeft = right ? left - cornerSize : left;
      final double cornerTop = bottom ? top - cornerSize : top;

      canvas.drawRect(
        Rect.fromLTWH(cornerLeft, cornerTop, cornerSize, cornerThickness),
        cornerPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          right ? left - cornerThickness : left,
          cornerTop,
          cornerThickness,
          cornerSize,
        ),
        cornerPaint,
      );
    }

    drawCorner(cropRect.left, cropRect.top, false, false);
    drawCorner(cropRect.right, cropRect.top, true, false);
    drawCorner(cropRect.left, cropRect.bottom, false, true);
    drawCorner(cropRect.right, cropRect.bottom, true, true);

    final Paint circlePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppDimensions.avatarCropCircleStrokeWidth
          ..color = AppColors.buttonGreen;
    canvas.drawOval(circleRect, circlePaint);
  }

  @override
  bool shouldRepaint(covariant _AvatarHandlesPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
