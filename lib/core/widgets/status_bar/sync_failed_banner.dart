import 'package:flutter/material.dart';

class SyncFailedBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const SyncFailedBanner({super.key, required this.count, required this.onTap});

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
            color: Color(0xFFFFF3CD),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFF856404),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$count data gagal dikirim — Tap untuk perbaiki',
                  style: const TextStyle(
                    color: Color(0xFF856404),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF856404),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
