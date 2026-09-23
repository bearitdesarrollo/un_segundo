import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sound = true;
  bool _haptics = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await StorageService().init();
    setState(() {
      _sound = StorageService().soundEnabled;
      _haptics = StorageService().hapticsEnabled;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context)),
          title: const Text('Ajustes',
              style: TextStyle(fontWeight: FontWeight.w800))),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accent))
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _tile('🔊 Sonido', 'Efectos sonoros (próximamente)', _sound,
                      (v) async {
                    await StorageService().setSoundEnabled(v);
                    setState(() => _sound = v);
                  }),
                  _tile('📳 Vibración', 'Feedback háptico al acierto/error',
                      _haptics, (v) async {
                    await StorageService().setHapticsEnabled(v);
                    setState(() => _haptics = v);
                  }),
                  _tile('🔔 Recordatorio', 'Notificación diaria 10:20', true,
                      (v) async {
                    if (v) {
                      await NotificationService()
                          .scheduleDailyReminder(hour: 10, minute: 20);
                    } else {
                      await NotificationService().cancelDailyReminder();
                    }
                  }),
                  ListTile(
                    title: const Text('Probar notificación',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                    trailing: IconButton(
                        icon: const Icon(Icons.notifications_active,
                            color: AppTheme.accent),
                        onPressed: () => NotificationService().showTestNow()),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(16)),
                    child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('1 SEGUNDO v1.0.0',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 6),
                          Text(
                              'Juego de memoria visual. Sin registro, sin internet (excepto anuncios). Hecho con Flutter.',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  height: 1.5)),
                        ]),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _tile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        activeColor: AppTheme.accent,
      ),
    );
  }
}
