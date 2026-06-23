import 'package:flutter_test/flutter_test.dart';
import 'package:veha_driver_app/app/data/models/dashboard_summary.dart';

void main() {
  group('DashboardSummary.fromJson', () {
    test(
      'parses verification status, active state, counts and next pickup',
      () {
        final summary = DashboardSummary.fromJson({
          'status': 'approved',
          'status_label': 'Approved',
          'active': true,
          'counts': {
            'assigned': 2,
            'accepted': 1,
            'on_trip': 0,
            'completed': 5,
          },
          'next_pickup': {
            'uuid': 'u1',
            'stage': 'assigned',
            'customer_name': 'Jane',
            'allowed_actions': ['accept'],
          },
        });

        expect(summary.status, 'approved');
        expect(summary.statusLabel, 'Approved');
        expect(summary.active, isTrue);
        expect(summary.counts.assigned, 2);
        expect(summary.counts.completed, 5);
        expect(summary.nextPickup, isNotNull);
        expect(summary.nextPickup!.customerName, 'Jane');
      },
    );

    test('handles null next pickup and missing counts', () {
      final summary = DashboardSummary.fromJson({
        'status': 'pending',
        'counts': null,
        'next_pickup': null,
      });

      expect(summary.status, 'pending');
      expect(summary.statusLabel, 'Pending');
      expect(summary.active, isFalse);
      expect(summary.counts.assigned, 0);
      expect(summary.nextPickup, isNull);
    });
  });
}
