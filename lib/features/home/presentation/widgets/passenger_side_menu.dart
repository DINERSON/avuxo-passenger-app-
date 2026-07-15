import 'package:flutter/material.dart';

class PassengerSideMenu extends StatelessWidget {
  const PassengerSideMenu({
    super.key,
    required this.onActivity,
    required this.onWallet,
    required this.onPromotions,
    required this.onHelp,
    required this.onSettings,
    required this.onAccount,
    required this.onLogout,
  });

  final VoidCallback onActivity;
  final VoidCallback onWallet;
  final VoidCallback onPromotions;
  final VoidCallback onHelp;
  final VoidCallback onSettings;
  final VoidCallback onAccount;
  final VoidCallback onLogout;

  static const Color avuxoGreen = Color(0xFF24F877);

  void _closeAndRun(
    BuildContext context,
    VoidCallback action,
  ) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    Future.microtask(action);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0B1117),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: avuxoGreen.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVUXO',
                    style: TextStyle(
                      color: avuxoGreen,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Mobilidade Premium',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 20,
                ),
                children: [
                  _menuTile(
                    icon: Icons.home_rounded,
                    title: 'Início',
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  _menuTile(
                    icon: Icons.history_rounded,
                    title: 'Atividade',
                    onTap: () => _closeAndRun(context, onActivity),
                  ),
                  _menuTile(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Carteira',
                    onTap: () => _closeAndRun(context, onWallet),
                  ),
                  _menuTile(
                    icon: Icons.local_offer_rounded,
                    title: 'Promoções',
                    onTap: () => _closeAndRun(context, onPromotions),
                  ),
                  _menuTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Ajuda',
                    onTap: () => _closeAndRun(context, onHelp),
                  ),
                  _menuTile(
                    icon: Icons.settings_rounded,
                    title: 'Configurações',
                    onTap: () => _closeAndRun(context, onSettings),
                  ),
                  _menuTile(
                    icon: Icons.person_rounded,
                    title: 'Conta',
                    onTap: () => _closeAndRun(context, onAccount),
                  ),
                  const SizedBox(height: 20),
                  _menuTile(
                    icon: Icons.logout_rounded,
                    title: 'Sair',
                    color: Colors.redAccent,
                    onTap: () => _closeAndRun(context, onLogout),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: avuxoGreen.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            child: ListTile(
              leading: Icon(
                icon,
                color: color,
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ),
    );
  }
}