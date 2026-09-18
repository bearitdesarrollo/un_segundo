import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/game_entities.dart';
import '../../core/utils/difficulty.dart';
import '../../domain/services/game_generator.dart';
import '../../domain/services/score_manager.dart';
import '../../services/daily_service.dart';
import '../../services/creator_service.dart';

class GameController extends ChangeNotifier {
  final GameGenerator _generator;
  final int? dailySeed;
  final dynamic creatorChallenge; // CreatorChallenge optional
  GameController({GameGenerator? generator, this.dailySeed, this.creatorChallenge})
      : _generator = generator ?? (dailySeed != null ? GameGenerator(rng: DailyService.randomForSeed(dailySeed)) : GameGenerator());

  GameState _state = const GameState();
  GameState get state => _state;

  Timer? _timer;
  DateTime? _questionShownAt;
  bool _hasUsedRewardedThisGame = false;
  int _bestStreakThisGame = 0;

  // Public for stats
  int get bestStreakThisGame => _bestStreakThisGame;
  bool get hasUsedRewarded => _hasUsedRewardedThisGame;

  bool _disposed = false;

  void _setState(GameState s) {
    if (_disposed) return;
    _state = s;
    notifyListeners();
  }

  void startGame() {
    _timer?.cancel();
    _hasUsedRewardedThisGame = false;
    _bestStreakThisGame = 0;
    _setState(const GameState(
      level: 1,
      score: 0,
      lives: AppConstants.initialLives,
      streak: 0,
      multiplier: 1,
      phase: GamePhase.showingLevel,
    ));
    _startLevel(1);
  }

  void _startLevel(int level) {
    try {
      GameLevel gameLevel;
      if (creatorChallenge != null && level == 1) {
        final c = creatorChallenge as CreatorChallenge;
        final objs = List.generate(c.emojis.length, (i) => GameObject(emoji: c.emojis[i], index: i));
        final q = Question(type: QuestionTypeId.seen, text: c.question, options: c.options, correctIndex: c.correctIndex);
        gameLevel = GameLevel(levelNumber: level, objects: objs, exposureSeconds: 1.0, question: q, createdAt: DateTime.now());
      } else {
        gameLevel = _generator.generateLevel(level);
      }
      _setState(_state.copyWith(
        currentLevel: gameLevel,
        phase: GamePhase.showingLevel,
      ));
    } catch (e, st) {
      if (kDebugMode) print('[GameController] generateLevel fallo nivel $level: $e\n$st');
      // Fallback a pregunta simple para no crashear
      try {
        final fallback = _generator.generateLevel(1);
        _setState(_state.copyWith(
          currentLevel: fallback,
          phase: GamePhase.showingLevel,
        ));
      } catch (_) {
        _setState(_state.copyWith(phase: GamePhase.gameOver));
        return;
      }
    }

    // Show level for ~700ms then countdown
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 700), () {
      try {
        _startCountdown();
      } catch (e, st) {
        if (kDebugMode) print('[GameController] _startCountdown error: $e\n$st');
      }
    });
  }

  void _startCountdown() {
    try {
      if (_disposed) return;
      _setState(_state.copyWith(phase: GamePhase.countdown, countdownValue: 3));
      int c = 3;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 600), (t) {
        try {
          if (_disposed) {
            t.cancel();
            return;
          }
          c--;
          if (c > 0) {
            _setState(_state.copyWith(countdownValue: c));
            Haptics.light();
          } else {
            t.cancel();
            _showObjects();
          }
        } catch (e, st) {
          if (kDebugMode) print('[GameController] countdown tick error: $e\n$st');
          t.cancel();
        }
      });
    } catch (e, st) {
      if (kDebugMode) print('[GameController] _startCountdown error: $e\n$st');
    }
  }

  void _showObjects() {
    try {
      if (_disposed) return;
      _setState(_state.copyWith(phase: GamePhase.showingObjects));
      final exposure = _state.currentLevel!.exposureSeconds;
      _timer?.cancel();
      _timer = Timer(Duration(milliseconds: (exposure * 1000).round()), () {
        if (_disposed) return;
        try {
          _setState(_state.copyWith(phase: GamePhase.hidden));
          // tiny hidden delay to add suspense 300ms
          _timer = Timer(const Duration(milliseconds: 250), () {
            if (_disposed) return;
            try {
              _setState(_state.copyWith(phase: GamePhase.questioning));
              _questionShownAt = DateTime.now();
            } catch (e, st) {
              if (kDebugMode) print('[GameController] questioning error: $e\n$st');
            }
          });
        } catch (e, st) {
          if (kDebugMode) print('[GameController] hidden error: $e\n$st');
        }
      });
    } catch (e, st) {
      if (kDebugMode) print('[GameController] _showObjects error: $e\n$st');
    }
  }

  void selectAnswer(int index) {
    if (_state.phase != GamePhase.questioning) return;
    final q = _state.currentLevel!.question;
    final isCorrect = index == q.correctIndex;
    final responseSeconds = _questionShownAt == null
        ? 2.0
        : DateTime.now().difference(_questionShownAt!).inMilliseconds / 1000.0;

    _setState(_state.copyWith(selectedIndex: index, lastAnswerCorrect: isCorrect));

    if (isCorrect) {
      Haptics.success();
      final newStreak = _state.streak + 1;
      if (newStreak > _bestStreakThisGame) _bestStreakThisGame = newStreak;
      final earned = ScoreManager.calculate(level: _state.level, streak: newStreak, responseSeconds: responseSeconds);
      final newScore = _state.score + earned;
      final newMultiplier = ScoreManager.displayMultiplier(newStreak);

      _setState(_state.copyWith(
        score: newScore,
        streak: newStreak,
        multiplier: newMultiplier,
        phase: GamePhase.feedback,
        totalCorrect: _state.totalCorrect + 1,
      ));

      // short feedback then next level
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 700), () {
        final nextLevel = _state.level + 1;
        _setState(_state.copyWith(level: nextLevel, clearSelection: true));
        _startLevel(nextLevel);
      });
    } else {
      Haptics.error();
      final newLives = _state.lives - 1;
      final newStreak = 0;
      _setState(_state.copyWith(
        lives: newLives,
        streak: newStreak,
        multiplier: 1,
        phase: GamePhase.feedback,
        totalWrong: _state.totalWrong + 1,
      ));

      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 700), () {
        if (newLives <= 0) {
          _setState(_state.copyWith(phase: GamePhase.gameOver, clearSelection: true));
        } else {
          // retry same level? spec says advance only on correct, but lives decrement.
          // We'll advance? No, stay same level but new question variant.
          // For simplicity: stay on same level count but regenerate question.
          _setState(_state.copyWith(clearSelection: true));
          _startLevel(_state.level);
        }
      });
    }
  }

  /// Rewarded: restore 1 life and continue
  bool consumeRewardedContinue() {
    if (_hasUsedRewardedThisGame) return false;
    if (_state.phase != GamePhase.gameOver) return false;
    _hasUsedRewardedThisGame = true;
    _setState(_state.copyWith(
      lives: 1,
      phase: GamePhase.showingLevel,
      clearSelection: true,
    ));
    _startLevel(_state.level);
    return true;
  }

  void forceGameOver() {
    _timer?.cancel();
    _setState(_state.copyWith(phase: GamePhase.gameOver));
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

class Haptics {
  static void light() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static void success() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static void error() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
