// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import 'language_selection_screen.dart';
import 'login_screen.dart';
import 'home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.repeat(reverse: true);

    // Navigate to appropriate screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final languageService = Provider.of<LanguageService>(
          context,
          listen: false,
        );

        if (languageService.isFirstRun) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LanguageSelectionScreen(),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Icon(
                Icons.eco_rounded,
                color: Color(0xFF2D6A4F),
                size: 100,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n('app_title'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D6A4F),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n('welcome_desc'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
