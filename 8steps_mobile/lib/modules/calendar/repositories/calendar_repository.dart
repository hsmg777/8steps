import '../models/calendar_event.dart';

abstract class CalendarRepository {
  Future<List<CalendarEvent>> getEvents({
    required DateTime from,
    required DateTime to,
  });

  Future<CalendarEventDetail> getEventDetail(String id);
}
