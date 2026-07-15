import 'package:flutter/material.dart';

class RideType {
  final String name;
  final IconData icon;
  final double multiplier;

  const RideType({
    required this.name,
    required this.icon,
    required this.multiplier,
  }) : assert(multiplier > 0);
}

const List<RideType> passengerRideTypes = [
  RideType(
    name: 'XMoto',
    icon: Icons.two_wheeler_rounded,
    multiplier: 0.75,
  ),
  RideType(
    name: 'XGo',
    icon: Icons.directions_car_filled_rounded,
    multiplier: 1.0,
  ),
  RideType(
    name: 'XComfort',
    icon: Icons.airline_seat_recline_extra_rounded,
    multiplier: 1.35,
  ),
  RideType(
    name: 'XBlack',
    icon: Icons.workspace_premium_rounded,
    multiplier: 1.75,
  ),
];