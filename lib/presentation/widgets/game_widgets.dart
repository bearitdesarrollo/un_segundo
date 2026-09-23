import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GameButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;
  final bool expanded;
  final bool dense;
  const GameButton({super.key, required this.label, this.onPressed, this.primary = true, this.icon, this.expanded = true, this.dense = false});

  @override
  Widget build(BuildContext context) {
    // FittedBox + Flexible evita desbordamiento en pantallas angostas (ej. 320dp)
    // y en labels largos como "CÓMO JUGAR" cuando dos botones comparten la fila.
    final iconSize = dense ? 14.0 : 18.0;
    final fontSize = dense ? 11.0 : 14.0;
    final letterSpacing = dense ? 0.4 : 0.8;
    final gap = dense ? 4.0 : 6.0;
    final hp = dense ? 10.0 : 16.0;
    final vp = dense ? 10.0 : 16.0;
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: iconSize),
          if (icon != null) SizedBox(width: gap),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: letterSpacing, fontSize: fontSize),
          ),
        ],
      ),
    );
    final btn = primary
        ? ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: EdgeInsets.symmetric(horizontal: hp, vertical: vp),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: child,
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.border, width: 1.5),
              backgroundColor: AppTheme.bgCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: EdgeInsets.symmetric(horizontal: hp - 2, vertical: vp),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: child,
          );
    if (expanded) return SizedBox(width: double.infinity, child: btn);
    return btn;
  }
}

class ScoreDisplay extends StatelessWidget {
  final int score;
  const ScoreDisplay({super.key, required this.score});
  String get _formatted {
    if (score >= 100000) return '${(score / 1000).toStringAsFixed(1)}k';
    if (score >= 10000) return '${(score / 1000).toStringAsFixed(1)}k';
    return '$score';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 110, minWidth: 52),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, color: AppTheme.warning, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(_formatted, maxLines: 1, softWrap: false, overflow: TextOverflow.visible, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13)),
          ),
        ),
      ]),
    );
  }
}

class LivesDisplay extends StatelessWidget {
  final int lives;
  const LivesDisplay({super.key, required this.lives});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < lives;
        return Padding(
          padding: EdgeInsets.only(right: i == 2 ? 0 : 3),
          child: Icon(Icons.favorite, color: filled ? AppTheme.accent : AppTheme.bgCard2, size: 18),
        );
      }),
    );
  }
}

class LevelDisplay extends StatelessWidget {
  final int level;
  const LevelDisplay({super.key, required this.level});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('NIVEL $level', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.0, fontSize: 12)),
    );
  }
}

class MultiplierBadge extends StatelessWidget {
  final int multiplier;
  const MultiplierBadge({super.key, required this.multiplier});
  @override
  Widget build(BuildContext context) {
    final active = multiplier > 1;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppTheme.accent3.withOpacity(0.15) : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? AppTheme.accent3 : Colors.transparent),
      ),
      child: Text('x$multiplier',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: active ? AppTheme.accent3 : AppTheme.textMuted,
            fontSize: 14,
          )),
    );
  }
}

class QuestionCard extends StatelessWidget {
  final String text;
  const QuestionCard({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center),
    );
  }
}

class AnswerButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;
  final bool selected;
  final bool isCorrect;
  final bool showResult;
  final bool enabled;

  const AnswerButton({
    super.key,
    required this.emoji,
    required this.onTap,
    this.selected = false,
    this.isCorrect = false,
    this.showResult = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppTheme.bgCard2;
    Color border = AppTheme.border;
    if (showResult) {
      if (isCorrect) {
        bg = AppTheme.success.withOpacity(0.2);
        border = AppTheme.success;
      } else if (selected && !isCorrect) {
        bg = AppTheme.accent.withOpacity(0.2);
        border = AppTheme.accent;
      }
    } else if (selected) {
      border = AppTheme.accent2;
    }

    final isNumber = int.tryParse(emoji) != null;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: border, width: 1.5)),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(emoji,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: isNumber ? 28 : 32,
                  height: 1.0,
                  fontWeight: isNumber ? FontWeight.w800 : FontWeight.normal,
                  color: Colors.white,
                )),
          ),
        ),
      ),
    );
  }
}

class EmojiGrid extends StatelessWidget {
  final List<String> emojis;
  final int columns;
  const EmojiGrid({super.key, required this.emojis, required this.columns});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, i) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              emojis[i],
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: const TextStyle(fontSize: 32, height: 1.0),
            ),
          ),
        );
      },
    );
  }
}
