import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final int pending;
  final VoidCallback onTap;
  const OfflineBanner({super.key, required this.pending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFFEF3C7),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFB45309),
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pending > 0
                      ? 'Mode Offline — $pending data antri dikirim saat online'
                      : 'Mode Offline — Data disimpan di perangkat',
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFB45309),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
