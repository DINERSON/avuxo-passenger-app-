import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PassengerPromotionsScreen extends StatefulWidget {
  const PassengerPromotionsScreen({super.key});

  @override
  State<PassengerPromotionsScreen> createState() =>
      _PassengerPromotionsScreenState();
}

class _PassengerPromotionsScreenState
    extends State<PassengerPromotionsScreen> {
  static const Color avuxoGreen = Color(0xFF24F877);

  static const String backendBaseUrl =
      'https://avuxo-backend-production.up.railway.app';

  static const String raffleCity = 'pimenta_bueno';

  final TextEditingController codeController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

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

  Future<void> _enterDailyRaffle() async {
    if (loading) return;

    final code = codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      _showMessage('Digite o código do sorteio.');
      return;
    }

    if (code.length < 4) {
      _showMessage('Código inválido.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Faça login para participar do sorteio.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$backendBaseUrl/promotions/raffle/enter'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'userId': user.uid,
              'passengerId': user.uid,
              'city': raffleCity,
              'code': code,
              'userName': user.displayName ?? 'Passageiro AVUXO',
              'email': user.email ?? '',
              'phone': user.phoneNumber ?? '',
              'platform': 'passenger_app',
            }),
          )
          .timeout(
            const Duration(seconds: 8),
          );

      if (!mounted) return;

      Map<String, dynamic> data = <String, dynamic>{};

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}

      final message = data['message']?.toString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showMessage(
          message ?? 'Você está participando do sorteio AVUXO!',
        );

        codeController.clear();
      } else if (response.statusCode == 404) {
        _showMessage(
          'Sorteio ainda não está ativo no backend.',
        );
      } else if (response.statusCode == 409) {
        _showMessage(
          message ?? 'Você já participou deste sorteio.',
        );
      } else {
        _showMessage(
          message ?? 'Não foi possível participar do sorteio.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Erro de conexão. Tente novamente.',
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1117),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: avuxoGreen.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: avuxoGreen.withValues(alpha: 0.08),
            blurRadius: 28,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.celebration_rounded,
            color: avuxoGreen,
            size: 54,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sorteio AVUXO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Digite o código divulgado pela AVUXO para participar do sorteio em Pimenta Bueno.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeInput() {
    return TextField(
      controller: codeController,
      enabled: !loading,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
      decoration: InputDecoration(
        hintText: 'DIGITE O CÓDIGO',
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.32),
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
        prefixIcon: const Icon(
          Icons.confirmation_number_rounded,
          color: avuxoGreen,
        ),
        filled: true,
        fillColor: const Color(0xFF0B1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: avuxoGreen.withValues(alpha: 0.14),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: avuxoGreen.withValues(alpha: 0.14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: avuxoGreen,
            width: 1.4,
          ),
        ),
      ),
      onSubmitted: (_) => _enterDailyRaffle(),
    );
  }

  Widget _rulesCard() {
    return Container(
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
          _rule('É necessário estar cadastrado e logado no AVUXO.'),
          _rule('Cada usuário participa apenas uma vez por código.'),
          _rule('O código precisa estar ativo para a cidade.'),
          _rule('O ganhador será divulgado pela AVUXO.'),
        ],
      ),
    );
  }

  Widget _rule(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: avuxoGreen,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
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
          'Promoções',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _infoCard(),
          const SizedBox(height: 22),
          _codeInput(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: loading ? null : _enterDailyRaffle,
              style: ElevatedButton.styleFrom(
                backgroundColor: avuxoGreen,
                disabledBackgroundColor:
                    avuxoGreen.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'PARTICIPAR DO SORTEIO',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 22),
          _rulesCard(),
        ],
      ),
    );
  }
}