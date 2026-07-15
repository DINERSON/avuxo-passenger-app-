import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';

import 'features/auth/presentation/screens/splash_screen.dart';

import 'features/home/presentation/passenger_activity_screen.dart';
import 'features/home/presentation/passenger_wallet_screen.dart';
import 'features/home/presentation/passenger_promotions_screen.dart';
import 'features/home/presentation/passenger_help_screen.dart';
import 'features/home/presentation/passenger_settings_screen.dart';
import 'features/home/presentation/passenger_account_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exceptionAsString()}');
  };

  Object? startupError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stackTrace) {
    startupError = e;
    debugPrint('Firebase init error: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF050505),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(
    ProviderScope(
      child: AvuxoApp(
        startupError: startupError,
      ),
    ),
  );
}

class AvuxoApp extends StatelessWidget {
  const AvuxoApp({
    super.key,
    this.startupError,
  });

  final Object? startupError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AVUXO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: startupError == null
          ? const SplashScreen()
          : StartupErrorScreen(error: startupError),
      routes: {
        '/passenger-activity': (_) => const PassengerActivityScreen(),
        '/passenger-wallet': (_) => const PassengerWalletScreen(),
        '/passenger-promotions': (_) => const PassengerPromotionsScreen(),
        '/passenger-help': (_) => const PassengerHelpScreen(),
        '/passenger-settings': (_) => const PassengerSettingsScreen(),
        '/passenger-account': (_) => const PassengerAccountScreen(),
      },
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: Color(0xFF050505),
              systemNavigationBarIconBrightness: Brightness.light,
              systemNavigationBarDividerColor: Colors.transparent,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Container(
                color: const Color(0xFF050505),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({
    super.key,
    required this.error,
  });

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonGreen.withValues(alpha: 0.12),
                      boxShadow: AppEffects.neonGlow(opacity: 0.18),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.neonGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Não foi possível iniciar o AVUXO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Verifique sua conexão com a internet e tente abrir o aplicativo novamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    error?.toString() ?? 'Erro desconhecido',
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppColors {
  static const background = Color(0xFF050505);
  static const neonGreen = Color(0xFF00FF8F);
  static const card = Color(0xFF0B0F14);
  static const border = Color(0xFF1A1F27);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF7E8A97);
}

class AppEffects {
  static List<BoxShadow> neonGlow({
    double opacity = 0.35,
  }) {
    return [
      BoxShadow(
        color: AppColors.neonGreen.withValues(alpha: opacity),
        blurRadius: 22,
        spreadRadius: 1,
      ),
    ];
  }
}

class Responsive {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 700;
  }

  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}

extension SpaceExtension on num {
  SizedBox get h => SizedBox(height: toDouble());
  SizedBox get w => SizedBox(width: toDouble());
}