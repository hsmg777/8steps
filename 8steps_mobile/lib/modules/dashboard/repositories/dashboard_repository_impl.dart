import '../../../services/dashboard/dashboard_service.dart';
import '../models/dashboard_balance.dart';
import 'dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._service);

  final DashboardService _service;

  @override
  Future<DashboardBalance> getBalance() => _service.getBalance();
}
