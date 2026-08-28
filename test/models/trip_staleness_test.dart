import 'package:flutter_test/flutter_test.dart';
import 'package:veha_driver_app/app/data/models/booking_detail.dart';
import 'package:veha_driver_app/app/data/models/booking_list_item.dart';

void main() {
  String ago(Duration d) =>
      DateTime.now().toUtc().subtract(d).toIso8601String();

  BookingListItem item({
    required String departure,
    required List<String> actions,
  }) => BookingListItem.fromJson({
    'departure_datetime': departure,
    'allowed_actions': actions,
  });

  BookingDetail detail({
    required String departure,
    required List<String> actions,
  }) => BookingDetail.fromJson({
    'departure_datetime': departure,
    'allowed_actions': actions,
  });

  group('BookingListItem.isStaleInProgress', () {
    test('true for a started trip long past its departure', () {
      expect(
        item(
          departure: ago(const Duration(days: 30)),
          actions: ['arrived'],
        ).isStaleInProgress,
        isTrue,
      );
    });

    test('false for a started trip that departed recently', () {
      expect(
        item(
          departure: ago(const Duration(hours: 2)),
          actions: ['arrived'],
        ).isStaleInProgress,
        isFalse,
      );
    });

    test('false for a trip that was never started, however old', () {
      // These are covered by isStartTooOld and the dispatch review flow.
      final b = item(
        departure: ago(const Duration(days: 30)),
        actions: ['start'],
      );
      expect(b.isStaleInProgress, isFalse);
      expect(b.isStartTooOld, isTrue);
    });

    test('false when there is nothing left to act on', () {
      expect(
        item(
          departure: ago(const Duration(days: 30)),
          actions: <String>[],
        ).isStaleInProgress,
        isFalse,
      );
    });

    test('false for a future departure', () {
      final future = DateTime.now()
          .toUtc()
          .add(const Duration(days: 1))
          .toIso8601String();
      expect(
        item(departure: future, actions: ['arrived']).isStaleInProgress,
        isFalse,
      );
    });
  });

  group('BookingDetail.isStaleInProgress', () {
    test('true for a started trip long past its departure', () {
      expect(
        detail(
          departure: ago(const Duration(days: 30)),
          actions: ['arrived'],
        ).isStaleInProgress,
        isTrue,
      );
    });

    test('false while the trip has not been started', () {
      expect(
        detail(
          departure: ago(const Duration(days: 30)),
          actions: ['start'],
        ).isStaleInProgress,
        isFalse,
      );
    });

    test('false with no actions left', () {
      expect(
        detail(
          departure: ago(const Duration(days: 30)),
          actions: <String>[],
        ).isStaleInProgress,
        isFalse,
      );
    });
  });
}
