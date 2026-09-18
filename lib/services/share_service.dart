import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> shareResult({required int level, required int score}) async {
    final text = '🧠 ¡Llegué al nivel $level con $score puntos en 1 SEGUNDO!\n'
        '¿Puedes superarme? #1Segundo';
    await SharePlus.instance.share(ShareParams(text: text));
  }
}
