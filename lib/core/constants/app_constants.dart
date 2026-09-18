class AppConstants {
  static const String appName = '1 SEGUNDO';
  static const String tagline = '¿Puedes recordarlo?';

  // Game balance
  static const int initialLives = 3;
  static const int baseScore = 100;
  static const int maxLives = 5;

  // Ads config
  static const int interstitialAfterGames = 3;

  // Storage keys
  static const String keyBestLevel = 'best_level';
  static const String keyBestScore = 'best_score';
  static const String keyBestStreak = 'best_streak';
  static const String keyGamesPlayed = 'games_played';
  static const String keyCorrectAnswers = 'correct_answers';
  static const String keyWrongAnswers = 'wrong_answers';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyHapticsEnabled = 'haptics_enabled';
  static const String keyGamesSinceInterstitial = 'games_since_interstitial';
}
