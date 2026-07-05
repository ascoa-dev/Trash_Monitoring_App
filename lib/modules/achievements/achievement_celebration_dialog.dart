import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/modules/achievements/achievements_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';

/// Shows a full-screen confetti celebration for a newly unlocked achievement.
/// [onDismiss] fires after the user closes it, so the queue can advance.
void showAchievementCelebration(
  UnlockedEvent event, {
  required VoidCallback onDismiss,
}) {
  Get.dialog(
    _CelebrationDialog(event: event),
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
  ).then((_) => onDismiss());
}

class _CelebrationDialog extends StatefulWidget {
  final UnlockedEvent event;
  const _CelebrationDialog({required this.event});

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog> {
  late final ConfettiController _center;
  late final ConfettiController _left;
  late final ConfettiController _right;

  static const _confettiColors = [
    Color(0xFF419310),
    Color(0xFF357187),
    Color(0xFFFBB825),
    Color(0xFF1E88A8),
    Color(0xFFBE123C),
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _center = ConfettiController(duration: const Duration(seconds: 3));
    _left = ConfettiController(duration: const Duration(seconds: 3));
    _right = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _center.play();
      _left.play();
      _right.play();
      try {
        Get.find<HapticController>().medium();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _center.dispose();
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.event.def;
    final level = widget.event.level;
    final maxed = level >= def.maxLevel;
    final threshold = def.thresholds[level - 1];
    final unitSuffix = def.unit.isEmpty ? '' : ' ${def.unit}';

    return Stack(
      children: [
        // Confetti layers span the whole screen.
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _center,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 24,
            maxBlastForce: 22,
            minBlastForce: 8,
            gravity: 0.25,
            colors: _confettiColors,
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: _left,
            blastDirection: math.pi / 3, // down-right
            emissionFrequency: 0.06,
            numberOfParticles: 12,
            maxBlastForce: 20,
            minBlastForce: 8,
            gravity: 0.3,
            colors: _confettiColors,
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: _right,
            blastDirection: 2 * math.pi / 3, // down-left
            emissionFrequency: 0.06,
            numberOfParticles: 12,
            maxBlastForce: 20,
            minBlastForce: 8,
            gravity: 0.3,
            colors: _confettiColors,
          ),
        ),
        // The card.
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                decoration: BoxDecoration(
                  color: AppColors.dialogBackground,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🎉  ACHIEVEMENT UNLOCKED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: def.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Badge
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [def.color.withValues(alpha: 0.85), def.color],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: def.color.withValues(alpha: 0.45),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(def.icon, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      def.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: def.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        maxed ? 'MAX LEVEL $level' : 'LEVEL $level',
                        style: TextStyle(
                          color: def.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'You reached $threshold$unitSuffix ${def.metric}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          try {
                            Get.find<HapticController>().medium();
                          } catch (_) {}
                          Get.back();
                        },
                        child: const Text(
                          'Awesome!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
