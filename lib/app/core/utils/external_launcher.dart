import 'package:url_launcher/url_launcher.dart';

/// Opens external apps for navigation and calls. v1 uses the platform maps app
/// (Google/Apple Maps) rather than an embedded SDK — no API key/billing.
class ExternalLauncher {
  const ExternalLauncher._();

  /// Open turn-by-turn directions to the destination. Prefers coordinates,
  /// falls back to an address search. Returns false if nothing could be opened.
  static Future<bool> navigateTo({
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    Uri? uri;
    if (latitude != null && longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
      );
    } else if (address != null && address.trim().isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
      );
    }
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Open turn-by-turn directions for a specific route. Use explicit origin and
  /// destination when both are known so Google Maps does not infer the wrong
  /// point from the device or stale app state.
  static Future<bool> navigateRoute({
    double? originLatitude,
    double? originLongitude,
    String? originAddress,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    final params = <String, String>{
      'api': '1',
      'travelmode': 'driving',
      'destination': '$destinationLatitude,$destinationLongitude',
    };

    if (originLatitude != null && originLongitude != null) {
      params['origin'] = '$originLatitude,$originLongitude';
    } else if (originAddress != null && originAddress.trim().isNotEmpty) {
      params['origin'] = originAddress.trim();
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', params);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Start a phone call to [phone].
  static Future<bool> call(String phone) {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    return launchUrl(uri);
  }

  /// Open the default mail app.
  static Future<bool> email(String email) {
    final uri = Uri(scheme: 'mailto', path: email);
    return launchUrl(uri);
  }

  /// Open an arbitrary URL (e.g. a Telegram support link) externally.
  static Future<bool> openUrl(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
