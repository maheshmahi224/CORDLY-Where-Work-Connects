import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cordly_client/features/auth/presentation/pages/login_page.dart';
import 'package:cordly_client/features/home/presentation/pages/home_page.dart';
import 'package:cordly_client/features/execute/presentation/pages/execute_page.dart';
import 'package:cordly_client/features/calendar/presentation/pages/calendar_page.dart';
import 'package:cordly_client/features/people/presentation/pages/people_page.dart';
import 'package:cordly_client/features/assistant/presentation/pages/assistant_page.dart';
import 'package:cordly_client/core/shell/app_shell.dart';
import 'package:cordly_client/features/auth/data/repositories/auth_repository.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthStateListenable(ref),
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      
      // Check if we are currently logged in
      final isLoggedIn = auth.value?.session != null;
      
      final isLoggingIn = state.uri.path == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/execute',
            builder: (context, state) => const ExecutePage(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: '/people',
            builder: (context, state) => const PeoplePage(),
          ),
          GoRoute(
            path: '/assistant',
            builder: (context, state) => const AssistantPage(),
          ),
        ],
      ),
    ],
  );
});

// Helper to convert Stream to Listenable for GoRouter
class _AuthStateListenable extends ChangeNotifier {
  final Ref ref;
  _AuthStateListenable(this.ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
