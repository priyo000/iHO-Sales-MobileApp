import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/promo_model.dart';
import '../controllers/promo_controller.dart';

class PromoSelectorPage extends ConsumerWidget {
  final String customerId;
  const PromoSelectorPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(availablePromosProvider(customerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Promo')),
      body: promosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (availablePromos) {
          final allPromos = [
            ...availablePromos.aturanHarga,
            ...availablePromos.grosir,
          ];
          if (allPromos.isEmpty) {
            return const Center(child: Text('Tidak ada promo tersedia'));
          }
          return ListView.builder(
            itemCount: allPromos.length,
            itemBuilder: (_, i) {
              final promo = allPromos[i];
              final promoName = promo is PromoAturanHarga
                  ? promo.namaPromo
                  : (promo as PromoGrosir).namaPromo;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.local_offer),
                  title: Text(promoName),
                  onTap: () {
                    // TODO: Wire up promo selection properly
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
