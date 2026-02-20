import '../../../services/reports/reports_service.dart';
import '../models/report_models.dart';
import 'reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._service);

  final ReportsService _service;

  @override
  Future<MonthlyReport> getMonthlyReport({required String month}) {
    return _service.getMonthlyReport(month: month);
  }

  @override
  Future<YearlyReport> getYearlyReport({required int year}) {
    return _service.getYearlyReport(year: year);
  }
}
