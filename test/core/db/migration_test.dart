import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_tracker_mobile/core/auth/user_provider.dart';
import 'package:sales_tracker_mobile/core/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift schema', () {
    test('opens at the current schema version', () async {
      // Opening the DB runs onCreate for an empty in-memory file.
      await db.customSelect('SELECT 1').get();
      expect(db.schemaVersion, 22);
    });

    test('sync_queue_table has the owner_key column', () async {
      final columns = await db
          .customSelect('PRAGMA table_info(sync_queue_table)')
          .get();
      final names = columns.map((r) => r.data['name'] as String).toSet();
      expect(names, contains('owner_key'));
    });

    test('visits_table has local_photo_paths column', () async {
      final columns =
          await db.customSelect('PRAGMA table_info(visits_table)').get();
      final names = columns.map((r) => r.data['name'] as String).toSet();
      expect(names, contains('local_photo_paths'));
    });

    test('customers_table has client_ref and created_by_id columns', () async {
      final columns =
          await db.customSelect('PRAGMA table_info(customers_table)').get();
      final names = columns.map((r) => r.data['name'] as String).toSet();
      expect(names, containsAll(<String>['client_ref', 'created_by_id']));
    });

    test('schedule_table has nama_rute column', () async {
      final columns =
          await db.customSelect('PRAGMA table_info(schedule_table)').get();
      final names = columns.map((r) => r.data['name'] as String).toSet();
      expect(names, contains('nama_rute'));
    });

    test('product_units_table exists', () async {
      final result = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'product_units_table'",
      ).getSingle();
      expect(result.data['name'], 'product_units_table');
    });
  });

  group('Sync queue owner guard', () {
    test('enqueue stamps ownerKey and scopes getAllQueueItems', () async {
      const ownerA = 'v1|c1|d1|u1';
      const ownerB = 'v1|c2|d2|u2';

      final refA = await db.syncDao.enqueue(
        operation: 'create_pelanggan',
        endpoint: '/kunjungan',
        method: 'POST',
        payload: {'client_ref': 'ref-a', 'nama_toko': 'Toko A'},
        ownerKey: ownerA,
      );
      final refB = await db.syncDao.enqueue(
        operation: 'create_pelanggan',
        endpoint: '/kunjungan',
        method: 'POST',
        payload: {'client_ref': 'ref-b', 'nama_toko': 'Toko B'},
        ownerKey: ownerB,
      );

      // Owner A sees only their own item.
      final itemsA = await db.syncDao.getAllQueueItems(ownerKey: ownerA);
      expect(itemsA.map((e) => e.localRef).toSet(), {refA});

      // Owner B sees only their own item.
      final itemsB = await db.syncDao.getAllQueueItems(ownerKey: ownerB);
      expect(itemsB.map((e) => e.localRef).toSet(), {refB});

      // Foreign-owner detection surfaces A's item as foreign to B.
      final foreignToB = await db.syncDao.getForeignQueueItems(ownerB);
      expect(foreignToB.map((e) => e.localRef).toSet(), {refA});
    });

    test('legacy null-owner rows remain visible to all scopes', () async {
      // Enqueue without an owner (legacy behaviour).
      final legacyRef = await db.syncDao.enqueue(
        operation: 'create_pelanggan',
        endpoint: '/kunjungan',
        method: 'POST',
        payload: {'client_ref': 'legacy', 'nama_toko': 'Legacy'},
      );
      final row =
          await db.syncDao.getAllQueueItems(ownerKey: 'v1|c1|d1|u1');
      expect(row.map((e) => e.localRef), contains(legacyRef));
    });
  });

  group('buildSyncOwnerKey', () {
    test('returns null for empty user', () {
      expect(buildSyncOwnerKey(null), isNull);
      expect(buildSyncOwnerKey(<String, dynamic>{}), isNull);
    });

    test('builds a versioned opaque key from nested karyawan data', () {
      final key = buildSyncOwnerKey({
        'id_perusahaan': 'p1',
        'karyawan': {'id': 'e1', 'id_divisi': 'd1'},
      });
      expect(key, 'v1|p1|d1|e1');
    });

    test('different users produce different keys', () {
      final k1 = buildSyncOwnerKey({'id_perusahaan': 'p1', 'id': 'u1'});
      final k2 = buildSyncOwnerKey({'id_perusahaan': 'p1', 'id': 'u2'});
      expect(k1, isNot(k2));
    });
  });
}
