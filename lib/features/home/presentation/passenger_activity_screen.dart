import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PassengerActivityScreen extends StatefulWidget {
  const PassengerActivityScreen({super.key});

  @override
  State<PassengerActivityScreen> createState() =>
      _PassengerActivityScreenState();
}

class _PassengerActivityScreenState extends State<PassengerActivityScreen> {
  static const Color avuxoGreen = Color(0xFF24F877);

  static const String backendBaseUrl =
      'https://avuxo-backend-production.up.railway.app';

  bool loading = true;
  String error = '';

  List<Map<String, dynamic>> rides = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null || token.trim().isEmpty) {
        throw StateError('Sessão Firebase inválida.');
      }

      final response = await http
          .get(
            Uri.parse('$backendBaseUrl/ride/history'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${token.trim()}',
            },
          )
          .timeout(
            const Duration(seconds: 8),
          );

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          loading = false;
          error = 'Erro ao carregar histórico.';
        });
        return;
      }

      final data = jsonDecode(response.body);

      dynamic list;

      if (data is Map) {
        list = data['rides'] ?? data['history'] ?? data['data'];
      } else {
        list = data;
      }

      if (list is! List) {
        setState(() {
          rides = [];
          loading = false;
        });
        return;
      }

      final parsed = list
          .whereType<Map>()
          .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e),
          )
          .toList();

      parsed.sort((a, b) {
        final ad = DateTime.tryParse(
              '${a['finishedAt'] ?? a['completedAt'] ?? a['updatedAt'] ?? a['createdAt'] ?? ''}',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final bd = DateTime.tryParse(
              '${b['finishedAt'] ?? b['completedAt'] ?? b['updatedAt'] ?? b['createdAt'] ?? ''}',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return bd.compareTo(ad);
      });

      if (!mounted) return;

      setState(() {
        rides = parsed;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Sem conexão com o backend.';
      });
    }
  }

  String _money(dynamic value) {
    final parsed = double.tryParse('$value') ?? 0;

    if (parsed <= 0 || parsed.isNaN || parsed.isInfinite) {
      return 'R\$ 0,00';
    }

    return 'R\$ ${parsed.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _text(dynamic value, String fallback) {
    final text = '$value'.trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null' ||
        text.toLowerCase() == 'undefined') {
      return fallback;
    }

    return text;
  }

  String _date(dynamic value) {
    final raw = '$value'.trim();

    if (raw.isEmpty ||
        raw.toLowerCase() == 'null' ||
        raw.toLowerCase() == 'undefined') {
      return 'Data não informada';
    }

    try {
      final date = DateTime.parse(raw).toLocal();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year às $hour:$minute';
    } catch (_) {
      return raw;
    }
  }

  String _origin(Map<String, dynamic> ride) {
    return _text(
      ride['originName'] ??
          ride['pickupAddress'] ??
          ride['origin'] ??
          ride['from'],
      'Origem não informada',
    );
  }

  String _destination(Map<String, dynamic> ride) {
    return _text(
      ride['destinationName'] ??
          ride['destinationAddress'] ??
          ride['destinationLabel'] ??
          ride['destination'] ??
          ride['to'],
      'Destino não informado',
    );
  }

  String _driverName(Map<String, dynamic> ride) {
    final driver = ride['driver'];

    if (driver is Map) {
      return _text(
        driver['name'] ?? driver['fullName'] ?? driver['driverName'],
        'Motorista AVUXO',
      );
    }

    return 'Motorista AVUXO';
  }

  String _rideStatus(Map<String, dynamic> ride) {
    final status = _text(
      ride['status'],
      'finished',
    );

    if (status == 'finished' || status == 'completed') {
      return 'Finalizada';
    }

    if (status == 'cancelled' || status == 'canceled') {
      return 'Cancelada';
    }

    return status;
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();

    if (s.contains('cancel')) {
      return Colors.redAccent;
    }

    return avuxoGreen;
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1117),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: avuxoGreen.withValues(alpha: 0.15),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.history_rounded,
            color: avuxoGreen,
            size: 34,
          ),
          SizedBox(height: 16),
          Text(
            'Histórico de corridas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Suas corridas realizadas aparecerão aqui.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rideCard(Map<String, dynamic> ride) {
    final status = _rideStatus(ride);

    final date = _date(
      ride['finishedAt'] ??
          ride['completedAt'] ??
          ride['updatedAt'] ??
          ride['createdAt'] ??
          ride['requestedAt'],
    );

    final price = _money(
      ride['price'] ?? ride['fare'] ?? ride['total'],
    );

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: avuxoGreen,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  date,
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
                price,
                style: const TextStyle(
                  color: avuxoGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _line(Icons.my_location_rounded, _origin(ride)),
          const SizedBox(height: 8),
          _line(Icons.location_on_rounded, _destination(ride)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _pill(
                  Icons.person_rounded,
                  _driverName(ride),
                  Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              _pill(
                Icons.check_circle_rounded,
                status,
                _statusColor(status),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: avuxoGreen,
          size: 18,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill(
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyActivityCard() {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            color: Colors.white54,
            size: 46,
          ),
          SizedBox(height: 14),
          Text(
            'Nenhuma corrida ainda',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Quando você finalizar uma corrida, ela aparecerá nesta tela.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: avuxoGreen,
        ),
      );
    }

    if (error.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header(),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.redAccent,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: loading ? null : _loadHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: avuxoGreen,
                  ),
                  child: const Text(
                    'TENTAR NOVAMENTE',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: avuxoGreen,
      backgroundColor: const Color(0xFF0B1117),
      onRefresh: _loadHistory,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header(),
          if (rides.isEmpty)
            _emptyActivityCard()
          else
            ...rides.map(_rideCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02040A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF02040A),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Atividade',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loading ? null : _loadHistory,
            icon: const Icon(
              Icons.refresh_rounded,
              color: avuxoGreen,
            ),
          ),
        ],
      ),
      body: _body(),
    );
  }
}
