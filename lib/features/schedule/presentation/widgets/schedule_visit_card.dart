import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/store_image.dart';

/// Single visit card in the schedule list.
///
/// Renders pelanggan info, status, distance, and a live timer when
/// the visit is currently active (DIKUNJUNGI without check-out).
class ScheduleVisitCard extends StatefulWidget {
  const ScheduleVisitCard({
    super.key,
    this.checkIn,
    this.checkOut,
    this.imageUrl,
    required this.name,
    required this.code,
    required this.address,
    required this.status,
    required this.statusColor,
    required this.distance,
    required this.onTap,
    this.isOffDateFulfilled = false,
    this.isUnplanned = false,
  });

  final String? checkIn;
  final String? checkOut;
  final String? imageUrl;
  final String name;
  final String code;
  final String address;
  final String status;
  final Color statusColor;
  final double? distance;
  final VoidCallback onTap;

  /// Local-only: true when this slot was fulfilled via an off-date visit.
  /// Prevents showing the active-timer red border even though status=DIKUNJUNGI.
  final bool isOffDateFulfilled;

  /// True when this visit is unplanned (kunjungan diluar jadwal).
  final bool isUnplanned;

  @override
  State<ScheduleVisitCard> createState() => _ScheduleVisitCardState();
}

class _ScheduleVisitCardState extends State<ScheduleVisitCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  String _liveDuration = '';
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(ScheduleVisitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checkIn != widget.checkIn ||
        oldWidget.checkOut != widget.checkOut ||
        oldWidget.status != widget.status) {
      _startTimerIfNeeded();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController?.dispose();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    final bool isActive =
        widget.status.toUpperCase() == 'DIKUNJUNGI' && widget.checkOut == null;

    if (isActive && widget.checkIn != null) {
      final startTime = DateTime.tryParse(widget.checkIn!)?.toLocal();
      if (startTime != null) {
        _updateDuration(startTime);
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          _updateDuration(startTime);
        });
      }
    }
  }

  void _updateDuration(DateTime startTime) {
    final diff = DateTime.now().difference(startTime);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    if (mounted) setState(() => _liveDuration = '$h:$m:$s');
  }

  Color _distanceColor(double km) {
    if (km < 1.0) return AppColors.success;
    if (km < 5.0) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final bool isVisited =
        widget.status.toUpperCase() == 'DIKUNJUNGI' ||
        widget.status.toUpperCase() == 'SELESAI';
    final bool isActive =
        widget.status.toUpperCase() == 'DIKUNJUNGI' &&
        widget.checkOut == null &&
        !widget.isOffDateFulfilled;

    String timeDisplay = 'Belum dikunjungi';
    if (isVisited) {
      String inTime = '--:--';
      if (widget.checkIn != null) {
        final dt = DateTime.tryParse(widget.checkIn!)?.toLocal();
        if (dt != null) inTime = DateFormat('HH:mm').format(dt);
      }
      if (isActive) {
        timeDisplay = _liveDuration;
      } else {
        timeDisplay = 'In: $inTime';
        if (widget.checkOut != null) {
          final dt = DateTime.tryParse(widget.checkOut!)?.toLocal();
          if (dt != null) {
            timeDisplay += ' - Out: ${DateFormat('HH:mm').format(dt)}';
          }
        }
      }
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: isActive
              ? Border.all(
                  color: AppColors.error.withValues(alpha: 0.5),
                  width: 2,
                )
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StoreImage(
                url: widget.imageUrl,
                width: 100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                fallbackIconSize: 40,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTitleRow(),
                      const SizedBox(height: AppSpacing.xs),
                      _buildCodeRow(),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.address,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildFooterRow(
                        timeDisplay: timeDisplay,
                        isActive: isActive,
                        isVisited: isVisited,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.name,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppBadge(
          label: _idLabel(widget.status),
          color: widget.statusColor,
        ),
      ],
    );
  }

  String _idLabel(String status) {
    final s = status.toUpperCase();
    return switch (s) {
      'PENDING' => 'TERTUNDA',
      'CANCELED' || 'CANCELLED' => 'BATAL',
      _ => s,
    };
  }

  Widget _buildCodeRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            widget.code,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.isUnplanned) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: Colors.deepPurple.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.alt_route,
                  size: 10,
                  color: Colors.deepPurple[400],
                ),
                const SizedBox(width: 3),
                Text(
                  'Diluar Jadwal',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.deepPurple[400],
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooterRow({
    required String timeDisplay,
    required bool isActive,
    required bool isVisited,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Row(
            children: [
              if (isActive)
                ScaleTransition(
                  scale: Tween(
                    begin: 0.8,
                    end: 1.2,
                  ).animate(_pulseController!),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              if (isActive) const SizedBox(width: AppSpacing.sm),
              Icon(
                isActive
                    ? Icons.timer_outlined
                    : isVisited
                    ? Icons.history
                    : Icons.access_time,
                size: 14,
                color: isActive ? AppColors.error : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  timeDisplay,
                  style: AppTextStyles.caption.copyWith(
                    color: isActive ? AppColors.error : AppColors.textMuted,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        _buildDistanceLabel(),
      ],
    );
  }

  Widget _buildDistanceLabel() {
    final dist = widget.distance;
    if (dist == null) {
      return Text(
        'Lokasi tdk diset',
        style: AppTextStyles.caption.copyWith(
          fontStyle: FontStyle.italic,
        ),
      );
    }
    final color = _distanceColor(dist);
    return Row(
      children: [
        Icon(Icons.location_on, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${dist.toStringAsFixed(1)} km',
          style: AppTextStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
