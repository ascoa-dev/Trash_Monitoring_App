import 'package:flutter_test/flutter_test.dart';
import 'package:we_monitor/app/models/achievement.dart';
import 'package:we_monitor/app/models/score.dart';

void main() {
  test('empty stats score 0', () {
    expect(Score.allTime(AchievementStats.empty), 0);
    expect(Score.monthly(AchievementStats.empty), 0);
  });

  test('one 6 kg cleanup, 4 volunteers, 1 location', () {
    const s = AchievementStats(
      totalWeight: 6,
      totalItems: 10,
      cleanups: 1,
      hotspots: 0,
      volunteers: 4,
      environments: 1,
      locations: 1,
      activeDays: 1,
      currentStreak: 0,
    );
    // activity = 10 + 12 + 4 + 0 + 3 = 29
    // levels: weight(5)=1, cleanups(1)=1, days(1)=1, mobilizer(10)=0,
    // explorer(1)=1, cartographer(3)=0, items(50)=0, hotspot=0, streak=0 -> 4
    expect(Score.activityPoints(s), 29);
    expect(Score.levelSum(s), 4);
    expect(Score.allTime(s), 29 + 20);
    expect(Score.monthly(s), 29);
  });

  test('hotspots and rounding', () {
    const s = AchievementStats(
      totalWeight: 0.25,
      totalItems: 0,
      cleanups: 0,
      hotspots: 2,
      volunteers: 0,
      environments: 0,
      locations: 0,
      activeDays: 0,
      currentStreak: 0,
    );
    // 2*5 + 0.25*2 = 10.5 -> 11
    expect(Score.monthly(s), 11);
  });
}
