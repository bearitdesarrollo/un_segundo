import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/storage_service.dart';
import '../../domain/entities/game_entities.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  PlayerStats _stats = const PlayerStats();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await StorageService().loadStats();
    if (mounted) setState(() { _stats = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)), title: const Text('Récords', style: TextStyle(fontWeight: FontWeight.w800))),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(children: [
                    Expanded(child: _bigCard('🏆', 'Mejor nivel', '${_stats.bestLevel}', AppTheme.primaryGradient)),
                    const SizedBox(width: 12),
                    Expanded(child: _bigCard('⭐', 'Mejor puntuación', '${_stats.bestScore}', AppTheme.successGradient)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _smallCard('🔥', 'Mejor racha', 'x${_stats.bestStreak}')),
                    const SizedBox(width: 12),
                    Expanded(child: _smallCard('🎮', 'Partidas', '${_stats.gamesPlayed}')),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _miniStat('✅ Correctas', '${_stats.correctAnswers}', AppTheme.success),
                      Container(width: 1, height: 40, color: AppTheme.border),
                      _miniStat('❌ Incorrectas', '${_stats.wrongAnswers}', AppTheme.accent),
                      Container(width: 1, height: 40, color: AppTheme.border),
                      _miniStat('📊 Precisión', _accuracy, AppTheme.accent2),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                        backgroundColor: AppTheme.bgCard,
                        title: const Text('¿Borrar récords?', style: TextStyle(color: Colors.white)),
                        content: const Text('Se restablecerán todas las estadísticas.', style: TextStyle(color: AppTheme.textSecondary)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Borrar', style: TextStyle(color: AppTheme.accent))),
                        ],
                      ));
                      if (confirm == true) {
                        await StorageService().saveStats(const PlayerStats());
                        _load();
                      }
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textSecondary, side: const BorderSide(color: AppTheme.border)),
                    child: const Text('Restablecer'),
                  ),
                ],
              ),
      ),
    );
  }

  String get _accuracy {
    final total = _stats.correctAnswers + _stats.wrongAnswers;
    if (total == 0) return '-';
    return '${((_stats.correctAnswers / total) * 100).toStringAsFixed(1)}%';
  }

  Widget _bigCard(String emoji, String label, String value, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 0.6, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _smallCard(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
    ]);
  }
}
