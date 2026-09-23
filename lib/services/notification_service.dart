import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Mexico_City'));
    } catch (_) {
      // fallback to UTC if not found
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings, onDidReceiveNotificationResponse: (r) {
      if (kDebugMode) print('[Notifs] tap ${r.payload}');
    });

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    }
    _initialized = true;
    if (kDebugMode) print('[Notifs] initialized');
  }

  Future<void> scheduleDailyReminder({int hour = 10, int minute = 20}) async {
    if (!_initialized) await init();
    await cancelDailyReminder();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Recordatorio diario',
      channelDescription: 'Te recuerda volver a jugar 1 Segundo',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      1001,
      '🧠 ¡Tu SEED diario te espera!',
      '¿Puedes superar tu récord en 1 SEGUNDO? ¡Juega ahora!',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repite diario
      payload: 'daily',
    );
    if (kDebugMode) print('[Notifs] daily scheduled $hour:$minute -> $scheduled');
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(1001);
  }

  Future<void> showTestNow() async {
    if (!_initialized) await init();
    const androidDetails = AndroidNotificationDetails('test', 'Test', importance: Importance.high, priority: Priority.high);
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(1002, '🔥 ¡Prueba 1 SEGUNDO!', 'Notificación local funcionando', details);
  }
}
