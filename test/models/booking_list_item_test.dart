import 'package:flutter_test/flutter_test.dart';
import 'package:veha_driver_app/app/data/models/booking_list_item.dart';

void main() {
  group('BookingListItem', () {
    test('parses fields and prefers location name for pickup label', () {
      final item = BookingListItem.fromJson({
        'uuid': 'u1',
        'stage': 'assigned',
        'service_type': 'private',
        'customer_name': 'Sok',
        'pickup_point': 'Street 240',
        'pickup_location_name': 'BKK1',
        'passenger_count': 3,
        'allowed_actions': ['accept'],
      });

      expect(item.uuid, 'u1');
      expect(item.pickupLabel, 'BKK1');
      expect(item.passengerCount, 3);
      expect(item.allowedActions, ['accept']);
    });

    test('falls back to pickup point when no location name', () {
      final item = BookingListItem.fromJson({
        'uuid': 'u2',
        'stage': 'assigned',
        'pickup_point': 'Street 240',
      });

      expect(item.pickupLabel, 'Street 240');
    });
  });
}
