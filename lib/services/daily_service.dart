import 'dart:math';
import '../core/constants/app_constants.dart';
import 'storage_service.dart';

class DailyService {
  static int todaySeed() {
    final now = DateTime.now();
    // seed determinístico del día: yyyymmdd
    return now.year * 10000 + now.month * 100 + now.day;
  }

  static int streakSeed(int offsetDays) {
    final d = DateTime.now().subtract(Duration(days: offsetDays));
    return d.year * 10000 + d.month * 100 + d.day;
  }

  static Random randomForSeed(int seed) => Random(seed);

  static String todayKey() => 'daily_${todaySeed()}';

  // Storage helpers
  static Future<int> getDailyBestLevel() async {
    final p = StorageService().prefs;
    return p.getInt('daily_best_level_${todaySeed()}') ?? 0;
  }

  static Future<int> getDailyBestScore() async {
    final p = StorageService().prefs;
    return p.getInt('daily_best_score_${todaySeed()}') ?? 0;
  }

  static Future<void> saveDailyResultIfBetter({required int level, required int score}) async {
    final p = StorageService().prefs;
    final kL = 'daily_best_level_${todaySeed()}';
    final kS = 'daily_best_score_${todaySeed()}';
    final curL = p.getInt(kL) ?? 0;
    final curS = p.getInt(kS) ?? 0;
    if (level > curL) await p.setInt(kL, level);
    if (score > curS) await p.setInt(kS, score);
    // mark played today
    await p.setInt('last_played_day', todaySeed());
    // update streak calendar
    await _updateStreak();
  }

  static Future<Map<String, dynamic>> getDailyStats() async {
    final p = StorageService().prefs;
    final last = p.getInt('last_played_day') ?? 0;
    final streak = p.getInt('daily_streak') ?? 0;
    return {
      'last': last,
      'streak': streak,
      'bestLevel': await getDailyBestLevel(),
      'bestScore': await getDailyBestScore(),
    };
  }

  static Future<int> getDailyStreak() async => StorageService().prefs.getInt('daily_streak') ?? 0;

  static Future<void> _updateStreak() async {
    final p = StorageService().prefs;
    final today = todaySeed();
    final last = p.getInt('last_streak_day') ?? 0;
    var streak = p.getInt('daily_streak') ?? 0;
    if (last == 0) {
      streak = 1;
    } else if (last == today) {
      // already counted today, keep streak
      return;
    } else {
      // check if consecutive
      final yesterday = DailyService.todaySeed() - 1; // not perfect for month boundaries, use date calc
      // Better: compare dates
      final now = DateTime.now();
      final lastDate = _seedToDate(last);
      final diff = now.difference(lastDate).inDays;
      if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        streak = 1;
      }
    }
    await p.setInt('daily_streak', streak);
    await p.setInt('last_streak_day', today);
    // also track calendar
    final cal = p.getStringList('calendar_days') ?? [];
    final tStr = today.toString();
    if (!cal.contains(tStr)) {
      cal.add(tStr);
      await p.setStringList('calendar_days', cal);
    }
  }

  static DateTime _seedToDate(int seed) {
    final y = seed ~/ 10000;
    final m = (seed % 10000) ~/ 100;
    final d = seed % 100;
    return DateTime(y, m, d);
  }

  static Future<List<int>> getCalendarDays() async {
    final list = StorageService().prefs.getStringList('calendar_days') ?? [];
    return list.map((e) => int.tryParse(e) ?? 0).toList();
  }

  static Future<int> getDailyAttempts() async {
    return StorageService().prefs.getInt('daily_attempts_${todaySeed()}') ?? 0;
  }

  static Future<void> incDailyAttempts() async {
    final k = 'daily_attempts_${todaySeed()}';
    final p = StorageService().prefs;
    await p.setInt(k, (p.getInt(k) ?? 0) + 1);
  }
}
