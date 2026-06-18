import 'place.dart';

/// Full booking detail (from `DriverBookingDetailResource`).
class BookingDetail {
  const BookingDetail({
    required this.uuid,
    required this.stage,
    this.code,
    this.serviceType,
    this.tripType,
    this.status,
    this.driverPickupStatus,
    this.acceptedAt,
    this.allowedActions = const [],
    this.customerName,
    this.customerPhone,
    this.pickup = const Place(),
    this.dropoff = const Place(),
    this.departureDatetime,
    this.passengerCount,
    this.notes,
    this.vehicleType,
    this.plateNumber,
    this.flightNumber,
    this.airline,
    this.terminal,
    this.flightDatetime,
  });

  final String uuid;
  final String stage;
  final String? code;
  final String? serviceType;
  final String? tripType;
  final String? status;
  final String? driverPickupStatus;
  final String? acceptedAt;
  final List<String> allowedActions;

  final String? customerName;
  final String? customerPhone;

  final Place pickup;
  final Place dropoff;

  final String? departureDatetime;
  final int? passengerCount;
  final String? notes;

  final String? vehicleType;
  final String? plateNumber;

  final String? flightNumber;
  final String? airline;
  final String? terminal;
  final String? flightDatetime;

  bool get isAirport => serviceType == 'airport';
  bool get can => allowedActions.isNotEmpty;
  bool allows(String action) => allowedActions.contains(action);

  factory BookingDetail.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    final flight = json['flight'] as Map<String, dynamic>?;

    return BookingDetail(
      uuid: json['uuid']?.toString() ?? '',
      stage: json['stage']?.toString() ?? 'assigned',
      code: json['code']?.toString(),
      serviceType: json['service_type']?.toString(),
      tripType: json['trip_type']?.toString(),
      status: json['status']?.toString(),
      driverPickupStatus: json['driver_pickup_status']?.toString(),
      acceptedAt: json['accepted_at']?.toString(),
      allowedActions: (json['allowed_actions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      customerName: customer?['name']?.toString(),
      customerPhone: customer?['phone']?.toString(),
      pickup: Place.fromJson(json['pickup'] as Map<String, dynamic>?),
      dropoff: Place.fromJson(json['dropoff'] as Map<String, dynamic>?),
      departureDatetime: json['departure_datetime']?.toString(),
      passengerCount: (json['passenger_count'] as num?)?.toInt(),
      notes: json['notes']?.toString(),
      vehicleType: vehicle?['type']?.toString(),
      plateNumber: vehicle?['plate_number']?.toString(),
      flightNumber: flight?['number']?.toString(),
      airline: flight?['airline']?.toString(),
      terminal: flight?['terminal']?.toString(),
      flightDatetime: flight?['datetime']?.toString(),
    );
  }
}
