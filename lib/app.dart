import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/game_screen.dart';
import 'presentation/screens/how_to_play_screen.dart';
import 'presentation/screens/records_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/creator_screen.dart';

class UnSegundoApp extends StatelessWidget {
  const UnSegundoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1 Segundo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
        '/game': (_) => const GameScreen(),
        '/howto': (_) => const HowToPlayScreen(),
        '/records': (_) => const RecordsScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/creator': (_) => const CreatorScreen(),
        '/creator_list': (_) => const CreatorListScreen(),
      },
    );
  }
}
