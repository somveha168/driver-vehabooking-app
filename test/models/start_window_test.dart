import 'package:flutter_test/flutter_test.dart';
import 'package:veha_driver_app/app/data/models/booking_detail.dart';
import 'package:veha_driver_app/app/data/models/booking_list_item.dart';

void main() {
  final unlocksAt = DateTime.now().toUtc().add(const Duration(hours: 22));

  group('BookingListItem start window', () {
    test('parses start_available_at and reports the window as closed', () {
      final b = BookingListItem.fromJson({
        'allowed_actions': <String>[],
        'start_available_at': unlocksAt.toIso8601String(),
      });

      expect(b.isStartWindowClosed, isTrue);
      expect(b.startAvailableAt, isNotNull);
      // Nothing to act on yet - the button must render disabled, not missing.
      expect(b.nextAction, isNull);
    });

    test('window is open when the API omits the field', () {
      final b = BookingListItem.fromJson({
        'allowed_actions': ['start'],
      });

      expect(b.isStartWindowClosed, isFalse);
      expect(b.startAvailableAt, isNull);
      expect(b.nextAction, 'start');
    });

    test('an unparseable timestamp does not lock the button', () {
      final b = BookingListItem.fromJson({
        'allowed_actions': <String>[],
        'start_available_at': 'not-a-date',
      });

      expect(b.startAvailableAt, isNull);
      expect(b.isStartWindowClosed, isFalse);
    });
  });

  group('BookingDetail start window', () {
    test('parses start_available_at and reports the window as closed', () {
      final b = BookingDetail.fromJson({
        'allowed_actions': <String>[],
        'start_available_at': unlocksAt.toIso8601String(),
      });

      expect(b.isStartWindowClosed, isTrue);
      expect(b.can, isFalse);
    });

    test('window is open once start is allowed', () {
      final b = BookingDetail.fromJson({
        'allowed_actions': ['start'],
      });

      expect(b.isStartWindowClosed, isFalse);
      expect(b.allows('start'), isTrue);
    });
  });
}
