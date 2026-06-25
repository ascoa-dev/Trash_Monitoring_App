import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';

/// A circular progress indicator for upload/download progress
/// Unlike CircularInfiniteLoader, this does NOT rotate - it shows static progress
class CircularUploadProgress extends StatelessWidget {
  final double size;
  final Color trackColor;
  final Color activeColor;
  final double strokeWidth;
  final double progress; // 0.0 to 1.0
  final double gap;

  const CircularUploadProgress({
    super.key,
    this.size = AppDimensions.circularLoaderSize,
    this.trackColor = AppColors.loaderTrack,
    this.activeColor = AppColors.loaderActive,
    this.strokeWidth = AppDimensions.circularLoaderStrokeWidth,
    required this.progress,
    this.gap = AppDimensions.circularLoaderGap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircularUploadProgressPainter(
          trackColor: trackColor,
          activeColor: activeColor,
          strokeWidth: strokeWidth,
          progress: progress.clamp(0.0, 1.0),
          gap: gap,
        ),
      ),
    );
  }
}

class _CircularUploadProgressPainter extends CustomPainter {
  final Color trackColor;
  final Color activeColor;
  final double strokeWidth;
  final double progress;
  final double gap;

  _CircularUploadProgressPainter({
    required this.trackColor,
    required this.activeColor,
    required this.strokeWidth,
    required this.progress,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final activePaint =
        Paint()
          ..color = activeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // Start from top (-90 degrees = -pi/2)
    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    // Draw background track with optional cleared gap before painting arc
    final layerBounds = Rect.fromLTWH(
      AppDimensions.zero,
      AppDimensions.zero,
      size.width,
      size.height,
    );
    canvas.saveLayer(layerBounds, Paint());
    canvas.drawCircle(center, radius, trackPaint);

    if (gap > AppDimensions.zero && progress > 0) {
      final gapPaint =
          Paint()
            ..color = Colors.transparent
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth + (gap * 2)
            ..strokeCap = StrokeCap.round
            ..blendMode = BlendMode.clear;

      canvas.drawArc(arcRect, startAngle, sweepAngle, false, gapPaint);
    }

    if (progress > 0) {
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, activePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CircularUploadProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}
