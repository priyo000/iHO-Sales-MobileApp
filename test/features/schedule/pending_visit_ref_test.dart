import 'package:flutter_test/flutter_test.dart';
import 'package:sales_tracker_mobile/features/schedule/data/schedule_repository.dart';

void main() {
  group('resolvePendingVisitRef', () {
    test('prefers client_ref so offline visit token matches backend flow', () {
      final queueItem = <String, dynamic>{
        'local_ref': 'check_in_1712730000_00001',
        'payload': <String, dynamic>{
          'client_ref': 'visit_1712730000_54321',
          'id_pelanggan': 10,
        },
      };

      expect(resolvePendingVisitRef(queueItem), 'visit_1712730000_54321');
    });

    test('falls back to local_ref when legacy payload has no client_ref', () {
      final queueItem = <String, dynamic>{
        'local_ref': 'check_in_1712730000_00001',
        'payload': <String, dynamic>{'id_pelanggan': 10},
      };

      expect(resolvePendingVisitRef(queueItem), 'check_in_1712730000_00001');
    });
  });
}
