import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../home/presentation/home_shell.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  static const Color avuxoGreen = Color(0xFF24F877);

  bool loading = false;
  bool _navigating = false;

  void _msg(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10151E),
        behavior: SnackBarBehavior.floating,
        content: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _goHome() async {
    if (_navigating || !mounted) return;

    _navigating = true;

    await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeShell(),
      ),
      (_) => false,
    );
  }

  Future<void> _allow() async {
    if (loading || _navigating) return;

    if (!mounted) return;

    setState(() => loading = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _msg('Ative a localização do celular para melhorar sua experiência.');
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _msg(
          'Permissão negada permanentemente. Você pode liberar depois nas configurações.',
        );
      }

      await _goHome();
    } catch (_) {
      await _goHome();
    } finally {
      if (mounted && !_navigating) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _skip() async {
    if (loading || _navigating) return;
    await _goHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF050807),
                    Color(0xFF0B1117),
                    Color(0xFF000000),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: RoutePainter(),
              ),
            ),
          ),
          Positioned(
            top: 110,
            right: 82,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: avuxoGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: avuxoGreen.withValues(alpha: 0.55),
                    blurRadius: 25,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.black,
                size: 14,
              ),
            ),
          ),
          Positioned(
            top: 230,
            left: 140,
            child: Transform.rotate(
              angle: -0.6,
              child: Container(
                width: 54,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF181818),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 10,
                    left: 20,
                    right: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/images/avuxo_logo.png',
                        width: 86,
                        errorBuilder: (_, __, ___) {
                          return const Text(
                            'AVUXO',
                            style: TextStyle(
                              color: avuxoGreen,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: loading || _navigating ? null : _skip,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(34),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 14,
                      sigmaY: 14,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        26,
                        30,
                        26,
                        34,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.74),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(34),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Permitir acesso à\nlocalização?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Precisamos da sua localização para encontrar motoristas próximos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.64),
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 30),
                          GestureDetector(
                            onTap: loading || _navigating ? null : _allow,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: loading
                                    ? avuxoGreen.withValues(alpha: 0.72)
                                    : avuxoGreen,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        avuxoGreen.withValues(alpha: 0.38),
                                    blurRadius: 30,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2.6,
                                        ),
                                      )
                                    : const Text(
                                        'PERMITIR',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: loading || _navigating ? null : _skip,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white12,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'AGORA NÃO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
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
        ],
      ),
    );
  }
}

class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = const Color(0xFF24F877).withValues(alpha: 0.20)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        14,
      );

    final linePaint = Paint()
      ..color = const Color(0xFF24F877)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    path.moveTo(
      size.width * 0.40,
      size.height * 0.58,
    );

    path.quadraticBezierTo(
      size.width * 0.50,
      size.height * 0.50,
      size.width * 0.62,
      size.height * 0.42,
    );

    path.quadraticBezierTo(
      size.width * 0.70,
      size.height * 0.34,
      size.width * 0.78,
      size.height * 0.24,
    );

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}