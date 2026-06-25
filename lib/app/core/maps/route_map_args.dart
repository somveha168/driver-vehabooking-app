import '../../data/models/place.dart';

class RouteMapArgs {
  const RouteMapArgs({
    required this.uuid,
    required this.assignmentId,
    required this.title,
    required this.subtitle,
    required this.pickup,
    required this.dropoff,
    required this.navigateToDropoff,
  });

  final String uuid;
  final int? assignmentId;
  final String title;
  final String subtitle;
  final Place pickup;
  final Place dropoff;
  final bool navigateToDropoff;

  Place get activeTarget => navigateToDropoff ? dropoff : pickup;
}
