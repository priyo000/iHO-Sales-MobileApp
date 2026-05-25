import 'package:flutter/material.dart';
import '../constants/order_status.dart';
import '../constants/visit_status.dart';
import '../theme/app_colors.dart';

class StatusStyles {
  StatusStyles._();

  static Color color(OrderStatus status) => switch (status) {
    OrderStatus.pending => AppColors.statusPending,
    OrderStatus.processing => AppColors.statusProcessing,
    OrderStatus.success => AppColors.statusSuccess,
    OrderStatus.cancelled => AppColors.statusCancelled,
    OrderStatus.failed => AppColors.statusFailed,
  };

  static IconData icon(OrderStatus status) => switch (status) {
    OrderStatus.pending => Icons.schedule,
    OrderStatus.processing => Icons.sync,
    OrderStatus.success => Icons.check_circle,
    OrderStatus.cancelled => Icons.cancel,
    OrderStatus.failed => Icons.error,
  };

  static Color colorFromCode(String? code) => color(OrderStatus.fromCode(code));

  static IconData iconFromCode(String? code) => icon(OrderStatus.fromCode(code));

  static Color visitColor(VisitStatus status) => switch (status) {
    VisitStatus.belumDikunjungi => AppColors.statusPending,
    VisitStatus.dikunjungi => AppColors.statusProcessing,
    VisitStatus.selesai => AppColors.statusSuccess,
    VisitStatus.dibatalkan => AppColors.statusCancelled,
  };

  static IconData visitIcon(VisitStatus status) => switch (status) {
    VisitStatus.belumDikunjungi => Icons.schedule,
    VisitStatus.dikunjungi => Icons.location_on,
    VisitStatus.selesai => Icons.check_circle,
    VisitStatus.dibatalkan => Icons.cancel,
  };

  static Color customerColor(String? status) {
    final s = status?.toUpperCase() ?? '';
    return switch (s) {
      'ACTIVE' || 'AKTIF' => AppColors.statusSuccess,
      'PENDING' => AppColors.statusPending,
      'PROSPECT' => AppColors.textSecondary,
      'NONACTIVE' || 'REJECTED' => AppColors.statusFailed,
      _ => AppColors.statusSuccess,
    };
  }
}
