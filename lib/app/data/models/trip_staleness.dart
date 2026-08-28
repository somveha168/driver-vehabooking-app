/// How long after its departure a trip that is already under way is treated as
/// abandoned rather than current.
///
/// Mirrors `DashboardController::ACTIVE_TRIP_MAX_AGE_HOURS` on the backend,
/// which stops such a trip claiming the dashboard's NOW card. Keep the two in
/// step: the API decides what to surface, the app explains why.
const Duration staleTripThreshold = Duration(hours: 24);
