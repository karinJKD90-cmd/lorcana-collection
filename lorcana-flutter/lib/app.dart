import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/collection/card_detail_screen.dart';
import 'screens/scan/scan_screen.dart';
import 'models/card_model.dart';

class LorcanaApp extends StatelessWidget {
  const LorcanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    final router = GoRouter(
      initialLocation: authService.isLoggedIn ? '/home' : '/auth',
      redirect: (context, state) {
        final loggedIn = Supabase.instance.client.auth.currentUser != null;
        final onAuth = state.matchedLocation == '/auth';
        if (!loggedIn && !onAuth) return '/auth';
        if (loggedIn && onAuth) return '/home';
        return null;
      },
      routes: [
        GoRoute(
          path: '/auth',
          builder: (_, __) => const AuthScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'card/:id',
              builder: (_, state) {
                final card = state.extra as LorcanaCard;
                return CardDetailScreen(card: card);
              },
            ),
            GoRoute(
              path: 'scan',
              builder: (_, __) => const ScanScreen(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Lorcana Collection',
      theme: LorcanaTheme.dark,
      routerConfig: router,
    );
  }
}
