import 'package:flutter/material.dart';

import '../../../home/presentation/home_shell.dart';
import '../../../../core/storage/local_storage.dart';
import '../../services/auth_service.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Color neonGreen = Color(0xFF32FF7E);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
    _startFlow();
  }

  Future<void> _startFlow() async {
    if (_navigating) return;

    try {
      final saved = await AuthService.hasSavedSession();

      if (!saved) {
        await LocalStorage().clearAuth();
      }

      await Future.delayed(
        const Duration(milliseconds: 2200),
      );

      if (!mounted || _navigating) return;

      _navigating = true;

      await Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) {
            return saved ? const HomeShell() : const WelcomeScreen();
          },
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    } catch (_) {
      if (!mounted || _navigating) return;

      _navigating = true;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _splash(),
    );
  }

  Widget _splash() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/splash_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                color: Colors.black,
              );
            },
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ),
        Positioned(
          top: 120,
          left: 24,
          right: 24,
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: const Column(
                children: [
                  Text(
                    'AVUXO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 10,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'VÁ COM CONFIANÇA.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: neonGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 30,
          right: 30,
          bottom: 56,
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              children: [
                const Text(
                  'MOBILIDADE PREMIUM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: neonGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Conforto, segurança e tecnologia\nem cada viagem.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 2000),
                  builder: (context, value, _) {
                    return Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: neonGreen,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
