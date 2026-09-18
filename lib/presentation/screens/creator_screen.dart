import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/emoji_bank.dart';
import '../../services/creator_service.dart';

class CreatorScreen extends StatefulWidget {
  const CreatorScreen({super.key});
  @override
  State<CreatorScreen> createState() => _CreatorScreenState();
}

class _CreatorScreenState extends State<CreatorScreen> {
  final titleCtrl = TextEditingController();
  final questionCtrl = TextEditingController(text: '¿Cuál de estos objetos viste?');
  final Set<String> selected = {};
  String? correct;
  List<String> options = [];

  void _toggle(String e) {
    setState(() {
      if (selected.contains(e)) {
        selected.remove(e);
        if (correct == e) correct = null;
      } else if (selected.length < 12) {
        selected.add(e);
      }
    });
  }

  void _buildOptions() {
    if (selected.isEmpty) return;
    final pool = EmojiBank.all.where((x) => !selected.contains(x)).toList()..shuffle();
    final corr = correct ?? selected.first;
    final distractors = pool.take(3).toList();
    setState(() => options = [...distractors, corr]..shuffle());
  }

  Future<void> _save() async {
    if (titleCtrl.text.trim().isEmpty || selected.length < 4 || options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elige 4-12 emojis, título y genera opciones')));
      return;
    }
    final corr = correct ?? selected.first;
    final idx = options.indexOf(corr);
    await CreatorService.add(CreatorChallenge(
      title: titleCtrl.text.trim(),
      emojis: selected.toList(),
      question: questionCtrl.text.trim(),
      options: options,
      correctIndex: idx < 0 ? 0 : idx,
      creator: 'TÚ',
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Reto creado! Aparece en Ver retos')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Modo creador', style: TextStyle(fontWeight: FontWeight.w800))),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título del reto', border: OutlineInputBorder()), style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            TextField(controller: questionCtrl, decoration: const InputDecoration(labelText: 'Pregunta', border: OutlineInputBorder()), style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            Text('Selecciona 4-12 emojis (${selected.length}/12)', style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: EmojiBank.all.take(80).map((e) {
              final sel = selected.contains(e);
              return GestureDetector(
                onTap: () => _toggle(e),
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: sel ? AppTheme.accent.withValues(alpha: 0.25) : AppTheme.bgCard2, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? AppTheme.accent : AppTheme.border)),
                  alignment: Alignment.center,
                  child: Text(e, style: const TextStyle(fontSize: 22)),
                ),
              );
            }).toList()),
            const SizedBox(height: 12),
            if (selected.isNotEmpty)
              Wrap(spacing: 6, children: selected.map((e) => Chip(
                    label: Text(e),
                    backgroundColor: AppTheme.bgCard2,
                    deleteIcon: Icon(Icons.close, size: 14, color: e == correct ? AppTheme.success : AppTheme.textMuted),
                    onDeleted: () => setState(() => correct = e),
                    labelStyle: TextStyle(color: e == correct ? AppTheme.success : Colors.white, fontWeight: e == correct ? FontWeight.w800 : FontWeight.normal),
                  )).toList()),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _buildOptions, child: const Text('Generar opciones (elige correcta tocando chip X)')),
            if (options.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Opciones: ${options.join(' ')}', style: const TextStyle(color: Colors.white)),
              Text('Correcta: ${options[correct != null ? options.indexOf(correct!) : 0]}', style: const TextStyle(color: AppTheme.success, fontSize: 11)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: const Text('GUARDAR RETO')),
          ],
        ),
      ),
    );
  }
}

class CreatorListScreen extends StatefulWidget {
  const CreatorListScreen({super.key});
  @override
  State<CreatorListScreen> createState() => _CreatorListScreenState();
}

class _CreatorListScreenState extends State<CreatorListScreen> {
  List<CreatorChallenge> list = [];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final l = await CreatorService.load(); if (mounted) setState(() => list = l); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Retos creados', style: TextStyle(fontWeight: FontWeight.w800))),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: list.isEmpty
            ? const Center(child: Text('Aún no hay retos. ¡Crea uno!', style: TextStyle(color: AppTheme.textMuted)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final c = list[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text(c.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                        IconButton(onPressed: () async { await CreatorService.removeAt(i); _load(); }, icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 18)),
                      ]),
                      const SizedBox(height: 6),
                      Text(c.emojis.join(' '), style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 6),
                      Text(c.question, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/game', arguments: {'creator': c}), child: const Text('JUGAR ESTE RETO'))),
                    ]),
                  );
                },
              ),
      ),
    );
  }
}
