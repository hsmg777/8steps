import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/config/env.dart';
import '../core/network/dio_client.dart';
import '../modules/accounts/repositories/accounts_repository.dart';
import '../modules/accounts/repositories/accounts_repository_impl.dart';
import '../modules/accounts/viewmodels/accounts_view_model.dart';
import '../modules/auth/repositories/auth_repository.dart';
import '../modules/auth/repositories/auth_repository_impl.dart';
import '../modules/auth/viewmodels/auth_view_model.dart';
import '../modules/categories/repositories/categories_repository.dart';
import '../modules/categories/repositories/categories_repository_impl.dart';
import '../modules/categories/viewmodels/categories_view_model.dart';
import '../modules/categories/models/budget_models.dart';
import '../modules/cards/repositories/cards_repository.dart';
import '../modules/cards/repositories/cards_repository_impl.dart';
import '../modules/cards/viewmodels/cards_view_model.dart';
import '../modules/calendar/repositories/calendar_repository.dart';
import '../modules/calendar/repositories/calendar_repository_impl.dart';
import '../modules/calendar/viewmodels/calendar_view_model.dart';
import '../modules/dashboard/repositories/dashboard_repository.dart';
import '../modules/dashboard/repositories/dashboard_repository_impl.dart';
import '../modules/dashboard/viewmodels/dashboard_view_model.dart';
import '../modules/goals/repositories/goals_repository.dart';
import '../modules/goals/repositories/goals_repository_impl.dart';
import '../modules/goals/viewmodels/goals_view_model.dart';
import '../modules/goals/models/goal_models.dart';
import '../modules/profile/repositories/profile_repository.dart';
import '../modules/profile/repositories/profile_repository_impl.dart';
import '../modules/profile/viewmodels/profile_view_model.dart';
import '../modules/reports/repositories/reports_repository.dart';
import '../modules/reports/repositories/reports_repository_impl.dart';
import '../modules/reports/viewmodels/reports_view_model.dart';
import '../modules/recurrings/repositories/recurrings_repository.dart';
import '../modules/recurrings/repositories/recurrings_repository_impl.dart';
import '../modules/recurrings/viewmodels/recurrings_view_model.dart';
import '../modules/transactions/repositories/transactions_repository.dart';
import '../modules/transactions/repositories/transactions_repository_impl.dart';
import '../modules/transactions/viewmodels/transactions_view_model.dart';
import '../services/accounts/account_service.dart';
import '../services/auth/auth_service.dart';
import '../services/categories/categories_service.dart';
import '../services/cards/cards_service.dart';
import '../services/calendar/calendar_service.dart';
import '../services/dashboard/dashboard_service.dart';
import '../services/goals/goals_service.dart';
import '../services/profile/profile_service.dart';
import '../services/reports/reports_service.dart';
import '../services/recurrings/recurrings_service.dart';
import '../services/transactions/transactions_service.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final authSessionInvalidationProvider = StateProvider<int>((ref) => 0);

final dioProvider = Provider<Dio>((ref) {
  return DioClient.create(
    baseUrl: Env.apiBaseUrl,
    storage: ref.watch(secureStorageProvider),
    onUnauthorized: () async {
      ref.read(authSessionInvalidationProvider.notifier).state++;
    },
  );
});

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(dioProvider)),
);

final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService(ref.watch(dioProvider)),
);

final accountServiceProvider = Provider<AccountService>(
  (ref) => AccountService(ref.watch(dioProvider)),
);

final categoriesServiceProvider = Provider<CategoriesService>(
  (ref) => CategoriesService(ref.watch(dioProvider)),
);

final transactionsServiceProvider = Provider<TransactionsService>(
  (ref) => TransactionsService(ref.watch(dioProvider)),
);

final cardsServiceProvider = Provider<CardsService>(
  (ref) => CardsService(ref.watch(dioProvider)),
);

final calendarServiceProvider = Provider<CalendarService>(
  (ref) => CalendarService(ref.watch(dioProvider)),
);

final dashboardServiceProvider = Provider<DashboardService>(
  (ref) => DashboardService(ref.watch(dioProvider)),
);

final goalsServiceProvider = Provider<GoalsService>(
  (ref) => GoalsService(ref.watch(dioProvider)),
);

final recurringsServiceProvider = Provider<RecurringsService>(
  (ref) => RecurringsService(ref.watch(dioProvider)),
);

final reportsServiceProvider = Provider<ReportsService>(
  (ref) => ReportsService(ref.watch(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    authService: ref.watch(authServiceProvider),
    profileService: ref.watch(profileServiceProvider),
    storage: ref.watch(secureStorageProvider),
  ),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(profileServiceProvider)),
);

final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => AccountsRepositoryImpl(ref.watch(accountServiceProvider)),
);

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepositoryImpl(ref.watch(categoriesServiceProvider)),
);

final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => TransactionsRepositoryImpl(ref.watch(transactionsServiceProvider)),
);

final cardsRepositoryProvider = Provider<CardsRepository>(
  (ref) => CardsRepositoryImpl(ref.watch(cardsServiceProvider)),
);

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => CalendarRepositoryImpl(ref.watch(calendarServiceProvider)),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(ref.watch(dashboardServiceProvider)),
);

final goalsRepositoryProvider = Provider<GoalsRepository>(
  (ref) => GoalsRepositoryImpl(ref.watch(goalsServiceProvider)),
);

final recurringsRepositoryProvider = Provider<RecurringsRepository>(
  (ref) => RecurringsRepositoryImpl(ref.watch(recurringsServiceProvider)),
);

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepositoryImpl(ref.watch(reportsServiceProvider)),
);

final authControllerProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) {
    final controller = AuthViewModel(ref.watch(authRepositoryProvider));

    ref.listen<int>(authSessionInvalidationProvider, (previous, next) {
      if (previous != next) {
        controller.handleUnauthorized();
      }
    });

    return controller;
  },
);

final profileViewModelProvider =
    StateNotifierProvider<ProfileViewModel, ProfileState>(
  (ref) => ProfileViewModel(ref.watch(profileRepositoryProvider)),
);

final accountsViewModelProvider =
    StateNotifierProvider<AccountsViewModel, AccountsState>(
  (ref) => AccountsViewModel(ref.watch(accountsRepositoryProvider)),
);

final categoriesViewModelProvider =
    StateNotifierProvider<CategoriesViewModel, CategoriesState>(
  (ref) => CategoriesViewModel(ref.watch(categoriesRepositoryProvider)),
);

final transactionsViewModelProvider =
    StateNotifierProvider<TransactionsViewModel, TransactionsState>(
  (ref) => TransactionsViewModel(ref.watch(transactionsRepositoryProvider)),
);

final cardsViewModelProvider =
    StateNotifierProvider<CardsViewModel, CardsState>(
  (ref) => CardsViewModel(ref.watch(cardsRepositoryProvider)),
);

final calendarViewModelProvider =
    StateNotifierProvider<CalendarViewModel, CalendarState>(
  (ref) => CalendarViewModel(ref.watch(calendarRepositoryProvider)),
);

final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>(
  (ref) => DashboardViewModel(ref.watch(dashboardRepositoryProvider)),
);

final goalsViewModelProvider =
    StateNotifierProvider<GoalsViewModel, GoalsState>(
  (ref) => GoalsViewModel(ref.watch(goalsRepositoryProvider)),
);

final goalsRecommendationsProvider =
    FutureProvider<List<GoalRecommendationResult>>((ref) async {
  final repo = ref.watch(goalsRepositoryProvider);
  final goals = await repo.getGoals();
  if (goals.isEmpty) return const [];

  Future<GoalRecommendationResult?> fetch(String goalId) async {
    try {
      return await repo.getRecommendation(goalId: goalId);
    } catch (_) {
      return null;
    }
  }

  final recommendations = await Future.wait(
    goals.take(3).map((goal) => fetch(goal.id)),
  );

  return recommendations.whereType<GoalRecommendationResult>().toList();
});

final recurringsViewModelProvider =
    StateNotifierProvider<RecurringsViewModel, RecurringsState>(
  (ref) => RecurringsViewModel(ref.watch(recurringsRepositoryProvider)),
);

final reportsViewModelProvider =
    StateNotifierProvider<ReportsViewModel, ReportsState>(
  (ref) => ReportsViewModel(ref.watch(reportsRepositoryProvider)),
);

final dashboardCategoryBudgetChartProvider =
    FutureProvider<List<BudgetStatusItem>>((ref) async {
  final repo = ref.watch(categoriesRepositoryProvider);
  final now = DateTime.now();
  final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  return repo.getBudgetStatus(month);
});
