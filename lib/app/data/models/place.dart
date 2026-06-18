/// A pickup or drop-off location with optional coordinates for navigation.
class Place {
  const Place({
    this.address,
    this.locationName,
    this.latitude,
    this.longitude,
  });

  final String? address;
  final String? locationName;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Best available human label for the place.
  String get label =>
      (locationName != null && locationName!.isNotEmpty) ? locationName! : (address ?? '—');

  factory Place.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Place();
    return Place(
      address: json['address']?.toString(),
      locationName: json['location_name']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
