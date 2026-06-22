/// Compact booking card (from `DriverBookingListResource`).
class BookingListItem {
  const BookingListItem({
    required this.uuid,
    required this.stage,
    this.code,
    this.serviceType,
    this.tripType,
    this.customerName,
    this.customerPhone,
    this.pickupPoint,
    this.pickupLocationName,
    this.dropoffPoint,
    this.dropoffLocationName,
    this.departureDatetime,
    this.passengerCount,
    this.acceptedAt,
    this.allowedActions = const [],
  });

  final String uuid;
  final String stage;
  final String? code;
  final String? serviceType;
  final String? tripType;
  final String? customerName;
  final String? customerPhone;
  final String? pickupPoint;
  final String? pickupLocationName;
  final String? dropoffPoint;
  final String? dropoffLocationName;
  final String? departureDatetime;
  final int? passengerCount;
  final String? acceptedAt;
  final List<String> allowedActions;

  String get pickupLabel {
    if (pickupLocationName != null && pickupLocationName!.isNotEmpty) {
      return pickupLocationName!;
    }
    return pickupPoint ?? '—';
  }

  String get dropoffLabel {
    if (dropoffLocationName != null && dropoffLocationName!.isNotEmpty) {
      return dropoffLocationName!;
    }
    return dropoffPoint ?? '—';
  }

  /// Whether a usable destination is present.
  bool get hasDropoff => dropoffLabel != '—';

  /// Whether a dialable customer phone is present.
  bool get hasPhone =>
      customerPhone != null &&
      customerPhone!.isNotEmpty &&
      customerPhone != 'N/A';

  /// The forward trip step to act on (start → arrived → meet_passenger →
  /// complete), ignoring the secondary "couldn't meet passenger" action.
  /// Null when there's nothing to advance.
  String? get nextAction {
    for (final a in allowedActions) {
      if (a != 'report_not_met_passenger') return a;
    }
    return null;
  }

  factory BookingListItem.fromJson(Map<String, dynamic> json) => BookingListItem(
        uuid: json['uuid']?.toString() ?? '',
        stage: json['stage']?.toString() ?? 'assigned',
        code: json['code']?.toString(),
        serviceType: json['service_type']?.toString(),
        tripType: json['trip_type']?.toString(),
        customerName: json['customer_name']?.toString(),
        customerPhone: json['customer_phone']?.toString(),
        pickupPoint: json['pickup_point']?.toString(),
        pickupLocationName: json['pickup_location_name']?.toString(),
        dropoffPoint: json['dropoff_point']?.toString(),
        dropoffLocationName: json['dropoff_location_name']?.toString(),
        departureDatetime: json['departure_datetime']?.toString(),
        passengerCount: (json['passenger_count'] as num?)?.toInt(),
        acceptedAt: json['accepted_at']?.toString(),
        allowedActions: (json['allowed_actions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}
