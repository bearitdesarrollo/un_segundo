import 'package:flutter/material.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  // AdMob init with graceful failure offline
  try {
    await AdService().initialize();
  } catch (_) {}
  // Notifs local diaria 10:20
  try {
    await NotificationService().init();
    await NotificationService().scheduleDailyReminder(hour: 10, minute: 20);
  } catch (_) {}
  runApp(const UnSegundoApp());
}
