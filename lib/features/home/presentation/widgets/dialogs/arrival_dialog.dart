import 'package:flutter/material.dart';

class ArrivalDialog extends StatelessWidget {
  const ArrivalDialog({
    super.key,
    required this.driverName,
  });

  final String driverName;

  static const Color avuxoGreen = Color(0xFF24F877);

  @override
  Widget build(BuildContext context) {
    final safeDriverName =
        driverName.trim().isEmpty ? 'seu motorista' : driverName.trim();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1117),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: avuxoGreen.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: avuxoGreen.withValues(alpha: 0.16),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avuxoGreen.withValues(alpha: 0.10),
                border: Border.all(color: avuxoGreen),
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                color: avuxoGreen,
                size: 42,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Seu motorista chegou',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Encontre $safeDriverName próximo ao local de embarque.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: avuxoGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'ENTENDI',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}