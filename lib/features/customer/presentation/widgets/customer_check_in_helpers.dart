import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_colors.dart';

/// Stateless helpers for the customer detail check-in flow:
/// confirmation dialogs, GPS resolution, and SOP window validation.
class CustomerCheckInHelpers {
  CustomerCheckInHelpers._();

  /// Confirm a re-visit when the customer's visit was already completed today.
  static Future<bool?> confirmRevisit(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Re-visit'),
        content: const Text(
          'Anda sudah menyelesaikan kunjungan ini hari ini. Apakah Anda yakin ingin mengunjungi ulang pelanggan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Ya, Kunjungi Lagi'),
          ),
        ],
      ),
    );
  }

  /// Confirm continuing check-in when user is outside the radius tolerance.
  static Future<bool?> confirmOutOfRange(
    BuildContext context, {
    required double distance,
    required double tolerance,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Peringatan Lokasi'),
        content: Text(
          'Anda berada ${distance.toStringAsFixed(0)}m dari lokasi pelanggan '
          '(Batas: ${tolerance.toStringAsFixed(0)}m).\n\n'
          'Apakah Anda ingin melanjutkan check-in?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Lanjutkan',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Show SOP violation dialog when scheduled date is outside the +/- 3 day window.
  static void showSopViolationDialog(
    BuildContext context,
    DateTime scheduleDate,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pelanggaran SOP'),
        content: Text(
          'Sesuai aturan perusahaan, Anda tidak diperbolehkan melakukan '
          'Check-in untuk jadwal yang sudah lewat atau yang masih lama (> 3 hari).'
          '\n\nTanggal Jadwal: ${scheduleDate.day}/${scheduleDate.month}/${scheduleDate.year}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  /// Validate the +/- 3 day visit schedule window. Returns false (and shows
  /// dialog) if the visit is outside the allowed range.
  static bool validateSopWindow({
    required BuildContext context,
    required String? scheduleDate,
  }) {
    if (scheduleDate == null) return true;
    try {
      final parsed = DateTime.parse(scheduleDate);
      final diffDays = DateTime.now().difference(parsed).inDays.abs();
      if (diffDays > 3) {
        if (context.mounted) {
          showSopViolationDialog(context, parsed);
        }
        return false;
      }
    } catch (e) {
      debugPrint('[SOP Check] Error parsing date: $e');
    }
    return true;
  }

  /// Resolve the user's current GPS position with progressive accuracy fallback.
  /// Returns null if all attempts fail (offline-friendly check-in).
  static Future<Position?> resolvePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied. Please enable them in settings.';
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 3),
          ),
        );
      } catch (_) {
        debugPrint('Check-in: GPS failed, using 0,0 position');
        return null;
      }
    }
  }

  /// Empty position used when GPS fails — coordinates default to 0,0
  /// and check-in proceeds offline-first.
  static Position emptyPosition() => Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
}
