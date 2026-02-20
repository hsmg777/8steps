import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/finance/calendar/financial_calendar_screen.dart';
import '../features/finance/categories/categories_screen.dart';
import '../features/finance/cards/card_detail_screen.dart';
import '../features/finance/cards/cards_screen.dart';
import '../features/finance/installments/installments_screen.dart';
import '../features/finance/presentation/home_shell_screen.dart';
import '../features/finance/goals/goals_screen.dart';
import '../features/finance/recurrings/recurrings_screen.dart';
import '../features/finance/reports/reports_screen.dart';
import '../modules/auth/viewmodels/auth_view_model.dart';
import 'providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier<int>(0);
  ref.onDispose(refreshNotifier.dispose);
  ref.listen<AuthState>(authControllerProvider, (_, __) {
    refreshNotifier.value++;
  });

  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isAuthPage = location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.onboarding;
      final isProtected = location == AppRoutes.dashboard ||
          location == AppRoutes.categories ||
          location == AppRoutes.projection ||
          location == AppRoutes.accounts ||
          location == AppRoutes.cards ||
          location == AppRoutes.recurrings ||
          location == AppRoutes.financialCalendar ||
          location == AppRoutes.reports ||
          location.startsWith('/cards/');

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
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.accounts,
        builder: (context, state) => const AccountsScreen(),
      ),
      GoRoute(
        path: AppRoutes.cards,
        builder: (context, state) => const CardsScreen(),
      ),
      GoRoute(
        path: AppRoutes.recurrings,
        builder: (context, state) => const RecurringsScreen(),
      ),
      GoRoute(
        path: AppRoutes.financialCalendar,
        builder: (context, state) => const FinancialCalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.cardDetailPattern,
        builder: (context, state) {
          final cardId = state.pathParameters['cardId'] ?? '';
          return CardDetailScreen(cardId: cardId);
        },
      ),
    ],
  );
});
