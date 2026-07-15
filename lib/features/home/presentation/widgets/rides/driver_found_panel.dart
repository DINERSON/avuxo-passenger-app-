import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';

class DriverFoundPanel extends StatelessWidget {
  const DriverFoundPanel({
    super.key,
    required this.driverName,
    required this.driverVehicle,
    required this.driverPlate,
    required this.driverPhoto,
    required this.vehiclePhoto,
    required this.onChat,
    required this.onCancel,
    this.driverRating = '5.0',
    this.driverEta = 'Chegando em instantes',
  });

  final String driverName;
  final String driverVehicle;
  final String driverPlate;
  final String driverPhoto;
  final String vehiclePhoto;
  final VoidCallback onChat;
  final VoidCallback onCancel;
  final String driverRating;
  final String driverEta;

  static const Color avuxoGreen = Color(0xFF24F877);

  ImageProvider? _imageFromString(String value) {
    final photo = value.trim();

    if (photo.isEmpty || photo == 'null' || photo == 'undefined') {
      return null;
    }

    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return NetworkImage(photo);
    }

    try {
      final cleanBase64 = photo.contains(',') ? photo.split(',').last : photo;

      if (cleanBase64.length > 3000000) {
        return null;
      }

      final bytes = base64Decode(cleanBase64);

      if (bytes.isEmpty) return null;

      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
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

  String _safeRating(String value) {
    final clean = value.trim();

    final parsed = double.tryParse(clean);

    if (parsed == null || parsed <= 0) {
      return '5.0';
    }

    return parsed.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    final safeName = _safeText(driverName, 'Motorista AVUXO');
    final safeVehicle = _safeText(driverVehicle, 'Veículo não informado');
    final safePlate =
        _safeText(driverPlate, 'Placa não informada').toUpperCase();
    final safeEta = _safeText(driverEta, 'Chegando em instantes');
    final safeRating = _safeRating(driverRating);

    final driverImage = _imageFromString(driverPhoto);
    final carImage = _imageFromString(vehiclePhoto);

    return Positioned(
      left: 12,
      right: 12,
      bottom: bottom + 36,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 20,
            sigmaY: 20,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1117).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: avuxoGreen.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: avuxoGreen.withValues(alpha: 0.10),
                  blurRadius: 34,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '✓ MOTORISTA ACEITOU SUA CORRIDA',
                        style: TextStyle(
                          color: avuxoGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: avuxoGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: avuxoGreen.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: avuxoGreen,
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            safeRating,
                            style: const TextStyle(
                              color: avuxoGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: avuxoGreen,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: avuxoGreen.withValues(alpha: 0.22),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor:
                                avuxoGreen.withValues(alpha: 0.14),
                            backgroundImage: driverImage,
                            child: driverImage == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    color: avuxoGreen,
                                    size: 38,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 86,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            image: carImage == null
                                ? null
                                : DecorationImage(
                                    image: carImage,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          child: carImage == null
                              ? const Icon(
                                  Icons.directions_car_rounded,
                                  color: avuxoGreen,
                                  size: 30,
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            safeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _InfoLine(
                            icon: Icons.directions_car_filled_rounded,
                            text: safeVehicle,
                          ),
                          const SizedBox(height: 8),
                          _InfoLine(
                            icon: Icons.confirmation_number_rounded,
                            text: safePlate,
                            highlight: true,
                          ),
                          const SizedBox(height: 8),
                          _InfoLine(
                            icon: Icons.schedule_rounded,
                            text: safeEta,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.055),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: const Text(
                              'O motorista está a caminho do seu local.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onChat,
                        icon: const Icon(
                          Icons.chat_rounded,
                          color: Colors.black,
                        ),
                        label: const Text(
                          'CHAT',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: avuxoGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          fixedSize: const Size.fromHeight(56),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'CANCELAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          fixedSize: const Size.fromHeight(56),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
    this.highlight = false,
  });

  final IconData icon;
  final String text;
  final bool highlight;

  static const Color avuxoGreen = Color(0xFF24F877);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: highlight ? avuxoGreen : Colors.white54,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlight
                  ? avuxoGreen
                  : Colors.white.withValues(alpha: 0.76),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}