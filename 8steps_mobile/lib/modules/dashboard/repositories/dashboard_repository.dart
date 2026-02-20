import '../models/dashboard_balance.dart';

abstract class DashboardRepository {
  Future<DashboardBalance> getBalance();
}
