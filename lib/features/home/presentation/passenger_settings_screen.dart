import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class PassengerSettingsScreen extends StatefulWidget {
  const PassengerSettingsScreen({super.key});

  @override
  State<PassengerSettingsScreen> createState() =>
      _PassengerSettingsScreenState();
}

class _PassengerSettingsScreenState extends State<PassengerSettingsScreen> {
  static const Color avuxoGreen = Color(0xFF24F877);

  bool notifications = true;
  bool darkMode = true;
  bool locationEnabled = true;

  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0B1117),
        behavior: SnackBarBehavior.floating,
        content: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Future<void> _handleLocation(bool value) async {
    if (!mounted) return;

    setState(() {
      locationEnabled = value;
    });

    if (!value) {
      _showMessage(
        'Para desativar totalmente, altere a permissão nas configurações do celular.',
      );
      return;
    }

    try {
      final permission = await Geolocator.checkPermission();

      if (!mounted) return;

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.openLocationSettings();
        return;
      }

      _showMessage('Localização já está ativa.');
    } catch (_) {
      _showMessage(
        'Não foi possível verificar a localização.',
      );
    }
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
          'Configurações',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _switchTile(
            title: 'Notificações',
            subtitle: 'Receber alertas de corridas',
            value: notifications,
            onChanged: (v) {
              setState(() {
                notifications = v;
              });

              _showMessage(
                v
                    ? 'Notificações ativadas.'
                    : 'Notificações desativadas.',
              );
            },
          ),
          const SizedBox(height: 12),
          _switchTile(
            title: 'Modo escuro',
            subtitle: 'Tema premium AVUXO',
            value: darkMode,
            onChanged: (_) {
              setState(() {
                darkMode = true;
              });

              _showMessage(
                'O AVUXO utiliza tema escuro premium por padrão.',
              );
            },
          ),
          const SizedBox(height: 12),
          _switchTile(
            title: 'Localização',
            subtitle: 'Permitir acesso à localização',
            value: locationEnabled,
            onChanged: _handleLocation,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1117),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: avuxoGreen.withValues(alpha: 0.10),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Versão do aplicativo',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'AVUXO v1.0.0',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1117),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: avuxoGreen.withValues(alpha: 0.08),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: avuxoGreen,
        activeTrackColor: avuxoGreen.withValues(alpha: 0.28),
        inactiveThumbColor: Colors.white70,
        inactiveTrackColor: Colors.white24,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
          ),
        ),
      ),
    );
  }
}