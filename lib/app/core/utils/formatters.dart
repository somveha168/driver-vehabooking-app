import 'package:intl/intl.dart';

/// Date/time display helpers. All inputs are ISO-8601 strings from the API.
class Formatters {
  const Formatters._();

  /// e.g. "Thu, 18 Jun · 9:00 AM". Returns '—' for null/invalid input.
  static String dateTime(String? iso) {
    final dt = _parse(iso);
    if (dt == null) return '—';
    return DateFormat('EEE, d MMM · h:mm a').format(dt.toLocal());
  }

  /// e.g. "9:00 AM".
  static String time(String? iso) {
    final dt = _parse(iso);
    if (dt == null) return '—';
    return DateFormat('h:mm a').format(dt.toLocal());
  }

  static DateTime? _parse(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }
}
