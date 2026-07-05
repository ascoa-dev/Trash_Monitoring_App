import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/models/achievement.dart';
import 'package:we_monitor/modules/achievements/achievements_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<AchievementsController>()
        ? Get.find<AchievementsController>()
        : Get.put(AchievementsController(), permanent: true);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: const Text(
          'Achievements',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.buttonGreen,
        onRefresh: controller.evaluate,
        child: Obx(() {
          final rows = controller.progress;
          final showLoader =
              controller.isLoading.value && controller.stats.value.cleanups == 0;
          if (showLoader) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.buttonGreen),
              ),
            );
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _SummaryCard(
                unlocked: controller.totalUnlocked,
                total: controller.totalPossible,
              ),
              const SizedBox(height: 18),
              ...rows.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AchievementCard(
                      progress: p,
                      // Unlocked but the celebration hasn't been seen yet.
                      pending: p.unlockedLevel > (controller.seen[p.def.id] ?? 0),
                    ),
                  )),
            ],
          );
        }),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int unlocked;
  final int total;
  const _SummaryCard({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : unlocked / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF357187), Color(0xFF419310)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Colors.white, size: 30),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Your progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              Text(
                '$unlocked / $total',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFBB825)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(pct * 100).round()}% of all levels earned',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementProgress progress;
  final bool pending;
  const _AchievementCard({required this.progress, this.pending = false});

  String _fmt(num n) {
    if (n is int || n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final def = progress.def;
    final maxed = progress.isMaxed;
    final locked = progress.unlockedLevel == 0;
    final unitSuffix = def.unit.isEmpty ? '' : ' ${def.unit}';

    final String progressLabel;
    if (maxed) {
      progressLabel = 'Maxed out · ${_fmt(progress.value)}$unitSuffix';
    } else {
      progressLabel =
          '${_fmt(progress.value)} / ${_fmt(progress.nextThreshold!)}$unitSuffix';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: maxed
              ? def.color.withValues(alpha: 0.5)
              : AppColors.divider,
          width: maxed ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: locked
                  ? AppColors.divider
                  : def.color.withValues(alpha: 0.15),
            ),
            child: Icon(
              def.icon,
              color: locked ? AppColors.textHint : def.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              def.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (pending) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBB825),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _LevelChip(
                      level: progress.unlockedLevel,
                      maxLevel: def.maxLevel,
                      color: def.color,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  def.metric,
                  style: TextStyle(
                    color: AppColors.textDark.withValues(alpha: 0.6),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 7,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(def.color),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      progressLabel,
                      style: TextStyle(
                        color: AppColors.textDark.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!maxed)
                      Text(
                        'Next: Lv ${progress.unlockedLevel + 1}',
                        style: TextStyle(
                          color: def.color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final int level;
  final int maxLevel;
  final Color color;
  const _LevelChip({
    required this.level,
    required this.maxLevel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final locked = level == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: locked ? AppColors.divider : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        locked ? 'Locked' : 'Lv $level / $maxLevel',
        style: TextStyle(
          color: locked ? AppColors.textHint : color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
