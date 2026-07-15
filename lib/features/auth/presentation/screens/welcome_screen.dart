import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const Color neonGreen = Color(0xFF32FF7E);

  bool _navigating = false;

  Future<void> _openRegister() async {
    if (_navigating || !mounted) return;

    setState(() {
      _navigating = true;
    });

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  Future<void> _openLogin() async {
    if (_navigating || !mounted) return;

    setState(() {
      _navigating = true;
    });

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(color: Colors.black);
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          'AVUXO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 8,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'VÁ COM CONFIANÇA.',
                          style: TextStyle(
                            color: neonGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 38),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Mobilidade\n',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: 'inteligente\n',
                          style: TextStyle(
                            color: neonGreen,
                            fontSize: 34,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: 'para o seu\n',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: 'dia.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Conforto, segurança e\ntecnologia para te levar\nmais longe.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dot(true),
                      _dot(false),
                      _dot(false),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _navigating ? null : _openRegister,
                    child: Container(
                      height: 62,
                      decoration: BoxDecoration(
                        color: _navigating
                            ? neonGreen.withValues(alpha: 0.72)
                            : neonGreen,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: neonGreen.withValues(alpha: 0.28),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _navigating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'VAMOS COMEÇAR',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: _navigating ? null : _openLogin,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Já tem uma conta? ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.62),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const TextSpan(
                              text: 'Entrar',
                              style: TextStyle(
                                color: neonGreen,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _dot(bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: active ? 18 : 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? neonGreen : Colors.white38,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}