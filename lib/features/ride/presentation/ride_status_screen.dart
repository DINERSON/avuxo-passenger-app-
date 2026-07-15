import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/providers/app_providers.dart';
import '../domain/ride_models.dart';
import 'rating_screen.dart';

class RideStatusScreen extends ConsumerStatefulWidget {
  const RideStatusScreen({
    super.key,
    required this.rideId,
  });

  final String rideId;

  @override
  ConsumerState<RideStatusScreen> createState() =>
      _RideStatusScreenState();
}

class _RideStatusScreenState
    extends ConsumerState<RideStatusScreen> {
  bool _ratingOpened = false;

  @override
  Widget build(BuildContext context) {
    final rideId = widget.rideId.trim();

    if (rideId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Corrida inválida.',
          ),
        ),
      );
    }

    final asyncRide =
        ref.watch(rideStatusStreamProvider(rideId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Status da corrida',
        ),
      ),
      body: asyncRide.when(
        data: (ride) {
          if (ride.status == RideStatus.completed &&
              !_ratingOpened) {
            _ratingOpened = true;

            WidgetsBinding.instance
                .addPostFrameCallback((_) {
              if (!mounted) return;

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) =>
                      RatingScreen(
                    rideId: ride.id,
                  ),
                ),
              );
            });
          }

          if (ride.status ==
              RideStatus.cancelled) {
            return const Center(
              child: Text(
                'Corrida cancelada.',
              ),
            );
          }

          return _RideStatusBody(
            ride: ride,
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (_, __) => Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                ),
                const SizedBox(
                  height: 12,
                ),
                const Text(
                  'Não foi possível atualizar a corrida.',
                  textAlign:
                      TextAlign.center,
                ),
                const SizedBox(
                  height: 12,
                ),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(
                      rideStatusStreamProvider(
                        rideId,
                      ),
                    );
                  },
                  child: const Text(
                    'Tentar novamente',
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

class _RideStatusBody
    extends StatelessWidget {
  const _RideStatusBody({
    required this.ride,
  });

  final Ride ride;

  String get _label {
    switch (ride.status) {
      case RideStatus.findingDriver:
        return 'Procurando motorista';

      case RideStatus.assigned:
        return 'Motorista designado';

      case RideStatus.driverArriving:
        return 'Motorista a caminho';

      case RideStatus.inProgress:
        return 'Viagem em andamento';

      case RideStatus.completed:
        return 'Viagem concluída';

      case RideStatus.cancelled:
        return 'Corrida cancelada';

      default:
        return 'Aguardando';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickupValid =
        ride.pickup.lat != 0 &&
            ride.pickup.lng != 0;

    final destinationValid =
        ride.destination.lat != 0 &&
            ride.destination.lng != 0;

    return Column(
      children: [
        Expanded(
          child: pickupValid
              ? GoogleMap(
                  initialCameraPosition:
                      CameraPosition(
                    target: LatLng(
                      ride.pickup.lat,
                      ride.pickup.lng,
                    ),
                    zoom: 13,
                  ),
                  markers: {
                    Marker(
                      markerId:
                          const MarkerId(
                        'pickup',
                      ),
                      position: LatLng(
                        ride.pickup.lat,
                        ride.pickup.lng,
                      ),
                    ),
                    if (destinationValid)
                      Marker(
                        markerId:
                            const MarkerId(
                          'destination',
                        ),
                        position:
                            LatLng(
                          ride.destination.lat,
                          ride.destination.lng,
                        ),
                      ),
                  },
                )
              : const Center(
                  child: Text(
                    'Mapa indisponível',
                  ),
                ),
        ),
        Padding(
          padding:
              const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                14,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    _label,
                    style: Theme.of(
                      context,
                    )
                        .textTheme
                        .titleLarge,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    'Tarifa: R\$ ${ride.fare.toStringAsFixed(2)}',
                  ),
                  if (ride.driver !=
                      null) ...[
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      'Motorista: ${ride.driver!.name}',
                    ),
                    Text(
                      'Carro: ${ride.driver!.carModel ?? "-"}',
                    ),
                    Text(
                      'Placa: ${ride.driver!.plate ?? "-"}',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}