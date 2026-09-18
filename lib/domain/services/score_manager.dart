class ScoreManager {
  static int calculate({
    required int level,
    required int streak,
    required double responseSeconds,
  }) {
    const base = 100;
    final levelBonus = level * 10;
    // speed bonus: max 50 if answered <1s, 0 if >5s
    final speedBonus = ((5 - responseSeconds).clamp(0, 5) * 10).round();
    final multiplier = _multiplier(streak);
    return ((base + levelBonus + speedBonus) * multiplier).round();
  }

  static int _multiplier(int streak) {
    if (streak <= 0) return 1;
    if (streak == 1) return 1;
    if (streak == 2) return 2;
    if (streak == 3) return 3;
    if (streak >= 4) return 4 + (streak - 4); // 4,5,6... cap handled in UI
    return 1;
  }

  static int displayMultiplier(int streak) {
    if (streak < 2) return 1;
    if (streak == 2) return 2;
    if (streak == 3) return 3;
    return 4 + (streak - 4);
  }
}
