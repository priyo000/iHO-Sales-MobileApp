import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String message;
  final LocationErrorType type;
  const LocationException(this.message, this.type);

  @override
  String toString() => 'LocationException: $message';
}

enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationService {
  LocationService._();

  static Future<Position> getCurrentWithPermission({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'Layanan lokasi (GPS) belum diaktifkan',
        LocationErrorType.serviceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          'Izin lokasi ditolak',
          LocationErrorType.permissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Izin lokasi ditolak permanen. Aktifkan lewat Pengaturan',
        LocationErrorType.permissionDeniedForever,
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      );
    } catch (e) {
      throw LocationException(
        'Gagal mendapatkan lokasi: $e',
        LocationErrorType.timeout,
      );
    }
  }

  static Future<Position?> getLastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  static double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
