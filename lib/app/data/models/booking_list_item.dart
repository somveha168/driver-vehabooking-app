/// Compact booking card (from `DriverBookingListResource`).
class BookingListItem {
  const BookingListItem({
    required this.uuid,
    required this.stage,
    this.code,
    this.serviceType,
    this.tripType,
    this.customerName,
    this.pickupPoint,
    this.pickupLocationName,
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
  final String? pickupPoint;
  final String? pickupLocationName;
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

  factory BookingListItem.fromJson(Map<String, dynamic> json) => BookingListItem(
        uuid: json['uuid']?.toString() ?? '',
        stage: json['stage']?.toString() ?? 'assigned',
        code: json['code']?.toString(),
        serviceType: json['service_type']?.toString(),
        tripType: json['trip_type']?.toString(),
        customerName: json['customer_name']?.toString(),
        pickupPoint: json['pickup_point']?.toString(),
        pickupLocationName: json['pickup_location_name']?.toString(),
        departureDatetime: json['departure_datetime']?.toString(),
        passengerCount: (json['passenger_count'] as num?)?.toInt(),
        acceptedAt: json['accepted_at']?.toString(),
        allowedActions: (json['allowed_actions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}
