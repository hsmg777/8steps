import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/config/env.dart';
import '../core/network/dio_client.dart';
import '../data/local/app_database.dart';
import '../data/repositories/finance_repository.dart';
import '../features/auth/data/datasources/remote_auth_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/finance/presentation/finance_controller.dart';

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

final remoteAuthDataSourceProvider = Provider<RemoteAuthDataSource>(
  (ref) => RemoteAuthDataSource(ref.watch(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(remoteAuthDataSourceProvider),
    storage: ref.watch(secureStorageProvider),
  ),
);

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final controller = AuthController(ref.watch(authRepositoryProvider));

  ref.listen<int>(authSessionInvalidationProvider, (previous, next) {
    if (previous != next) {
      controller.handleUnauthorized();
    }
  });

  return controller;
});

final uuidProvider = Provider<Uuid>((ref) => const Uuid());

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final categoriesProvider = StreamProvider((ref) {
  return ref.watch(appDatabaseProvider).categoriesDao.watchAll();
});

final monthlyTransactionsProvider = StreamProvider((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(appDatabaseProvider).transactionsDao.watchByMonth(month);
});

final fixedExpensesProvider = StreamProvider((ref) {
  return ref.watch(appDatabaseProvider).fixedExpensesDao.watchAll();
});

final installmentsProvider = StreamProvider((ref) {
  return ref.watch(appDatabaseProvider).installmentsDao.watchAll();
});

final monthlySummaryProvider = FutureProvider((ref) async {
  final month = ref.watch(selectedMonthProvider);
  return ref
      .watch(appDatabaseProvider)
      .transactionsDao
      .getMonthlySummary(month);
});

final monthlyCategoryExpensesProvider = FutureProvider((ref) async {
  final month = ref.watch(selectedMonthProvider);
  return ref
      .watch(appDatabaseProvider)
      .transactionsDao
      .getMonthlyExpensesByCategory(month);
});

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepository(ref.watch(appDatabaseProvider)),
);

final financeControllerProvider = Provider<FinanceController>((ref) {
  return FinanceController(
    repository: ref.watch(financeRepositoryProvider),
    uuid: ref.watch(uuidProvider),
  );
});
