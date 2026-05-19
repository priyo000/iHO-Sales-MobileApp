import 'package:flutter/material.dart';

class UpdateBanner extends StatelessWidget {
  final VoidCallback onTap;
  const UpdateBanner({super.key, required this.onTap});

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
            color: Color(0xFFDC2626),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.system_update_alt_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Versi baru tersedia — Tap untuk update',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
