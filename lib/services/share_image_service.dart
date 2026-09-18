import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../core/theme/app_theme.dart';

class ShareImageService {
  static Future<void> shareText({required int level, required int score, int? seed, int? streak}) async {
    final seedPart = seed != null ? '\nSeed diario #$seed' : '';
    final text = '🧠 ¡Nivel $level — $score pts en 1 SEGUNDO!$seedPart\n¿Puedes superarme? #1Segundo';
    await SharePlus.instance.share(ShareParams(text: text));
  }

  static Future<void> shareImage(GlobalKey boundaryKey, {required int level, required int score, String? extra}) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        await shareText(level: level, score: score);
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        await shareText(level: level, score: score);
        return;
      }
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/1segundo_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: '🧠 Nivel $level — $score pts en 1 SEGUNDO! ${extra ?? ''} #1Segundo',
      ));
    } catch (_) {
      await shareText(level: level, score: score);
    }
  }
}

class RecordCard extends StatelessWidget {
  final int level;
  final int score;
  final int streak;
  final int? seed;
  final String playerName;
  const RecordCard({super.key, required this.level, required this.score, required this.streak, this.seed, this.playerName = 'TÚ'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080 / 3,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF040F23), Color(0xFF0A1E3C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(20)),
            child: Text(seed != null ? 'DESAFÍO DIARIO #$seed' : '1 SEGUNDO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
          ),
          const SizedBox(height: 14),
          Text(playerName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text('NIVEL $level', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 4),
          Text('$score PTS', style: TextStyle(color: AppTheme.accent2, fontSize: 18, fontWeight: FontWeight.w800)),
          if (streak > 1)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.accent3.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.accent3)),
              child: Text('RACHA x$streak', style: const TextStyle(color: AppTheme.accent3, fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _mini('⚡', '${(level * 0.9).toStringAsFixed(1)}s'),
            const SizedBox(width: 12),
            _mini('🎯', '$score'),
          ]),
          const SizedBox(height: 12),
          const Text('¿Puedes superarme?', style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 6),
          const Text('1segundo.app • #1Segundo', style: TextStyle(color: AppTheme.textMuted, fontSize: 9, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _mini(String emoji, String v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppTheme.bgCard2, borderRadius: BorderRadius.circular(10)),
        child: Text('$emoji $v', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
      );
}
