import 'package:dio/dio.dart';

import '../../modules/reports/models/report_models.dart';

class ReportsService {
  ReportsService(this._dio);

  final Dio _dio;

  Future<MonthlyReport> getMonthlyReport({required String month}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reports/monthly',
      queryParameters: {'month': month},
    );
    final body = response.data;
    if (body == null) {
      throw const FormatException('Respuesta inválida de reporte mensual');
    }
    return MonthlyReport.fromJson(body);
  }

  Future<YearlyReport> getYearlyReport({required int year}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reports/yearly',
      queryParameters: {'year': year},
    );
    final body = response.data;
    if (body == null) {
      throw const FormatException('Respuesta inválida de reporte anual');
    }
    return YearlyReport.fromJson(body);
  }
}
