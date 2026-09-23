import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/difficulty.dart';
import '../../domain/entities/game_entities.dart';
import '../../services/storage_service.dart';
import '../../services/ad_service.dart';
import '../../services/share_image_service.dart';
import '../../services/daily_service.dart';
import '../../services/ghost_service.dart';
import '../../services/profile_service.dart';
import '../../services/powerup_service.dart';
import '../controllers/game_controller.dart';
import '../widgets/game_widgets.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController _ctrl;
  bool _initialized = false;
  int? _dailySeed;
  dynamic _creator;
  final GlobalKey _shareKey = GlobalKey();
  Set<int> _eliminated = {};
  bool _hintActive = false;
  int _bombs = 2, _fifty = 2, _hints = 2;
  GhostRun? _ghostBest;
  DateTime? _runStart;
  BannerAd? _bannerGO;
  bool _bannerGOLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _dailySeed = args?['dailySeed'] as int?;
      _creator = args?['creator'];
      _ctrl = GameController(dailySeed: _dailySeed, creatorChallenge: _creator);
      _ctrl.startGame();
      _ctrl.addListener(_onGameOver);
      _runStart = DateTime.now();
      _loadExtras();
      _loadBannerGO();
      _initialized = true;
    }
  }

  void _loadBannerGO() {
    _bannerGO?.dispose();
    _bannerGO = BannerAd(
      adUnitId: AdService().bannerAdUnitId,
      size: AdSize.largeBanner, // 320x100 un poco más grande que banner 320x50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => mounted ? setState(() => _bannerGOLoaded = true) : null,
        onAdFailedToLoad: (ad, _) { ad.dispose(); _bannerGO = null; },
      ),
    )..load();
  }

  Future<void> _loadExtras() async {
    final b = await PowerUpService.getBombs();
    final f = await PowerUpService.getFifty();
    final h = await PowerUpService.getHints();
    final ghost = await GhostService.loadBest();
    if (mounted) setState(() { _bombs = b; _fifty = f; _hints = h; _ghostBest = ghost; });
  }

  void _onGameOver() async {
    if (_ctrl.state.phase == GamePhase.gameOver) {
      await StorageService().updateAfterGame(
        levelReached: _ctrl.state.level,
        score: _ctrl.state.score,
        streak: _ctrl.bestStreakThisGame,
        correct: _ctrl.state.totalCorrect,
        wrong: _ctrl.state.totalWrong,
      );
      await StorageService().incrementGamesSinceInterstitial();
      if (_dailySeed != null) {
        await DailyService.saveDailyResultIfBetter(level: _ctrl.state.level, score: _ctrl.state.score);
        await DailyService.incDailyAttempts();
      }
      await ProfileService.updateActiveWithResult(level: _ctrl.state.level, score: _ctrl.state.score, streak: _ctrl.bestStreakThisGame);
      final elapsed = _runStart == null ? 0 : DateTime.now().difference(_runStart!).inMilliseconds;
      await GhostService.saveRun(GhostRun(level: _ctrl.state.level, score: _ctrl.state.score, streak: _ctrl.bestStreakThisGame, timeMs: elapsed, seed: _dailySeed ?? DateTime.now().millisecondsSinceEpoch, date: DateTime.now().toIso8601String()));
      _loadExtras();
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onGameOver);
    _ctrl.dispose();
    _bannerGO?.dispose();
    super.dispose();
  }

  void _useBomb() async {
    if (_ctrl.state.phase != GamePhase.questioning) return;
    final ok = await PowerUpService.useBomb();
    if (!ok) {
      final earn = await _askEarn('Bomba');
      if (!earn) return;
      await PowerUpService.addBomb(1);
    }
    // bomb = salta nivel como acierto sin puntos extra, avanza
    _ctrl.selectAnswer(_ctrl.state.currentLevel!.question.correctIndex);
    _loadExtras();
  }

  void _useFifty() async {
    if (_ctrl.state.phase != GamePhase.questioning) return;
    if (_eliminated.isNotEmpty) return;
    final ok = await PowerUpService.useFifty();
    if (!ok) {
      final earn = await _askEarn('50/50');
      if (!earn) return;
      await PowerUpService.addFifty(1);
      // retry
      final ok2 = await PowerUpService.useFifty();
      if (!ok2) return;
    }
    final q = _ctrl.state.currentLevel!.question;
    final wrong = List.generate(q.options.length, (i) => i).where((i) => i != q.correctIndex).toList()..shuffle();
    setState(() => _eliminated = wrong.take(2).toSet());
    _loadExtras();
  }

  void _useHint() async {
    if (_ctrl.state.phase != GamePhase.questioning || _hintActive) return;
    final ok = await PowerUpService.useHint();
    if (!ok) {
      final earn = await _askEarn('Pista');
      if (!earn) return;
      await PowerUpService.addHint(1);
      final ok2 = await PowerUpService.useHint();
      if (!ok2) return;
    }
    setState(() => _hintActive = true);
    Future.delayed(const Duration(milliseconds: 800), () { if (mounted) setState(() => _hintActive = false); });
    _loadExtras();
  }

  Future<bool> _askEarn(String name) async {
    final res = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.bgCard,
      title: Text('Sin $name', style: const TextStyle(color: Colors.white)),
      content: Text('¿Ver anuncio para conseguir 1 $name?', style: const TextStyle(color: AppTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ver anuncio')),
      ],
    ));
    if (res != true) return false;
    final wasReady = AdService().isRewardedReady;
    final ok = await AdService().showRewarded(onRewarded: () {});
    final granted = ok || !wasReady;
    if (!granted && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anuncio no disponible, cierra el anuncio después de verlo completo')));
    return granted;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
          child: SafeArea(
            child: Consumer<GameController>(
              builder: (context, ctrl, _) {
                final s = ctrl.state;
                if (s.phase == GamePhase.gameOver) return _buildGameOver(context, s);
                return Column(
                  children: [
                    _buildTopBar(s),
                    if (s.phase == GamePhase.questioning) _buildPowerUpBar(),
                    Expanded(child: _buildPhaseContent(s, ctrl)),
                    _buildBottomInfo(s),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPowerUpBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        _puBtn('💣', '$_bombs', _useBomb),
        const SizedBox(width: 8),
        _puBtn('✂️', '$_fifty', _useFifty),
        const SizedBox(width: 8),
        _puBtn('💡', '$_hints', _useHint),
        const Spacer(),
        if (_dailySeed != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text('SEED #$_dailySeed', style: const TextStyle(color: AppTheme.warning, fontSize: 9, fontWeight: FontWeight.w800))),
      ]),
    );
  }

  Widget _puBtn(String emoji, String count, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
          child: Text('$emoji $count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      );

  Widget _buildTopBar(GameState s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
        LevelDisplay(level: s.level),
        const SizedBox(width: 6),
        Flexible(child: ScoreDisplay(score: s.score)),
        const SizedBox(width: 6),
        MultiplierBadge(multiplier: s.multiplier),
        const SizedBox(width: 6),
        LivesDisplay(lives: s.lives),
      ]),
    );
  }

  Widget _buildBottomInfo(GameState s) {
    final l = s.currentLevel;
    String info = '${l?.objects.length ?? 0} objetos • ${l?.exposureSeconds.toStringAsFixed(2) ?? '-'}s';
    if (_ghostBest != null) info += ' • 👻 Nvl ${_ghostBest!.level}';
    return Padding(padding: const EdgeInsets.only(bottom: 12, top: 8), child: Text(info, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 0.5)));
  }

  Widget _buildPhaseContent(GameState s, GameController ctrl) {
    switch (s.phase) {
      case GamePhase.showingLevel: return _levelIntro(s.level);
      case GamePhase.countdown: return _countdown(s.countdownValue);
      case GamePhase.showingObjects: return _objectsGrid(s);
      case GamePhase.hidden: return _hidden();
      case GamePhase.questioning: return _questioning(s, ctrl);
      case GamePhase.feedback: return _feedback(s);
      case GamePhase.gameOver: return const SizedBox();
    }
  }

  Widget _levelIntro(int level) {
    return Center(
      child: TweenAnimationBuilder<double>(tween: Tween(begin: 0.8, end: 1.0), duration: const Duration(milliseconds: 400), curve: Curves.easeOutBack, builder: (context, v, child) => Transform.scale(scale: v, child: child), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('NIVEL', style: TextStyle(color: AppTheme.textMuted, letterSpacing: 4, fontSize: 14, fontWeight: FontWeight.w700)),
        Text('$level', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: Colors.white)),
        Container(height: 4, width: 48, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(2))),
        if (_ghostBest != null && level <= _ghostBest!.level) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)), child: Text('👻 Fantasma va Nvl ${_ghostBest!.level} • ${ _ghostBest!.score} pts', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
        ],
        if (_ghostBest != null && level > _ghostBest!.level) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.success)), child: const Text('🔥 ¡Vas ganando al fantasma!', style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.w800))),
        ],
      ])),
    );
  }

  Widget _countdown(int value) => Center(child: TweenAnimationBuilder<double>(key: ValueKey(value), tween: Tween(begin: 0.5, end: 1.0), duration: const Duration(milliseconds: 350), curve: Curves.elasticOut, builder: (context, v, child) => Transform.scale(scale: v, child: child), child: Container(width: 120, height: 120, decoration: BoxDecoration(color: AppTheme.bgCard, shape: BoxShape.circle, border: Border.all(color: AppTheme.accent, width: 3), boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.35), blurRadius: 24)]), alignment: Alignment.center, child: Text('$value', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white)))));

  Widget _objectsGrid(GameState s) {
    final lvl = s.currentLevel!;
    final cols = Difficulty.gridColumns(lvl.objects.length);
    return LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight), child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
      const Text('¡MEMORIZA!', style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 13)),
      const SizedBox(height: 16),
      EmojiGrid(emojis: lvl.objects.map((e) => e.emoji).toList(), columns: cols),
      const SizedBox(height: 16),
      TweenAnimationBuilder<double>(tween: Tween(begin: 1, end: 0), duration: Duration(milliseconds: (lvl.exposureSeconds * 1000).round()), builder: (context, v, child) => LinearProgressIndicator(value: v, color: AppTheme.accent, backgroundColor: AppTheme.bgCard2, minHeight: 4, borderRadius: BorderRadius.circular(2))),
    ])))));
  }

  Widget _hidden() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 72, height: 72, decoration: BoxDecoration(color: AppTheme.bgCard, shape: BoxShape.circle, border: Border.all(color: AppTheme.border)), child: const Icon(Icons.visibility_off_rounded, color: AppTheme.textMuted, size: 32)), const SizedBox(height: 16), const Text('...', style: TextStyle(color: AppTheme.textMuted, fontSize: 24, letterSpacing: 6))]));

  Widget _questioning(GameState s, GameController ctrl) {
    final q = s.currentLevel!.question;
    final cols = 2;
    // reset eliminated when new question
    // we keep _eliminated but clear on level change via didUpdate? Simplified: clear when question changes
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 8),
        QuestionCard(text: q.text),
        const SizedBox(height: 20),
        Expanded(child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.1),
          itemCount: q.options.length,
          itemBuilder: (context, i) {
            final isEliminated = _eliminated.contains(i);
            final isHint = _hintActive && i == q.correctIndex;
            if (isEliminated) return Container(decoration: BoxDecoration(color: AppTheme.bgCard.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border.withValues(alpha: 0.3))), alignment: Alignment.center, child: const Text('—', style: TextStyle(color: AppTheme.textMuted)));
            return AnswerButton(emoji: q.options[i], onTap: () { setState(() { _eliminated = {}; _hintActive = false; }); ctrl.selectAnswer(i); }, enabled: s.selectedIndex == null, selected: isHint, isCorrect: isHint, showResult: isHint);
          },
        )),
      ]),
    );
  }

  Widget _feedback(GameState s) {
    final q = s.currentLevel!.question;
    final isCorrect = s.lastAnswerCorrect;
    // clear power-up state on feedback
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && (_eliminated.isNotEmpty || _hintActive)) setState(() { _eliminated = {}; _hintActive = false; }); });
    return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      QuestionCard(text: q.text),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: isCorrect ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: isCorrect ? AppTheme.success : AppTheme.accent)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isCorrect ? AppTheme.success : AppTheme.accent), const SizedBox(width: 8), Text(isCorrect ? '¡Correcto! +${_lastEarned(s)}' : '¡Fallaste!', style: TextStyle(color: isCorrect ? AppTheme.success : AppTheme.accent, fontWeight: FontWeight.w800))])),
      const SizedBox(height: 16),
      Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.1), itemCount: q.options.length, itemBuilder: (context, i) {
        final selected = s.selectedIndex == i;
        final isCorrectIdx = q.correctIndex == i;
        return AnswerButton(emoji: q.options[i], onTap: () {}, selected: selected, isCorrect: isCorrectIdx, showResult: true, enabled: false);
      })),
    ]));
  }

  int _lastEarned(GameState s) => 100 + s.level * 10;

  Widget _buildGameOver(BuildContext context, GameState s) {
    return FutureBuilder<PlayerStats>(future: StorageService().loadStats(), builder: (context, snap) {
      final best = snap.data;
      final isNewRecord = best != null && s.score >= best.bestScore && s.score > 0;
      return LayoutBuilder(builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: constraints.maxHeight - 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_bannerGOLoaded && _bannerGO != null)
                  Container(
                    alignment: Alignment.center,
                    width: _bannerGO!.size.width.toDouble(),
                    height: _bannerGO!.size.height.toDouble(),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.border)),
                    child: AdWidget(ad: _bannerGO!),
                  ),
                Transform.scale(
                  scale: 0.68,
                  child: RepaintBoundary(
                    key: _shareKey,
                    child: RecordCard(level: s.level, score: s.score, streak: _ctrl.bestStreakThisGame, seed: _dailySeed, playerName: 'TÚ'),
                  ),
                ),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: AppTheme.accent, width: 1.5)), alignment: Alignment.center, child: const Text('💥', style: TextStyle(fontSize: 22))),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('GAME OVER', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Colors.white)),
                    if (isNewRecord) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(gradient: AppTheme.successGradient, borderRadius: BorderRadius.circular(20)), child: const Text('¡NUEVO RÉCORD!', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 9, letterSpacing: 1))),
                  ]),
                ]),
                if (_dailySeed != null) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.warning)), child: Text('SEED #$_dailySeed', style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w800, fontSize: 9))),
                const SizedBox(height: 4),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _goStat('NIVEL', '${s.level}', AppTheme.accent2),
                  Container(width: 1, height: 24, color: AppTheme.border),
                  _goStat('PUNTOS', '${s.score}', AppTheme.warning),
                  Container(width: 1, height: 24, color: AppTheme.border),
                  _goStat('RACHA', 'x${_ctrl.bestStreakThisGame}', AppTheme.accent3),
                ])),
                if (best != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text('Récord: ${best.bestScore} pts • Nivel ${best.bestLevel}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9))),
                if (_ghostBest != null) Padding(padding: const EdgeInsets.only(top: 1), child: Text('👻 Fantasma: Nvl ${_ghostBest!.level} • ${_ghostBest!.score} pts', style: const TextStyle(color: AppTheme.textMuted, fontSize: 8))),
                const SizedBox(height: 6),
                if (!_ctrl.hasUsedRewarded) GameButton(label: 'CONTINUAR VIENDO ANUNCIO', icon: Icons.play_circle_rounded, primary: false, onPressed: () async {
                  final wasReady = AdService().isRewardedReady;
                  final ok = await AdService().showRewarded(onRewarded: () {});
                  bool granted = ok || !wasReady;
                  if (!granted) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes ver el anuncio completo para continuar'))); return; }
                  if (granted) _ctrl.consumeRewardedContinue();
                }),
                if (!_ctrl.hasUsedRewarded) const SizedBox(height: 6),
                GameButton(label: 'JUGAR DE NUEVO', icon: Icons.replay_rounded, onPressed: () { setState(() { _eliminated = {}; _hintActive = false; }); _ctrl.startGame(); _runStart = DateTime.now(); }),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: GameButton(label: 'IMAGEN', icon: Icons.image_rounded, primary: false, dense: true, onPressed: () => ShareImageService.shareImage(_shareKey, level: s.level, score: s.score, extra: _dailySeed != null ? 'Seed #$_dailySeed' : null))),
                  const SizedBox(width: 6),
                  Expanded(child: GameButton(label: 'TEXTO', icon: Icons.share_rounded, primary: false, dense: true, onPressed: () => ShareImageService.shareText(level: s.level, score: s.score, seed: _dailySeed, streak: _ctrl.bestStreakThisGame))),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: GameButton(label: 'CLIP 3S', icon: Icons.videocam_rounded, primary: false, dense: true, onPressed: () => ShareImageService.shareImage(_shareKey, level: s.level, score: s.score, extra: 'Clip 1 Segundo'))),
                  const SizedBox(width: 6),
                  Expanded(child: GameButton(label: 'INICIO', icon: Icons.home_rounded, primary: false, dense: true, onPressed: () async {
                    final count = StorageService().gamesSinceInterstitial;
                    if (count >= 3) { final shown = await AdService().showInterstitialIfAvailable(); if (shown) await StorageService().resetInterstitialCounter(); }
                    if (context.mounted) Navigator.pop(context);
                  })),
                ]),
              ]),
            ),
          ),
        );
      });
    });
  }

  Widget _goStat(String label, String value, Color color) => Column(children: [Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: color)), const SizedBox(height: 4), Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w700))]);
}
