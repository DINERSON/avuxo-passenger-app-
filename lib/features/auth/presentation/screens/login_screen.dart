import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color avuxoGreen = Color(0xFF24F877);

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool loadingPhone = false;
  bool hidePassword = true;

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _msg(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10151E),
        behavior: SnackBarBehavior.floating,
        content: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  bool _isValidBrazilPhone(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('55')) {
      return digits.length == 12 || digits.length == 13;
    }

    return digits.length == 10 || digits.length == 11;
  }

  Future<void> _sendOtp() async {
    if (loadingPhone) return;

    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      _msg('Digite seu telefone.');
      return;
    }

    if (phone.contains('@')) {
      _msg('Digite um telefone válido, não e-mail.');
      return;
    }

    if (!_isValidBrazilPhone(phone)) {
      _msg('Digite um telefone válido com DDD.');
      return;
    }

    final formattedPhone = AuthService.normalizeBrazilPhone(phone);

    if (formattedPhone.isEmpty || !formattedPhone.startsWith('+55')) {
      _msg('Digite um telefone válido com DDD.');
      return;
    }

    if (!mounted) return;

    setState(() => loadingPhone = true);

    try {
      await AuthService.sendPhoneOtp(
        phone: formattedPhone,
        onCodeSent: (verificationId) {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                phone: formattedPhone,
                verificationId: verificationId,
              ),
            ),
          );
        },
        onError: (error) {
          if (!mounted) return;
          _msg(error);
        },
      );
    } catch (_) {
      if (mounted) {
        _msg('Erro ao enviar código. Tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() => loadingPhone = false);
      }
    }
  }

  void _openRegister() {
    if (loadingPhone || !mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  void _togglePasswordVisibility() {
    if (loadingPhone || !mounted) return;

    setState(() {
      hidePassword = !hidePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            left: -135,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avuxoGreen.withValues(alpha: 0.075),
              ),
            ),
          ),
          Positioned(
            right: -165,
            bottom: -135,
            child: Container(
              width: 310,
              height: 310,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avuxoGreen.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(26, 8, 26, 10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: _textLogo()),
                      const SizedBox(height: 26),
                      const Text(
                        'Entre na sua conta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vamos enviar um código por SMS.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 26),
                      _label('Telefone'),
                      const SizedBox(height: 8),
                      _input(
                        controller: phoneController,
                        hint: '(69) 9 9999-9999',
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        prefix: Icons.phone_android_rounded,
                      ),
                      const SizedBox(height: 16),
                      _label('Senha'),
                      const SizedBox(height: 8),
                      _input(
                        controller: passwordController,
                        hint: 'Opcional nesta versão',
                        obscure: hidePassword,
                        prefix: Icons.lock_outline_rounded,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!loadingPhone) {
                            _sendOtp();
                          }
                        },
                        suffix: IconButton(
                          onPressed:
                              loadingPhone ? null : _togglePasswordVisibility,
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white38,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: loadingPhone
                              ? null
                              : () {
                                  _msg('Recuperação de senha será ativada.');
                                },
                          child: const Text(
                            'Esqueci minha senha',
                            style: TextStyle(
                              color: avuxoGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      GestureDetector(
                        onTap: loadingPhone ? null : _sendOtp,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: loadingPhone
                                ? avuxoGreen.withValues(alpha: 0.75)
                                : avuxoGreen,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: avuxoGreen.withValues(alpha: 0.42),
                                blurRadius: 32,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: loadingPhone
                                ? const SizedBox(
                                    width: 23,
                                    height: 23,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2.6,
                                    ),
                                  )
                                : const Text(
                                    'ENTRAR',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Não tem uma conta?',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton(
                            onPressed: loadingPhone ? null : _openRegister,
                            child: const Text(
                              'Criar conta',
                              style: TextStyle(
                                color: avuxoGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textLogo() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'AVU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 8,
                ),
              ),
              TextSpan(
                text: 'X',
                style: TextStyle(
                  color: avuxoGreen,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
              ),
              TextSpan(
                text: 'O',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'MOBILIDADE INTELIGENTE',
          style: TextStyle(
            color: avuxoGreen,
            fontSize: 7,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'MOVA-SE COM CONFIANÇA.',
          style: TextStyle(
            color: avuxoGreen,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.8,
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    IconData? prefix,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscure = false,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    return SizedBox(
      height: 54,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscure,
        onSubmitted: onSubmitted,
        cursorColor: avuxoGreen,
        enabled: !loadingPhone,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.30),
            fontSize: 13,
          ),
          prefixIcon: prefix == null
              ? null
              : Icon(
                  prefix,
                  color: Colors.white38,
                  size: 22,
                ),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFF05090F).withValues(alpha: 0.86),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.13),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.13),
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(
              color: avuxoGreen,
              width: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}