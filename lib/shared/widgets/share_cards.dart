import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_images.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';

/// Logical size of every share card; rendered at pixelRatio 3 => 1080x1350.
const Size shareCardSize = Size(360, 450);

const _hotspotOrange = Color(0xFFD3691E);

TextStyle _t(double size, FontWeight w, {Color c = Colors.white, double? h}) =>
    TextStyle(
      fontFamily: AppTextStyles.rubik,
      fontSize: size,
      fontWeight: w,
      color: c,
      height: h,
      decoration: TextDecoration.none,
    );

/// Brand lockup shown at the top of every card.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Image.asset(AppImages.logo, width: 26, height: 26),
        ),
        const SizedBox(width: 8),
        Text(AppStrings.shareCardBrand, style: _t(16, FontWeight.w700)),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final String text;
  const _Footer(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: _t(12, FontWeight.w500),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _t(17, FontWeight.w700),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _t(10.5, FontWeight.w400, c: AppColors.textWhite70),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _t(12.5, FontWeight.w400),
          ),
        ),
      ],
    );
  }
}

/// Shared frame for photo-based cards: photo (or gradient + icon fallback),
/// dark scrim, brand at top and [children] stacked at the bottom.
class _PhotoCardFrame extends StatelessWidget {
  final ImageProvider? photo;
  final Color accent;
  final IconData fallbackIcon;
  final List<Widget> children;
  const _PhotoCardFrame({
    required this.photo,
    required this.accent,
    required this.fallbackIcon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: shareCardSize,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, AppColors.textDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            if (photo == null)
              Align(
                alignment: const Alignment(0, -0.35),
                child: Icon(
                  fallbackIcon,
                  size: 150,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              )
            else
              Image(image: photo!, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.25, 0.5, 1],
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                    AppColors.textDark.withValues(alpha: 0.7),
                    AppColors.textDark.withValues(alpha: 0.96),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [const _Brand(), const Spacer(), ...children],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CleanupShareCard extends StatelessWidget {
  final ImageProvider? photo;
  final String weight; // already formatted, e.g. "12.5"
  final int items;
  final int volunteers;
  final String environment;
  final String location;
  final String date;
  final String groupName;
  const CleanupShareCard({
    super.key,
    required this.photo,
    required this.weight,
    required this.items,
    required this.volunteers,
    required this.environment,
    required this.location,
    required this.date,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return _PhotoCardFrame(
      photo: photo,
      accent: AppColors.buttonGreen,
      fallbackIcon: Icons.recycling_rounded,
      children: [
        Text(
          AppStrings.shareCardCleanupHeadline.replaceAll('{kg}', weight),
          maxLines: 1,
          style: _t(54, FontWeight.w800, h: 1),
        ),
        Text(
          AppStrings.shareCardCleanupSubtitle,
          style: _t(20, FontWeight.w500, c: AppColors.dialogBackground),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _Stat('$items', AppStrings.shareCardItems),
            const SizedBox(width: 8),
            _Stat('$volunteers', AppStrings.shareCardVolunteers),
            if (environment.isNotEmpty) ...[
              const SizedBox(width: 8),
              _Stat(environment, AppStrings.shareCardEnvironment),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (location.isNotEmpty) _InfoLine(Icons.location_on, location),
        const SizedBox(height: 4),
        _InfoLine(Icons.calendar_today, date),
        if (groupName.isNotEmpty) ...[
          const SizedBox(height: 4),
          _InfoLine(
            Icons.groups_rounded,
            AppStrings.shareCardGroup.replaceAll('{group}', groupName),
          ),
        ],
        const SizedBox(height: 14),
        _Footer(AppStrings.shareCardFooter),
      ],
    );
  }
}

class HotspotShareCard extends StatelessWidget {
  final ImageProvider? photo;
  final String location;
  final String date;
  const HotspotShareCard({
    super.key,
    required this.photo,
    required this.location,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return _PhotoCardFrame(
      photo: photo,
      accent: _hotspotOrange,
      fallbackIcon: Icons.local_fire_department_rounded,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _hotspotOrange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          AppStrings.shareCardHotspotHeadline,
          style: _t(32, FontWeight.w800, h: 1.1),
        ),
        const SizedBox(height: 12),
        if (location.isNotEmpty) _InfoLine(Icons.location_on, location),
        if (date.isNotEmpty) ...[
          const SizedBox(height: 4),
          _InfoLine(Icons.calendar_today, date),
        ],
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.buttonGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            AppStrings.shareCardHotspotCta,
            textAlign: TextAlign.center,
            style: _t(17, FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        _Footer(AppStrings.shareCardFooter),
      ],
    );
  }
}

class AchievementShareCard extends StatelessWidget {
  final String title;
  final int level;
  final IconData icon;
  final Color color;
  final String description;
  const AchievementShareCard({
    super.key,
    required this.title,
    required this.level,
    required this.icon,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: shareCardSize,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.textDark, color],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            const CustomPaint(painter: _ConfettiPainter()),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Align(alignment: Alignment.centerLeft, child: _Brand()),
                  const Spacer(),
                  Text(
                    AppStrings.shareCardAchievementKicker,
                    style: _t(
                      13,
                      FontWeight.w800,
                      c: AppColors.profileAvatarAccent,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 78),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: _t(30, FontWeight.w800, h: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppStrings.shareCardLevel.replaceAll('{level}', '$level'),
                      style: _t(15, FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: _t(14, FontWeight.w400, c: AppColors.textWhite70),
                  ),
                  const Spacer(),
                  _Footer(AppStrings.shareCardAchievementFooter),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deterministic confetti: same seed => same picture every time.
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter();

  static const _colors = [
    Color(0xFF419310),
    Color(0xFF1E88A8),
    Color(0xFFFBB825),
    Color(0xFFBE123C),
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final paint = Paint();
    for (var i = 0; i < 70; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final s = 5 + rnd.nextDouble() * 8;
      final angle = rnd.nextDouble() * math.pi;
      final shape = rnd.nextInt(3);
      paint.color = _colors[rnd.nextInt(_colors.length)].withValues(
        alpha: 0.55 + rnd.nextDouble() * 0.4,
      );
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      switch (shape) {
        case 0:
          canvas.drawCircle(Offset.zero, s / 2, paint);
        case 1:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.5),
            paint,
          );
        default:
          canvas.drawPath(
            Path()
              ..moveTo(0, -s / 2)
              ..lineTo(s / 2, s / 2)
              ..lineTo(-s / 2, s / 2)
              ..close(),
            paint,
          );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
