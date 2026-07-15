import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../home/presentation/home_shell.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  static const Color avuxoGreen = Color(0xFF24F877);

  bool _navigating = false;

  Future<void> _goHome() async {
    if (_navigating || !mounted) return;

    setState(() {
      _navigating = true;
    });

    await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeShell(),
      ),
      (_) => false,
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
              'assets/images/tutorial_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(color: Colors.black);
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            top: -120,
            right: -120,
            child: _glow(280, 0.22),
          ),
          Positioned(
            bottom: -140,
            left: -130,
            child: _glow(300, 0.20),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/avuxo_logo.png',
                    width: 160,
                    errorBuilder: (_, __, ___) {
                      return const Text(
                        'AVUXO',
                        style: TextStyle(
                          color: avuxoGreen,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(38),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 18,
                        sigmaY: 18,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.56),
                          borderRadius: BorderRadius.circular(38),
                          border: Border.all(
                            color: avuxoGreen.withValues(alpha: 0.22),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.55),
                              blurRadius: 45,
                              offset: const Offset(0, 22),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Como funciona\no ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      height: 1.08,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'AVUXO',
                                    style: TextStyle(
                                      color: avuxoGreen,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      height: 1.08,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Uma experiência premium de mobilidade urbana.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.68),
                                fontSize: 15,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 30),
                            _item(
                              icon: Icons.location_on_rounded,
                              title: 'Escolha seu destino',
                              subtitle: 'Digite para onde deseja ir.',
                            ),
                            _divider(),
                            _item(
                              icon: Icons.directions_car_rounded,
                              title: 'Motoristas próximos',
                              subtitle:
                                  'Encontramos rapidamente o melhor motorista.',
                            ),
                            _divider(),
                            _item(
                              icon: Icons.verified_user_rounded,
                              title: 'Viagem segura',
                              subtitle: 'Acompanhe tudo em tempo real.',
                            ),
                            const SizedBox(height: 30),
                            GestureDetector(
                              onTap: _navigating ? null : _goHome,
                              child: Container(
                                width: double.infinity,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: _navigating
                                      ? avuxoGreen.withValues(alpha: 0.72)
                                      : avuxoGreen,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          avuxoGreen.withValues(alpha: 0.48),
                                      blurRadius: 36,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _navigating
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 2.6,
                                          ),
                                        )
                                      : const Text(
                                          'ENTENDI',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: avuxoGreen.withValues(alpha: 0.13),
            border: Border.all(
              color: avuxoGreen.withValues(alpha: 0.32),
            ),
            boxShadow: [
              BoxShadow(
                color: avuxoGreen.withValues(alpha: 0.18),
                blurRadius: 24,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: avuxoGreen,
            size: 30,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 80, top: 18, bottom: 18),
      child: Container(
        height: 1,
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }

  Widget _glow(double size, double opacity) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 75,
        sigmaY: 75,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: avuxoGreen.withValues(alpha: opacity),
        ),
      ),
    );
  }
}