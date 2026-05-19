import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Streams the user's current GPS position.
///
/// Yields:
/// 1. Last known position immediately (if available) for instant UX
/// 2. A high-accuracy single fix (5s timeout)
/// 3. Continuous updates every 10m of movement
///
/// Throws if location services are disabled or permission is denied.
final userLocationProvider = StreamProvider<Position>((ref) async* {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) throw Exception('Location services are disabled.');

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions are denied');
    }
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permissions are permanently denied.');
  }

  final lastKnown = await Geolocator.getLastKnownPosition();
  if (lastKnown != null) yield lastKnown;

  try {
    final current = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 5),
      ),
    );
    yield current;
  } catch (_) {}

  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  );
});
