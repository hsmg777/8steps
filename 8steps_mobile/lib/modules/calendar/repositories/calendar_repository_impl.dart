import '../../../services/calendar/calendar_service.dart';
import '../models/calendar_event.dart';
import 'calendar_repository.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  CalendarRepositoryImpl(this._service);

  final CalendarService _service;

  @override
  Future<List<CalendarEvent>> getEvents({
    required DateTime from,
    required DateTime to,
  }) {
    return _service.getEvents(from: from, to: to);
  }

  @override
  Future<CalendarEventDetail> getEventDetail(String id) {
    return _service.getEventDetail(id);
  }
}
