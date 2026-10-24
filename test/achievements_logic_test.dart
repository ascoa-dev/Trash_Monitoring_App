import 'package:flutter_test/flutter_test.dart';
import 'package:we_monitor/app/models/achievement.dart';

void main() {
  final weight = Achievements.byId('weight_warrior'); // [5,25,50,100,250,500]

  test('levelFor counts passed thresholds', () {
    expect(weight.levelFor(0), 0);
    expect(weight.levelFor(4.9), 0);
    expect(weight.levelFor(5), 1);
    expect(weight.levelFor(60), 3); // 5,25,50 passed
    expect(weight.levelFor(9999), weight.maxLevel);
  });

  test('progress fraction matches the value / next threshold label', () {
    // unlocked lvl 1 (>=5), value 6.1, next threshold 25 -> 6.1/25
    final p = AchievementProgress(def: weight, unlockedLevel: 1, value: 6.1);
    expect(p.nextThreshold, 25);
    expect(p.fraction, closeTo(0.244, 1e-9));
    expect(p.isMaxed, false);
  });

  test('maxed achievement reports full progress and no next threshold', () {
    final p = AchievementProgress(
      def: weight,
      unlockedLevel: weight.maxLevel,
      value: 999,
    );
    expect(p.isMaxed, true);
    expect(p.nextThreshold, isNull);
    expect(p.fraction, 1);
  });

  group('WeekStreak', () {
    // Wednesday 2026-10-21; its week starts Monday 2026-10-19.
    final now = DateTime(2026, 10, 21, 15);
    DateTime weeksAgo(int n) => DateTime(2026, 10, 19 - 7 * n);

    test('weekStart is the Monday of the week', () {
      expect(WeekStreak.weekStart(now), DateTime(2026, 10, 19));
      expect(WeekStreak.weekStart(DateTime(2026, 10, 25, 23)), DateTime(2026, 10, 19));
      expect(WeekStreak.weekStart(DateTime(2026, 10, 26)), DateTime(2026, 10, 26));
    });

    test('counts consecutive weeks up to this week', () {
      expect(WeekStreak.current({weeksAgo(0), weeksAgo(1), weeksAgo(2)}, now), 3);
    });

    test('stays alive through the current week if last week was active', () {
      expect(WeekStreak.current({weeksAgo(1), weeksAgo(2)}, now), 2);
    });

    test('breaks after a whole week without activity', () {
      expect(WeekStreak.current({weeksAgo(2), weeksAgo(3)}, now), 0);
      expect(WeekStreak.current({weeksAgo(0), weeksAgo(2)}, now), 1);
      expect(WeekStreak.current({}, now), 0);
    });

    test('crosses month and year boundaries', () {
      final jan = DateTime(2027, 1, 6); // Wednesday; week starts Mon Jan 4
      expect(
        WeekStreak.current({
          DateTime(2027, 1, 4),
          DateTime(2026, 12, 28),
          DateTime(2026, 12, 21),
        }, jan),
        3,
      );
    });
  });

  test('stats.valueFor maps ids to metrics', () {
    const s = AchievementStats(
      totalWeight: 12.5,
      totalItems: 40,
      cleanups: 3,
      hotspots: 1,
      volunteers: 22,
      environments: 2,
      locations: 5,
      activeDays: 4,
      currentStreak: 2,
    );
    expect(s.valueFor('weight_warrior'), 12.5);
    expect(s.valueFor('streak_master'), 2);
    expect(s.valueFor('mobilizer'), 22);
  });

  test('cumulative level can drop, streak level never regresses', () {
    final champ = Achievements.byId('cleanup_champion'); // [1,5,...]
    final streak = Achievements.byId('streak_master'); // [2,4,...]
    expect(champ.resolveLevel(4, 2), 1);
    expect(champ.resolveLevel(0, 1), 0);
    expect(streak.resolveLevel(0, 2), 2);
    expect(streak.resolveLevel(5, 1), 2);
  });
}
