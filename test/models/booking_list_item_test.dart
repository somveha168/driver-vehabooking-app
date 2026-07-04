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

    test('tolerates invalid nested shapes and string numbers', () {
      final item = BookingListItem.fromJson({
        'uuid': 100,
        'stage': null,
        'assignment_id': '7',
        'route_summary': 'bad-route',
        'vehicle': {'seats': '5'},
        'pickup_latitude': '11.5564',
        'pickup_longitude': '104.9282',
        'passenger_count': '3',
        'allowed_actions': {'bad': 'shape'},
        'pickup_issue_note_max_length': '250',
        'start_blocked_by': {'uuid': 200, 'assignment_id': '8'},
      });

      expect(item.uuid, '100');
      expect(item.stage, 'assigned');
      expect(item.assignmentId, 7);
      expect(item.vehicleSeats, 5);
      expect(item.pickupLatitude, 11.5564);
      expect(item.pickupLongitude, 104.9282);
      expect(item.passengerCount, 3);
      expect(item.allowedActions, isEmpty);
      expect(item.pickupIssueNoteMaxLength, 250);
      expect(item.startBlockedBy?.uuid, '200');
      expect(item.startBlockedBy?.assignmentId, 8);
    });
  });
}
