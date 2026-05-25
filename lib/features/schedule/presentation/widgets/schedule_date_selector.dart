import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Horizontal date selector covering ±3 days from today.
///
/// Renders 7 day chips. Tapping one calls [onDateSelected] with the
/// chosen [DateTime]. Highlights the [selectedDate] and marks today.
class ScheduleDateSelector extends StatelessWidget {
  const ScheduleDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final today = DateTime.now();
          final date = today.add(Duration(days: index - 3));
          final isSelected =
              DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(selectedDate);
          final isToday =
              DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(today);

          return _DateChip(
            date: date,
            isSelected: isSelected,
            isToday: isToday,
            onTap: () => onDateSelected(date),
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    if (isSelected) {
      borderColor = AppColors.primary;
    } else if (isToday) {
      borderColor = AppColors.primary.withValues(alpha: 0.4);
    } else {
      borderColor = AppColors.textPrimary.withValues(alpha: 0.15);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        margin: const EdgeInsets.only(right: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('E').format(date),
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? AppColors.textOnPrimary.withValues(alpha: 0.7)
                    : AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            Text(
              DateFormat('d').format(date),
              style: AppTextStyles.titleLarge.copyWith(
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isToday && !isSelected)
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
