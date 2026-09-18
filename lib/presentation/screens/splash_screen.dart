import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.85, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _c.forward();
    Timer(const Duration(milliseconds: 1600), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.35), blurRadius: 30, offset: const Offset(0, 10))],
                    ),
                    alignment: Alignment.center,
                    child: const Text('1"', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(height: 24),
                  const Text('1 SEGUNDO', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('¿Puedes recordarlo?', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, letterSpacing: 0.5)),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.accent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
