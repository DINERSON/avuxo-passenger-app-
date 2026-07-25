import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _isLoggedInKey = 'is_logged_in';
  static const String _uidKey = 'uid';
  static const String _pendingUserNameKey = 'pending_user_name';
  static const String _tooManyOtpRequestsMessage =
      'Muitas tentativas de envio. Aguarde alguns minutos e tente novamente.';

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static String authErrorMessage(
    FirebaseAuthException error, {
    required String fallback,
  }) {
    return _firebaseErrorMessage(error, fallback: fallback);
  }

  static String _firebaseErrorMessage(
    FirebaseAuthException error, {
    required String fallback,
  }) {
    final message = error.message?.trim();
    final code = error.code.trim();
    final lowerCode = code.toLowerCase();

    if (_isTooManyOtpRequests(code: lowerCode, message: message)) {
      return _tooManyOtpRequestsMessage;
    }

    switch (lowerCode) {
      case 'invalid-phone-number':
        return 'Número de telefone inválido.';
      case 'too-many-requests':
        return _tooManyOtpRequestsMessage;
      case 'network-request-failed':
        return 'Falha de conexão. Verifique sua internet.';
      case 'invalid-verification-code':
        return 'Código inválido. Confira o SMS e tente novamente.';
      case 'session-expired':
        return 'Código expirado. Envie um novo SMS.';
      case 'credential-already-in-use':
        return 'Esse telefone já está vinculado a outra conta.';
      case 'provider-already-linked':
        return 'Esse telefone já está vinculado.';
      case 'email-already-in-use':
        return 'Esse e-mail já está cadastrado. Entre na sua conta ou use outro e-mail.';
      case 'invalid-email':
        return 'Digite um e-mail válido.';
      case 'weak-password':
        return 'Senha fraca. Use pelo menos 6 caracteres.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'user-disabled':
        return 'Essa conta foi desativada.';
      case 'operation-not-allowed':
        return 'Login indisponível no momento.';
      default:
        if (message != null && message.isNotEmpty) {
          final lower = message.toLowerCase();

          if (lower.contains('email address is already in use') ||
              lower.contains('already in use by another account')) {
            return 'Esse e-mail já está cadastrado. Entre na sua conta ou use outro e-mail.';
          }

          if (lower.contains('password should be at least')) {
            return 'Senha fraca. Use pelo menos 6 caracteres.';
          }

          if (lower.contains('invalid email')) {
            return 'Digite um e-mail válido.';
          }
        }

        return fallback;
    }
  }

  static bool _isTooManyOtpRequests({
    required String code,
    String? message,
  }) {
    final lowerMessage = message?.toLowerCase() ?? '';

    return code == '17010' ||
        code == 'too-many-requests' ||
        code == 'error_too_many_requests' ||
        lowerMessage.contains('17010') ||
        lowerMessage.contains('too-many-requests') ||
        lowerMessage.contains('error_too_many_requests') ||
        lowerMessage.contains('too many requests') ||
        lowerMessage.contains('excesso de tentativas') ||
        lowerMessage.contains('muitas tentativas');
  }

  static String _genericOtpErrorMessage(
    Object error, {
    required String fallback,
  }) {
    final lower = error.toString().toLowerCase();

    if (lower.contains('17010') ||
        lower.contains('too-many-requests') ||
        lower.contains('error_too_many_requests') ||
        lower.contains('too many requests') ||
        lower.contains('excesso de tentativas') ||
        lower.contains('muitas tentativas')) {
      return _tooManyOtpRequestsMessage;
    }

    return fallback;
  }

  static Future<void> saveLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;

    if (user == null) {
      await clearLoginSession();
      return;
    }

    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_uidKey, user.uid);
  }

  static Future<void> clearLoginSession() async {
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      prefs.remove(_isLoggedInKey),
      prefs.remove(_uidKey),
    ]);
  }

  static Future<bool> hasSavedSession() async {
    final prefs = await SharedPreferences.getInstance();

    final localSession = prefs.getBool(_isLoggedInKey) ?? false;
    final uid = prefs.getString(_uidKey)?.trim();
    final firebaseUser = _auth.currentUser;

    if (!localSession) {
      return false;
    }

    if (uid == null || uid.isEmpty) {
      await clearLoginSession();
      return false;
    }

    if (firebaseUser == null) {
      await clearLoginSession();
      return false;
    }

    if (firebaseUser.uid != uid) {
      await clearLoginSession();
      return false;
    }

    return true;
  }

  static Future<void> savePendingName(String name) async {
    final cleanName = name.trim();
    final prefs = await SharedPreferences.getInstance();

    if (cleanName.isEmpty) {
      await prefs.remove(_pendingUserNameKey);
      return;
    }

    await prefs.setString(_pendingUserNameKey, cleanName);
  }

  static Future<String?> getPendingName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_pendingUserNameKey)?.trim();

    if (name == null || name.isEmpty) {
      return null;
    }

    return name;
  }

  static Future<void> clearPendingName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingUserNameKey);
  }

  static String normalizeBrazilPhone(String input) {
    final cleanInput = input.trim();

    if (cleanInput.isEmpty) {
      return '';
    }

    final numbers = cleanInput.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbers.isEmpty) {
      return '';
    }

    if (numbers.startsWith('55') && numbers.length >= 12) {
      return '+$numbers';
    }

    if (numbers.length == 10 || numbers.length == 11) {
      return '+55$numbers';
    }

    if (cleanInput.startsWith('+') && numbers.length >= 10) {
      return '+$numbers';
    }

    return cleanInput;
  }

  static Future<void> sendPhoneOtp({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    final normalizedPhone = normalizeBrazilPhone(phone);

    if (normalizedPhone.isEmpty) {
      onError('Informe um telefone válido.');
      return;
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _finishPhoneCredential(credential);
            await saveLoginSession();
            await clearPendingName();
          } on FirebaseAuthException catch (e) {
            onError(
              _firebaseErrorMessage(
                e,
                fallback: 'Erro ao validar telefone automaticamente.',
              ),
            );
          } catch (_) {
            onError('Erro ao validar telefone automaticamente.');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(
            _firebaseErrorMessage(
              e,
              fallback: 'Erro ao enviar SMS.',
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          final cleanVerificationId = verificationId.trim();

          if (cleanVerificationId.isEmpty) {
            onError('Código de verificação inválido.');
            return;
          }

          onCodeSent(cleanVerificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
      onError(
        _firebaseErrorMessage(
          e,
          fallback: 'Erro ao enviar código.',
        ),
      );
    } catch (e) {
      onError(
        _genericOtpErrorMessage(
          e,
          fallback: 'Erro ao enviar código. Tente novamente.',
        ),
      );
    }
  }

  static Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
    required String phone,
  }) async {
    final cleanVerificationId = verificationId.trim();
    final cleanSmsCode = smsCode.trim();
    final normalizedPhone = normalizeBrazilPhone(phone);

    if (cleanVerificationId.isEmpty) {
      throw Exception('Envie o código novamente.');
    }

    if (cleanSmsCode.isEmpty) {
      throw Exception('Informe o código recebido.');
    }

    if (normalizedPhone.isEmpty) {
      throw Exception('Telefone inválido.');
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: cleanVerificationId,
        smsCode: cleanSmsCode,
      );

      await _finishPhoneCredential(credential);
      await saveLoginSession();
      await clearPendingName();
    } on FirebaseAuthException catch (e) {
      throw Exception(
        _firebaseErrorMessage(
          e,
          fallback: 'Erro ao confirmar código.',
        ),
      );
    }
  }

  static Future<void> _finishPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    final current = _auth.currentUser;

    if (current != null) {
      try {
        await current.linkWithCredential(credential);
        await current.reload();
        return;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'provider-already-linked') {
          await current.reload();
          return;
        }

        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          await _auth.signInWithCredential(credential);
          return;
        }

        rethrow;
      }
    }

    await _auth.signInWithCredential(credential);
  }

  static Future<UserCredential> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();

      if (account == null) {
        throw Exception('Login cancelado.');
      }

      final googleAuth = await account.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);

      await result.user?.reload();
      await saveLoginSession();

      return result;
    } on FirebaseAuthException catch (e) {
      throw Exception(
        _firebaseErrorMessage(
          e,
          fallback: 'Erro ao entrar com Google.',
        ),
      );
    }
  }

  static Future<UserCredential> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();
    final cleanName = name.trim();

    if (cleanEmail.isEmpty) {
      throw Exception('Informe seu e-mail.');
    }

    if (cleanPassword.isEmpty) {
      throw Exception('Informe sua senha.');
    }

    if (cleanName.isEmpty) {
      throw Exception('Informe seu nome.');
    }

    try {
      await savePendingName(cleanName);
      await clearLoginSession();

      final result = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      await result.user?.updateDisplayName(cleanName);
      await result.user?.reload();

      // Não salva sessão aqui.
      // A Home só deve liberar depois do OTP confirmado em verifyOtp().
      await clearLoginSession();

      return result;
    } on FirebaseAuthException catch (e) {
      throw Exception(
        _firebaseErrorMessage(
          e,
          fallback: 'Erro ao criar conta.',
        ),
      );
    }
  }

  static Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty) {
      throw Exception('Informe seu e-mail.');
    }

    if (cleanPassword.isEmpty) {
      throw Exception('Informe sua senha.');
    }

    final result = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: cleanPassword,
    );

    await result.user?.reload();
    await saveLoginSession();

    return result;
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      throw Exception('Informe seu e-mail.');
    }

    await _auth.sendPasswordResetEmail(email: cleanEmail);
  }

  static Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    await _auth.signOut();
    await clearLoginSession();
    await clearPendingName();
  }
}
