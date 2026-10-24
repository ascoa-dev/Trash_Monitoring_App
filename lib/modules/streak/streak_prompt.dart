import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';

/// Once a day, on app open, shows the user's weekly streak: counting up when
/// it grew since they last saw it, or counting down to 0 when it was lost.
class StreakPrompt {
  StreakPrompt._();

  static Future<Box> _box() => Hive.openBox('app_settings');

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  /// [trusted] is false when the activity came from the offline cache, which
  /// may be incomplete: a "lost" streak is then not shown, never falsely.
  static Future<void> maybeShow({
    required String uid,
    required int streak,
    required bool activeThisWeek,
    required bool trusted,
  }) async {
    try {
      final box = await _box();
      if (box.get('streak_shown_$uid') == _today()) return;
      final last = (box.get('streak_last_$uid') as int?) ?? streak;
      final lost = streak == 0 && last > 0;
      if (streak == 0 && !lost) return;
      if (lost && !trusted) return;

      await box.put('streak_shown_$uid', _today());
      await box.put('streak_last_$uid', streak);
      // Count up from what they saw last time; never count "up" from a
      // bigger number (a streak that broke and restarted just shows today's).
      final from = lost ? last : (last < streak ? last : streak);
      await Get.dialog(
        _StreakDialog(
          from: from,
          to: streak,
          lost: lost,
          activeThisWeek: activeThisWeek,
        ),
        barrierColor: Colors.black.withValues(alpha: 0.55),
      );
    } catch (e) {
      debugPrint('[Streak] prompt skipped: $e');
    }
  }
}

class _StreakDialog extends StatefulWidget {
  final int from;
  final int to;
  final bool lost;
  final bool activeThisWeek;

  const _StreakDialog({
    required this.from,
    required this.to,
    required this.lost,
    required this.activeThisWeek,
  });

  @override
  State<_StreakDialog> createState() => _StreakDialogState();
}

class _StreakDialogState extends State<_StreakDialog>
    with SingleTickerProviderStateMixin {
  static const _flame = Color(0xFFFBB825);
  static const _ash = Color(0xFF9F9F9F);

  late final AnimationController _anim;

  // Hold the old number, roll to the new one, then settle (shake on loss).
  late final Animation<double> _count = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.25, 0.75, curve: Curves.easeInOut),
  );
  late final Animation<double> _settle = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.75, 1),
  );

  bool get _changes => widget.from != widget.to;

  @override
  void initState() {
    super.initState();
    final steps = (widget.from - widget.to).abs();
    _anim = AnimationController(
      vsync: this,
      // Longer for bigger drops so each number is visible, capped at 3.2s.
      duration: Duration(milliseconds: 1400 + math.min(steps * 120, 1800)),
    );
    _anim.addStatusListener((s) {
      if (s != AnimationStatus.completed || !_changes) return;
      try {
        final haptics = Get.find<HapticController>();
        widget.lost ? haptics.heavy() : haptics.medium();
      } catch (_) {}
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _anim.forward(from: _changes ? 0 : 1);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.lost) return 'sync.streakLostTitle'.tr;
    return 'sync.streakTitle'.trPluralParams(
      'sync.streakTitlePlural',
      widget.to,
      {'count': '${widget.to}'},
    );
  }

  String get _body {
    if (widget.lost) {
      return 'sync.streakLostBody'.trPluralParams(
        'sync.streakLostBodyPlural',
        widget.from,
        {'count': '${widget.from}'},
      );
    }
    return widget.activeThisWeek
        ? 'sync.streakSafeBody'.tr
        : 'sync.streakAtRiskBody'.tr;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
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
                AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) {
                    final value =
                        (widget.from + (widget.to - widget.from) * _count.value)
                            .round();
                    // On loss the flame fades to ash as the number drops.
                    final color =
                        widget.lost
                            ? Color.lerp(_flame, _ash, _count.value)!
                            : _flame;
                    final shake =
                        widget.lost
                            ? math.sin(_settle.value * math.pi * 6) *
                                8 *
                                (1 - _settle.value)
                            : 0.0;
                    // A small pop when a growing streak lands.
                    final pop =
                        !widget.lost && _changes
                            ? 1 + 0.18 * math.sin(_settle.value * math.pi)
                            : 1.0;
                    return Transform.translate(
                      offset: Offset(shake, 0),
                      child: Transform.scale(
                        scale: pop,
                        child: Column(
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 84,
                              color: color,
                            ),
                            Text(
                              '$value',
                              style: TextStyle(
                                color: color,
                                fontSize: 56,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'sync.weeksUnit'.trPlural(
                                'sync.weeksUnitPlural',
                                value,
                              ),
                              style: TextStyle(
                                color: AppColors.textDark.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 21,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _body,
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
                    onPressed: Get.back,
                    child: Text(
                      widget.lost
                          ? 'sync.streakRestart'.tr
                          : 'sync.streakContinue'.tr,
                      style: const TextStyle(
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
    );
  }
}
