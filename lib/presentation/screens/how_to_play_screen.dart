import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/game_widgets.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)), title: const Text('Cómo jugar', style: TextStyle(fontWeight: FontWeight.w800))),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _step('1', 'Memoriza', 'Los objetos aparecen solo por un instante. ¡Concéntrate!', '👀'),
            _step('2', 'Responde', 'Elige la respuesta correcta entre las opciones.', '🧠'),
            _step('3', 'Avanza', 'Cada nivel es más rápido y con más objetos.', '⚡'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('💡 Consejos', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                SizedBox(height: 8),
                Text('• No intentes contar todo, busca patrones.\n• Fíjate en posiciones si el nivel es alto.\n• La velocidad es clave: responde rápido para bonus.\n• 3 vidas por partida. ¡Úsalas bien!', style: TextStyle(color: AppTheme.textSecondary, height: 1.6)),
              ]),
            ),
            const SizedBox(height: 24),
            GameButton(label: '¡ENTENDIDO!', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _step(String n, String title, String desc, String emoji) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.bgCard2, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(emoji, style: const TextStyle(fontSize: 24))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$n. $title', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ])),
      ]),
    );
  }
}
