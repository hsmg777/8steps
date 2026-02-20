import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/utils/app_alert.dart';
import '../../../modules/calendar/models/calendar_event.dart';

class FinancialCalendarScreen extends ConsumerStatefulWidget {
  const FinancialCalendarScreen({super.key});

  @override
  ConsumerState<FinancialCalendarScreen> createState() =>
      _FinancialCalendarScreenState();
}

class _FinancialCalendarScreenState
    extends ConsumerState<FinancialCalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  final _dateLabelFormat = DateFormat('EEEE, d MMMM y', 'es');
  final _hourFormat = DateFormat('HH:mm');
  final _monthLabelFormat = DateFormat('MMMM y', 'es');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _displayedMonth = DateTime(now.year, now.month, 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMonthEvents(_displayedMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarViewModelProvider);
    final eventsOfDay = _eventsOfDay(state.events, _selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFF13151D),
      appBar: AppBar(
        title: const Text('Calendario financiero'),
        actions: [
          IconButton(
            onPressed:
                state.loading ? null : () => _loadMonthEvents(_displayedMonth),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CalendarCard(
            displayedMonth: _displayedMonth,
            selectedDate: _selectedDate,
            monthLabel: _capitalize(_monthLabelFormat.format(_displayedMonth)),
            events: state.events,
            onPreviousMonth: () {
              final prev =
                  DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
              setState(() {
                _displayedMonth = prev;
                if (_selectedDate.month != prev.month ||
                    _selectedDate.year != prev.year) {
                  _selectedDate = DateTime(prev.year, prev.month, 1);
                }
              });
              _loadMonthEvents(prev);
            },
            onNextMonth: () {
              final next =
                  DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
              setState(() {
                _displayedMonth = next;
                if (_selectedDate.month != next.month ||
                    _selectedDate.year != next.year) {
                  _selectedDate = DateTime(next.year, next.month, 1);
                }
              });
              _loadMonthEvents(next);
            },
            onSelectDay: (date) {
              setState(() => _selectedDate = date);
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1E28),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x332D364A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Eventos del día',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _capitalize(_dateLabelFormat.format(_selectedDate)),
                  style: const TextStyle(color: Colors.white70),
                ),
                if (state.loading) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                ] else if (eventsOfDay.isEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'No hay eventos para esta fecha.',
                    style: TextStyle(color: Colors.white60),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  ...eventsOfDay.map(
                    (event) => _EventTile(
                      event: event,
                      hourFormat: _hourFormat,
                      onTap: () => _openEventDetail(event.id),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMonthEvents(DateTime month) async {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    await ref.read(calendarViewModelProvider.notifier).loadEvents(
          from: first,
          to: last,
        );

    if (!mounted) return;
    final error = ref.read(calendarViewModelProvider).errorMessage;
    if (error != null && error.isNotEmpty) {
      AppAlert.error(context, error);
    }
  }

  Future<void> _openEventDetail(String id) async {
    final detail =
        await ref.read(calendarViewModelProvider.notifier).loadEventDetail(id);
    if (!mounted) return;

    if (detail == null) {
      final error = ref.read(calendarViewModelProvider).errorMessage;
      if (error != null) AppAlert.error(context, error);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(detail.event.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipo: ${detail.event.type}'),
              Text('Fecha: ${detail.event.date.toLocal()}'),
              if (detail.event.amount != null)
                Text('Monto: \$${detail.event.amount!.toStringAsFixed(2)}'),
              if (detail.event.cardName != null)
                Text('Tarjeta: ${detail.event.cardName}'),
              if (detail.event.originType != null)
                Text('Origen: ${detail.event.originType}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  List<CalendarEvent> _eventsOfDay(List<CalendarEvent> events, DateTime day) {
    return events.where((event) {
      final d = event.date.toLocal();
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.displayedMonth,
    required this.selectedDate,
    required this.monthLabel,
    required this.events,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDay,
  });

  final DateTime displayedMonth;
  final DateTime selectedDate;
  final String monthLabel;
  final List<CalendarEvent> events;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth =
        DateTime(displayedMonth.year, displayedMonth.month, 1);
    final daysInMonth =
        DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;
    final startOffset = firstDayOfMonth.weekday - 1;
    final totalCells = ((startOffset + daysInMonth) / 7).ceil() * 7;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2130), Color(0xFF171C29)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left, color: Colors.white70),
              ),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              _WeekdayLabel('L'),
              _WeekdayLabel('M'),
              _WeekdayLabel('M'),
              _WeekdayLabel('J'),
              _WeekdayLabel('V'),
              _WeekdayLabel('S'),
              _WeekdayLabel('D'),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            itemCount: totalCells,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.86,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - startOffset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final dayDate = DateTime(
                  displayedMonth.year, displayedMonth.month, dayNumber);
              final isSelected = selectedDate.year == dayDate.year &&
                  selectedDate.month == dayDate.month &&
                  selectedDate.day == dayDate.day;
              final isToday = _isToday(dayDate);

              final eventsOfDay = _eventsOfDay(events, dayDate);
              final dotColors = _dotColors(eventsOfDay);

              return GestureDetector(
                onTap: () => onSelectDay(dayDate),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1EA7CF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isToday && !isSelected
                          ? const Color(0xFF1EA7CF)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (dotColors.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 2,
                          children: dotColors
                              .take(3)
                              .map(
                                (c) => Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<CalendarEvent> _eventsOfDay(List<CalendarEvent> all, DateTime day) {
    return all.where((event) {
      final d = event.date.toLocal();
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  List<Color> _dotColors(List<CalendarEvent> dayEvents) {
    final colors = <Color>[];
    for (final event in dayEvents) {
      colors.add(_colorForType(event.type));
    }
    return colors.toSet().toList();
  }

  Color _colorForType(String type) {
    final normalized = type.toUpperCase();
    if (normalized.contains('INCOME')) return const Color(0xFF65E5A5);
    if (normalized.contains('EXPENSE')) return const Color(0xFFFF7D7D);
    return const Color(0xFF2FB9E2);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.hourFormat,
    required this.onTap,
  });

  final CalendarEvent event;
  final DateFormat hourFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amountColor = _amountColor(event.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF151B27),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        title: Text(
          event.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${event.type} • ${hourFormat.format(event.date.toLocal())}',
          style: const TextStyle(color: Colors.white60),
        ),
        trailing: event.amount == null
            ? const Icon(Icons.chevron_right, color: Colors.white60)
            : Text(
                '\$${event.amount!.toStringAsFixed(2)}',
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Color _amountColor(String type) {
    final normalized = type.toUpperCase();
    if (normalized.contains('INCOME')) return const Color(0xFF65E5A5);
    if (normalized.contains('EXPENSE')) return const Color(0xFFFF7D7D);
    return const Color(0xFF9CCBFF);
  }
}
