import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/providers/app_providers.dart';
import '../../services/auth_service.dart';
import 'tutorial_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String verificationId;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.verificationId,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const Color avuxoGreen = Color(0xFF24F877);

  final codeCtrl = TextEditingController();

  Timer? timer;

  int seconds = 25;

  bool loading = false;
  bool resending = false;

  late String verificationId;
  late String phone;

  @override
  void initState() {
    super.initState();
    verificationId = widget.verificationId.trim();
    phone = AuthService.normalizeBrazilPhone(widget.phone);
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _msg('Código enviado.');
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    codeCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    timer?.cancel();

    if (!mounted) return;

    setState(() {
      seconds = 25;
    });

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (t) {
        if (!mounted) {
          t.cancel();
          return;
        }

        if (seconds <= 0) {
          t.cancel();
          return;
        }

        setState(() {
          seconds--;
        });
      },
    );
  }

  String get _timerText {
    final value = seconds.toString().padLeft(2, '0');
    return 'Reenviar código em 00:$value';
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

  String _cleanErrorMessage(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();

    if (text.isEmpty) {
      return 'Código inválido.';
    }

    if (text.contains('invalid-verification-code')) {
      return 'Código inválido. Confira o SMS e tente novamente.';
    }

    if (text.contains('session-expired')) {
      return 'Código expirou. Toque em reenviar código.';
    }

    if (text.contains('network-request-failed')) {
      return 'Sem conexão. Verifique sua internet.';
    }

    return text;
  }

 Future<void> _verify() async {
  if (loading || resending) return;

  final code = codeCtrl.text.trim();

  if (code.length < 6) {
    _msg('Digite o código completo.');
    return;
  }

  if (verificationId.trim().isEmpty) {
    _msg('Código ainda não foi enviado. Toque em reenviar código.');
    return;
  }

  if (phone.trim().isEmpty) {
    _msg('Telefone inválido. Volte e tente novamente.');
    return;
  }

  if (!mounted) return;

  setState(() {
    loading = true;
  });

  try {
    // O repositório confirma o OTP uma vez no Firebase e depois cria a sessão
    // correspondente no backend.
    final result = await ref.read(authRepositoryProvider).verifyOtp(
          verificationId: verificationId,
          otp: code,
          phone: phone,
        );

    ref.read(apiClientProvider).setToken(result.$1);
    await ref.read(localStorageProvider).saveAuth(result.$1, result.$2);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const TutorialScreen(),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    _msg(_cleanErrorMessage(e));
  } finally {
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }
}

  Future<void> _resend() async {
    if (seconds > 0 || resending || loading) return;

    if (phone.trim().isEmpty) {
      _msg('Telefone inválido. Volte e tente novamente.');
      return;
    }

    if (!mounted) return;

    setState(() {
      resending = true;
    });

    try {
      await AuthService.sendPhoneOtp(
        phone: phone,
        onCodeSent: (id) {
          if (!mounted) return;

          final cleanId = id.trim();

          if (cleanId.isEmpty) {
            _msg('Erro ao reenviar código. Tente novamente.');
            return;
          }

          verificationId = cleanId;
          codeCtrl.clear();
          _startTimer();
          _msg('Código reenviado.');
        },
        onError: (error) {
          if (!mounted) return;
          _msg(error);
        },
      );
    } catch (_) {
      if (!mounted) return;
      _msg('Erro ao reenviar código.');
    } finally {
      if (mounted) {
        setState(() {
          resending = false;
        });
      }
    }
  }

  void _goBack() {
    if (loading || resending || !mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pinTheme = PinTheme(
      width: 42,
      height: 46,
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF060A0F),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black,
            ),
          ),
          Positioned(
            top: -120,
            right: -120,
            child: _glow(260, 0.14),
          ),
          Positioned(
            bottom: -120,
            left: -120,
            child: _glow(260, 0.10),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 420,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _backButton(),
                          const Spacer(),
                          _logo(),
                          const Spacer(),
                          const SizedBox(width: 42),
                        ],
                      ),
                      const SizedBox(height: 86),
                      const Text(
                        'Verificação de\ntelefone',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          height: 1.10,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Enviamos um código para\n$phone',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 38),
                      Center(
                        child: Pinput(
                          controller: codeCtrl,
                          length: 6,
                          enabled: !loading && !resending,
                          keyboardType: TextInputType.number,
                          defaultPinTheme: pinTheme,
                          focusedPinTheme: pinTheme.copyWith(
                            decoration: BoxDecoration(
                              color: const Color(0xFF060A0F),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: avuxoGreen,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: avuxoGreen.withValues(alpha: 0.28),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                          ),
                          submittedPinTheme: pinTheme.copyWith(
                            decoration: BoxDecoration(
                              color: const Color(0xFF060A0F),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: avuxoGreen.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                          onCompleted: (_) {
                            if (!loading && !resending) {
                              _verify();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 154),
                      Center(
                        child: GestureDetector(
                          onTap: seconds > 0 || resending || loading
                              ? null
                              : _resend,
                          child: Text(
                            seconds > 0
                                ? _timerText
                                : resending
                                    ? 'Reenviando...'
                                    : 'Reenviar código',
                            style: TextStyle(
                              color: seconds > 0 || resending || loading
                                  ? Colors.white.withValues(alpha: 0.45)
                                  : avuxoGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: loading || resending ? null : _verify,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: loading || resending
                                ? avuxoGreen.withValues(alpha: 0.72)
                                : avuxoGreen,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: avuxoGreen.withValues(alpha: 0.36),
                                blurRadius: 28,
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
                                    'VERIFICAR',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                          ),
                        ),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 5,
                ),
              ),
              TextSpan(
                text: 'X',
                style: TextStyle(
                  color: avuxoGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5,
                ),
              ),
              TextSpan(
                text: 'O',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'VÁ COM CONFIANÇA',
          style: TextStyle(
            color: avuxoGreen,
            fontSize: 6,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _backButton() {
    return GestureDetector(
      onTap: loading || resending ? null : _goBack,
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
    );
  }

  Widget _glow(double size, double opacity) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 70,
        sigmaY: 70,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: avuxoGreen.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
