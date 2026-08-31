import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/location/location_service.dart';
import '../../core/maps/route_map_args.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/external_launcher.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/step_action_button.dart';
import '../../data/models/booking_detail.dart';
import '../../data/models/place.dart';
import '../../data/models/trip_route.dart';
import '../../data/repositories/booking_repository.dart';

const _focusedMapStyle = '''
[
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"road.local","elementType":"labels","stylers":[{"visibility":"simplified"}]},
  {"featureType":"administrative","elementType":"labels","stylers":[{"visibility":"simplified"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#eef8f4"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#bfe9ee"}]}
]
''';

const _routeRefreshInterval = Duration(seconds: 30);
const _routeRefreshDistanceMeters = 80.0;
const _markerUpdateDistanceMeters = 2.0;
const _locationSyncInterval = Duration(seconds: 20);
const _locationSyncDistanceMeters = 20.0;
const _pickupApproachingDistanceMeters = 1000.0;
const _pickupArrivalDistanceMeters = 200.0;

class TripMapView extends StatefulWidget {
  const TripMapView({super.key});

  @override
  State<TripMapView> createState() => _TripMapViewState();
}

class _TripMapViewState extends State<TripMapView> {
  GoogleMapController? _mapController;
  DriverLocation? _driverLocation;
  DriverLocation? _lastRouteLocation;
  DriverLocation? _lastSyncedLocation;
  DateTime? _lastLocationSyncAt;
  TripRoute? _roadRoute;
  String? _lastRouteMode;
  Timer? _routeRefreshTimer;
  StreamSubscription<DriverLocation>? _locationSubscription;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropoffIcon;
  BitmapDescriptor? _driverIcon;
  bool _isLocating = false;
  bool _isLoadingRoute = false;
  bool _isSyncingLocation = false;
  bool _isSheetCollapsed = false;
  bool _isLoadingBooking = false;
  bool _isActing = false;
  BookingDetail? _booking;

  RouteMapArgs get args => Get.arguments as RouteMapArgs;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareMarkerIcons());
    unawaited(_loadBooking());
    unawaited(_refreshLocation());
    _startLiveLocationStream();
    _startRouteRefreshTimer();
  }

  @override
  void dispose() {
    _routeRefreshTimer?.cancel();
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMap = args.pickup.hasCoordinates && args.dropoff.hasCoordinates;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            RepaintBoundary(
              child: hasMap ? _googleMap() : _fallbackMap(context),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 18,
              right: 18,
              child: _mapHeader(context),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _RouteSheet(
                args: args,
                distanceLabel: _distanceLabel(),
                durationLabel: _durationLabel(),
                loadingRoute: _isLoadingRoute,
                routeUnavailable: _routeUnavailable,
                showsPassengerRoute: _routeMode == 'passenger',
                usesDriverLocation: _hasUsableDriverLocation,
                collapsed: _isSheetCollapsed,
                action: _mapAction,
                acting: _isActing,
                pickupDistanceMeters: _pickupDistanceMeters,
                onToggleCollapsed: () =>
                    setState(() => _isSheetCollapsed = !_isSheetCollapsed),
                onNavigate: _navigate,
                onAction: _runMapAction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadBooking() async {
    if (_isLoadingBooking || args.uuid.isEmpty) return;

    _isLoadingBooking = true;
    try {
      final booking = await Get.find<BookingRepository>().show(
        args.uuid,
        assignmentId: args.assignmentId,
      );
      if (!mounted) return;
      setState(() => _booking = booking);
    } catch (_) {
      // Route navigation stays usable when booking refresh is unavailable.
    } finally {
      _isLoadingBooking = false;
    }
  }

  String? get _mapAction {
    if (args.navigateToDropoff) return null;
    return _booking?.allows('arrived') == true ? 'arrived' : null;
  }

  double? get _pickupDistanceMeters {
    final driver = _driverLocation;
    if (driver == null || !args.pickup.hasCoordinates) return null;

    return _distanceMeters(
      driver.latitude,
      driver.longitude,
      args.pickup.latitude!,
      args.pickup.longitude!,
    );
  }

  Future<void> _runMapAction() async {
    final action = _mapAction;
    if (action == null || _isActing) return;
    if (!await confirmStepAction(action)) return;

    setState(() => _isActing = true);
    try {
      final booking = await Get.find<BookingRepository>().arrived(
        args.uuid,
        assignmentId: args.assignmentId,
      );
      if (!mounted) return;
      setState(() => _booking = booking);
      AppSnackbar.success('arrived_done'.tr);
    } on ApiException catch (error) {
      AppSnackbar.error(error.message);
    } catch (_) {
      AppSnackbar.error('error_generic'.tr);
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Widget _googleMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _initialTarget(), zoom: 12),
      markers: _markers(),
      polylines: _polylines(),
      myLocationButtonEnabled: false,
      myLocationEnabled: _hasUsableDriverLocation,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      style: _focusedMapStyle,
      onMapCreated: (controller) {
        _mapController = controller;
        unawaited(_fitCamera());
      },
    );
  }

  Widget _fallbackMap(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.canvas),
      child: Center(
        child: Icon(
          IconsaxPlusLinear.map,
          size: 92,
          color: AppColors.primary.withValues(alpha: 0.22),
        ),
      ),
    );
  }

  Widget _mapHeader(BuildContext context) {
    return Row(
      children: [
        const AppBackButton(),
        Expanded(child: Center(child: _routePill(context))),
        _circleButton(
          icon: IconsaxPlusLinear.gps,
          loading: _isLocating,
          onTap: _refreshLocation,
        ),
      ],
    );
  }

  Widget _routePill(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.84),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(_routeHeaderIcon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              _routeHeaderLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData get _routeHeaderIcon {
    if (_routeMode == 'passenger') {
      return IconsaxPlusLinear.route_square;
    }

    return args.navigateToDropoff
        ? IconsaxPlusLinear.flag
        : IconsaxPlusLinear.location;
  }

  String get _routeHeaderLabel {
    if (_routeMode == 'passenger') {
      return 'passenger_route'.tr;
    }

    return args.navigateToDropoff ? 'dropoff_route'.tr : 'pickup_route'.tr;
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(13),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, color: AppColors.secondary, size: 20),
        ),
      ),
    );
  }

  LatLng _initialTarget() {
    if (_hasUsableDriverLocation) {
      return LatLng(_driverLocation!.latitude, _driverLocation!.longitude);
    }

    if (args.activeTarget.hasCoordinates) {
      return LatLng(args.activeTarget.latitude!, args.activeTarget.longitude!);
    }

    return LatLng(args.pickup.latitude ?? 0, args.pickup.longitude ?? 0);
  }

  Set<Marker> _markers() {
    if (!args.pickup.hasCoordinates || !args.dropoff.hasCoordinates) {
      return {};
    }

    return {
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(args.pickup.latitude!, args.pickup.longitude!),
        icon:
            _pickupIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 1),
        infoWindow: InfoWindow(title: 'pickup'.tr, snippet: args.pickup.label),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(args.dropoff.latitude!, args.dropoff.longitude!),
        icon:
            _dropoffIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 1),
        infoWindow: InfoWindow(
          title: 'dropoff'.tr,
          snippet: args.dropoff.label,
        ),
      ),
      if (_hasUsableDriverLocation)
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            _driverLocation!.latitude,
            _driverLocation!.longitude,
          ),
          icon:
              _driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: InfoWindow(title: 'driver_location'.tr),
        ),
    };
  }

  Set<Polyline> _polylines() {
    if (!args.pickup.hasCoordinates || !args.dropoff.hasCoordinates) {
      return {};
    }

    final roadPoints = _roadRoute?.points;
    final polylines = <Polyline>{};

    if (roadPoints != null && roadPoints.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('active_route'),
          points: roadPoints,
          color: AppColors.primary,
          width: 7,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }

    return polylines;
  }

  Future<void> _refreshLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final location = await Get.find<LocationService>().current();
      if (!mounted) return;
      _setDriverLocation(location, force: true);
      unawaited(_syncLocationForObservers(location));
      unawaited(_loadRoadRoute(force: true));
      await _fitCamera();
    } catch (_) {
      // Full-screen map remains usable with pickup/drop-off coordinates.
      unawaited(_loadRoadRoute());
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _startLiveLocationStream() {
    _locationSubscription?.cancel();
    _locationSubscription = Get.find<LocationService>()
        .liveStream(distanceFilterMeters: 5)
        .listen(
          _handleLiveLocation,
          onError: (_) {
            // The manual GPS button remains available for visible retry/error.
          },
        );
  }

  void _handleLiveLocation(DriverLocation location) {
    if (!mounted || _isLocating) return;

    final previous = _driverLocation;
    final wasUsingDriverLocation = _hasUsableDriverLocation;
    final shouldUpdateMarker =
        previous == null ||
        _distanceMeters(
              previous.latitude,
              previous.longitude,
              location.latitude,
              location.longitude,
            ) >=
            _markerUpdateDistanceMeters;

    if (!shouldUpdateMarker) return;

    _setDriverLocation(location);
    unawaited(_syncLocationForObservers(location));

    final isNowUsingDriverLocation = _hasUsableDriverLocation;
    if (!wasUsingDriverLocation && isNowUsingDriverLocation) {
      unawaited(_loadRoadRoute(force: true));
      unawaited(_fitCamera());
      return;
    }

    if (_routeMode != 'passenger' && _shouldRefreshRouteFromMovement()) {
      unawaited(_loadRoadRoute());
    }
  }

  void _setDriverLocation(DriverLocation location, {bool force = false}) {
    if (!mounted) return;
    if (!force) {
      final previous = _driverLocation;
      if (previous != null &&
          _distanceMeters(
                previous.latitude,
                previous.longitude,
                location.latitude,
                location.longitude,
              ) <
              _markerUpdateDistanceMeters) {
        return;
      }
    }

    setState(() => _driverLocation = location);
  }

  Future<void> _syncLocationForObservers(DriverLocation location) async {
    if (_isSyncingLocation || args.uuid.isEmpty || args.assignmentId == null) {
      return;
    }

    final lastSynced = _lastSyncedLocation;
    final lastSyncedAt = _lastLocationSyncAt;
    final movedEnough =
        lastSynced == null ||
        _distanceMeters(
              lastSynced.latitude,
              lastSynced.longitude,
              location.latitude,
              location.longitude,
            ) >=
            _locationSyncDistanceMeters;
    final waitedEnough =
        lastSyncedAt == null ||
        DateTime.now().difference(lastSyncedAt) >= _locationSyncInterval;

    if (!movedEnough && !waitedEnough) return;

    _isSyncingLocation = true;
    try {
      await Get.find<BookingRepository>().storeLocation(
        args.uuid,
        assignmentId: args.assignmentId!,
        location: location,
      );
      _lastSyncedLocation = location;
      _lastLocationSyncAt = DateTime.now();
    } catch (_) {
      // Live map should stay smooth even if the background sync fails.
    } finally {
      _isSyncingLocation = false;
    }
  }

  void _startRouteRefreshTimer() {
    _routeRefreshTimer?.cancel();
    _routeRefreshTimer = Timer.periodic(
      _routeRefreshInterval,
      (_) => unawaited(_refreshRouteIfNeeded()),
    );
  }

  Future<void> _refreshRouteIfNeeded() async {
    if (!mounted || _isLocating) return;

    try {
      final location = await Get.find<LocationService>().current();
      if (!mounted) return;

      _setDriverLocation(location);
      unawaited(_syncLocationForObservers(location));

      if (_routeMode == 'passenger') {
        await _fitCamera();
        return;
      }

      final lastRouteLocation = _lastRouteLocation;
      if (lastRouteLocation == null ||
          _distanceMeters(
                lastRouteLocation.latitude,
                lastRouteLocation.longitude,
                location.latitude,
                location.longitude,
              ) >=
              _routeRefreshDistanceMeters) {
        await _loadRoadRoute();
      } else {
        await _fitCamera();
      }
    } catch (_) {
      // Auto-refresh should be silent; the manual GPS button reports errors.
    }
  }

  Future<void> _prepareMarkerIcons() async {
    final icons = await Future.wait([
      _letterMarker('A', AppColors.secondary),
      _letterMarker('B', AppColors.primary),
      _carMarker(),
    ]);

    if (!mounted) return;
    setState(() {
      _pickupIcon = icons[0];
      _dropoffIcon = icons[1];
      _driverIcon = icons[2];
    });
  }

  Future<void> _loadRoadRoute({bool force = false}) async {
    if (_isLoadingRoute || args.assignmentId == null) {
      return;
    }

    final mode = _routeMode;
    if (mode != 'passenger' && !_hasUsableDriverLocation) {
      return;
    }

    if (!force && mode == 'passenger' && _lastRouteMode == mode) {
      await _fitCamera();
      return;
    }

    if (!force && mode != 'passenger' && !_shouldRefreshRouteFromMovement()) {
      await _fitCamera();
      return;
    }

    setState(() => _isLoadingRoute = true);
    try {
      final route = await Get.find<BookingRepository>().route(
        args.uuid,
        assignmentId: args.assignmentId!,
        mode: mode,
        originLatitude: _hasUsableDriverLocation
            ? _driverLocation!.latitude
            : null,
        originLongitude: _hasUsableDriverLocation
            ? _driverLocation!.longitude
            : null,
      );
      if (!mounted) return;
      setState(() {
        _roadRoute = route;
        _lastRouteLocation = _hasUsableDriverLocation ? _driverLocation : null;
        _lastRouteMode = mode;
      });
      await _fitCamera();
    } catch (_) {
      // Keep marker + fallback line usable if Routes API is unavailable.
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  bool _shouldRefreshRouteFromMovement() {
    final current = _driverLocation;
    if (current == null) {
      return true;
    }

    final last = _lastRouteLocation;
    if (last == null) {
      return true;
    }

    return _distanceMeters(
          last.latitude,
          last.longitude,
          current.latitude,
          current.longitude,
        ) >=
        _routeRefreshDistanceMeters;
  }

  Future<void> _fitCamera() async {
    final controller = _mapController;
    if (controller == null) return;

    final points = _cameraPoints();

    if (points.isEmpty) return;
    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 14),
        ),
      );
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(_boundsFor(points), 84),
    );
  }

  LatLngBounds _boundsFor(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  String? _distanceLabel() {
    final routeDistance = _roadRoute?.distanceMeters;
    if (routeDistance != null) {
      return routeDistance < 1000
          ? '$routeDistance m'
          : '${(routeDistance / 1000).toStringAsFixed(routeDistance >= 100000 ? 0 : 1)} km';
    }

    if (!args.pickup.hasCoordinates || !args.dropoff.hasCoordinates) {
      return null;
    }

    final meters =
        _routeMode != 'passenger' &&
            _hasUsableDriverLocation &&
            args.activeTarget.hasCoordinates
        ? _distanceMeters(
            _driverLocation!.latitude,
            _driverLocation!.longitude,
            args.activeTarget.latitude!,
            args.activeTarget.longitude!,
          )
        : _distanceMeters(
            args.pickup.latitude!,
            args.pickup.longitude!,
            args.dropoff.latitude!,
            args.dropoff.longitude!,
          );

    return meters < 1000
        ? '${meters.round()} m'
        : '${(meters / 1000).toStringAsFixed(meters >= 10000 ? 0 : 1)} km';
  }

  String? _durationLabel() {
    final seconds = _roadRoute?.durationSeconds;
    if (seconds == null) return null;

    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes == 0
        ? '${hours}h'
        : '${hours}h ${remainingMinutes}m';
  }

  bool get _routeUnavailable =>
      _roadRoute != null && !_roadRoute!.hasRoadRoute && !_isLoadingRoute;

  String get _routeMode {
    if (!_hasUsableDriverLocation) {
      return 'passenger';
    }

    return args.navigateToDropoff ? 'to_dropoff' : 'to_pickup';
  }

  List<LatLng> _cameraPoints() {
    final roadPoints = _roadRoute?.points;
    if (roadPoints != null && roadPoints.length > 1) {
      return roadPoints;
    }

    if (_routeMode == 'passenger') {
      return [
        if (args.pickup.hasCoordinates)
          LatLng(args.pickup.latitude!, args.pickup.longitude!),
        if (args.dropoff.hasCoordinates)
          LatLng(args.dropoff.latitude!, args.dropoff.longitude!),
      ];
    }

    return [
      if (_hasUsableDriverLocation)
        LatLng(_driverLocation!.latitude, _driverLocation!.longitude),
      if (args.activeTarget.hasCoordinates)
        LatLng(args.activeTarget.latitude!, args.activeTarget.longitude!),
    ];
  }

  bool get _hasUsableDriverLocation {
    final driver = _driverLocation;
    final target = args.activeTarget;
    if (driver == null || !target.hasCoordinates) {
      return false;
    }

    final meters = _distanceMeters(
      driver.latitude,
      driver.longitude,
      target.latitude!,
      target.longitude!,
    );

    // Simulator/device GPS can sometimes report a location on another continent.
    // Keep the trip map useful by ignoring impossible driver positions.
    return meters <= 1000000;
  }

  double _distanceMeters(double aLat, double aLng, double bLat, double bLng) {
    const radius = 6371000.0;
    final dLat = _radians(bLat - aLat);
    final dLng = _radians(bLng - aLng);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(aLat)) *
            math.cos(_radians(bLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _radians(double degrees) => degrees * math.pi / 180;

  Future<BitmapDescriptor> _letterMarker(String letter, Color color) async {
    const size = 66.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final pinPaint = Paint()..color = color;
    final whitePaint = Paint()..color = Colors.white;

    final pinPath = Path()
      ..addOval(const Rect.fromLTWH(10, 4, 46, 46))
      ..moveTo(33, 62)
      ..lineTo(23, 42)
      ..lineTo(43, 42)
      ..close();

    canvas.drawPath(pinPath.shift(const Offset(0, 4)), shadowPaint);
    canvas.drawPath(pinPath, pinPaint);
    canvas.drawCircle(const Offset(33, 27), 17, whitePaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: color,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(33 - textPainter.width / 2, 27 - textPainter.height / 2),
    );

    return _bitmapFromCanvas(recorder, size);
  }

  Future<BitmapDescriptor> _carMarker() async {
    const size = 62.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final bgPaint = Paint()..color = Colors.white;
    final bodyPaint = Paint()..color = AppColors.primary;
    final glassPaint = Paint()..color = const Color(0xFFE2FAF6);

    canvas.drawCircle(const Offset(31, 33), 22, shadowPaint);
    canvas.drawCircle(const Offset(31, 31), 22, bgPaint);
    canvas.drawCircle(
      const Offset(31, 31),
      18,
      Paint()..color = AppColors.primary.withValues(alpha: 0.12),
    );

    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(18, 26, 26, 16),
      const Radius.circular(6),
    );
    canvas.drawRRect(body, bodyPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(23, 21, 16, 13),
        const Radius.circular(5),
      ),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(25, 23, 12, 7),
        const Radius.circular(3),
      ),
      glassPaint,
    );
    canvas.drawCircle(const Offset(23, 43), 3.2, bodyPaint);
    canvas.drawCircle(const Offset(39, 43), 3.2, bodyPaint);
    canvas.drawCircle(const Offset(23, 43), 1.4, bgPaint);
    canvas.drawCircle(const Offset(39, 43), 1.4, bgPaint);

    return _bitmapFromCanvas(recorder, size);
  }

  Future<BitmapDescriptor> _bitmapFromCanvas(
    ui.PictureRecorder recorder,
    double size,
  ) async {
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List() ?? Uint8List(0);

    return BitmapDescriptor.bytes(bytes, width: size, height: size);
  }

  Future<void> _navigate() async {
    if (!args.pickup.hasCoordinates || !args.dropoff.hasCoordinates) {
      final target = args.activeTarget;
      await ExternalLauncher.navigateTo(
        latitude: target.latitude,
        longitude: target.longitude,
        address: target.label,
      );

      return;
    }

    final mode = _routeMode;
    final destination = mode == 'to_pickup' ? args.pickup : args.dropoff;
    final origin = mode == 'passenger'
        ? args.pickup
        : (_hasUsableDriverLocation ? null : args.pickup);

    await ExternalLauncher.navigateRoute(
      originLatitude: _hasUsableDriverLocation
          ? _driverLocation!.latitude
          : origin?.latitude,
      originLongitude: _hasUsableDriverLocation
          ? _driverLocation!.longitude
          : origin?.longitude,
      originAddress: origin?.label,
      destinationLatitude: destination.latitude!,
      destinationLongitude: destination.longitude!,
    );
  }
}

class _RouteSheet extends StatelessWidget {
  const _RouteSheet({
    required this.args,
    required this.onNavigate,
    required this.usesDriverLocation,
    required this.loadingRoute,
    required this.routeUnavailable,
    required this.showsPassengerRoute,
    required this.collapsed,
    required this.acting,
    required this.onToggleCollapsed,
    required this.onAction,
    this.distanceLabel,
    this.durationLabel,
    this.action,
    this.pickupDistanceMeters,
  });

  final RouteMapArgs args;
  final String? distanceLabel;
  final String? durationLabel;
  final bool usesDriverLocation;
  final bool loadingRoute;
  final bool routeUnavailable;
  final bool showsPassengerRoute;
  final bool collapsed;
  final bool acting;
  final String? action;
  final double? pickupDistanceMeters;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onNavigate;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomPadding = collapsed
        ? math.max(bottomInset + 2, 10.0)
        : math.max(bottomInset + 8, 20.0);
    final targetLabel = showsPassengerRoute
        ? 'preview_passenger_route'.tr
        : usesDriverLocation
        ? (args.navigateToDropoff
              ? 'you_are_heading_to_dropoff'.tr
              : 'you_are_heading_to_pickup'.tr)
        : 'preview_passenger_route'.tr;
    final routeCaption = showsPassengerRoute
        ? '${args.pickup.label} -> ${args.dropoff.label}'
        : usesDriverLocation
        ? '${'driver_location'.tr} -> ${args.activeTarget.label}'
        : '${args.pickup.label} -> ${args.dropoff.label}';

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.16),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleCollapsed,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 2, 24, 8),
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: _ExpandedRouteSheetBody(
              args: args,
              targetLabel: targetLabel,
              routeCaption: routeCaption,
              distanceLabel: distanceLabel,
              durationLabel: durationLabel,
              loadingRoute: loadingRoute,
              routeUnavailable: routeUnavailable,
              onNavigate: onNavigate,
            ),
            secondChild: _CollapsedRouteSheetBody(
              targetLabel: targetLabel,
              routeCaption: routeCaption,
              distanceLabel: distanceLabel,
              durationLabel: durationLabel,
              onExpand: onToggleCollapsed,
            ),
            crossFadeState: collapsed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeOut,
            sizeCurve: Curves.easeOut,
          ),
          if (action == 'arrived') ...[
            if (pickupDistanceMeters != null &&
                pickupDistanceMeters! <= _pickupApproachingDistanceMeters) ...[
              const SizedBox(height: 10),
              _PickupProximityNotice(
                distanceMeters: pickupDistanceMeters!,
                isArrivalZone:
                    pickupDistanceMeters! <= _pickupArrivalDistanceMeters,
              ),
            ],
            const SizedBox(height: 10),
            StepActionButton(
              label: 'mark_arrived'.tr,
              icon: IconsaxPlusLinear.location_tick,
              loading: acting,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

class _PickupProximityNotice extends StatelessWidget {
  const _PickupProximityNotice({
    required this.distanceMeters,
    required this.isArrivalZone,
  });

  final double distanceMeters;
  final bool isArrivalZone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = distanceMeters < 1000
        ? '${distanceMeters.round()} m'
        : '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    final color = isArrivalZone ? AppColors.primary : const Color(0xFFB7791F);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isArrivalZone
                  ? IconsaxPlusLinear.location_tick
                  : IconsaxPlusLinear.location,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArrivalZone
                      ? 'pickup_arrival_zone_title'.tr
                      : 'pickup_nearby_title'.tr,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isArrivalZone
                      ? 'pickup_arrival_zone_message'.tr
                      : 'pickup_nearby_message'.trParams({'distance': label}),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedRouteSheetBody extends StatelessWidget {
  const _ExpandedRouteSheetBody({
    required this.args,
    required this.targetLabel,
    required this.routeCaption,
    required this.loadingRoute,
    required this.routeUnavailable,
    required this.onNavigate,
    this.distanceLabel,
    this.durationLabel,
  });

  final RouteMapArgs args;
  final String targetLabel;
  final String routeCaption;
  final String? distanceLabel;
  final String? durationLabel;
  final bool loadingRoute;
  final bool routeUnavailable;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    targetLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    distanceLabel ?? 'route_preview'.tr,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (durationLabel != null) ...[
                        Text(
                          durationLabel!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outline,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          routeCaption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (loadingRoute) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                  if (routeUnavailable) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6DF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            IconsaxPlusLinear.info_circle,
                            size: 14,
                            color: Color(0xFFB7791F),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'road_route_unavailable'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF8A5A13),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.canvas.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              _StopLine(
                badge: 'A',
                label: 'pickup_point_a'.tr,
                place: args.pickup,
                color: AppColors.primary,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 1.5,
                    height: 8,
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
              ),
              _StopLine(
                badge: 'B',
                label: 'dropoff_point_b'.tr,
                place: args.dropoff,
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: TextButton.icon(
            onPressed: onNavigate,
            icon: const Icon(IconsaxPlusLinear.routing, size: 16),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('open_google_maps'.tr),
                const SizedBox(width: 4),
                const Icon(IconsaxPlusLinear.arrow_right_3, size: 13),
              ],
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(0, 26),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CollapsedRouteSheetBody extends StatelessWidget {
  const _CollapsedRouteSheetBody({
    required this.targetLabel,
    required this.routeCaption,
    required this.onExpand,
    this.distanceLabel,
    this.durationLabel,
  });

  final String targetLabel;
  final String routeCaption;
  final String? distanceLabel;
  final String? durationLabel;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onExpand,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    targetLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        distanceLabel ?? 'route_preview'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      if (durationLabel != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          durationLabel!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    routeCaption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                IconsaxPlusLinear.arrow_up_2,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopLine extends StatelessWidget {
  const _StopLine({
    required this.badge,
    required this.label,
    required this.place,
    required this.color,
  });

  final String badge;
  final String label;
  final Place place;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              badge,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  height: 1,
                ),
              ),
              Text(
                place.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              if (place.nearbyLocation != null &&
                  place.nearbyLocation!.isNotEmpty)
                Text(
                  place.nearbyLocation!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
