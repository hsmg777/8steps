import 'package:dio/dio.dart';

import '../../modules/calendar/models/calendar_event.dart';

class CalendarService {
  CalendarService(this._dio);

  final Dio _dio;

  Future<List<CalendarEvent>> getEvents({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _dio.get(
      '/calendar/events',
      queryParameters: {
        'from': _dateOnly(from),
        'to': _dateOnly(to),
      },
    );

    final raw = _extractList(response.data, 'events');
    return raw
        .whereType<Map<String, dynamic>>()
        .map(CalendarEvent.fromJson)
        .toList();
  }

  Future<CalendarEventDetail> getEventDetail(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/calendar/events/$id');
    final body = response.data;
    if (body == null) {
      throw const FormatException('Respuesta inválida de detalle de evento');
    }
    return CalendarEventDetail.fromJson(body);
  }

  List<dynamic> _extractList(dynamic body, String key) {
    if (body is List<dynamic>) return body;
    if (body is! Map<String, dynamic>) return const [];

    final direct = body[key];
    if (direct is List<dynamic>) return direct;

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final nested = data[key];
      if (nested is List<dynamic>) return nested;
    }

    return const [];
  }

  String _dateOnly(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}
