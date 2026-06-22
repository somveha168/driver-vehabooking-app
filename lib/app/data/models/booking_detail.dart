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
    this.driverTripStatus,
    this.acceptedAt,
    this.startedAt,
    this.arrivedAt,
    this.metPassengerAt,
    this.droppedAt,
    this.notMetPassengerReason,
    this.allowedActions = const [],
    this.customerName,
    this.customerPhone,
    this.pickup = const Place(),
    this.dropoff = const Place(),
    this.departureDatetime,
    this.passengerCount,
    this.nationality,
    this.notes,
    this.vehicleBooked,
    this.vehicleModel,
    this.vehiclePlate,
    this.vehicleColor,
    this.vehicleSeats,
    this.isReturn = false,
    this.returnDate,
    this.returnTime,
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
  final String? driverTripStatus;
  final String? acceptedAt;
  final String? startedAt;
  final String? arrivedAt;
  final String? metPassengerAt;
  final String? droppedAt;
  final String? notMetPassengerReason;
  final List<String> allowedActions;

  final String? customerName;
  final String? customerPhone;

  final Place pickup;
  final Place dropoff;

  final String? departureDatetime;
  final int? passengerCount;
  final String? nationality;
  final String? notes;

  final String? vehicleBooked; // class the customer booked, e.g. "Van 10 Seats"
  final String? vehicleModel; // real assigned vehicle, e.g. "Luxis Camary"
  final String? vehiclePlate;
  final String? vehicleColor;
  final int? vehicleSeats;

  final bool isReturn;
  final String? returnDate; // ISO date (yyyy-MM-dd)
  final String? returnTime; // HH:mm

  final String? flightNumber;
  final String? airline;
  final String? terminal;
  final String? flightDatetime;

  bool get isAirport => serviceType == 'airport';
  bool get can => allowedActions.isNotEmpty;
  bool allows(String action) => allowedActions.contains(action);

  /// A round-trip booking with a usable return date.
  bool get hasReturn => isReturn && returnDate != null && returnDate!.isNotEmpty;

  /// Whether any vehicle info (booked or assigned) exists.
  bool get hasVehicle =>
      (vehicleBooked?.isNotEmpty ?? false) ||
      (vehicleModel?.isNotEmpty ?? false) ||
      (vehiclePlate?.isNotEmpty ?? false);

  /// The real assigned vehicle line, e.g. "Luxis Camary · 2A-2025".
  String? get assignedVehicleLabel {
    final parts = <String>[
      if (vehicleModel != null && vehicleModel!.isNotEmpty) vehicleModel!,
      if (vehiclePlate != null && vehiclePlate!.isNotEmpty) vehiclePlate!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  factory BookingDetail.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    final flight = json['flight'] as Map<String, dynamic>?;
    final returnTrip = json['return_trip'] as Map<String, dynamic>?;

    return BookingDetail(
      uuid: json['uuid']?.toString() ?? '',
      stage: json['stage']?.toString() ?? 'assigned',
      code: json['code']?.toString(),
      serviceType: json['service_type']?.toString(),
      tripType: json['trip_type']?.toString(),
      status: json['status']?.toString(),
      driverPickupStatus: json['driver_pickup_status']?.toString(),
      driverTripStatus: json['driver_trip_status']?.toString(),
      acceptedAt: json['accepted_at']?.toString(),
      startedAt: json['started_at']?.toString(),
      arrivedAt: json['arrived_at']?.toString(),
      metPassengerAt: json['met_passenger_at']?.toString(),
      droppedAt: json['dropped_at']?.toString(),
      notMetPassengerReason: json['not_met_passenger_reason']?.toString(),
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
      nationality: json['nationality']?.toString(),
      notes: json['notes']?.toString(),
      vehicleBooked: vehicle?['booked_name']?.toString(),
      vehicleModel: vehicle?['model']?.toString(),
      vehiclePlate: vehicle?['plate_number']?.toString(),
      vehicleColor: vehicle?['color']?.toString(),
      vehicleSeats: (vehicle?['seats'] as num?)?.toInt(),
      isReturn: json['is_return'] == true,
      returnDate: returnTrip?['date']?.toString(),
      returnTime: returnTrip?['time']?.toString(),
      flightNumber: flight?['number']?.toString(),
      airline: flight?['airline']?.toString(),
      terminal: flight?['terminal']?.toString(),
      flightDatetime: flight?['datetime']?.toString(),
    );
  }
}
