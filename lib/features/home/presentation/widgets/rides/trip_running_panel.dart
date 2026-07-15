import 'dart:ui';

import 'package:flutter/material.dart';

class TripRunningPanel extends StatelessWidget {
  const TripRunningPanel({
    super.key,
    required this.driverName,
    required this.destination,
    required this.price,
    required this.onChat,
  });

  final String driverName;
  final String destination;
  final double price;
  final VoidCallback onChat;

  static const Color avuxoGreen = Color(0xFF24F877);

  String get money {
    if (price.isNaN || price.isInfinite || price <= 0) {
      return 'Calculando';
    }

    return 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _safeText(String value, String fallback) {
    final clean = value.trim();

    if (clean.isEmpty ||
        clean.toLowerCase() == 'null' ||
        clean.toLowerCase() == 'undefined') {
      return fallback;
    }

    return clean;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    final safeDriver = _safeText(driverName, 'Motorista AVUXO');
    final safeDestination = _safeText(destination, 'Destino da corrida');

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom + 110,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18,
            sigmaY: 18,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1117).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: avuxoGreen.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: avuxoGreen.withValues(alpha: 0.08),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: avuxoGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Center(
                    child: Text(
                      'CORRIDA EM ANDAMENTO',
                      style: TextStyle(
                        color: avuxoGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: avuxoGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: avuxoGreen.withValues(alpha: 0.24),
                        ),
                      ),
                      child: const Icon(
                        Icons.directions_car_filled_rounded,
                        color: avuxoGreen,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Viagem em andamento',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            safeDriver,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.62),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      money,
                      style: const TextStyle(
                        color: avuxoGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white10,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: avuxoGreen,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          safeDestination,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: onChat,
                    icon: const Icon(
                      Icons.chat_rounded,
                      color: Colors.black,
                    ),
                    label: const Text(
                      'ABRIR CHAT',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: avuxoGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}