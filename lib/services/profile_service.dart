import 'dart:convert';
import 'storage_service.dart';

class LocalProfile {
  String name;
  String emoji;
  int bestLevel;
  int bestScore;
  int bestStreak;
  LocalProfile({required this.name, required this.emoji, this.bestLevel = 0, this.bestScore = 0, this.bestStreak = 0});
  Map<String, dynamic> toJson() => {'n': name, 'e': emoji, 'l': bestLevel, 's': bestScore, 'st': bestStreak};
  factory LocalProfile.fromJson(Map<String, dynamic> j) => LocalProfile(name: j['n'], emoji: j['e'], bestLevel: j['l'] ?? 0, bestScore: j['s'] ?? 0, bestStreak: j['st'] ?? 0);
}

class ProfileService {
  static const _key = 'local_profiles';
  static const _activeKey = 'active_profile_idx';

  static Future<List<LocalProfile>> load() async {
    final p = StorageService().prefs;
    final raw = p.getString(_key);
    if (raw == null) {
      // default profiles
      return [
        LocalProfile(name: 'TÚ', emoji: '😎'),
        LocalProfile(name: 'Amigo 1', emoji: '🤖'),
      ];
    }
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => LocalProfile.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<LocalProfile> list) async {
    await StorageService().prefs.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<int> activeIndex() async => StorageService().prefs.getInt(_activeKey) ?? 0;
  static Future<void> setActive(int idx) async => StorageService().prefs.setInt(_activeKey, idx);

  static Future<LocalProfile> activeProfile() async {
    final list = await load();
    final idx = await activeIndex();
    if (idx < 0 || idx >= list.length) return list.first;
    return list[idx];
  }

  static Future<void> updateActiveWithResult({required int level, required int score, required int streak}) async {
    final list = await load();
    final idx = await activeIndex();
    if (idx < 0 || idx >= list.length) return;
    final p = list[idx];
    if (level > p.bestLevel) p.bestLevel = level;
    if (score > p.bestScore) p.bestScore = score;
    if (streak > p.bestStreak) p.bestStreak = streak;
    await save(list);
  }
}
