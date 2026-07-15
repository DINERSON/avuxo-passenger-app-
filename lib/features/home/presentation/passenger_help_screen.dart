import 'package:flutter/material.dart';

class PassengerHelpScreen extends StatelessWidget {
  const PassengerHelpScreen({super.key});

  static const Color avuxoGreen = Color(0xFF24F877);

  void _showInfo(
    BuildContext context,
    String title,
    String message,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF0B1117),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.support_agent_rounded,
                  color: avuxoGreen,
                  size: 42,
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: avuxoGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'ENTENDI',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          'Ajuda',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _helpItem(
            context: context,
            icon: Icons.chat_rounded,
            title: 'Falar com suporte',
            subtitle: 'Entre em contato com a equipe AVUXO.',
            message:
                'O suporte direto será conectado em breve. Por enquanto, você pode relatar problemas pelo painel de ajuda do aplicativo.',
          ),
          const SizedBox(height: 14),
          _helpItem(
            context: context,
            icon: Icons.help_outline_rounded,
            title: 'Perguntas frequentes',
            subtitle: 'Dúvidas comuns dos passageiros.',
            message:
                'Aqui ficarão as principais dúvidas sobre corrida, pagamento, cancelamento, motorista e segurança.',
          ),
          const SizedBox(height: 14),
          _helpItem(
            context: context,
            icon: Icons.security_rounded,
            title: 'Segurança',
            subtitle: 'Informações sobre segurança nas corridas.',
            message:
                'Sempre confira o nome do motorista, veículo e placa antes de entrar no carro. Use o chat da corrida quando precisar falar com o motorista.',
          ),
          const SizedBox(height: 14),
          _helpItem(
            context: context,
            icon: Icons.report_problem_rounded,
            title: 'Reportar problema',
            subtitle: 'Relatar ocorrências durante uma corrida.',
            message:
                'O envio de ocorrência será ativado em breve. Guarde o histórico da corrida para facilitar a análise do suporte.',
          ),
        ],
      ),
    );
  }

  Widget _helpItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String message,
  }) {
    return Material(
      color: const Color(0xFF0B1117),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _showInfo(
          context,
          title,
          message,
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: avuxoGreen.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: avuxoGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: avuxoGreen,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white38,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}