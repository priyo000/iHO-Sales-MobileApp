import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';

class CustomerBottomBar extends StatelessWidget {
  final bool isCheckedIn;
  final bool isCompleted;
  final bool isLoading;
  final Stream<String> timerStream;
  final String currentDuration;
  final VoidCallback onCartTap;
  final VoidCallback onCheckInTap;
  final VoidCallback? onLastVisitTap;

  const CustomerBottomBar({
    super.key,
    required this.isCheckedIn,
    required this.isCompleted,
    required this.isLoading,
    required this.timerStream,
    required this.currentDuration,
    required this.onCartTap,
    required this.onCheckInTap,
    this.onLastVisitTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            if (onLastVisitTap != null) ...[
              IconButton(
                onPressed: onLastVisitTap,
                tooltip: 'Riwayat Kunjungan Terakhir',
                icon: const Icon(Icons.history),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              onPressed: onCartTap,
              icon: const Icon(Icons.add_shopping_cart),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildActionButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (isCheckedIn) {
      return StreamBuilder<String>(
        stream: timerStream,
        initialData: currentDuration,
        builder: (context, snapshot) {
          return ElevatedButton.icon(
            onPressed: onCheckInTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.stop_circle_outlined),
            label: Text('Check Out (${snapshot.data})'),
          );
        },
      );
    }

    if (isCompleted) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onCheckInTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.refresh),
        label: const Text(
          'Kunjungi Lagi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onCheckInTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.surface,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.location_on),
      label: Text(isLoading ? 'Memverifikasi Lokasi...' : 'Start Check-in'),
    );
  }
}
