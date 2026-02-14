import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/finance/presentation/home_shell_screen.dart';
import '../features/finance/projection/projection_screen.dart';
import 'providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthPage = location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.onboarding;
      final isProtected =
          location == AppRoutes.dashboard || location == AppRoutes.projection;

      if (authState.status == AuthStatus.unknown) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      if (authState.status == AuthStatus.unauthenticated) {
        if (isProtected) return AppRoutes.login;
        return null;
      }

      if (authState.status == AuthStatus.authenticated && isAuthPage) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const HomeShellScreen(),
      ),
      GoRoute(
        path: AppRoutes.projection,
        builder: (context, state) => const ProjectionScreen(),
      ),
    ],
  );
});
