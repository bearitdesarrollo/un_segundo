import 'dart:convert';
import 'storage_service.dart';

class GhostRun {
  final int level;
  final int score;
  final int streak;
  final int timeMs;
  final int seed;
  final String date;
  GhostRun({required this.level, required this.score, required this.streak, required this.timeMs, required this.seed, required this.date});
  Map<String, dynamic> toJson() => {'l': level, 's': score, 'st': streak, 't': timeMs, 'seed': seed, 'd': date};
  factory GhostRun.fromJson(Map<String, dynamic> j) => GhostRun(level: j['l'], score: j['s'], streak: j['st'], timeMs: j['t'], seed: j['seed'], date: j['d']);
}

class GhostService {
  static const _key = 'ghost_runs';
  static const _bestKey = 'ghost_best';

  static Future<List<GhostRun>> loadRuns() async {
    final p = StorageService().prefs;
    final raw = p.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => GhostRun.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<GhostRun?> loadBest() async {
    final p = StorageService().prefs;
    final raw = p.getString(_bestKey);
    if (raw == null) return null;
    try {
      return GhostRun.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveRun(GhostRun run) async {
    final p = StorageService().prefs;
    final runs = await loadRuns();
    runs.add(run);
    // keep last 20
    if (runs.length > 20) runs.removeAt(0);
    await p.setString(_key, jsonEncode(runs.map((e) => e.toJson()).toList()));
    final best = await loadBest();
    if (best == null || run.level > best.level || (run.level == best.level && run.score > best.score)) {
      await p.setString(_bestKey, jsonEncode(run.toJson()));
    }
  }
}
