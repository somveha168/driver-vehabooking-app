import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripRoute {
  const TripRoute({
    required this.mode,
    required this.routeFound,
    required this.points,
    this.distanceMeters,
    this.durationSeconds,
  });

  final String mode;
  final bool routeFound;
  final List<LatLng> points;
  final int? distanceMeters;
  final int? durationSeconds;

  bool get hasRoadRoute => routeFound && points.length > 1;

  factory TripRoute.fromJson(Map<String, dynamic> json) {
    final encoded = json['encoded_polyline']?.toString();
    return TripRoute(
      mode: json['mode']?.toString() ?? 'passenger',
      routeFound: json['route_found'] == true,
      points: encoded == null || encoded.isEmpty
          ? const []
          : _decodePolyline(encoded),
      distanceMeters: (json['distance_meters'] as num?)?.toInt(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
    );
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encoded.length) {
      final latResult = _decodeValue(encoded, index);
      index = latResult.nextIndex;
      latitude += latResult.value;

      final lngResult = _decodeValue(encoded, index);
      index = lngResult.nextIndex;
      longitude += lngResult.value;

      points.add(LatLng(latitude / 1e5, longitude / 1e5));
    }

    return points;
  }

  static ({int value, int nextIndex}) _decodeValue(String encoded, int index) {
    var result = 0;
    var shift = 0;
    var currentIndex = index;
    int byte;

    do {
      byte = encoded.codeUnitAt(currentIndex++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20 && currentIndex < encoded.length);

    final value = (result & 1) == 1 ? ~(result >> 1) : result >> 1;
    return (value: value, nextIndex: currentIndex);
  }
}
