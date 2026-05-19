// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_dao.dart';

// ignore_for_file: type=lint
mixin _$ScheduleDaoMixin on DatabaseAccessor<AppDatabase> {
  $ScheduleTableTable get scheduleTable => attachedDatabase.scheduleTable;
  $VisitsTableTable get visitsTable => attachedDatabase.visitsTable;
  ScheduleDaoManager get managers => ScheduleDaoManager(this);
}

class ScheduleDaoManager {
  final _$ScheduleDaoMixin _db;
  ScheduleDaoManager(this._db);
  $$ScheduleTableTableTableManager get scheduleTable =>
      $$ScheduleTableTableTableManager(_db.attachedDatabase, _db.scheduleTable);
  $$VisitsTableTableTableManager get visitsTable =>
      $$VisitsTableTableTableManager(_db.attachedDatabase, _db.visitsTable);
}
