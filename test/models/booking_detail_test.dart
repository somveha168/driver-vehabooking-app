import 'package:flutter_test/flutter_test.dart';
import 'package:veha_driver_app/app/data/models/booking_detail.dart';

void main() {
  group('BookingDetail.fromJson', () {
    test('parses an airport booking with pickup coordinates and actions', () {
      final json = {
        'uuid': 'abc-123',
        'code': 'TAX-1',
        'service_type': 'airport',
        'trip_type': 'outbound',
        'stage': 'accepted',
        'status': 'confirmed',
        'driver_pickup_status': 'pending',
        'accepted_at': '2026-06-18T08:00:00+07:00',
        'allowed_actions': ['confirm_pickup'],
        'customer': {'name': 'Jane Doe', 'phone': '+85599999999'},
        'pickup': {
          'address': 'Hotel Sunrise',
          'location_name': 'BKK1',
          'nearby_location': 'Near Brown Coffee',
          'latitude': 11.5564,
          'longitude': 104.9282,
        },
        'dropoff': {
          'address': 'PNH Airport',
          'nearby_location': 'Opposite Gate 3',
        },
        'departure_datetime': '2026-06-18T09:00:00+07:00',
        'passenger_count': 2,
        'vehicle': {'type': 'Sedan', 'plate_number': '2AB-1234'},
        'flight': {'number': 'QR123', 'airline': 'Qatar', 'terminal': '1'},
      };

      final b = BookingDetail.fromJson(json);

      expect(b.uuid, 'abc-123');
      expect(b.stage, 'accepted');
      expect(b.isAirport, isTrue);
      expect(b.allows('confirm_pickup'), isTrue);
      expect(b.allows('complete'), isFalse);
      expect(b.customerPhone, '+85599999999');
      expect(b.pickup.hasCoordinates, isTrue);
      expect(b.pickup.latitude, 11.5564);
      expect(b.pickup.label, 'BKK1');
      expect(b.pickup.nearbyLocation, 'Near Brown Coffee');
      expect(b.dropoff.nearbyLocation, 'Opposite Gate 3');
      expect(b.flightNumber, 'QR123');
    });

    test('parses the trip lifecycle status, timestamps and next action', () {
      final b = BookingDetail.fromJson({
        'uuid': 'u1',
        'stage': 'arrived_location',
        'driver_trip_status': 'arrived_location',
        'started_at': '2026-06-19T09:00:00+07:00',
        'arrived_at': '2026-06-19T09:20:00+07:00',
        'met_passenger_at': null,
        'dropped_at': null,
        'allowed_actions': ['meet_passenger'],
      });

      expect(b.driverTripStatus, 'arrived_location');
      expect(b.startedAt, isNotNull);
      expect(b.arrivedAt, isNotNull);
      expect(b.metPassengerAt, isNull);
      expect(b.allows('meet_passenger'), isTrue);
    });

    test('offers report_pickup_issue and parses the pickup issue reason', () {
      final beforeArrival = BookingDetail.fromJson({
        'uuid': 'u-before',
        'stage': 'start',
        'driver_trip_status': 'start',
        'allowed_actions': ['arrived', 'report_pickup_issue'],
      });

      expect(beforeArrival.allows('report_pickup_issue'), isTrue);
      expect(beforeArrival.canReportPickupIssue, isTrue);

      final b = BookingDetail.fromJson({
        'uuid': 'u2',
        'stage': 'arrived_location',
        'driver_trip_status': 'arrived_location',
        'allowed_actions': ['meet_passenger', 'report_pickup_issue'],
      });

      expect(b.allows('report_pickup_issue'), isTrue);
      expect(b.canReportPickupIssue, isTrue);

      final afterMeet = BookingDetail.fromJson({
        'uuid': 'u-meet',
        'stage': 'meet_passenger',
        'driver_trip_status': 'meet_passenger',
        'allowed_actions': ['complete', 'report_pickup_issue'],
      });
      expect(afterMeet.canReportPickupIssue, isTrue);

      final closed = BookingDetail.fromJson({
        'uuid': 'u3',
        'stage': 'pickup_issue',
        'driver_trip_status': 'pickup_issue',
        'pickup_issue_reason': "Passenger didn't show up",
        'pickup_issue_reason_options': [
          "Passenger didn't show up",
          "Can't reach passenger",
        ],
        'pickup_issue_note_max_length': 280,
        'allowed_actions': [],
      });

      expect(closed.stage, 'pickup_issue');
      expect(closed.pickupIssueReason, "Passenger didn't show up");
      expect(closed.pickupIssueReasonOptions, [
        "Passenger didn't show up",
        "Can't reach passenger",
      ]);
      expect(closed.pickupIssueNoteMaxLength, 280);
      expect(closed.can, isFalse);
    });

    test('handles missing optional blocks gracefully', () {
      final b = BookingDetail.fromJson({'uuid': 'x', 'stage': 'assigned'});

      expect(b.allowedActions, isEmpty);
      expect(b.can, isFalse);
      expect(b.pickup.hasCoordinates, isFalse);
      expect(b.pickup.label, '—');
      expect(b.isAirport, isFalse);
    });
  });
}
