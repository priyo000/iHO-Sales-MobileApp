import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';

class OrderSummarySection extends StatelessWidget {
  final double subtotal;
  final double diskonTotal;
  final double totalHadiah;
  final double grandTotal;
  final NumberFormat fmt;

  const OrderSummarySection({
    super.key,
    required this.subtotal,
    required this.diskonTotal,
    required this.totalHadiah,
    required this.grandTotal,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          _SummaryLine(label: "Subtotal", value: fmt.format(subtotal)),
          if (totalHadiah > 0) ...[
            const SizedBox(height: 6),
            _SummaryLine(
              label: "Hadiah / Tebus",
              value: "+ ${fmt.format(totalHadiah)}",
              valueColor: Colors.orange.shade700,
              icon: Icons.card_giftcard,
              iconColor: Colors.orange,
            ),
          ],
          if (diskonTotal > 0) ...[
            const SizedBox(height: 6),
            _SummaryLine(
              label: "Total Diskon",
              value: "- ${fmt.format(diskonTotal)}",
              valueColor: AppColors.success,
              icon: Icons.local_offer,
              iconColor: AppColors.success,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Grand Total",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                fmt.format(grandTotal),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;
  final Color? iconColor;

  const _SummaryLine({
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: iconColor ?? Colors.grey),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
