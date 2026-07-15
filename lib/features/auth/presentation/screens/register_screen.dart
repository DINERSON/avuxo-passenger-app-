import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color avuxoGreen = Color(0xFF24F877);

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  // Evita tentar criar a mesma conta duas vezes
  // quando o Firebase cria a conta, mas o OTP demora ou falha.
  bool accountAlreadyCreatedInThisFlow = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
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

  bool _isValidEmail(String email) {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      return false;
    }

    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(cleanEmail);
  }

  bool _isValidBrazilPhone(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('55')) {
      return digits.length == 12 || digits.length == 13;
    }

    return digits.length == 10 || digits.length == 11;
  }

  String _cleanErrorMessage(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    final lowerText = text.toLowerCase();

    if (text.isEmpty) {
      return 'Erro ao criar conta. Tente novamente.';
    }

    if (lowerText.contains('email-already-in-use') ||
        lowerText.contains('email address is already in use') ||
        lowerText.contains('already in use by another account')) {
      return 'Este e-mail já está cadastrado. Entre na sua conta ou use outro e-mail.';
    }

    if (lowerText.contains('weak-password')) {
      return 'Sua senha está muito fraca. Use pelo menos 6 caracteres.';
    }

    if (lowerText.contains('invalid-email')) {
      return 'Digite um e-mail válido.';
    }

    if (lowerText.contains('invalid-phone-number')) {
      return 'Digite um telefone válido com DDD.';
    }

    if (lowerText.contains('network-request-failed')) {
      return 'Sem conexão. Verifique sua internet.';
    }

    if (lowerText.contains('too-many-requests')) {
      return 'Muitas tentativas. Aguarde um pouco e tente novamente.';
    }

    if (lowerText.contains('user-disabled')) {
      return 'Esta conta foi desativada.';
    }

    if (lowerText.contains('operation-not-allowed')) {
      return 'Cadastro indisponível no momento. Tente novamente mais tarde.';
    }

    if (lowerText.contains('invalid-credential') ||
        lowerText.contains('wrong-password')) {
      return 'E-mail ou senha incorretos.';
    }

    return 'Não foi possível criar sua conta. Verifique os dados e tente novamente.';
  }

  Future<void> _sendOtpAndGo({
    required String formattedPhone,
  }) async {
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
        _msg(_cleanErrorMessage(error));
      },
    );
  }

  Future<void> _create() async {
    if (loading) return;

    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _msg('Preencha nome, e-mail, telefone e senha.');
      return;
    }

    if (name.length < 3 || !name.contains(' ')) {
      _msg('Digite seu nome completo.');
      return;
    }

    if (!_isValidEmail(email)) {
      _msg('Digite um e-mail válido.');
      return;
    }

    if (!_isValidBrazilPhone(phone)) {
      _msg('Digite um telefone válido com DDD.');
      return;
    }

    if (password.length < 6) {
      _msg('A senha deve ter pelo menos 6 caracteres.');
      return;
    }

    final formattedPhone = AuthService.normalizeBrazilPhone(phone);

    if (formattedPhone.isEmpty || !formattedPhone.startsWith('+55')) {
      _msg('Digite um telefone válido com DDD.');
      return;
    }

    if (!mounted) return;

    setState(() => loading = true);

    try {
      await AuthService.savePendingName(name);

      if (!accountAlreadyCreatedInThisFlow) {
        await AuthService.createAccount(
          email: email,
          password: password,
          name: name,
        );

        accountAlreadyCreatedInThisFlow = true;
      }

      await _sendOtpAndGo(
        formattedPhone: formattedPhone,
      );
    } catch (e) {
      if (!mounted) return;
      _msg(_cleanErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _goBack() {
    if (loading || !mounted) return;
    Navigator.pop(context);
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
            right: -140,
            child: _glow(280, 0.10),
          ),
          Positioned(
            bottom: -150,
            left: -140,
            child: _glow(280, 0.08),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(26, 10, 26, 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: loading ? null : _goBack,
                            child: Container(
                              width: 42,
                              height: 42,
                              color: Colors.transparent,
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _logo(),
                          const Spacer(),
                          const SizedBox(width: 42),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Criar conta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vamos começar!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.56),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 26),
                      _label('Nome completo'),
                      const SizedBox(height: 8),
                      _input(
                        controller: nameCtrl,
                        hint: 'Digite seu nome',
                        prefix: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      _label('E-mail'),
                      const SizedBox(height: 8),
                      _input(
                        controller: emailCtrl,
                        hint: 'Digite seu e-mail',
                        prefix: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      _label('Telefone'),
                      const SizedBox(height: 8),
                      _input(
                        controller: phoneCtrl,
                        hint: '(69) 9 9999-9999',
                        prefix: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      _label('Senha'),
                      const SizedBox(height: 8),
                      _input(
                        controller: passwordCtrl,
                        hint: 'Crie uma senha',
                        prefix: Icons.lock_outline_rounded,
                        obscure: hidePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!loading) {
                            _create();
                          }
                        },
                        suffix: IconButton(
                          onPressed: loading
                              ? null
                              : () {
                                  if (!mounted) return;

                                  setState(() {
                                    hidePassword = !hidePassword;
                                  });
                                },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white38,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text.rich(
                        TextSpan(
                          text: 'Ao criar sua conta, você concorda com nossos ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.42),
                            fontSize: 11,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Termos de Uso',
                              style: TextStyle(
                                color: avuxoGreen,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: ' e '),
                            TextSpan(
                              text: 'Política de Privacidade.',
                              style: TextStyle(
                                color: avuxoGreen,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      GestureDetector(
                        onTap: loading ? null : _create,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            color: loading
                                ? avuxoGreen.withValues(alpha: 0.72)
                                : avuxoGreen,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: avuxoGreen.withValues(alpha: 0.42),
                                blurRadius: 34,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2.6,
                                    ),
                                  )
                                : const Text(
                                    'CADASTRAR',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Já tem uma conta?',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.52),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton(
                            onPressed: loading ? null : _goBack,
                            child: const Text(
                              'Entrar',
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

  Widget _logo() {
    return Column(
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'AVU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 8,
                ),
              ),
              TextSpan(
                text: 'X',
                style: TextStyle(
                  color: avuxoGreen,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
              ),
              TextSpan(
                text: 'O',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
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
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'MOVA-SE COM CONFIANÇA.',
          style: TextStyle(
            color: avuxoGreen,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
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
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscure = false,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    return SizedBox(
      height: 56,
      child: TextField(
        enabled: !loading,
        textAlign: TextAlign.left,
        textAlignVertical: TextAlignVertical.center,
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        obscureText: obscure,
        onSubmitted: onSubmitted,
        cursorColor: avuxoGreen,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          overflow: TextOverflow.ellipsis,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.28),
            fontSize: 13,
          ),
          prefixIcon: prefix == null
              ? null
              : Icon(
                  prefix,
                  color: avuxoGreen,
                  size: 22,
                ),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFF05090F).withValues(alpha: 0.90),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: avuxoGreen,
              width: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _glow(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avuxoGreen.withValues(alpha: opacity),
      ),
    );
  }
}