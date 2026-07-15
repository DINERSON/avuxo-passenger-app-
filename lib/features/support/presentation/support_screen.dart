import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const routeName = '/support';

  static const String whatsappNumber =
      '55119900000000';

  static const String supportEmail =
      'suporte@avuxo.com';

  Future<void> _openUrl(
    BuildContext context,
    Uri uri,
  ) async {
    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível abrir o aplicativo.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erro ao abrir o aplicativo.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final whatsappUri =
        Uri.parse('https://wa.me/$whatsappNumber');

    final emailUri =
        Uri.parse('mailto:$supportEmail');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Suporte',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(
                Icons.support_agent,
              ),
              title: Text(
                'Central de Suporte AVUXO',
              ),
              subtitle: Text(
                'Precisa de ajuda com sua corrida?',
              ),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(
              Icons.chat,
            ),
            title: const Text(
              'WhatsApp',
            ),
            subtitle: const Text(
              '+55 11 90000-0000',
            ),
            onTap: () =>
                _openUrl(
              context,
              whatsappUri,
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.mail_outline,
            ),
            title: const Text(
              'Email',
            ),
            subtitle: const Text(
              supportEmail,
            ),
            onTap: () =>
                _openUrl(
              context,
              emailUri,
            ),
          ),
        ],
      ),
    );
  }
}