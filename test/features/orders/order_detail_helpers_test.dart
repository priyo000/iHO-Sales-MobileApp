import 'package:flutter_test/flutter_test.dart';
import 'package:sales_tracker_mobile/features/orders/presentation/pages/order_detail_page.dart';

void main() {
  group('Order detail helpers', () {
    test('parseServerOrderId returns valid string id only', () {
      expect(parseServerOrderId(123), '123');
      expect(parseServerOrderId('45'), '45');
      expect(parseServerOrderId('uuid-abc-123'), 'uuid-abc-123');
      expect(parseServerOrderId(null), isNull);
      expect(parseServerOrderId(''), isNull);
      expect(parseServerOrderId('null'), isNull);
    });

    test(
      'resolveOrderForDisplay prefers route order when fetched is empty',
      () {
        final routeOrder = <String, dynamic>{
          'id': null,
          'is_offline': true,
          'no_pesanan': 'PENDING SYNC',
          'items': [
            {'id_produk': 1, 'jumlah': 2, 'harga_satuan': 10000},
          ],
          'total_tagihan': 20000,
        };

        expect(
          resolveOrderForDisplay(routeOrder: routeOrder),
          routeOrder,
        );

        expect(
          resolveOrderForDisplay(
            routeOrder: routeOrder,
            fetchedOrder: <String, dynamic>{},
          ),
          routeOrder,
        );
      },
    );

    test('resolveOrderForDisplay uses fetched order when meaningful', () {
      final routeOrder = <String, dynamic>{'id': 12, 'no_pesanan': 'SO-001'};
      final fetched = <String, dynamic>{
        'id': 12,
        'no_pesanan': 'SO-001-UPDATED',
        'items': [
          {'id_produk': 1, 'jumlah': 1, 'harga_satuan': 9000},
        ],
      };

      expect(
        resolveOrderForDisplay(routeOrder: routeOrder, fetchedOrder: fetched),
        fetched,
      );
    });
  });
}
