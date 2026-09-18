import 'dart:math';
import '../../core/utils/difficulty.dart';
import '../../data/local/emoji_bank.dart';
import '../entities/game_entities.dart';

class GameGenerator {
  final Random _rng;
  GameGenerator({Random? rng}) : _rng = rng ?? Random();

  GameLevel generateLevel(int level) {
    final count = Difficulty.objectCount(level);
    final exposure = Difficulty.exposureSeconds(level);
    final answerCount = Difficulty.answerCount(level);

    // Pick unique objects for this level
    final pool = List<String>.from(EmojiBank.all)..shuffle(_rng);
    // For duplicate question we may need to allow duplicates
    final allowedTypes = Difficulty.allowedQuestionTypes(level);
    // Decide question type upfront, because duplicate type needs special generation
    QuestionTypeId type = allowedTypes[_rng.nextInt(allowedTypes.length)];

    List<GameObject> objects;
    // Handle duplicate type: force one duplicate
    String? duplicateEmoji;
    if (type == QuestionTypeId.duplicate && count >= 3) {
      // pick count-1 unique then duplicate one
      final uniqueNeeded = count - 1;
      final uniques = pool.take(uniqueNeeded).toList();
      duplicateEmoji = uniques[_rng.nextInt(uniques.length)];
      final list = [...uniques, duplicateEmoji];
      list.shuffle(_rng);
      objects = List.generate(list.length, (i) => GameObject(emoji: list[i], index: i));
    } else {
      final picked = pool.take(count).toList();
      objects = List.generate(picked.length, (i) => GameObject(emoji: picked[i], index: i));
      // if type is duplicate but count <3, fallback to seen
      if (type == QuestionTypeId.duplicate) {
        type = QuestionTypeId.seen;
      }
    }

    final question = _generateQuestion(
      type: type,
      objects: objects,
      pool: pool,
      answerCount: answerCount,
      level: level,
      duplicateEmoji: duplicateEmoji,
    );

    return GameLevel(
      levelNumber: level,
      objects: objects,
      exposureSeconds: exposure,
      question: question,
      createdAt: DateTime.now(),
    );
  }

  Question _generateQuestion({
    required QuestionTypeId type,
    required List<GameObject> objects,
    required List<String> pool,
    required int answerCount,
    required int level,
    String? duplicateEmoji,
  }) {
    final emojisInLevel = objects.map((e) => e.emoji).toSet();
    final notInLevel = EmojiBank.all.where((e) => !emojisInLevel.contains(e)).toList()..shuffle(_rng);

    switch (type) {
      case QuestionTypeId.seen:
        return _questionSeen(emojisInLevel, notInLevel, answerCount);
      case QuestionTypeId.notSeen:
        return _questionNotSeen(emojisInLevel, notInLevel, answerCount);
      case QuestionTypeId.count:
        return _questionCount(objects, pool, answerCount);
      case QuestionTypeId.position:
        return _questionPosition(objects, notInLevel, answerCount);
      case QuestionTypeId.first:
        return _questionFirst(objects, notInLevel, answerCount);
      case QuestionTypeId.last:
        return _questionLast(objects, notInLevel, answerCount);
      case QuestionTypeId.whichOfTwo:
        return _questionWhichOfTwo(emojisInLevel, notInLevel);
      case QuestionTypeId.duplicate:
        return _questionDuplicate(objects, notInLevel, duplicateEmoji!, answerCount);
    }
  }

  Question _questionSeen(Set<String> inLevel, List<String> notInLevel, int answerCount) {
    final correct = (inLevel.toList()..shuffle(_rng)).first;
    final distractors = notInLevel.take(answerCount - 1).toList();
    final options = [...distractors, correct]..shuffle(_rng);
    return Question(
      type: QuestionTypeId.seen,
      text: '¿Cuál de estos objetos viste?',
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  Question _questionNotSeen(Set<String> inLevel, List<String> notInLevel, int answerCount) {
    final correct = notInLevel.first;
    final distractors = (inLevel.toList()..shuffle(_rng)).take(answerCount - 1).toList();
    final options = [...distractors, correct]..shuffle(_rng);
    return Question(
      type: QuestionTypeId.notSeen,
      text: '¿Cuál NO viste?',
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  Question _questionCount(List<GameObject> objects, List<String> pool, int answerCount) {
    try {
      final candidates = objects.map((e) => e.emoji).toList()..shuffle(_rng);
      final target = _rng.nextBool() ? candidates.first : pool[_rng.nextInt(pool.length)];
      final actualCount = objects.where((o) => o.emoji == target).length;
      // Generar opciones numéricas determinísticas sin riesgo de bucle infinito
      // Rango 0..max(4, actualCount+2) garantiza suficientes valores únicos
      final maxVal = (actualCount + 3).clamp(4, 10);
      final optionsSet = <int>{actualCount};
      int safety = 0;
      while (optionsSet.length < answerCount && safety < 50) {
        safety++;
        // alternar entre valores bajos y cercanos al correcto
        if (safety % 2 == 0) {
          optionsSet.add(_rng.nextInt(maxVal + 1));
        } else {
          // valor cercano pero distinto
          final delta = _rng.nextInt(3) + 1;
          final candidate = (actualCount + delta) % (maxVal + 1);
          if (candidate != actualCount) optionsSet.add(candidate);
          // relleno extra si falta
          if (optionsSet.length < answerCount) {
            optionsSet.add(_rng.nextInt(maxVal + 1));
          }
        }
      }
      // Fallback determinístico si aún falta (no debería pasar)
      int filler = 0;
      while (optionsSet.length < answerCount) {
        if (!optionsSet.contains(filler)) optionsSet.add(filler);
        filler++;
      }
      final opts = optionsSet.take(answerCount).toList()..shuffle(_rng);
      return Question(
        type: QuestionTypeId.count,
        text: '¿Cuántos $target aparecieron?',
        options: opts.map((e) => e.toString()).toList(),
        correctIndex: opts.indexOf(actualCount),
        highlightedEmoji: target,
        countAnswer: actualCount,
      );
    } catch (e) {
      // Fallback a pregunta vista si algo falla
      final inLevel = objects.map((e) => e.emoji).toSet();
      final notInLevel = EmojiBank.all.where((x) => !inLevel.contains(x)).toList()..shuffle(_rng);
      return _questionSeen(inLevel, notInLevel, answerCount);
    }
  }

  Question _questionPosition(List<GameObject> objects, List<String> notInLevel, int answerCount) {
    final pos = _rng.nextInt(objects.length); // 0-indexed
    final correct = objects[pos].emoji;
    final distractors = notInLevel.take(answerCount - 1).toList();
    final options = [...distractors, correct]..shuffle(_rng);
    return Question(
      type: QuestionTypeId.position,
      text: '¿Qué objeto estaba en la posición ${pos + 1}?',
      options: options,
      correctIndex: options.indexOf(correct),
      positionHint: pos + 1,
    );
  }

  Question _questionFirst(List<GameObject> objects, List<String> notInLevel, int answerCount) {
    final correct = objects.first.emoji;
    final distractors = notInLevel.take(answerCount - 1).toList();
    final options = [...distractors, correct]..shuffle(_rng);
    return Question(
      type: QuestionTypeId.first,
      text: '¿Cuál apareció primero?',
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  Question _questionLast(List<GameObject> objects, List<String> notInLevel, int answerCount) {
    final correct = objects.last.emoji;
    final distractors = notInLevel.take(answerCount - 1).toList();
    final options = [...distractors, correct]..shuffle(_rng);
    return Question(
      type: QuestionTypeId.last,
      text: '¿Cuál apareció al final?',
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  Question _questionWhichOfTwo(Set<String> inLevel, List<String> notInLevel) {
    final seen = (inLevel.toList()..shuffle(_rng)).first;
    final unseen = notInLevel.first;
    final options = [seen, unseen]..shuffle(_rng);
    return Question(
      type: QuestionTypeId.whichOfTwo,
      text: '¿Cuál de estos dos viste?',
      options: options,
      correctIndex: options.indexOf(seen),
    );
  }

  Question _questionDuplicate(List<GameObject> objects, List<String> notInLevel, String duplicateEmoji, int answerCount) {
    final distractors = notInLevel.take(answerCount - 1).toList();
    final options = [...distractors, duplicateEmoji]..shuffle(_rng);
    return Question(
      type: QuestionTypeId.duplicate,
      text: '¿Qué objeto apareció dos veces?',
      options: options,
      correctIndex: options.indexOf(duplicateEmoji),
    );
  }
}
