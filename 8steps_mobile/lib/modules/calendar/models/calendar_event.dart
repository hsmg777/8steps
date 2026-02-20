class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    this.amount,
    this.cardId,
    this.cardName,
    this.originType,
    this.originId,
    this.metadata,
  });

  final String id;
  final String type;
  final String title;
  final DateTime date;
  final double? amount;
  final String? cardId;
  final String? cardName;
  final String? originType;
  final String? originId;
  final Map<String, dynamic>? metadata;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      date:
          DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      amount: _toDoubleOrNull(json['amount']),
      cardId: json['cardId']?.toString() ?? json['card_id']?.toString(),
      cardName: json['cardName']?.toString() ?? json['card_name']?.toString(),
      originType:
          json['originType']?.toString() ?? json['origin_type']?.toString(),
      originId: json['originId']?.toString() ?? json['origin_id']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
    );
  }
}

class CalendarEventDetail {
  const CalendarEventDetail({
    required this.event,
    this.origin,
  });

  final CalendarEvent event;
  final Map<String, dynamic>? origin;

  factory CalendarEventDetail.fromJson(Map<String, dynamic> json) {
    final eventJson = json['event'] is Map<String, dynamic>
        ? json['event'] as Map<String, dynamic>
        : json;

    return CalendarEventDetail(
      event: CalendarEvent.fromJson(eventJson),
      origin: json['origin'] is Map<String, dynamic>
          ? json['origin'] as Map<String, dynamic>
          : null,
    );
  }
}

double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
