import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _standardDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy hh:mm a');
  static final DateFormat _friendlyDate = DateFormat('d MMM yyyy');
  static final DateFormat _headerDate = DateFormat('d MMM');

  /// Standard DD/MM/YYYY format required by specs
  static String format(DateTime date) => _standardDate.format(date);

  static String formatIso(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return _standardDate.format(dt);
    } catch (_) {
      return isoString;
    }
  }

  static String formatTime(DateTime date) => _timeFormat.format(date);

  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  static String formatFriendly(DateTime date) => _friendlyDate.format(date);

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Displays "Today, 14 Nov" or "Yesterday, 13 Nov" or "14 Nov"
  static String formatHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDay = DateTime(date.year, date.month, date.day);

    if (inputDay == today) {
      return 'Today, ${_headerDate.format(date)}';
    } else if (inputDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_headerDate.format(date)}';
    }
    return _friendlyDate.format(date);
  }
}
