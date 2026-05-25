import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';

class OrderDetailTimeline extends StatelessWidget {
  const OrderDetailTimeline({
    super.key,
    required this.order,
    required this.dateFormat,
  });

  final Map<String, dynamic> order;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final stages = _buildStages();
    if (stages.isEmpty) return const SizedBox.shrink();

    return AppCard(
      bordered: false,
      shadow: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat Status',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...stages.asMap().entries.map((entry) {
            final idx = entry.key;
            final stage = entry.value;
            final isLast = idx == stages.length - 1;
            return _TimelineRow(
              stage: stage,
              isLast: isLast,
              dateFormat: dateFormat,
            );
          }),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildStages() {
    final List<Map<String, dynamic>> stages = [
      {
        'label': 'Order Dibuat',
        'time': order['tanggal_transaksi'],
        'icon': Icons.add_shopping_cart,
      },
      {
        'label': 'Diproses',
        'time': order['waktu_proses'],
        'icon': Icons.sync,
      },
      {
        'label': 'Dikirim',
        'time': order['waktu_kirim'],
        'icon': Icons.local_shipping,
      },
      {
        'label': 'Selesai',
        'time': order['waktu_selesai'],
        'icon': Icons.check_circle,
      },
    ];
    if (order['waktu_batal'] != null) {
      stages.add({
        'label': 'Dibatalkan',
        'time': order['waktu_batal'],
        'icon': Icons.cancel,
        'color': AppColors.error,
      });
    }
    return stages.where((s) => s['time'] != null).toList();
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.stage,
    required this.isLast,
    required this.dateFormat,
  });

  final Map<String, dynamic> stage;
  final bool isLast;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final rawTime = stage['time'];
    DateTime? dt;
    if (rawTime is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(rawTime);
    } else if (rawTime is String) {
      dt = DateTime.tryParse(rawTime)?.toLocal();
    }

    final stageColor =
        (stage['color'] as Color?) ?? AppColors.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: stageColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                stage['icon'] as IconData,
                size: 14,
                color: stageColor,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stage['label'] as String,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                dt != null ? dateFormat.format(dt) : '-',
                style: AppTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ],
    );
  }
}
