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

    test('parses the server-authoritative unfinished trip recovery state', () {
      final item = BookingListItem.fromJson({
        'uuid': 'u-stale',
        'stage': 'arrived_location',
        'needs_resolution': true,
        'resolution_available_at': '2026-09-01T02:00:00+07:00',
        'allowed_actions': ['resolve_completed', 'report_pickup_issue'],
      });

      expect(item.needsResolution, isTrue);
      expect(item.isStaleInProgress, isTrue);
      expect(item.nextAction, 'resolve_completed');
      expect(item.resolutionAvailableAt, isNotNull);
    });

    test('uses the linked return leg route without reversing it again', () {
      final item = BookingListItem.fromJson({
        'uuid': 'u-return',
        'assignment_id': 7,
        'booking_leg_id': 999,
        'leg': {
          'id': '88',
          'uuid': 'leg-return',
          'status': 'active',
          'schedule_id': '44',
          'origin_id': 12,
          'destination_id': 13,
        },
        'trip_type': 'return',
        'stage': 'assigned',
        'route_summary': {'origin': 'Phnom Penh', 'destination': 'Siem Reap'},
      });

      expect(item.bookingLegId, 88);
      expect(item.bookingLegUuid, 'leg-return');
      expect(item.bookingLegStatus, 'active');
      expect(item.scheduleId, 44);
      expect(item.originId, 12);
      expect(item.destinationId, 13);
      expect(item.driverRouteOriginLabel, 'Phnom Penh');
      expect(item.driverRouteDestinationLabel, 'Siem Reap');
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
