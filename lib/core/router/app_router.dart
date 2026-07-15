import 'package:flutter/widgets.dart';

import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/ride/presentation/rating_screen.dart';
import '../../features/support/presentation/support_screen.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      HomeShell.routeName: (_) => const HomeShell(),
      HistoryScreen.routeName: (_) => const HistoryScreen(),
      ProfileScreen.routeName: (_) => const ProfileScreen(),
      SupportScreen.routeName: (_) => const SupportScreen(),
      RatingScreen.routeName: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;

        final rideId = args is String ? args.trim() : '';

        return RatingScreen(
          rideId: rideId,
        );
      },
    };
  }
}