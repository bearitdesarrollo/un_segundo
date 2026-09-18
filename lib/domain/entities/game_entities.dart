import '../../core/utils/difficulty.dart';

class GameObject {
  final String emoji;
  final int index; // position index 0..n
  GameObject({required this.emoji, required this.index});
}

class Question {
  final QuestionTypeId type;
  final String text;
  final List<String> options; // emojis or text options
  final int correctIndex;
  final String? highlightedEmoji; // for count/position questions
  final int? positionHint; // 1-indexed for display
  final int? countAnswer; // for count questions

  Question({
    required this.type,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.highlightedEmoji,
    this.positionHint,
    this.countAnswer,
  });
}

class GameLevel {
  final int levelNumber;
  final List<GameObject> objects;
  final double exposureSeconds;
  final Question question;
  final DateTime createdAt;

  GameLevel({
    required this.levelNumber,
    required this.objects,
    required this.exposureSeconds,
    required this.question,
    required this.createdAt,
  });
}

enum GamePhase {
  showingLevel,
  countdown,
  showingObjects,
  hidden,
  questioning,
  feedback,
  gameOver,
}

class GameState {
  final int level;
  final int score;
  final int lives;
  final int streak;
  final int multiplier;
  final GamePhase phase;
  final GameLevel? currentLevel;
  final int countdownValue; // 3,2,1
  final bool lastAnswerCorrect;
  final int? selectedIndex;
  final int totalCorrect;
  final int totalWrong;

  const GameState({
    this.level = 1,
    this.score = 0,
    this.lives = 3,
    this.streak = 0,
    this.multiplier = 1,
    this.phase = GamePhase.showingLevel,
    this.currentLevel,
    this.countdownValue = 3,
    this.lastAnswerCorrect = false,
    this.selectedIndex,
    this.totalCorrect = 0,
    this.totalWrong = 0,
  });

  GameState copyWith({
    int? level,
    int? score,
    int? lives,
    int? streak,
    int? multiplier,
    GamePhase? phase,
    GameLevel? currentLevel,
    int? countdownValue,
    bool? lastAnswerCorrect,
    int? selectedIndex,
    int? totalCorrect,
    int? totalWrong,
    bool clearLevel = false,
    bool clearSelection = false,
  }) {
    return GameState(
      level: level ?? this.level,
      score: score ?? this.score,
      lives: lives ?? this.lives,
      streak: streak ?? this.streak,
      multiplier: multiplier ?? this.multiplier,
      phase: phase ?? this.phase,
      currentLevel: clearLevel ? null : (currentLevel ?? this.currentLevel),
      countdownValue: countdownValue ?? this.countdownValue,
      lastAnswerCorrect: lastAnswerCorrect ?? this.lastAnswerCorrect,
      selectedIndex: clearSelection ? null : (selectedIndex ?? this.selectedIndex),
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalWrong: totalWrong ?? this.totalWrong,
    );
  }
}

class PlayerStats {
  final int bestLevel;
  final int bestScore;
  final int bestStreak;
  final int gamesPlayed;
  final int correctAnswers;
  final int wrongAnswers;

  const PlayerStats({
    this.bestLevel = 0,
    this.bestScore = 0,
    this.bestStreak = 0,
    this.gamesPlayed = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
  });

  PlayerStats copyWith({
    int? bestLevel,
    int? bestScore,
    int? bestStreak,
    int? gamesPlayed,
    int? correctAnswers,
    int? wrongAnswers,
  }) {
    return PlayerStats(
      bestLevel: bestLevel ?? this.bestLevel,
      bestScore: bestScore ?? this.bestScore,
      bestStreak: bestStreak ?? this.bestStreak,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
    );
  }
}
