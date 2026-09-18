import 'package:flutter/material.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  // AdMob init with graceful failure offline
  try {
    await AdService().initialize();
  } catch (_) {}
  runApp(const UnSegundoApp());
}
