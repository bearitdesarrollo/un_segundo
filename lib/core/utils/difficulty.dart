import 'dart:math' as math;

/// Dynamic difficulty calculation
class Difficulty {
  static int objectCount(int level) {
    if (level <= 1) return 4;
    if (level <= 5) return 4 + ((level - 1) * 1); // 4..8
    if (level <= 10) return 8 + ((level - 5) * 1); // 8..13 ~12
    if (level <= 20) return 12 + ((level - 10) * 1); // 12..22 but cap
    // 30+
    final extra = math.min(20, 16 + ((level - 20) ~/ 2));
    // smooth curve: logarithmic growth after 20
    final logPart = (math.log(level) * 2).round();
    return math.min(24, extra + logPart);
  }

  static double exposureSeconds(int level) {
    // 1.0 -> 0.35
    if (level <= 1) return 1.0;
    if (level <= 5) return 1.0 - (level - 1) * 0.05; // 1.0..0.8
    if (level <= 10) return 0.8 - (level - 5) * 0.04; // 0.8..0.6
    if (level <= 20) return 0.6 - (level - 10) * 0.01; // 0.6..0.5
    // 30+: asymptotically to 0.3
    final v = 0.5 - (level - 20) * 0.015;
    return v.clamp(0.28, 0.5);
  }

  static int answerCount(int level) {
    if (level <= 3) return 4;
    if (level <= 7) return 5;
    return 6;
  }

  static int gridColumns(int objectCount) {
    if (objectCount <= 4) return 2;
    if (objectCount <= 9) return 3;
    if (objectCount <= 16) return 4;
    return 5;
  }

  /// Which question types are allowed at this level
  static List<QuestionTypeId> allowedQuestionTypes(int level) {
    if (level <= 2) return [QuestionTypeId.seen, QuestionTypeId.notSeen];
    if (level <= 5) {
      return [
        QuestionTypeId.seen,
        QuestionTypeId.notSeen,
        QuestionTypeId.count,
        QuestionTypeId.position,
      ];
    }
    if (level <= 10) {
      return [
        QuestionTypeId.seen,
        QuestionTypeId.notSeen,
        QuestionTypeId.count,
        QuestionTypeId.position,
        QuestionTypeId.first,
        QuestionTypeId.last,
        QuestionTypeId.whichOfTwo,
      ];
    }
    return QuestionTypeId.values;
  }
}

enum QuestionTypeId {
  seen,       // ¿Cuál viste?
  notSeen,    // ¿Cuál NO viste?
  count,      // ¿Cuántos ...?
  position,   // ¿Qué había en posición X?
  first,      // ¿Cuál apareció primero?
  last,       // ¿Cuál apareció al final?
  whichOfTwo, // ¿Cuál de estos dos viste?
  duplicate,  // ¿Cuál apareció dos veces?
}
