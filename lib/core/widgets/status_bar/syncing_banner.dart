import 'package:flutter/material.dart';

class SyncingBanner extends StatelessWidget {
  final int pending;
  final int downloading;
  final VoidCallback onTap;
  const SyncingBanner({
    super.key,
    required this.pending,
    required this.downloading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    if (downloading > 0 && pending > 0) {
      label = 'Sinkronisasi... $pending upload, $downloading download';
    } else if (pending > 0) {
      label = 'Mengirim $pending data...';
    } else {
      label = 'Sinkronisasi...';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFDBEAFE),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF1E40AF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF2563EB),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
