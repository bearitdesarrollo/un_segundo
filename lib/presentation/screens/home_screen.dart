import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/storage_service.dart';
import '../../services/ad_service.dart';
import '../../services/daily_service.dart';
import '../../services/ghost_service.dart';
import '../../services/profile_service.dart';
import '../../services/powerup_service.dart';
import '../widgets/game_widgets.dart';
import '../../domain/entities/game_entities.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PlayerStats _stats = const PlayerStats();
  bool _loading = true;
  int _dailySeed = 0;
  int _dailyBestLevel = 0;
  int _dailyStreak = 0;
  List<int> _calendar = [];
  GhostRun? _ghost;
  List<LocalProfile> _profiles = [];
  int _activeIdx = 0;
  int _bombs = 2, _fifty = 2, _hints = 2;

  @override
  void initState() {
    super.initState();
    _load();
    AdService().initialize();
  }

  Future<void> _load() async {
    try {
      final s = await StorageService().loadStats();
      final seed = DailyService.todaySeed();
      final dailyBest = await DailyService.getDailyBestLevel();
      final streak = await DailyService.getDailyStreak();
      final cal = await DailyService.getCalendarDays();
      final ghost = await GhostService.loadBest();
      final profiles = await ProfileService.load();
      final active = await ProfileService.activeIndex();
      final b = await PowerUpService.getBombs();
      final f = await PowerUpService.getFifty();
      final h = await PowerUpService.getHints();
      if (mounted) {
        setState(() {
          _stats = s;
          _loading = false;
          _dailySeed = seed;
          _dailyBestLevel = dailyBest;
          _dailyStreak = streak;
          _calendar = cal;
          _ghost = ghost;
          _profiles = profiles;
          _activeIdx = active;
          _bombs = b;
          _fifty = f;
          _hints = h;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _navigate(String route) async {
    await Navigator.pushNamed(context, route);
    if (mounted) _load();
  }

  void _playDaily() async {
    await Navigator.pushNamed(context, '/game', arguments: {'dailySeed': _dailySeed});
    if (mounted) _load();
  }

  void _playWithSeedDialog() async {
    final ctrl = TextEditingController(text: '$_dailySeed');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Retar con seed', style: TextStyle(color: Colors.white)),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Seed', border: OutlineInputBorder()), style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('JUGAR')),
        ],
      ),
    );
    if (ok == true) {
      final seed = int.tryParse(ctrl.text.trim()) ?? _dailySeed;
      if (mounted) await Navigator.pushNamed(context, '/game', arguments: {'dailySeed': seed});
      if (mounted) _load();
    }
  }

  void _showProfiles() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setM) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Liga local', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ...List.generate(_profiles.length, (i) {
              final p = _profiles[i];
              final active = i == _activeIdx;
              return ListTile(
                leading: Text(p.emoji, style: const TextStyle(fontSize: 22)),
                title: Text(p.name, style: TextStyle(color: active ? AppTheme.accent2 : Colors.white, fontWeight: active ? FontWeight.w800 : FontWeight.w600)),
                subtitle: Text('Nvl ${p.bestLevel} • ${p.bestScore} pts • x${p.bestStreak}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                trailing: active ? const Icon(Icons.check_circle, color: AppTheme.success) : null,
                onTap: () async {
                  await ProfileService.setActive(i);
                  if (mounted) setState(() => _activeIdx = i);
                  setM(() {});
                },
              );
            }),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () async {
                final nameCtrl = TextEditingController();
                final emojiCtrl = TextEditingController(text: '😀');
                final add = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                  backgroundColor: AppTheme.bgCard,
                  title: const Text('Nuevo perfil', style: TextStyle(color: Colors.white)),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                    TextField(controller: emojiCtrl, decoration: const InputDecoration(labelText: 'Emoji')),
                  ]),
                  actions: [TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Añadir'))],
                ));
                if (add == true && nameCtrl.text.isNotEmpty) {
                  _profiles.add(LocalProfile(name: nameCtrl.text.trim(), emoji: emojiCtrl.text.trim().isEmpty ? '😀' : emojiCtrl.text.trim()));
                  await ProfileService.save(_profiles);
                  setM(() {});
                  if (mounted) setState(() {});
                }
              }, child: const Text('Añadir perfil'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))),
            ])
          ]),
        );
      }),
    );
    _load();
  }

  void _showPowerUpShop() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Power-ups', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 12),
          _puTile('💣', 'Bomba', 'Salta nivel (cuesta 1 vida menos)', _bombs, () async {
            final ok = await AdService().showRewarded(onRewarded: () {});
            bool granted = ok || !AdService().isRewardedReady;
            if (granted) { await PowerUpService.addBomb(1); if (mounted) setState(() => _bombs++); }
            if (mounted) Navigator.pop(context);
          }),
          _puTile('✂️', '50/50', 'Elimina 2 opciones incorrectas', _fifty, () async {
            final ok = await AdService().showRewarded(onRewarded: () {});
            bool granted = ok || !AdService().isRewardedReady;
            if (granted) { await PowerUpService.addFifty(1); if (mounted) setState(() => _fifty++); }
            if (mounted) Navigator.pop(context);
          }),
          _puTile('💡', 'Pista', 'Resalta la correcta brevemente', _hints, () async {
            final ok = await AdService().showRewarded(onRewarded: () {});
            bool granted = ok || !AdService().isRewardedReady;
            if (granted) { await PowerUpService.addHint(1); if (mounted) setState(() => _hints++); }
            if (mounted) Navigator.pop(context);
          }),
        ]),
      ),
    );
    _load();
  }

  Widget _puTile(String emoji, String title, String desc, int count, VoidCallback onEarn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.bgCard2, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$title  x$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          Text(desc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ])),
        ElevatedButton(onPressed: onEarn, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)), child: const Text('Ver anuncio')),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('1"', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white)),
                  Row(children: [
                    IconButton(onPressed: () => _navigate('/settings'), icon: const Icon(Icons.settings_rounded, color: AppTheme.textSecondary)),
                  ]),
                ]),
                const SizedBox(height: 8),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))]),
                  alignment: Alignment.center,
                  child: const Text('1"', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                const SizedBox(height: 12),
                const Text('1 SEGUNDO', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.2, color: Colors.white)),
                const Text('¿Puedes recordarlo?', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 16),
                if (!_loading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _stat('MEJOR NIVEL', '${_stats.bestLevel}'),
                      Container(width: 1, height: 32, color: AppTheme.border),
                      _stat('RÉCORD', '${_stats.bestScore}'),
                      Container(width: 1, height: 32, color: AppTheme.border),
                      _stat('RACHA', 'x${_stats.bestStreak}'),
                    ]),
                  ),
                const SizedBox(height: 16),
                GameButton(label: 'JUGAR', icon: Icons.play_arrow_rounded, onPressed: () => _navigate('/game')),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: GameButton(label: 'RÉCORDS', icon: Icons.emoji_events_rounded, primary: false, onPressed: () => _navigate('/records'))),
                  const SizedBox(width: 10),
                  Expanded(child: GameButton(label: 'CÓMO JUGAR', icon: Icons.help_outline_rounded, primary: false, onPressed: () => _navigate('/howto'))),
                ]),
                const SizedBox(height: 16),
                // DESAFÍO DIARIO
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0D1E3A), Color(0xFF143054)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35))),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('🔥 DESAFÍO DIARIO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8)),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text('SEED #$_dailySeed', style: const TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.w800))),
                    ]),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _miniStat('HOY', 'Nvl $_dailyBestLevel'),
                      _miniStat('RACHA', '$_dailyStreak días'),
                      _miniStat('FANTASMA', _ghost == null ? '-' : 'Nvl ${_ghost!.level}'),
                    ]),
                    const SizedBox(height: 8),
                    // calendario 7 días
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(7, (i) {
                      final daySeed = DailyService.todaySeed() - (6 - i);
                      final played = _calendar.contains(daySeed);
                      final isToday = i == 6;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: played ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.bgCard2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isToday ? AppTheme.accent : played ? AppTheme.success : AppTheme.border),
                        ),
                        alignment: Alignment.center,
                        child: Text(played ? '✓' : '${(6 - i) == 0 ? 'H' : (6 - i)}', style: TextStyle(color: played ? AppTheme.success : AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                      );
                    })),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: GameButton(label: 'JUGAR DIARIO', icon: Icons.calendar_today_rounded, onPressed: _playDaily)),
                      const SizedBox(width: 8),
                      Expanded(child: GameButton(label: 'RETAR SEED', icon: Icons.link_rounded, primary: false, onPressed: _playWithSeedDialog)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 12),
                // LIGA + POWER-UPS
                Row(children: [
                  Expanded(child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
                    child: Column(children: [
                      Text('${_profiles.isEmpty ? '😎' : _profiles[_activeIdx].emoji}  ${_profiles.isEmpty ? 'TÚ' : _profiles[_activeIdx].name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Liga local: ${_profiles.length} jugadores', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _showProfiles, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), side: const BorderSide(color: AppTheme.border)), child: const Text('Cambiar perfil', style: TextStyle(fontSize: 11)))),
                    ]),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
                    child: Column(children: [
                      const Text('🎒 Power-ups', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _puBadge('💣', _bombs),
                        const SizedBox(width: 6),
                        _puBadge('✂️', _fifty),
                        const SizedBox(width: 6),
                        _puBadge('💡', _hints),
                      ]),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _showPowerUpShop, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), side: const BorderSide(color: AppTheme.border)), child: const Text('Conseguir', style: TextStyle(fontSize: 11)))),
                    ]),
                  )),
                ]),
                const SizedBox(height: 12),
                // CREADOR
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
                  child: Row(children: [
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('🎨 Modo creador', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Crea retos con tus emojis y compártelos', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ])),
                    ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/creator'), child: const Text('Crear')),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: () => Navigator.pushNamed(context, '/creator_list'), child: const Text('Ver')),
                  ]),
                ),
                const SizedBox(height: 16),
                const Text('Sin internet • Sin registro • Solo memoria', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 0.5)),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, letterSpacing: 0.8, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
      ]);

  Widget _miniStat(String label, String v) => Column(children: [
        Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      ]);

  Widget _puBadge(String e, int n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(color: AppTheme.bgCard2, borderRadius: BorderRadius.circular(8)),
        child: Text('$e $n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
      );
}
