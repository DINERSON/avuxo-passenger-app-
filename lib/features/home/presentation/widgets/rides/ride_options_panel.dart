import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../models/ride_type.dart';

class RideOptionsPanel extends StatefulWidget {
  const RideOptionsPanel({
    super.key,
    required this.rideTypes,
    required this.selectedRide,
    required this.distanceText,
    required this.eta,
    required this.price,
    required this.loadingRoute,
    required this.requestingRide,
    required this.onChangeRide,
    required this.onRequestRide,
    required this.onOpenSearch,
  });

  final List<RideType> rideTypes;
  final int selectedRide;
  final String distanceText;
  final String eta;
  final double price;
  final bool loadingRoute;
  final bool requestingRide;
  final void Function(int index) onChangeRide;
  final VoidCallback onRequestRide;
  final VoidCallback onOpenSearch;

  @override
  State<RideOptionsPanel> createState() => _RideOptionsPanelState();
}

class _RideOptionsPanelState extends State<RideOptionsPanel> {
  static const Color avuxoGreen = Color(0xFF24F877);

  bool compact = false;

  String _money(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _ridePrice(int index) {
    if (widget.price <= 0 || widget.rideTypes.isEmpty) {
      return '--';
    }

    if (index < 0 || index >= widget.rideTypes.length) {
      return '--';
    }

    final selectedIndex =
        widget.selectedRide >= 0 && widget.selectedRide < widget.rideTypes.length
            ? widget.selectedRide
            : 0;

    final selectedMultiplier = widget.rideTypes[selectedIndex].multiplier;
    final targetMultiplier = widget.rideTypes[index].multiplier;

    if (selectedMultiplier <= 0 || targetMultiplier <= 0) {
      return _money(widget.price);
    }

    final basePrice = widget.price / selectedMultiplier;

    return _money(basePrice * targetMultiplier);
  }

  void _togglePanel() {
    setState(() {
      compact = !compact;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      left: 8,
      right: 8,
      bottom: bottom + 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 20,
            sigmaY: 20,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: BoxDecoration(
              color: const Color(0xFF071014).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: avuxoGreen.withValues(alpha: 0.24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.60),
                  blurRadius: 35,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: avuxoGreen.withValues(alpha: 0.10),
                  blurRadius: 34,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dragHeader(),
                const SizedBox(height: 8),
                _searchBox(),
                const SizedBox(height: 10),
                if (!compact) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _miniInfo(
                          title: 'Distância',
                          value: widget.distanceText == '--'
                              ? '--'
                              : widget.distanceText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _miniInfo(
                          title: 'Tempo',
                          value: widget.eta == '--' ? '--' : widget.eta,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _miniInfo(
                          title: 'Preço',
                          value: widget.price <= 0
                              ? '--'
                              : _money(widget.price),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ridesScrollableList(),
                  const SizedBox(height: 8),
                ],
                _requestButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dragHeader() {
    return GestureDetector(
      onTap: _togglePanel,
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                compact
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: avuxoGreen,
                size: 25,
              ),
              const SizedBox(width: 4),
              Text(
                compact ? 'Subir painel' : 'Abaixar painel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.56),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ridesScrollableList() {
    if (widget.rideTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 128,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.rideTypes.length,
        itemBuilder: (context, index) {
          if (index < 0 || index >= widget.rideTypes.length) {
            return const SizedBox.shrink();
          }

          final ride = widget.rideTypes[index];
          final selected = widget.selectedRide == index;

          return _rideCard(
            index: index,
            ride: ride,
            selected: selected,
          );
        },
      ),
    );
  }

  Widget _searchBox() {
    return GestureDetector(
      onTap: widget.onOpenSearch,
      child: Container(
        height: compact ? 50 : 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: avuxoGreen,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Para onde você vai?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              color: Colors.white.withValues(alpha: 0.34),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rideCard({
    required int index,
    required RideType ride,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () {
        if (index < 0 || index >= widget.rideTypes.length) {
          return;
        }

        widget.onChangeRide(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? avuxoGreen.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? avuxoGreen.withValues(alpha: 0.70)
                : Colors.white.withValues(alpha: 0.10),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? avuxoGreen : const Color(0xFF07131A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                ride.icon,
                color: selected ? Colors.black : avuxoGreen,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ride.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              _ridePrice(index),
              style: TextStyle(
                color: selected
                    ? avuxoGreen
                    : Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestButton() {
    final disabled = widget.loadingRoute ||
        widget.requestingRide ||
        widget.price <= 0 ||
        widget.rideTypes.isEmpty;

    return SizedBox(
      width: double.infinity,
      height: compact ? 50 : 52,
      child: ElevatedButton(
        onPressed: disabled ? null : widget.onRequestRide,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: avuxoGreen,
          disabledBackgroundColor: avuxoGreen.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: widget.requestingRide
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2.6,
                ),
              )
            : const Text(
                'SOLICITAR CORRIDA',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.6,
                ),
              ),
      ),
    );
  }

  Widget _miniInfo({
    required String title,
    required String value,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}