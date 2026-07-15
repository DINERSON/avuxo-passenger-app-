import 'package:flutter/material.dart';

class PassengerWalletScreen extends StatefulWidget {
  const PassengerWalletScreen({super.key});

  @override
  State<PassengerWalletScreen> createState() =>
      _PassengerWalletScreenState();
}

class _PassengerWalletScreenState extends State<PassengerWalletScreen> {
  static const Color avuxoGreen = Color(0xFF24F877);

  double balance = 0;
  bool loading = false;

  String get money {
    if (balance.isNaN || balance.isInfinite) {
      return 'R\$ 0,00';
    }

    return 'R\$ ${balance.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  void _showComingSoon(String title) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0B1117),
        behavior: SnackBarBehavior.floating,
        content: Text(
          '$title será ativado em breve.',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Future<void> _refreshWallet() async {
    if (loading || !mounted) return;

    setState(() {
      loading = true;
    });

    try {
      await Future.delayed(
        const Duration(milliseconds: 450),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
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
          'Carteira',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loading ? null : _refreshWallet,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: avuxoGreen,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: avuxoGreen,
                  ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: avuxoGreen,
        backgroundColor: const Color(0xFF0B1117),
        onRefresh: _refreshWallet,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1117),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: avuxoGreen.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: avuxoGreen.withValues(alpha: 0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo AVUXO',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    money,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use sua carteira para acompanhar pagamentos e promoções.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _WalletButton(
              icon: Icons.pix,
              title: 'Adicionar saldo',
              subtitle: 'Recarregar com PIX',
              onTap: () => _showComingSoon('Adicionar saldo'),
            ),
            const SizedBox(height: 12),
            _WalletButton(
              icon: Icons.credit_card_rounded,
              title: 'Cartões cadastrados',
              subtitle: 'Gerenciar cartões',
              onTap: () => _showComingSoon('Cartões cadastrados'),
            ),
            const SizedBox(height: 12),
            _WalletButton(
              icon: Icons.receipt_long_rounded,
              title: 'Histórico financeiro',
              subtitle: 'Ver entradas e saídas',
              onTap: () => _showComingSoon('Histórico financeiro'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletButton extends StatelessWidget {
  const _WalletButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const Color avuxoGreen = Color(0xFF24F877);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 72,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: ListTile(
            leading: Icon(
              icon,
              color: avuxoGreen,
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}