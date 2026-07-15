import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PassengerAccountScreen extends StatelessWidget {
  const PassengerAccountScreen({super.key});

  static const Color avuxoGreen = Color(0xFF24F877);

  void _showInfo(
    BuildContext context,
    String title,
  ) {
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

  bool _validPhotoUrl(String value) {
    final clean = value.trim();

    return clean.startsWith('http://') || clean.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName?.trim() ?? '';
    final userEmail = user?.email?.trim() ?? '';
    final userPhone = user?.phoneNumber?.trim() ?? '';
    final photo = user?.photoURL?.trim() ?? '';

    final name = displayName.isNotEmpty ? displayName : 'Passageiro AVUXO';
    final email = userEmail.isNotEmpty ? userEmail : 'Sem e-mail';
    final phone = userPhone.isNotEmpty ? userPhone : 'Telefone não informado';
    final validPhoto = _validPhotoUrl(photo);

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
          'Conta',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1117),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: avuxoGreen.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: avuxoGreen,
                  backgroundImage: validPhoto ? NetworkImage(photo) : null,
                  child: validPhoto
                      ? null
                      : const Icon(
                          Icons.person,
                          size: 52,
                          color: Colors.black,
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  phone,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.52),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _accountTile(
            icon: Icons.person_outline_rounded,
            title: 'Dados pessoais',
            onTap: () => _showInfo(context, 'Dados pessoais'),
          ),
          const SizedBox(height: 12),
          _accountTile(
            icon: Icons.lock_outline_rounded,
            title: 'Privacidade',
            onTap: () => _showInfo(context, 'Privacidade'),
          ),
          const SizedBox(height: 12),
          _accountTile(
            icon: Icons.security_rounded,
            title: 'Segurança',
            onTap: () => _showInfo(context, 'Segurança'),
          ),
          const SizedBox(height: 12),
          _accountTile(
            icon: Icons.star_outline_rounded,
            title: 'Conta Premium',
            onTap: () => _showInfo(context, 'Conta Premium'),
          ),
        ],
      ),
    );
  }

  Widget _accountTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF0B1117),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: avuxoGreen.withValues(alpha: 0.08),
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
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}