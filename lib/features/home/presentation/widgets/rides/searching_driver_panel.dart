import 'dart:ui';

import 'package:flutter/material.dart';

class SearchingDriverPanel extends StatefulWidget {
  const SearchingDriverPanel({
    super.key,
    required this.onCancel,
  });

  final VoidCallback onCancel;

  @override
  State<SearchingDriverPanel> createState() => _SearchingDriverPanelState();
}

class _SearchingDriverPanelState extends State<SearchingDriverPanel>
    with SingleTickerProviderStateMixin {
  static const Color avuxoGreen = Color(0xFF24F877);

  late final AnimationController controller;

  bool _cancelling = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    controller.stop();
    controller.dispose();
    super.dispose();
  }

  void _cancelRide() {
    if (_cancelling) return;

    setState(() {
      _cancelling = true;
    });

    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final height = MediaQuery.of(context).size.height;

    return Positioned(
      left: 14,
      right: 14,
      bottom: bottom + 18,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: height * 0.68,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 22,
              sigmaY: 22,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF071018).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: avuxoGreen.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: avuxoGreen.withValues(alpha: 0.08),
                      blurRadius: 34,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _radar(),
                    const SizedBox(height: 18),
                    const Text(
                      'Procurando motorista',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Estamos buscando um motorista perto de você.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(
                          child: _StepItem(
                            icon: Icons.location_on_outlined,
                            title: 'Buscando',
                          ),
                        ),
                        Expanded(
                          child: _StepItem(
                            icon: Icons.wifi_tethering_rounded,
                            title: 'Online',
                          ),
                        ),
                        Expanded(
                          child: _StepItem(
                            icon: Icons.person_search_rounded,
                            title: 'Motorista',
                          ),
                        ),
                        Expanded(
                          child: _StepItem(
                            icon: Icons.verified_user_outlined,
                            title: 'Seguro',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                      height: 1,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Tempo estimado',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '1 - 2 minutos',
                      style: TextStyle(
                        color: avuxoGreen,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _cancelling ? null : _cancelRide,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.redAccent,
                        ),
                        label: Text(
                          _cancelling
                              ? 'CANCELANDO...'
                              : 'CANCELAR CORRIDA',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: avuxoGreen,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Sua segurança é nossa prioridade',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.68),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
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
        ),
      ),
    );
  }

  Widget _radar() {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final value = controller.value;

        return SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.75 + (value * 0.45),
                child: Opacity(
                  opacity: 1 - value,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: avuxoGreen.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: avuxoGreen.withValues(alpha: 0.30),
                  ),
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avuxoGreen.withValues(alpha: 0.14),
                  border: Border.all(
                    color: avuxoGreen.withValues(alpha: 0.26),
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: avuxoGreen,
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.icon,
    required this.title,
  });

  static const Color avuxoGreen = Color(0xFF24F877);

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: avuxoGreen,
          size: 23,
        ),
        const SizedBox(height: 7),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 11,
            height: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}