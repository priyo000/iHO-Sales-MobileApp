import 'package:flutter/material.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';

import 'customer_stat_card.dart';

class CustomerFinancialSection extends StatelessWidget {
  final Map<dynamic, dynamic> pelanggan;

  const CustomerFinancialSection({super.key, required this.pelanggan});

  String _getPaymentSystemDisplay(dynamic value) {
    if (value == null) return '-';
    final str = value.toString();
    if (str.isEmpty) return '-';
    return str;
  }

  String _getPaymentMethodSubtext(dynamic value) {
    if (value == null) return 'Belum diatur';
    final str = value.toString().toLowerCase();
    if (str.contains('transfer')) return 'Via Transfer Bank';
    if (str.contains('tunai') || str.contains('cash')) return 'Bayar Langsung';
    if (str.contains('giro')) return 'Via Giro';
    return 'Metode Lainnya';
  }

  IconData _getPaymentMethodIcon(dynamic value) {
    if (value == null) return Icons.help_outline;
    final str = value.toString().toLowerCase();
    if (str.contains('transfer')) return Icons.account_balance;
    if (str.contains('tunai') || str.contains('cash')) return Icons.payments;
    if (str.contains('giro')) return Icons.receipt_long;
    return Icons.payment;
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final num = double.tryParse(value.toString()) ?? 0;
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}jt';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(0)}rb';
    }
    return num.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Finansial',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomerStatCard(
                label: 'Sistem Pembayaran',
                value: _getPaymentSystemDisplay(pelanggan['sistem_pembayaran']),
                subtext: pelanggan['sistem_pembayaran'] == 'Kredit'
                    ? 'Pembayaran Tempo'
                    : 'Pembayaran Tunai',
                subicon: pelanggan['sistem_pembayaran'] == 'Kredit'
                    ? Icons.credit_card
                    : Icons.payments_outlined,
                subcolor: pelanggan['sistem_pembayaran'] == 'Kredit'
                    ? Colors.orange
                    : AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomerStatCard(
                label: 'Cara Bayar',
                value: (pelanggan['cara_pembayaran'] as String?) ?? '-',
                subtext: _getPaymentMethodSubtext(pelanggan['cara_pembayaran']),
                subicon: _getPaymentMethodIcon(pelanggan['cara_pembayaran']),
                subcolor: Colors.blue,
              ),
            ),
          ],
        ),
        if (pelanggan['sistem_pembayaran'] == 'Kredit') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomerStatCard(
                  label: 'Limit Kredit',
                  value: 'Rp ${_formatCurrency(pelanggan['limit_kredit_awal'] ?? 0)}',
                  subtext: 'Limit Awal',
                  subicon: Icons.account_balance_wallet,
                  subcolor: AppTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomerStatCard(
                  label: 'TOP (Hari)',
                  value: '${pelanggan['top_hari'] ?? 0} Hari',
                  subtext: 'Term of Payment',
                  subicon: Icons.timer,
                  subcolor: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
