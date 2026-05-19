import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/sync_service.dart';

class FailedItemsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final WidgetRef ref;
  const FailedItemsSheet({super.key, required this.items, required this.ref});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Data Gagal Sinkronisasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${items.length} item gagal dikirim setelah 5x percobaan.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final item = items[index];
                    final operation = item['operation'] as String? ?? '-';
                    final errorMessage =
                        item['error_message'] as String? ?? 'Unknown error';
                    final localRef = item['local_ref'] as String;
                    final createdAt = item['created_at'] as int?;
                    final createdDate = createdAt != null
                        ? DateTime.fromMillisecondsSinceEpoch(createdAt)
                        : null;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _operationLabel(operation),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (createdDate != null)
                                Text(
                                  '${createdDate.day}/${createdDate.month} '
                                  '${createdDate.hour}:${createdDate.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Error: $errorMessage',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text(
                                    'Coba Lagi',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: const BorderSide(color: Colors.blue),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(syncServiceProvider)
                                        .retryFailed(localRef);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                              if (operation == 'create_pelanggan') ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text(
                                      'Edit HP',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                      side: const BorderSide(
                                        color: Colors.orange,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                    ),
                                    onPressed: () => _editPhoneNumber(
                                      context,
                                      localRef,
                                      Map<String, dynamic>.from(
                                        item['payload']
                                                as Map<String, dynamic>? ??
                                            {},
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Hapus',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _confirmDiscard(context, localRef),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editPhoneNumber(
    BuildContext context,
    String localRef,
    Map<String, dynamic> payload,
  ) {
    final phoneCtrl = TextEditingController(
      text: payload['no_hp_pribadi']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Nomor HP', style: TextStyle(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubah nomor HP jika sebelumnya gagal karena bentrok atau salah pendaftaran.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Nomor HP (Baru)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (phoneCtrl.text.trim().isEmpty) return;
              final newPayload = Map<String, dynamic>.from(payload);
              newPayload['no_hp_pribadi'] = phoneCtrl.text.trim();
              ref
                  .read(syncServiceProvider)
                  .updatePayloadAndRetry(localRef, newPayload);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan & Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _confirmDiscard(BuildContext context, String localRef) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data?'),
        content: const Text(
          'Data ini akan dihapus permanen dari antrian sinkronisasi. '
          'Aksi ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(syncServiceProvider).discardFailed(localRef);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _operationLabel(String operation) {
    return switch (operation) {
      'check_in' => 'Check-In',
      'check_out' => 'Check-Out',
      'create_order' => 'Pesanan',
      'create_pelanggan' => 'Pelanggan Baru',
      _ => operation,
    };
  }
}
