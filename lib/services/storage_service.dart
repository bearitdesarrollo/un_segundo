import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../domain/entities/game_entities.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) throw StateError('StorageService not initialized. Call init() first.');
    return _prefs!;
  }

  Future<PlayerStats> loadStats() async {
    // ensure init
    if (_prefs == null) await init();
    return PlayerStats(
      bestLevel: prefs.getInt(AppConstants.keyBestLevel) ?? 0,
      bestScore: prefs.getInt(AppConstants.keyBestScore) ?? 0,
      bestStreak: prefs.getInt(AppConstants.keyBestStreak) ?? 0,
      gamesPlayed: prefs.getInt(AppConstants.keyGamesPlayed) ?? 0,
      correctAnswers: prefs.getInt(AppConstants.keyCorrectAnswers) ?? 0,
      wrongAnswers: prefs.getInt(AppConstants.keyWrongAnswers) ?? 0,
    );
  }

  Future<void> saveStats(PlayerStats stats) async {
    await prefs.setInt(AppConstants.keyBestLevel, stats.bestLevel);
    await prefs.setInt(AppConstants.keyBestScore, stats.bestScore);
    await prefs.setInt(AppConstants.keyBestStreak, stats.bestStreak);
    await prefs.setInt(AppConstants.keyGamesPlayed, stats.gamesPlayed);
    await prefs.setInt(AppConstants.keyCorrectAnswers, stats.correctAnswers);
    await prefs.setInt(AppConstants.keyWrongAnswers, stats.wrongAnswers);
  }

  Future<void> updateAfterGame({
    required int levelReached,
    required int score,
    required int streak,
    required int correct,
    required int wrong,
  }) async {
    final current = await loadStats();
    final updated = current.copyWith(
      bestLevel: levelReached > current.bestLevel ? levelReached : current.bestLevel,
      bestScore: score > current.bestScore ? score : current.bestScore,
      bestStreak: streak > current.bestStreak ? streak : current.bestStreak,
      gamesPlayed: current.gamesPlayed + 1,
      correctAnswers: current.correctAnswers + correct,
      wrongAnswers: current.wrongAnswers + wrong,
    );
    await saveStats(updated);
  }

  int get gamesSinceInterstitial => prefs.getInt(AppConstants.keyGamesSinceInterstitial) ?? 0;
  Future<void> incrementGamesSinceInterstitial() async {
    await prefs.setInt(AppConstants.keyGamesSinceInterstitial, gamesSinceInterstitial + 1);
  }

  Future<void> resetInterstitialCounter() async {
    await prefs.setInt(AppConstants.keyGamesSinceInterstitial, 0);
  }

  bool get soundEnabled => prefs.getBool(AppConstants.keySoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool v) => prefs.setBool(AppConstants.keySoundEnabled, v);

  bool get hapticsEnabled => prefs.getBool(AppConstants.keyHapticsEnabled) ?? true;
  Future<void> setHapticsEnabled(bool v) => prefs.setBool(AppConstants.keyHapticsEnabled, v);
}
