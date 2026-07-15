import 'dart:ui';

import 'package:flutter/material.dart';

class TopStatusBar extends StatelessWidget {
  const TopStatusBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onLocate,
    required this.onMenu,
    required this.onNotifications,
  });

  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback onLocate;
  final VoidCallback onMenu;
  final VoidCallback onNotifications;

  static const Color avuxoGreen = Color(0xFF24F877);

  String _safeText(
    String value,
    String fallback,
  ) {
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
    final top = MediaQuery.of(context).padding.top;

    final safeTitle = _safeText(
      title,
      'Passageiro',
    );

    final safeSubtitle = _safeText(
      subtitle,
      'Carregando localização...',
    );

    return Positioned(
      top: top + 12,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18,
            sigmaY: 18,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1117).withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: avuxoGreen.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: avuxoGreen.withValues(alpha: 0.10),
                  blurRadius: 30,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                _IconButtonGlass(
                  icon: Icons.menu_rounded,
                  onTap: onMenu,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AVUXO',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: avuxoGreen,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        safeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        safeSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _IconButtonGlass(
                  icon: Icons.notifications_none_rounded,
                  onTap: onNotifications,
                ),
                const SizedBox(width: 10),
                IgnorePointer(
                  ignoring: loading,
                  child: GestureDetector(
                    onTap: onLocate,
                    child: AnimatedOpacity(
                      duration: const Duration(
                        milliseconds: 180,
                      ),
                      opacity: loading ? 0.72 : 1,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: avuxoGreen,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: avuxoGreen.withValues(alpha: 0.35),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: loading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Icon(
                                Icons.my_location_rounded,
                                color: Colors.black,
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
    );
  }
}

class _IconButtonGlass extends StatelessWidget {
  const _IconButtonGlass({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  static const Color avuxoGreen = Color(0xFF24F877);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: avuxoGreen.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 23,
          ),
        ),
      ),
    );
  }
}