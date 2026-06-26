import 'dart:math';
import 'package:flutter/material.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';

class CircularInfiniteLoader extends StatefulWidget {
  final double size;
  final Color trackColor;
  final Color activeColor;
  final double strokeWidth;
  final Duration duration;
  final double arcFraction; // how much of the circle is filled (0.0–1.0)
  final double gap;

  const CircularInfiniteLoader({
    super.key,
    this.size = AppDimensions.circularLoaderSize,
    this.trackColor = AppColors.loaderTrack,
    this.activeColor = AppColors.loaderActive,
    this.strokeWidth = AppDimensions.circularLoaderStrokeWidth,
    this.duration = const Duration(seconds: 1),
    this.arcFraction = 0.18, // 18% of circle = visible arc, 82% = gap
    this.gap = AppDimensions.circularLoaderGap,
  });

  @override
  State<CircularInfiniteLoader> createState() => _CircularInfiniteLoaderState();
}

class _CircularInfiniteLoaderState extends State<CircularInfiniteLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _CircularLoaderPainter(
              rotation: _controller.value * 2 * pi,
              trackColor: widget.trackColor,
              activeColor: widget.activeColor,
              strokeWidth: widget.strokeWidth,
              arcFraction: widget.arcFraction,
              gap: widget.gap,
            ),
          );
        },
      ),
    );
  }
}

class _CircularLoaderPainter extends CustomPainter {
  final double rotation;
  final Color trackColor;
  final Color activeColor;
  final double strokeWidth;
  final double arcFraction;
  final double gap;

  _CircularLoaderPainter({
    required this.rotation,
    required this.trackColor,
    required this.activeColor,
    required this.strokeWidth,
    required this.arcFraction,
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

    final startAngle = rotation;
    final sweepAngle = 2 * pi * arcFraction;

    // Draw background track with optional cleared gap before painting arc
    final layerBounds = Rect.fromLTWH(
      AppDimensions.zero,
      AppDimensions.zero,
      size.width,
      size.height,
    );
    canvas.saveLayer(layerBounds, Paint());
    canvas.drawCircle(center, radius, trackPaint);

    if (gap > AppDimensions.zero) {
      final gapPaint =
          Paint()
            ..color = Colors.transparent
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth + (gap * 2)
            ..strokeCap = StrokeCap.round
            ..blendMode = BlendMode.clear;

      canvas.drawArc(arcRect, startAngle, sweepAngle, false, gapPaint);
    }

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, activePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CircularLoaderPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.arcFraction != arcFraction ||
        oldDelegate.gap != gap;
  }
}
