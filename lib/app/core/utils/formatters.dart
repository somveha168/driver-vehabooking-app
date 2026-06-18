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

  /// Short "time from now" until [iso], e.g. "2h 15m" or "20m".
  /// Returns null when the time is now or already past.
  static String? timeUntil(String? iso) {
    final dt = _parse(iso);
    if (dt == null) return null;
    final diff = dt.toLocal().difference(DateTime.now());
    if (diff.inMinutes <= 0) return null;
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  /// Weekday + day + month for the home header, e.g. "Thu, 18 Jun".
  static String todayLabel() => DateFormat('EEE, d MMM').format(DateTime.now());

  static DateTime? _parse(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }
}
