import 'package:flutter/material.dart';

/// Reusable stale data warning banner.
/// Muncul di atas halaman jika data sudah lama tidak di-sync.
/// Tidak blocking — user tetap bisa kerja normal.
class StaleWarningBanner extends StatelessWidget {
  final String dataType;
  final DateTime lastSync;
  final VoidCallback? onSync;

  const StaleWarningBanner({
    super.key,
    required this.dataType,
    required this.lastSync,
    this.onSync,
  });

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else {
      return '${diff.inDays} hari lalu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFFFFF3CD),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFF856404),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$dataType mungkin sudah berubah. Terakhir sync: ${_timeAgo(lastSync)}.',
              style: const TextStyle(
                color: Color(0xFF856404),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onSync != null)
            TextButton(
              onPressed: onSync,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Sync',
                style: TextStyle(
                  color: Color(0xFF856404),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
