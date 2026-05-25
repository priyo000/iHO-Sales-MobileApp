import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../controllers/order_controller.dart';

class OrderDetailActionBar extends ConsumerWidget {
  const OrderDetailActionBar({
    super.key,
    required this.displayOrder,
    required this.serverOrderId,
    required this.localRef,
    required this.canMutateOrder,
    required this.hasPendingActions,
  });

  final Map<String, dynamic> displayOrder;
  final String? serverOrderId;
  final String? localRef;
  final bool canMutateOrder;
  final bool hasPendingActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPendingActions)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: Text(
                  'Perubahan akan disimpan ke antrean offline dan diterapkan saat sinkronisasi berhasil.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                    fontSize: 12,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton.destructive(
                      label: 'Batalkan Pesanan',
                      size: AppButtonSize.lg,
                      isFullWidth: true,
                      onPressed: canMutateOrder
                          ? () => _showCancelDialog(context, ref)
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AppButton.primary(
                      label: 'Edit Pesanan',
                      size: AppButtonSize.lg,
                      isFullWidth: true,
                      onPressed:
                          canMutateOrder ? () => _onEdit(context, ref) : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onEdit(BuildContext context, WidgetRef ref) async {
    await ref
        .read(orderControllerProvider.notifier)
        .prepareEdit(displayOrder);
    if (!context.mounted) return;
    context.push(
      '/order-review',
      extra: {
        'orderId': serverOrderId,
        'localRef': localRef,
        'isEdit': true,
        'initialNotes': displayOrder['catatan'],
        'pelangganId': displayOrder['id_pelanggan'],
        'pelangganData': displayOrder['pelanggan'],
        'kunjunganId': displayOrder['id_kunjungan'],
      },
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Batalkan Pesanan'),
          content: const Text(
            'Yakin ingin membatalkan pesanan ini? Tindakan ini tidak bisa dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            Consumer(
              builder: (innerContext, innerRef, child) {
                final isLoading =
                    innerRef.watch(orderControllerProvider).isLoading;
                return TextButton(
                  onPressed: isLoading
                      ? null
                      : () => _onConfirmCancel(dialogContext, innerRef),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Ya, Batalkan',
                          style: TextStyle(color: AppColors.error),
                        ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _onConfirmCancel(
    BuildContext dialogContext,
    WidgetRef ref,
  ) async {
    final notifier = ref.read(orderControllerProvider.notifier);
    final success = serverOrderId != null
        ? await notifier.cancelOrder(serverOrderId!)
        : (localRef != null && localRef!.isNotEmpty
            ? await notifier.cancelPendingOrder(localRef!)
            : false);
    if (!dialogContext.mounted) return;
    Navigator.pop(dialogContext);
    if (success) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.surface),
              SizedBox(width: AppSpacing.md),
              Text('Pesanan berhasil dibatalkan'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          margin: const EdgeInsets.all(AppSpacing.lg),
        ),
      );
    }
  }
}
