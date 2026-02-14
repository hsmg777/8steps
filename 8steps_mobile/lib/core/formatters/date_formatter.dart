import 'package:intl/intl.dart';

class DateFormatter {
  static final _date = DateFormat('dd/MM/yyyy');

  static String short(DateTime date) => _date.format(date);
}
