// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalCacheTableTable extends LocalCacheTable
    with TableInfo<$LocalCacheTableTable, LocalCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, cacheKey, data, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_cache_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCacheTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCacheTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCacheTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $LocalCacheTableTable createAlias(String alias) {
    return $LocalCacheTableTable(attachedDatabase, alias);
  }
}

class LocalCacheTableData extends DataClass
    implements Insertable<LocalCacheTableData> {
  final int id;
  final String cacheKey;
  final String data;
  final int cachedAt;
  const LocalCacheTableData({
    required this.id,
    required this.cacheKey,
    required this.data,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cache_key'] = Variable<String>(cacheKey);
    map['data'] = Variable<String>(data);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  LocalCacheTableCompanion toCompanion(bool nullToAbsent) {
    return LocalCacheTableCompanion(
      id: Value(id),
      cacheKey: Value(cacheKey),
      data: Value(data),
      cachedAt: Value(cachedAt),
    );
  }

  factory LocalCacheTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCacheTableData(
      id: serializer.fromJson<int>(json['id']),
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      data: serializer.fromJson<String>(json['data']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cacheKey': serializer.toJson<String>(cacheKey),
      'data': serializer.toJson<String>(data),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  LocalCacheTableData copyWith({
    int? id,
    String? cacheKey,
    String? data,
    int? cachedAt,
  }) => LocalCacheTableData(
    id: id ?? this.id,
    cacheKey: cacheKey ?? this.cacheKey,
    data: data ?? this.data,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  LocalCacheTableData copyWithCompanion(LocalCacheTableCompanion data) {
    return LocalCacheTableData(
      id: data.id.present ? data.id.value : this.id,
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      data: data.data.present ? data.data.value : this.data,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCacheTableData(')
          ..write('id: $id, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('data: $data, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, cacheKey, data, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCacheTableData &&
          other.id == this.id &&
          other.cacheKey == this.cacheKey &&
          other.data == this.data &&
          other.cachedAt == this.cachedAt);
}

class LocalCacheTableCompanion extends UpdateCompanion<LocalCacheTableData> {
  final Value<int> id;
  final Value<String> cacheKey;
  final Value<String> data;
  final Value<int> cachedAt;
  const LocalCacheTableCompanion({
    this.id = const Value.absent(),
    this.cacheKey = const Value.absent(),
    this.data = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  LocalCacheTableCompanion.insert({
    this.id = const Value.absent(),
    required String cacheKey,
    required String data,
    required int cachedAt,
  }) : cacheKey = Value(cacheKey),
       data = Value(data),
       cachedAt = Value(cachedAt);
  static Insertable<LocalCacheTableData> custom({
    Expression<int>? id,
    Expression<String>? cacheKey,
    Expression<String>? data,
    Expression<int>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cacheKey != null) 'cache_key': cacheKey,
      if (data != null) 'data': data,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  LocalCacheTableCompanion copyWith({
    Value<int>? id,
    Value<String>? cacheKey,
    Value<String>? data,
    Value<int>? cachedAt,
  }) {
    return LocalCacheTableCompanion(
      id: id ?? this.id,
      cacheKey: cacheKey ?? this.cacheKey,
      data: data ?? this.data,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCacheTableCompanion(')
          ..write('id: $id, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('data: $data, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataTableTable extends SyncMetadataTable
    with TableInfo<$SyncMetadataTableTable, SyncMetadataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceMeta = const VerificationMeta(
    'resource',
  );
  @override
  late final GeneratedColumn<String> resource = GeneratedColumn<String>(
    'resource',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncMeta = const VerificationMeta(
    'lastSync',
  );
  @override
  late final GeneratedColumn<int> lastSync = GeneratedColumn<int>(
    'last_sync',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<String> lastModified = GeneratedColumn<String>(
    'last_modified',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [resource, lastSync, lastModified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource')) {
      context.handle(
        _resourceMeta,
        resource.isAcceptableOrUnknown(data['resource']!, _resourceMeta),
      );
    } else if (isInserting) {
      context.missing(_resourceMeta);
    }
    if (data.containsKey('last_sync')) {
      context.handle(
        _lastSyncMeta,
        lastSync.isAcceptableOrUnknown(data['last_sync']!, _lastSyncMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSyncMeta);
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resource};
  @override
  SyncMetadataTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataTableData(
      resource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource'],
      )!,
      lastSync: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sync'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified'],
      ),
    );
  }

  @override
  $SyncMetadataTableTable createAlias(String alias) {
    return $SyncMetadataTableTable(attachedDatabase, alias);
  }
}

class SyncMetadataTableData extends DataClass
    implements Insertable<SyncMetadataTableData> {
  final String resource;
  final int lastSync;
  final String? lastModified;
  const SyncMetadataTableData({
    required this.resource,
    required this.lastSync,
    this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource'] = Variable<String>(resource);
    map['last_sync'] = Variable<int>(lastSync);
    if (!nullToAbsent || lastModified != null) {
      map['last_modified'] = Variable<String>(lastModified);
    }
    return map;
  }

  SyncMetadataTableCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataTableCompanion(
      resource: Value(resource),
      lastSync: Value(lastSync),
      lastModified: lastModified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModified),
    );
  }

  factory SyncMetadataTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataTableData(
      resource: serializer.fromJson<String>(json['resource']),
      lastSync: serializer.fromJson<int>(json['lastSync']),
      lastModified: serializer.fromJson<String?>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resource': serializer.toJson<String>(resource),
      'lastSync': serializer.toJson<int>(lastSync),
      'lastModified': serializer.toJson<String?>(lastModified),
    };
  }

  SyncMetadataTableData copyWith({
    String? resource,
    int? lastSync,
    Value<String?> lastModified = const Value.absent(),
  }) => SyncMetadataTableData(
    resource: resource ?? this.resource,
    lastSync: lastSync ?? this.lastSync,
    lastModified: lastModified.present ? lastModified.value : this.lastModified,
  );
  SyncMetadataTableData copyWithCompanion(SyncMetadataTableCompanion data) {
    return SyncMetadataTableData(
      resource: data.resource.present ? data.resource.value : this.resource,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataTableData(')
          ..write('resource: $resource, ')
          ..write('lastSync: $lastSync, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(resource, lastSync, lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataTableData &&
          other.resource == this.resource &&
          other.lastSync == this.lastSync &&
          other.lastModified == this.lastModified);
}

class SyncMetadataTableCompanion
    extends UpdateCompanion<SyncMetadataTableData> {
  final Value<String> resource;
  final Value<int> lastSync;
  final Value<String?> lastModified;
  final Value<int> rowid;
  const SyncMetadataTableCompanion({
    this.resource = const Value.absent(),
    this.lastSync = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataTableCompanion.insert({
    required String resource,
    required int lastSync,
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : resource = Value(resource),
       lastSync = Value(lastSync);
  static Insertable<SyncMetadataTableData> custom({
    Expression<String>? resource,
    Expression<int>? lastSync,
    Expression<String>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resource != null) 'resource': resource,
      if (lastSync != null) 'last_sync': lastSync,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataTableCompanion copyWith({
    Value<String>? resource,
    Value<int>? lastSync,
    Value<String?>? lastModified,
    Value<int>? rowid,
  }) {
    return SyncMetadataTableCompanion(
      resource: resource ?? this.resource,
      lastSync: lastSync ?? this.lastSync,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resource.present) {
      map['resource'] = Variable<String>(resource.value);
    }
    if (lastSync.present) {
      map['last_sync'] = Variable<int>(lastSync.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<String>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataTableCompanion(')
          ..write('resource: $resource, ')
          ..write('lastSync: $lastSync, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localRefMeta = const VerificationMeta(
    'localRef',
  );
  @override
  late final GeneratedColumn<String> localRef = GeneratedColumn<String>(
    'local_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endpointMeta = const VerificationMeta(
    'endpoint',
  );
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastServerIdMeta = const VerificationMeta(
    'lastServerId',
  );
  @override
  late final GeneratedColumn<String> lastServerId = GeneratedColumn<String>(
    'last_server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSyncedAtMeta = const VerificationMeta(
    'serverSyncedAt',
  );
  @override
  late final GeneratedColumn<int> serverSyncedAt = GeneratedColumn<int>(
    'server_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localRef,
    operation,
    endpoint,
    method,
    payload,
    createdAt,
    retryCount,
    status,
    errorMessage,
    lastServerId,
    serverSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_ref')) {
      context.handle(
        _localRefMeta,
        localRef.isAcceptableOrUnknown(data['local_ref']!, _localRefMeta),
      );
    } else if (isInserting) {
      context.missing(_localRefMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(
        _endpointMeta,
        endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta),
      );
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('last_server_id')) {
      context.handle(
        _lastServerIdMeta,
        lastServerId.isAcceptableOrUnknown(
          data['last_server_id']!,
          _lastServerIdMeta,
        ),
      );
    }
    if (data.containsKey('server_synced_at')) {
      context.handle(
        _serverSyncedAtMeta,
        serverSyncedAt.isAcceptableOrUnknown(
          data['server_synced_at']!,
          _serverSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_ref'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      endpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      lastServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_server_id'],
      ),
      serverSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_synced_at'],
      ),
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueTableData extends DataClass
    implements Insertable<SyncQueueTableData> {
  final int id;
  final String localRef;
  final String operation;
  final String endpoint;
  final String method;
  final String payload;
  final int createdAt;
  final int retryCount;
  final String status;
  final String? errorMessage;
  final String? lastServerId;
  final int? serverSyncedAt;
  const SyncQueueTableData({
    required this.id,
    required this.localRef,
    required this.operation,
    required this.endpoint,
    required this.method,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    required this.status,
    this.errorMessage,
    this.lastServerId,
    this.serverSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_ref'] = Variable<String>(localRef);
    map['operation'] = Variable<String>(operation);
    map['endpoint'] = Variable<String>(endpoint);
    map['method'] = Variable<String>(method);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<int>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || lastServerId != null) {
      map['last_server_id'] = Variable<String>(lastServerId);
    }
    if (!nullToAbsent || serverSyncedAt != null) {
      map['server_synced_at'] = Variable<int>(serverSyncedAt);
    }
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      localRef: Value(localRef),
      operation: Value(operation),
      endpoint: Value(endpoint),
      method: Value(method),
      payload: Value(payload),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      lastServerId: lastServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastServerId),
      serverSyncedAt: serverSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSyncedAt),
    );
  }

  factory SyncQueueTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueTableData(
      id: serializer.fromJson<int>(json['id']),
      localRef: serializer.fromJson<String>(json['localRef']),
      operation: serializer.fromJson<String>(json['operation']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      method: serializer.fromJson<String>(json['method']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      lastServerId: serializer.fromJson<String?>(json['lastServerId']),
      serverSyncedAt: serializer.fromJson<int?>(json['serverSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localRef': serializer.toJson<String>(localRef),
      'operation': serializer.toJson<String>(operation),
      'endpoint': serializer.toJson<String>(endpoint),
      'method': serializer.toJson<String>(method),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<int>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'lastServerId': serializer.toJson<String?>(lastServerId),
      'serverSyncedAt': serializer.toJson<int?>(serverSyncedAt),
    };
  }

  SyncQueueTableData copyWith({
    int? id,
    String? localRef,
    String? operation,
    String? endpoint,
    String? method,
    String? payload,
    int? createdAt,
    int? retryCount,
    String? status,
    Value<String?> errorMessage = const Value.absent(),
    Value<String?> lastServerId = const Value.absent(),
    Value<int?> serverSyncedAt = const Value.absent(),
  }) => SyncQueueTableData(
    id: id ?? this.id,
    localRef: localRef ?? this.localRef,
    operation: operation ?? this.operation,
    endpoint: endpoint ?? this.endpoint,
    method: method ?? this.method,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    lastServerId: lastServerId.present ? lastServerId.value : this.lastServerId,
    serverSyncedAt: serverSyncedAt.present
        ? serverSyncedAt.value
        : this.serverSyncedAt,
  );
  SyncQueueTableData copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      localRef: data.localRef.present ? data.localRef.value : this.localRef,
      operation: data.operation.present ? data.operation.value : this.operation,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      method: data.method.present ? data.method.value : this.method,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      lastServerId: data.lastServerId.present
          ? data.lastServerId.value
          : this.lastServerId,
      serverSyncedAt: data.serverSyncedAt.present
          ? data.serverSyncedAt.value
          : this.serverSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableData(')
          ..write('id: $id, ')
          ..write('localRef: $localRef, ')
          ..write('operation: $operation, ')
          ..write('endpoint: $endpoint, ')
          ..write('method: $method, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('lastServerId: $lastServerId, ')
          ..write('serverSyncedAt: $serverSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localRef,
    operation,
    endpoint,
    method,
    payload,
    createdAt,
    retryCount,
    status,
    errorMessage,
    lastServerId,
    serverSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueTableData &&
          other.id == this.id &&
          other.localRef == this.localRef &&
          other.operation == this.operation &&
          other.endpoint == this.endpoint &&
          other.method == this.method &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.lastServerId == this.lastServerId &&
          other.serverSyncedAt == this.serverSyncedAt);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueTableData> {
  final Value<int> id;
  final Value<String> localRef;
  final Value<String> operation;
  final Value<String> endpoint;
  final Value<String> method;
  final Value<String> payload;
  final Value<int> createdAt;
  final Value<int> retryCount;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<String?> lastServerId;
  final Value<int?> serverSyncedAt;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.localRef = const Value.absent(),
    this.operation = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.method = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.lastServerId = const Value.absent(),
    this.serverSyncedAt = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    this.id = const Value.absent(),
    required String localRef,
    required String operation,
    required String endpoint,
    required String method,
    required String payload,
    required int createdAt,
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.lastServerId = const Value.absent(),
    this.serverSyncedAt = const Value.absent(),
  }) : localRef = Value(localRef),
       operation = Value(operation),
       endpoint = Value(endpoint),
       method = Value(method),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueTableData> custom({
    Expression<int>? id,
    Expression<String>? localRef,
    Expression<String>? operation,
    Expression<String>? endpoint,
    Expression<String>? method,
    Expression<String>? payload,
    Expression<int>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<String>? lastServerId,
    Expression<int>? serverSyncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localRef != null) 'local_ref': localRef,
      if (operation != null) 'operation': operation,
      if (endpoint != null) 'endpoint': endpoint,
      if (method != null) 'method': method,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (lastServerId != null) 'last_server_id': lastServerId,
      if (serverSyncedAt != null) 'server_synced_at': serverSyncedAt,
    });
  }

  SyncQueueTableCompanion copyWith({
    Value<int>? id,
    Value<String>? localRef,
    Value<String>? operation,
    Value<String>? endpoint,
    Value<String>? method,
    Value<String>? payload,
    Value<int>? createdAt,
    Value<int>? retryCount,
    Value<String>? status,
    Value<String?>? errorMessage,
    Value<String?>? lastServerId,
    Value<int?>? serverSyncedAt,
  }) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      localRef: localRef ?? this.localRef,
      operation: operation ?? this.operation,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastServerId: lastServerId ?? this.lastServerId,
      serverSyncedAt: serverSyncedAt ?? this.serverSyncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localRef.present) {
      map['local_ref'] = Variable<String>(localRef.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (lastServerId.present) {
      map['last_server_id'] = Variable<String>(lastServerId.value);
    }
    if (serverSyncedAt.present) {
      map['server_synced_at'] = Variable<int>(serverSyncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('localRef: $localRef, ')
          ..write('operation: $operation, ')
          ..write('endpoint: $endpoint, ')
          ..write('method: $method, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('lastServerId: $lastServerId, ')
          ..write('serverSyncedAt: $serverSyncedAt')
          ..write(')'))
        .toString();
  }
}

class $RefIdMapTableTable extends RefIdMapTable
    with TableInfo<$RefIdMapTableTable, RefIdMapTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RefIdMapTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localRefMeta = const VerificationMeta(
    'localRef',
  );
  @override
  late final GeneratedColumn<String> localRef = GeneratedColumn<String>(
    'local_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [localRef, serverId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ref_id_map_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<RefIdMapTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_ref')) {
      context.handle(
        _localRefMeta,
        localRef.isAcceptableOrUnknown(data['local_ref']!, _localRefMeta),
      );
    } else if (isInserting) {
      context.missing(_localRefMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localRef};
  @override
  RefIdMapTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RefIdMapTableData(
      localRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_ref'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RefIdMapTableTable createAlias(String alias) {
    return $RefIdMapTableTable(attachedDatabase, alias);
  }
}

class RefIdMapTableData extends DataClass
    implements Insertable<RefIdMapTableData> {
  final String localRef;
  final String serverId;
  final int createdAt;
  const RefIdMapTableData({
    required this.localRef,
    required this.serverId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_ref'] = Variable<String>(localRef);
    map['server_id'] = Variable<String>(serverId);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  RefIdMapTableCompanion toCompanion(bool nullToAbsent) {
    return RefIdMapTableCompanion(
      localRef: Value(localRef),
      serverId: Value(serverId),
      createdAt: Value(createdAt),
    );
  }

  factory RefIdMapTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RefIdMapTableData(
      localRef: serializer.fromJson<String>(json['localRef']),
      serverId: serializer.fromJson<String>(json['serverId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localRef': serializer.toJson<String>(localRef),
      'serverId': serializer.toJson<String>(serverId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  RefIdMapTableData copyWith({
    String? localRef,
    String? serverId,
    int? createdAt,
  }) => RefIdMapTableData(
    localRef: localRef ?? this.localRef,
    serverId: serverId ?? this.serverId,
    createdAt: createdAt ?? this.createdAt,
  );
  RefIdMapTableData copyWithCompanion(RefIdMapTableCompanion data) {
    return RefIdMapTableData(
      localRef: data.localRef.present ? data.localRef.value : this.localRef,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RefIdMapTableData(')
          ..write('localRef: $localRef, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localRef, serverId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RefIdMapTableData &&
          other.localRef == this.localRef &&
          other.serverId == this.serverId &&
          other.createdAt == this.createdAt);
}

class RefIdMapTableCompanion extends UpdateCompanion<RefIdMapTableData> {
  final Value<String> localRef;
  final Value<String> serverId;
  final Value<int> createdAt;
  final Value<int> rowid;
  const RefIdMapTableCompanion({
    this.localRef = const Value.absent(),
    this.serverId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RefIdMapTableCompanion.insert({
    required String localRef,
    required String serverId,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : localRef = Value(localRef),
       serverId = Value(serverId),
       createdAt = Value(createdAt);
  static Insertable<RefIdMapTableData> custom({
    Expression<String>? localRef,
    Expression<String>? serverId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localRef != null) 'local_ref': localRef,
      if (serverId != null) 'server_id': serverId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RefIdMapTableCompanion copyWith({
    Value<String>? localRef,
    Value<String>? serverId,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return RefIdMapTableCompanion(
      localRef: localRef ?? this.localRef,
      serverId: serverId ?? this.serverId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localRef.present) {
      map['local_ref'] = Variable<String>(localRef.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RefIdMapTableCompanion(')
          ..write('localRef: $localRef, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncLockTableTable extends SyncLockTable
    with TableInfo<$SyncLockTableTable, SyncLockTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLockTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _lockNameMeta = const VerificationMeta(
    'lockName',
  );
  @override
  late final GeneratedColumn<String> lockName = GeneratedColumn<String>(
    'lock_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _acquiredAtMeta = const VerificationMeta(
    'acquiredAt',
  );
  @override
  late final GeneratedColumn<int> acquiredAt = GeneratedColumn<int>(
    'acquired_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, lockName, acquiredAt, ownerId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_lock_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncLockTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lock_name')) {
      context.handle(
        _lockNameMeta,
        lockName.isAcceptableOrUnknown(data['lock_name']!, _lockNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lockNameMeta);
    }
    if (data.containsKey('acquired_at')) {
      context.handle(
        _acquiredAtMeta,
        acquiredAt.isAcceptableOrUnknown(data['acquired_at']!, _acquiredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_acquiredAtMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncLockTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLockTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lockName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lock_name'],
      )!,
      acquiredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}acquired_at'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
    );
  }

  @override
  $SyncLockTableTable createAlias(String alias) {
    return $SyncLockTableTable(attachedDatabase, alias);
  }
}

class SyncLockTableData extends DataClass
    implements Insertable<SyncLockTableData> {
  final int id;
  final String lockName;
  final int acquiredAt;
  final String ownerId;
  const SyncLockTableData({
    required this.id,
    required this.lockName,
    required this.acquiredAt,
    required this.ownerId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lock_name'] = Variable<String>(lockName);
    map['acquired_at'] = Variable<int>(acquiredAt);
    map['owner_id'] = Variable<String>(ownerId);
    return map;
  }

  SyncLockTableCompanion toCompanion(bool nullToAbsent) {
    return SyncLockTableCompanion(
      id: Value(id),
      lockName: Value(lockName),
      acquiredAt: Value(acquiredAt),
      ownerId: Value(ownerId),
    );
  }

  factory SyncLockTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLockTableData(
      id: serializer.fromJson<int>(json['id']),
      lockName: serializer.fromJson<String>(json['lockName']),
      acquiredAt: serializer.fromJson<int>(json['acquiredAt']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lockName': serializer.toJson<String>(lockName),
      'acquiredAt': serializer.toJson<int>(acquiredAt),
      'ownerId': serializer.toJson<String>(ownerId),
    };
  }

  SyncLockTableData copyWith({
    int? id,
    String? lockName,
    int? acquiredAt,
    String? ownerId,
  }) => SyncLockTableData(
    id: id ?? this.id,
    lockName: lockName ?? this.lockName,
    acquiredAt: acquiredAt ?? this.acquiredAt,
    ownerId: ownerId ?? this.ownerId,
  );
  SyncLockTableData copyWithCompanion(SyncLockTableCompanion data) {
    return SyncLockTableData(
      id: data.id.present ? data.id.value : this.id,
      lockName: data.lockName.present ? data.lockName.value : this.lockName,
      acquiredAt: data.acquiredAt.present
          ? data.acquiredAt.value
          : this.acquiredAt,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLockTableData(')
          ..write('id: $id, ')
          ..write('lockName: $lockName, ')
          ..write('acquiredAt: $acquiredAt, ')
          ..write('ownerId: $ownerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lockName, acquiredAt, ownerId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLockTableData &&
          other.id == this.id &&
          other.lockName == this.lockName &&
          other.acquiredAt == this.acquiredAt &&
          other.ownerId == this.ownerId);
}

class SyncLockTableCompanion extends UpdateCompanion<SyncLockTableData> {
  final Value<int> id;
  final Value<String> lockName;
  final Value<int> acquiredAt;
  final Value<String> ownerId;
  const SyncLockTableCompanion({
    this.id = const Value.absent(),
    this.lockName = const Value.absent(),
    this.acquiredAt = const Value.absent(),
    this.ownerId = const Value.absent(),
  });
  SyncLockTableCompanion.insert({
    this.id = const Value.absent(),
    required String lockName,
    required int acquiredAt,
    required String ownerId,
  }) : lockName = Value(lockName),
       acquiredAt = Value(acquiredAt),
       ownerId = Value(ownerId);
  static Insertable<SyncLockTableData> custom({
    Expression<int>? id,
    Expression<String>? lockName,
    Expression<int>? acquiredAt,
    Expression<String>? ownerId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lockName != null) 'lock_name': lockName,
      if (acquiredAt != null) 'acquired_at': acquiredAt,
      if (ownerId != null) 'owner_id': ownerId,
    });
  }

  SyncLockTableCompanion copyWith({
    Value<int>? id,
    Value<String>? lockName,
    Value<int>? acquiredAt,
    Value<String>? ownerId,
  }) {
    return SyncLockTableCompanion(
      id: id ?? this.id,
      lockName: lockName ?? this.lockName,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lockName.present) {
      map['lock_name'] = Variable<String>(lockName.value);
    }
    if (acquiredAt.present) {
      map['acquired_at'] = Variable<int>(acquiredAt.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLockTableCompanion(')
          ..write('id: $id, ')
          ..write('lockName: $lockName, ')
          ..write('acquiredAt: $acquiredAt, ')
          ..write('ownerId: $ownerId')
          ..write(')'))
        .toString();
  }
}

class $CartItemsTableTable extends CartItemsTable
    with TableInfo<$CartItemsTableTable, CartItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CartItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pelangganIdMeta = const VerificationMeta(
    'pelangganId',
  );
  @override
  late final GeneratedColumn<String> pelangganId = GeneratedColumn<String>(
    'pelanggan_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productJsonMeta = const VerificationMeta(
    'productJson',
  );
  @override
  late final GeneratedColumn<String> productJson = GeneratedColumn<String>(
    'product_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _negotiatedPriceMeta = const VerificationMeta(
    'negotiatedPrice',
  );
  @override
  late final GeneratedColumn<double> negotiatedPrice = GeneratedColumn<double>(
    'negotiated_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
    'unit_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitNameMeta = const VerificationMeta(
    'unitName',
  );
  @override
  late final GeneratedColumn<String> unitName = GeneratedColumn<String>(
    'unit_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pelangganId,
    productJson,
    productId,
    quantity,
    negotiatedPrice,
    unitId,
    unitName,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cart_items_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CartItemsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pelanggan_id')) {
      context.handle(
        _pelangganIdMeta,
        pelangganId.isAcceptableOrUnknown(
          data['pelanggan_id']!,
          _pelangganIdMeta,
        ),
      );
    }
    if (data.containsKey('product_json')) {
      context.handle(
        _productJsonMeta,
        productJson.isAcceptableOrUnknown(
          data['product_json']!,
          _productJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productJsonMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('negotiated_price')) {
      context.handle(
        _negotiatedPriceMeta,
        negotiatedPrice.isAcceptableOrUnknown(
          data['negotiated_price']!,
          _negotiatedPriceMeta,
        ),
      );
    }
    if (data.containsKey('unit_id')) {
      context.handle(
        _unitIdMeta,
        unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta),
      );
    }
    if (data.containsKey('unit_name')) {
      context.handle(
        _unitNameMeta,
        unitName.isAcceptableOrUnknown(data['unit_name']!, _unitNameMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CartItemsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CartItemsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      pelangganId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pelanggan_id'],
      ),
      productJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_json'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      negotiatedPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}negotiated_price'],
      ),
      unitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_id'],
      ),
      unitName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_name'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CartItemsTableTable createAlias(String alias) {
    return $CartItemsTableTable(attachedDatabase, alias);
  }
}

class CartItemsTableData extends DataClass
    implements Insertable<CartItemsTableData> {
  final int id;
  final String? pelangganId;
  final String productJson;
  final String productId;
  final int quantity;
  final double? negotiatedPrice;
  final String? unitId;
  final String? unitName;
  final int createdAt;
  const CartItemsTableData({
    required this.id,
    this.pelangganId,
    required this.productJson,
    required this.productId,
    required this.quantity,
    this.negotiatedPrice,
    this.unitId,
    this.unitName,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || pelangganId != null) {
      map['pelanggan_id'] = Variable<String>(pelangganId);
    }
    map['product_json'] = Variable<String>(productJson);
    map['product_id'] = Variable<String>(productId);
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || negotiatedPrice != null) {
      map['negotiated_price'] = Variable<double>(negotiatedPrice);
    }
    if (!nullToAbsent || unitId != null) {
      map['unit_id'] = Variable<String>(unitId);
    }
    if (!nullToAbsent || unitName != null) {
      map['unit_name'] = Variable<String>(unitName);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CartItemsTableCompanion toCompanion(bool nullToAbsent) {
    return CartItemsTableCompanion(
      id: Value(id),
      pelangganId: pelangganId == null && nullToAbsent
          ? const Value.absent()
          : Value(pelangganId),
      productJson: Value(productJson),
      productId: Value(productId),
      quantity: Value(quantity),
      negotiatedPrice: negotiatedPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(negotiatedPrice),
      unitId: unitId == null && nullToAbsent
          ? const Value.absent()
          : Value(unitId),
      unitName: unitName == null && nullToAbsent
          ? const Value.absent()
          : Value(unitName),
      createdAt: Value(createdAt),
    );
  }

  factory CartItemsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CartItemsTableData(
      id: serializer.fromJson<int>(json['id']),
      pelangganId: serializer.fromJson<String?>(json['pelangganId']),
      productJson: serializer.fromJson<String>(json['productJson']),
      productId: serializer.fromJson<String>(json['productId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      negotiatedPrice: serializer.fromJson<double?>(json['negotiatedPrice']),
      unitId: serializer.fromJson<String?>(json['unitId']),
      unitName: serializer.fromJson<String?>(json['unitName']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pelangganId': serializer.toJson<String?>(pelangganId),
      'productJson': serializer.toJson<String>(productJson),
      'productId': serializer.toJson<String>(productId),
      'quantity': serializer.toJson<int>(quantity),
      'negotiatedPrice': serializer.toJson<double?>(negotiatedPrice),
      'unitId': serializer.toJson<String?>(unitId),
      'unitName': serializer.toJson<String?>(unitName),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CartItemsTableData copyWith({
    int? id,
    Value<String?> pelangganId = const Value.absent(),
    String? productJson,
    String? productId,
    int? quantity,
    Value<double?> negotiatedPrice = const Value.absent(),
    Value<String?> unitId = const Value.absent(),
    Value<String?> unitName = const Value.absent(),
    int? createdAt,
  }) => CartItemsTableData(
    id: id ?? this.id,
    pelangganId: pelangganId.present ? pelangganId.value : this.pelangganId,
    productJson: productJson ?? this.productJson,
    productId: productId ?? this.productId,
    quantity: quantity ?? this.quantity,
    negotiatedPrice: negotiatedPrice.present
        ? negotiatedPrice.value
        : this.negotiatedPrice,
    unitId: unitId.present ? unitId.value : this.unitId,
    unitName: unitName.present ? unitName.value : this.unitName,
    createdAt: createdAt ?? this.createdAt,
  );
  CartItemsTableData copyWithCompanion(CartItemsTableCompanion data) {
    return CartItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      pelangganId: data.pelangganId.present
          ? data.pelangganId.value
          : this.pelangganId,
      productJson: data.productJson.present
          ? data.productJson.value
          : this.productJson,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      negotiatedPrice: data.negotiatedPrice.present
          ? data.negotiatedPrice.value
          : this.negotiatedPrice,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      unitName: data.unitName.present ? data.unitName.value : this.unitName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CartItemsTableData(')
          ..write('id: $id, ')
          ..write('pelangganId: $pelangganId, ')
          ..write('productJson: $productJson, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('negotiatedPrice: $negotiatedPrice, ')
          ..write('unitId: $unitId, ')
          ..write('unitName: $unitName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pelangganId,
    productJson,
    productId,
    quantity,
    negotiatedPrice,
    unitId,
    unitName,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CartItemsTableData &&
          other.id == this.id &&
          other.pelangganId == this.pelangganId &&
          other.productJson == this.productJson &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.negotiatedPrice == this.negotiatedPrice &&
          other.unitId == this.unitId &&
          other.unitName == this.unitName &&
          other.createdAt == this.createdAt);
}

class CartItemsTableCompanion extends UpdateCompanion<CartItemsTableData> {
  final Value<int> id;
  final Value<String?> pelangganId;
  final Value<String> productJson;
  final Value<String> productId;
  final Value<int> quantity;
  final Value<double?> negotiatedPrice;
  final Value<String?> unitId;
  final Value<String?> unitName;
  final Value<int> createdAt;
  const CartItemsTableCompanion({
    this.id = const Value.absent(),
    this.pelangganId = const Value.absent(),
    this.productJson = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.negotiatedPrice = const Value.absent(),
    this.unitId = const Value.absent(),
    this.unitName = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CartItemsTableCompanion.insert({
    this.id = const Value.absent(),
    this.pelangganId = const Value.absent(),
    required String productJson,
    required String productId,
    required int quantity,
    this.negotiatedPrice = const Value.absent(),
    this.unitId = const Value.absent(),
    this.unitName = const Value.absent(),
    required int createdAt,
  }) : productJson = Value(productJson),
       productId = Value(productId),
       quantity = Value(quantity),
       createdAt = Value(createdAt);
  static Insertable<CartItemsTableData> custom({
    Expression<int>? id,
    Expression<String>? pelangganId,
    Expression<String>? productJson,
    Expression<String>? productId,
    Expression<int>? quantity,
    Expression<double>? negotiatedPrice,
    Expression<String>? unitId,
    Expression<String>? unitName,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pelangganId != null) 'pelanggan_id': pelangganId,
      if (productJson != null) 'product_json': productJson,
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (negotiatedPrice != null) 'negotiated_price': negotiatedPrice,
      if (unitId != null) 'unit_id': unitId,
      if (unitName != null) 'unit_name': unitName,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CartItemsTableCompanion copyWith({
    Value<int>? id,
    Value<String?>? pelangganId,
    Value<String>? productJson,
    Value<String>? productId,
    Value<int>? quantity,
    Value<double?>? negotiatedPrice,
    Value<String?>? unitId,
    Value<String?>? unitName,
    Value<int>? createdAt,
  }) {
    return CartItemsTableCompanion(
      id: id ?? this.id,
      pelangganId: pelangganId ?? this.pelangganId,
      productJson: productJson ?? this.productJson,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      negotiatedPrice: negotiatedPrice ?? this.negotiatedPrice,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pelangganId.present) {
      map['pelanggan_id'] = Variable<String>(pelangganId.value);
    }
    if (productJson.present) {
      map['product_json'] = Variable<String>(productJson.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (negotiatedPrice.present) {
      map['negotiated_price'] = Variable<double>(negotiatedPrice.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (unitName.present) {
      map['unit_name'] = Variable<String>(unitName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CartItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('pelangganId: $pelangganId, ')
          ..write('productJson: $productJson, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('negotiatedPrice: $negotiatedPrice, ')
          ..write('unitId: $unitId, ')
          ..write('unitName: $unitName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PromoCacheTableTable extends PromoCacheTable
    with TableInfo<$PromoCacheTableTable, PromoCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromoCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idPelangganMeta = const VerificationMeta(
    'idPelanggan',
  );
  @override
  late final GeneratedColumn<String> idPelanggan = GeneratedColumn<String>(
    'id_pelanggan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [idPelanggan, data, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'promo_cache_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PromoCacheTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_pelanggan')) {
      context.handle(
        _idPelangganMeta,
        idPelanggan.isAcceptableOrUnknown(
          data['id_pelanggan']!,
          _idPelangganMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idPelangganMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idPelanggan};
  @override
  PromoCacheTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PromoCacheTableData(
      idPelanggan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_pelanggan'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $PromoCacheTableTable createAlias(String alias) {
    return $PromoCacheTableTable(attachedDatabase, alias);
  }
}

class PromoCacheTableData extends DataClass
    implements Insertable<PromoCacheTableData> {
  final String idPelanggan;
  final String data;
  final int syncedAt;
  const PromoCacheTableData({
    required this.idPelanggan,
    required this.data,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_pelanggan'] = Variable<String>(idPelanggan);
    map['data'] = Variable<String>(data);
    map['synced_at'] = Variable<int>(syncedAt);
    return map;
  }

  PromoCacheTableCompanion toCompanion(bool nullToAbsent) {
    return PromoCacheTableCompanion(
      idPelanggan: Value(idPelanggan),
      data: Value(data),
      syncedAt: Value(syncedAt),
    );
  }

  factory PromoCacheTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PromoCacheTableData(
      idPelanggan: serializer.fromJson<String>(json['idPelanggan']),
      data: serializer.fromJson<String>(json['data']),
      syncedAt: serializer.fromJson<int>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idPelanggan': serializer.toJson<String>(idPelanggan),
      'data': serializer.toJson<String>(data),
      'syncedAt': serializer.toJson<int>(syncedAt),
    };
  }

  PromoCacheTableData copyWith({
    String? idPelanggan,
    String? data,
    int? syncedAt,
  }) => PromoCacheTableData(
    idPelanggan: idPelanggan ?? this.idPelanggan,
    data: data ?? this.data,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  PromoCacheTableData copyWithCompanion(PromoCacheTableCompanion data) {
    return PromoCacheTableData(
      idPelanggan: data.idPelanggan.present
          ? data.idPelanggan.value
          : this.idPelanggan,
      data: data.data.present ? data.data.value : this.data,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PromoCacheTableData(')
          ..write('idPelanggan: $idPelanggan, ')
          ..write('data: $data, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(idPelanggan, data, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PromoCacheTableData &&
          other.idPelanggan == this.idPelanggan &&
          other.data == this.data &&
          other.syncedAt == this.syncedAt);
}

class PromoCacheTableCompanion extends UpdateCompanion<PromoCacheTableData> {
  final Value<String> idPelanggan;
  final Value<String> data;
  final Value<int> syncedAt;
  final Value<int> rowid;
  const PromoCacheTableCompanion({
    this.idPelanggan = const Value.absent(),
    this.data = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PromoCacheTableCompanion.insert({
    required String idPelanggan,
    required String data,
    required int syncedAt,
    this.rowid = const Value.absent(),
  }) : idPelanggan = Value(idPelanggan),
       data = Value(data),
       syncedAt = Value(syncedAt);
  static Insertable<PromoCacheTableData> custom({
    Expression<String>? idPelanggan,
    Expression<String>? data,
    Expression<int>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idPelanggan != null) 'id_pelanggan': idPelanggan,
      if (data != null) 'data': data,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PromoCacheTableCompanion copyWith({
    Value<String>? idPelanggan,
    Value<String>? data,
    Value<int>? syncedAt,
    Value<int>? rowid,
  }) {
    return PromoCacheTableCompanion(
      idPelanggan: idPelanggan ?? this.idPelanggan,
      data: data ?? this.data,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idPelanggan.present) {
      map['id_pelanggan'] = Variable<String>(idPelanggan.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromoCacheTableCompanion(')
          ..write('idPelanggan: $idPelanggan, ')
          ..write('data: $data, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitsTableTable extends VisitsTable
    with TableInfo<$VisitsTableTable, VisitsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isLocalMeta = const VerificationMeta(
    'isLocal',
  );
  @override
  late final GeneratedColumn<int> isLocal = GeneratedColumn<int>(
    'is_local',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'schedule_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pelangganIdMeta = const VerificationMeta(
    'pelangganId',
  );
  @override
  late final GeneratedColumn<String> pelangganId = GeneratedColumn<String>(
    'pelanggan_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CHECKED_IN'),
  );
  static const VerificationMeta _latInMeta = const VerificationMeta('latIn');
  @override
  late final GeneratedColumn<double> latIn = GeneratedColumn<double>(
    'lat_in',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longInMeta = const VerificationMeta('longIn');
  @override
  late final GeneratedColumn<double> longIn = GeneratedColumn<double>(
    'long_in',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latOutMeta = const VerificationMeta('latOut');
  @override
  late final GeneratedColumn<double> latOut = GeneratedColumn<double>(
    'lat_out',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longOutMeta = const VerificationMeta(
    'longOut',
  );
  @override
  late final GeneratedColumn<double> longOut = GeneratedColumn<double>(
    'long_out',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waktuCheckInMeta = const VerificationMeta(
    'waktuCheckIn',
  );
  @override
  late final GeneratedColumn<String> waktuCheckIn = GeneratedColumn<String>(
    'waktu_check_in',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waktuCheckOutMeta = const VerificationMeta(
    'waktuCheckOut',
  );
  @override
  late final GeneratedColumn<String> waktuCheckOut = GeneratedColumn<String>(
    'waktu_check_out',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alasanTidakMeta = const VerificationMeta(
    'alasanTidak',
  );
  @override
  late final GeneratedColumn<String> alasanTidak = GeneratedColumn<String>(
    'alasan_tidak',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _catatanMeta = const VerificationMeta(
    'catatan',
  );
  @override
  late final GeneratedColumn<String> catatan = GeneratedColumn<String>(
    'catatan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photosPendingMeta = const VerificationMeta(
    'photosPending',
  );
  @override
  late final GeneratedColumn<int> photosPending = GeneratedColumn<int>(
    'photos_pending',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localPhotoPathsMeta = const VerificationMeta(
    'localPhotoPaths',
  );
  @override
  late final GeneratedColumn<String> localPhotoPaths = GeneratedColumn<String>(
    'local_photo_paths',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isLocal,
    scheduleId,
    pelangganId,
    status,
    latIn,
    longIn,
    latOut,
    longOut,
    waktuCheckIn,
    waktuCheckOut,
    alasanTidak,
    catatan,
    serverId,
    photosPending,
    localPhotoPaths,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visits_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_local')) {
      context.handle(
        _isLocalMeta,
        isLocal.isAcceptableOrUnknown(data['is_local']!, _isLocalMeta),
      );
    }
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    }
    if (data.containsKey('pelanggan_id')) {
      context.handle(
        _pelangganIdMeta,
        pelangganId.isAcceptableOrUnknown(
          data['pelanggan_id']!,
          _pelangganIdMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('lat_in')) {
      context.handle(
        _latInMeta,
        latIn.isAcceptableOrUnknown(data['lat_in']!, _latInMeta),
      );
    }
    if (data.containsKey('long_in')) {
      context.handle(
        _longInMeta,
        longIn.isAcceptableOrUnknown(data['long_in']!, _longInMeta),
      );
    }
    if (data.containsKey('lat_out')) {
      context.handle(
        _latOutMeta,
        latOut.isAcceptableOrUnknown(data['lat_out']!, _latOutMeta),
      );
    }
    if (data.containsKey('long_out')) {
      context.handle(
        _longOutMeta,
        longOut.isAcceptableOrUnknown(data['long_out']!, _longOutMeta),
      );
    }
    if (data.containsKey('waktu_check_in')) {
      context.handle(
        _waktuCheckInMeta,
        waktuCheckIn.isAcceptableOrUnknown(
          data['waktu_check_in']!,
          _waktuCheckInMeta,
        ),
      );
    }
    if (data.containsKey('waktu_check_out')) {
      context.handle(
        _waktuCheckOutMeta,
        waktuCheckOut.isAcceptableOrUnknown(
          data['waktu_check_out']!,
          _waktuCheckOutMeta,
        ),
      );
    }
    if (data.containsKey('alasan_tidak')) {
      context.handle(
        _alasanTidakMeta,
        alasanTidak.isAcceptableOrUnknown(
          data['alasan_tidak']!,
          _alasanTidakMeta,
        ),
      );
    }
    if (data.containsKey('catatan')) {
      context.handle(
        _catatanMeta,
        catatan.isAcceptableOrUnknown(data['catatan']!, _catatanMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('photos_pending')) {
      context.handle(
        _photosPendingMeta,
        photosPending.isAcceptableOrUnknown(
          data['photos_pending']!,
          _photosPendingMeta,
        ),
      );
    }
    if (data.containsKey('local_photo_paths')) {
      context.handle(
        _localPhotoPathsMeta,
        localPhotoPaths.isAcceptableOrUnknown(
          data['local_photo_paths']!,
          _localPhotoPathsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VisitsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_local'],
      )!,
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_id'],
      ),
      pelangganId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pelanggan_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      latIn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat_in'],
      ),
      longIn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}long_in'],
      ),
      latOut: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat_out'],
      ),
      longOut: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}long_out'],
      ),
      waktuCheckIn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}waktu_check_in'],
      ),
      waktuCheckOut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}waktu_check_out'],
      ),
      alasanTidak: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alasan_tidak'],
      ),
      catatan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catatan'],
      ),
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      photosPending: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}photos_pending'],
      )!,
      localPhotoPaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_photo_paths'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VisitsTableTable createAlias(String alias) {
    return $VisitsTableTable(attachedDatabase, alias);
  }
}

class VisitsTableData extends DataClass implements Insertable<VisitsTableData> {
  final String id;
  final int isLocal;
  final String? scheduleId;
  final String? pelangganId;
  final String status;
  final double? latIn;
  final double? longIn;
  final double? latOut;
  final double? longOut;
  final String? waktuCheckIn;
  final String? waktuCheckOut;
  final String? alasanTidak;
  final String? catatan;
  final String? serverId;
  final int photosPending;
  final String? localPhotoPaths;
  final int createdAt;
  final int updatedAt;
  const VisitsTableData({
    required this.id,
    required this.isLocal,
    this.scheduleId,
    this.pelangganId,
    required this.status,
    this.latIn,
    this.longIn,
    this.latOut,
    this.longOut,
    this.waktuCheckIn,
    this.waktuCheckOut,
    this.alasanTidak,
    this.catatan,
    this.serverId,
    required this.photosPending,
    this.localPhotoPaths,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_local'] = Variable<int>(isLocal);
    if (!nullToAbsent || scheduleId != null) {
      map['schedule_id'] = Variable<String>(scheduleId);
    }
    if (!nullToAbsent || pelangganId != null) {
      map['pelanggan_id'] = Variable<String>(pelangganId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || latIn != null) {
      map['lat_in'] = Variable<double>(latIn);
    }
    if (!nullToAbsent || longIn != null) {
      map['long_in'] = Variable<double>(longIn);
    }
    if (!nullToAbsent || latOut != null) {
      map['lat_out'] = Variable<double>(latOut);
    }
    if (!nullToAbsent || longOut != null) {
      map['long_out'] = Variable<double>(longOut);
    }
    if (!nullToAbsent || waktuCheckIn != null) {
      map['waktu_check_in'] = Variable<String>(waktuCheckIn);
    }
    if (!nullToAbsent || waktuCheckOut != null) {
      map['waktu_check_out'] = Variable<String>(waktuCheckOut);
    }
    if (!nullToAbsent || alasanTidak != null) {
      map['alasan_tidak'] = Variable<String>(alasanTidak);
    }
    if (!nullToAbsent || catatan != null) {
      map['catatan'] = Variable<String>(catatan);
    }
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['photos_pending'] = Variable<int>(photosPending);
    if (!nullToAbsent || localPhotoPaths != null) {
      map['local_photo_paths'] = Variable<String>(localPhotoPaths);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  VisitsTableCompanion toCompanion(bool nullToAbsent) {
    return VisitsTableCompanion(
      id: Value(id),
      isLocal: Value(isLocal),
      scheduleId: scheduleId == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduleId),
      pelangganId: pelangganId == null && nullToAbsent
          ? const Value.absent()
          : Value(pelangganId),
      status: Value(status),
      latIn: latIn == null && nullToAbsent
          ? const Value.absent()
          : Value(latIn),
      longIn: longIn == null && nullToAbsent
          ? const Value.absent()
          : Value(longIn),
      latOut: latOut == null && nullToAbsent
          ? const Value.absent()
          : Value(latOut),
      longOut: longOut == null && nullToAbsent
          ? const Value.absent()
          : Value(longOut),
      waktuCheckIn: waktuCheckIn == null && nullToAbsent
          ? const Value.absent()
          : Value(waktuCheckIn),
      waktuCheckOut: waktuCheckOut == null && nullToAbsent
          ? const Value.absent()
          : Value(waktuCheckOut),
      alasanTidak: alasanTidak == null && nullToAbsent
          ? const Value.absent()
          : Value(alasanTidak),
      catatan: catatan == null && nullToAbsent
          ? const Value.absent()
          : Value(catatan),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      photosPending: Value(photosPending),
      localPhotoPaths: localPhotoPaths == null && nullToAbsent
          ? const Value.absent()
          : Value(localPhotoPaths),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VisitsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitsTableData(
      id: serializer.fromJson<String>(json['id']),
      isLocal: serializer.fromJson<int>(json['isLocal']),
      scheduleId: serializer.fromJson<String?>(json['scheduleId']),
      pelangganId: serializer.fromJson<String?>(json['pelangganId']),
      status: serializer.fromJson<String>(json['status']),
      latIn: serializer.fromJson<double?>(json['latIn']),
      longIn: serializer.fromJson<double?>(json['longIn']),
      latOut: serializer.fromJson<double?>(json['latOut']),
      longOut: serializer.fromJson<double?>(json['longOut']),
      waktuCheckIn: serializer.fromJson<String?>(json['waktuCheckIn']),
      waktuCheckOut: serializer.fromJson<String?>(json['waktuCheckOut']),
      alasanTidak: serializer.fromJson<String?>(json['alasanTidak']),
      catatan: serializer.fromJson<String?>(json['catatan']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      photosPending: serializer.fromJson<int>(json['photosPending']),
      localPhotoPaths: serializer.fromJson<String?>(json['localPhotoPaths']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isLocal': serializer.toJson<int>(isLocal),
      'scheduleId': serializer.toJson<String?>(scheduleId),
      'pelangganId': serializer.toJson<String?>(pelangganId),
      'status': serializer.toJson<String>(status),
      'latIn': serializer.toJson<double?>(latIn),
      'longIn': serializer.toJson<double?>(longIn),
      'latOut': serializer.toJson<double?>(latOut),
      'longOut': serializer.toJson<double?>(longOut),
      'waktuCheckIn': serializer.toJson<String?>(waktuCheckIn),
      'waktuCheckOut': serializer.toJson<String?>(waktuCheckOut),
      'alasanTidak': serializer.toJson<String?>(alasanTidak),
      'catatan': serializer.toJson<String?>(catatan),
      'serverId': serializer.toJson<String?>(serverId),
      'photosPending': serializer.toJson<int>(photosPending),
      'localPhotoPaths': serializer.toJson<String?>(localPhotoPaths),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  VisitsTableData copyWith({
    String? id,
    int? isLocal,
    Value<String?> scheduleId = const Value.absent(),
    Value<String?> pelangganId = const Value.absent(),
    String? status,
    Value<double?> latIn = const Value.absent(),
    Value<double?> longIn = const Value.absent(),
    Value<double?> latOut = const Value.absent(),
    Value<double?> longOut = const Value.absent(),
    Value<String?> waktuCheckIn = const Value.absent(),
    Value<String?> waktuCheckOut = const Value.absent(),
    Value<String?> alasanTidak = const Value.absent(),
    Value<String?> catatan = const Value.absent(),
    Value<String?> serverId = const Value.absent(),
    int? photosPending,
    Value<String?> localPhotoPaths = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => VisitsTableData(
    id: id ?? this.id,
    isLocal: isLocal ?? this.isLocal,
    scheduleId: scheduleId.present ? scheduleId.value : this.scheduleId,
    pelangganId: pelangganId.present ? pelangganId.value : this.pelangganId,
    status: status ?? this.status,
    latIn: latIn.present ? latIn.value : this.latIn,
    longIn: longIn.present ? longIn.value : this.longIn,
    latOut: latOut.present ? latOut.value : this.latOut,
    longOut: longOut.present ? longOut.value : this.longOut,
    waktuCheckIn: waktuCheckIn.present ? waktuCheckIn.value : this.waktuCheckIn,
    waktuCheckOut: waktuCheckOut.present
        ? waktuCheckOut.value
        : this.waktuCheckOut,
    alasanTidak: alasanTidak.present ? alasanTidak.value : this.alasanTidak,
    catatan: catatan.present ? catatan.value : this.catatan,
    serverId: serverId.present ? serverId.value : this.serverId,
    photosPending: photosPending ?? this.photosPending,
    localPhotoPaths: localPhotoPaths.present
        ? localPhotoPaths.value
        : this.localPhotoPaths,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VisitsTableData copyWithCompanion(VisitsTableCompanion data) {
    return VisitsTableData(
      id: data.id.present ? data.id.value : this.id,
      isLocal: data.isLocal.present ? data.isLocal.value : this.isLocal,
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      pelangganId: data.pelangganId.present
          ? data.pelangganId.value
          : this.pelangganId,
      status: data.status.present ? data.status.value : this.status,
      latIn: data.latIn.present ? data.latIn.value : this.latIn,
      longIn: data.longIn.present ? data.longIn.value : this.longIn,
      latOut: data.latOut.present ? data.latOut.value : this.latOut,
      longOut: data.longOut.present ? data.longOut.value : this.longOut,
      waktuCheckIn: data.waktuCheckIn.present
          ? data.waktuCheckIn.value
          : this.waktuCheckIn,
      waktuCheckOut: data.waktuCheckOut.present
          ? data.waktuCheckOut.value
          : this.waktuCheckOut,
      alasanTidak: data.alasanTidak.present
          ? data.alasanTidak.value
          : this.alasanTidak,
      catatan: data.catatan.present ? data.catatan.value : this.catatan,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      photosPending: data.photosPending.present
          ? data.photosPending.value
          : this.photosPending,
      localPhotoPaths: data.localPhotoPaths.present
          ? data.localPhotoPaths.value
          : this.localPhotoPaths,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitsTableData(')
          ..write('id: $id, ')
          ..write('isLocal: $isLocal, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('pelangganId: $pelangganId, ')
          ..write('status: $status, ')
          ..write('latIn: $latIn, ')
          ..write('longIn: $longIn, ')
          ..write('latOut: $latOut, ')
          ..write('longOut: $longOut, ')
          ..write('waktuCheckIn: $waktuCheckIn, ')
          ..write('waktuCheckOut: $waktuCheckOut, ')
          ..write('alasanTidak: $alasanTidak, ')
          ..write('catatan: $catatan, ')
          ..write('serverId: $serverId, ')
          ..write('photosPending: $photosPending, ')
          ..write('localPhotoPaths: $localPhotoPaths, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isLocal,
    scheduleId,
    pelangganId,
    status,
    latIn,
    longIn,
    latOut,
    longOut,
    waktuCheckIn,
    waktuCheckOut,
    alasanTidak,
    catatan,
    serverId,
    photosPending,
    localPhotoPaths,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitsTableData &&
          other.id == this.id &&
          other.isLocal == this.isLocal &&
          other.scheduleId == this.scheduleId &&
          other.pelangganId == this.pelangganId &&
          other.status == this.status &&
          other.latIn == this.latIn &&
          other.longIn == this.longIn &&
          other.latOut == this.latOut &&
          other.longOut == this.longOut &&
          other.waktuCheckIn == this.waktuCheckIn &&
          other.waktuCheckOut == this.waktuCheckOut &&
          other.alasanTidak == this.alasanTidak &&
          other.catatan == this.catatan &&
          other.serverId == this.serverId &&
          other.photosPending == this.photosPending &&
          other.localPhotoPaths == this.localPhotoPaths &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VisitsTableCompanion extends UpdateCompanion<VisitsTableData> {
  final Value<String> id;
  final Value<int> isLocal;
  final Value<String?> scheduleId;
  final Value<String?> pelangganId;
  final Value<String> status;
  final Value<double?> latIn;
  final Value<double?> longIn;
  final Value<double?> latOut;
  final Value<double?> longOut;
  final Value<String?> waktuCheckIn;
  final Value<String?> waktuCheckOut;
  final Value<String?> alasanTidak;
  final Value<String?> catatan;
  final Value<String?> serverId;
  final Value<int> photosPending;
  final Value<String?> localPhotoPaths;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const VisitsTableCompanion({
    this.id = const Value.absent(),
    this.isLocal = const Value.absent(),
    this.scheduleId = const Value.absent(),
    this.pelangganId = const Value.absent(),
    this.status = const Value.absent(),
    this.latIn = const Value.absent(),
    this.longIn = const Value.absent(),
    this.latOut = const Value.absent(),
    this.longOut = const Value.absent(),
    this.waktuCheckIn = const Value.absent(),
    this.waktuCheckOut = const Value.absent(),
    this.alasanTidak = const Value.absent(),
    this.catatan = const Value.absent(),
    this.serverId = const Value.absent(),
    this.photosPending = const Value.absent(),
    this.localPhotoPaths = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitsTableCompanion.insert({
    required String id,
    this.isLocal = const Value.absent(),
    this.scheduleId = const Value.absent(),
    this.pelangganId = const Value.absent(),
    this.status = const Value.absent(),
    this.latIn = const Value.absent(),
    this.longIn = const Value.absent(),
    this.latOut = const Value.absent(),
    this.longOut = const Value.absent(),
    this.waktuCheckIn = const Value.absent(),
    this.waktuCheckOut = const Value.absent(),
    this.alasanTidak = const Value.absent(),
    this.catatan = const Value.absent(),
    this.serverId = const Value.absent(),
    this.photosPending = const Value.absent(),
    this.localPhotoPaths = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<VisitsTableData> custom({
    Expression<String>? id,
    Expression<int>? isLocal,
    Expression<String>? scheduleId,
    Expression<String>? pelangganId,
    Expression<String>? status,
    Expression<double>? latIn,
    Expression<double>? longIn,
    Expression<double>? latOut,
    Expression<double>? longOut,
    Expression<String>? waktuCheckIn,
    Expression<String>? waktuCheckOut,
    Expression<String>? alasanTidak,
    Expression<String>? catatan,
    Expression<String>? serverId,
    Expression<int>? photosPending,
    Expression<String>? localPhotoPaths,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isLocal != null) 'is_local': isLocal,
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (pelangganId != null) 'pelanggan_id': pelangganId,
      if (status != null) 'status': status,
      if (latIn != null) 'lat_in': latIn,
      if (longIn != null) 'long_in': longIn,
      if (latOut != null) 'lat_out': latOut,
      if (longOut != null) 'long_out': longOut,
      if (waktuCheckIn != null) 'waktu_check_in': waktuCheckIn,
      if (waktuCheckOut != null) 'waktu_check_out': waktuCheckOut,
      if (alasanTidak != null) 'alasan_tidak': alasanTidak,
      if (catatan != null) 'catatan': catatan,
      if (serverId != null) 'server_id': serverId,
      if (photosPending != null) 'photos_pending': photosPending,
      if (localPhotoPaths != null) 'local_photo_paths': localPhotoPaths,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitsTableCompanion copyWith({
    Value<String>? id,
    Value<int>? isLocal,
    Value<String?>? scheduleId,
    Value<String?>? pelangganId,
    Value<String>? status,
    Value<double?>? latIn,
    Value<double?>? longIn,
    Value<double?>? latOut,
    Value<double?>? longOut,
    Value<String?>? waktuCheckIn,
    Value<String?>? waktuCheckOut,
    Value<String?>? alasanTidak,
    Value<String?>? catatan,
    Value<String?>? serverId,
    Value<int>? photosPending,
    Value<String?>? localPhotoPaths,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return VisitsTableCompanion(
      id: id ?? this.id,
      isLocal: isLocal ?? this.isLocal,
      scheduleId: scheduleId ?? this.scheduleId,
      pelangganId: pelangganId ?? this.pelangganId,
      status: status ?? this.status,
      latIn: latIn ?? this.latIn,
      longIn: longIn ?? this.longIn,
      latOut: latOut ?? this.latOut,
      longOut: longOut ?? this.longOut,
      waktuCheckIn: waktuCheckIn ?? this.waktuCheckIn,
      waktuCheckOut: waktuCheckOut ?? this.waktuCheckOut,
      alasanTidak: alasanTidak ?? this.alasanTidak,
      catatan: catatan ?? this.catatan,
      serverId: serverId ?? this.serverId,
      photosPending: photosPending ?? this.photosPending,
      localPhotoPaths: localPhotoPaths ?? this.localPhotoPaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isLocal.present) {
      map['is_local'] = Variable<int>(isLocal.value);
    }
    if (scheduleId.present) {
      map['schedule_id'] = Variable<String>(scheduleId.value);
    }
    if (pelangganId.present) {
      map['pelanggan_id'] = Variable<String>(pelangganId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (latIn.present) {
      map['lat_in'] = Variable<double>(latIn.value);
    }
    if (longIn.present) {
      map['long_in'] = Variable<double>(longIn.value);
    }
    if (latOut.present) {
      map['lat_out'] = Variable<double>(latOut.value);
    }
    if (longOut.present) {
      map['long_out'] = Variable<double>(longOut.value);
    }
    if (waktuCheckIn.present) {
      map['waktu_check_in'] = Variable<String>(waktuCheckIn.value);
    }
    if (waktuCheckOut.present) {
      map['waktu_check_out'] = Variable<String>(waktuCheckOut.value);
    }
    if (alasanTidak.present) {
      map['alasan_tidak'] = Variable<String>(alasanTidak.value);
    }
    if (catatan.present) {
      map['catatan'] = Variable<String>(catatan.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (photosPending.present) {
      map['photos_pending'] = Variable<int>(photosPending.value);
    }
    if (localPhotoPaths.present) {
      map['local_photo_paths'] = Variable<String>(localPhotoPaths.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitsTableCompanion(')
          ..write('id: $id, ')
          ..write('isLocal: $isLocal, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('pelangganId: $pelangganId, ')
          ..write('status: $status, ')
          ..write('latIn: $latIn, ')
          ..write('longIn: $longIn, ')
          ..write('latOut: $latOut, ')
          ..write('longOut: $longOut, ')
          ..write('waktuCheckIn: $waktuCheckIn, ')
          ..write('waktuCheckOut: $waktuCheckOut, ')
          ..write('alasanTidak: $alasanTidak, ')
          ..write('catatan: $catatan, ')
          ..write('serverId: $serverId, ')
          ..write('photosPending: $photosPending, ')
          ..write('localPhotoPaths: $localPhotoPaths, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrdersTableTable extends OrdersTable
    with TableInfo<$OrdersTableTable, OrdersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isLocalMeta = const VerificationMeta(
    'isLocal',
  );
  @override
  late final GeneratedColumn<int> isLocal = GeneratedColumn<int>(
    'is_local',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _kunjunganIdMeta = const VerificationMeta(
    'kunjunganId',
  );
  @override
  late final GeneratedColumn<String> kunjunganId = GeneratedColumn<String>(
    'kunjungan_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pelangganIdMeta = const VerificationMeta(
    'pelangganId',
  );
  @override
  late final GeneratedColumn<String> pelangganId = GeneratedColumn<String>(
    'pelanggan_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _itemsJsonMeta = const VerificationMeta(
    'itemsJson',
  );
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
    'items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promosJsonMeta = const VerificationMeta(
    'promosJson',
  );
  @override
  late final GeneratedColumn<String> promosJson = GeneratedColumn<String>(
    'promos_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalTagihanMeta = const VerificationMeta(
    'totalTagihan',
  );
  @override
  late final GeneratedColumn<double> totalTagihan = GeneratedColumn<double>(
    'total_tagihan',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientRefMeta = const VerificationMeta(
    'clientRef',
  );
  @override
  late final GeneratedColumn<String> clientRef = GeneratedColumn<String>(
    'client_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tanggalTransaksiMeta = const VerificationMeta(
    'tanggalTransaksi',
  );
  @override
  late final GeneratedColumn<int> tanggalTransaksi = GeneratedColumn<int>(
    'tanggal_transaksi',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noPesananMeta = const VerificationMeta(
    'noPesanan',
  );
  @override
  late final GeneratedColumn<String> noPesanan = GeneratedColumn<String>(
    'no_pesanan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isLocal,
    kunjunganId,
    pelangganId,
    status,
    itemsJson,
    notes,
    promosJson,
    totalTagihan,
    serverId,
    clientRef,
    createdAt,
    updatedAt,
    tanggalTransaksi,
    noPesanan,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrdersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_local')) {
      context.handle(
        _isLocalMeta,
        isLocal.isAcceptableOrUnknown(data['is_local']!, _isLocalMeta),
      );
    }
    if (data.containsKey('kunjungan_id')) {
      context.handle(
        _kunjunganIdMeta,
        kunjunganId.isAcceptableOrUnknown(
          data['kunjungan_id']!,
          _kunjunganIdMeta,
        ),
      );
    }
    if (data.containsKey('pelanggan_id')) {
      context.handle(
        _pelangganIdMeta,
        pelangganId.isAcceptableOrUnknown(
          data['pelanggan_id']!,
          _pelangganIdMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_itemsJsonMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('promos_json')) {
      context.handle(
        _promosJsonMeta,
        promosJson.isAcceptableOrUnknown(data['promos_json']!, _promosJsonMeta),
      );
    }
    if (data.containsKey('total_tagihan')) {
      context.handle(
        _totalTagihanMeta,
        totalTagihan.isAcceptableOrUnknown(
          data['total_tagihan']!,
          _totalTagihanMeta,
        ),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('client_ref')) {
      context.handle(
        _clientRefMeta,
        clientRef.isAcceptableOrUnknown(data['client_ref']!, _clientRefMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('tanggal_transaksi')) {
      context.handle(
        _tanggalTransaksiMeta,
        tanggalTransaksi.isAcceptableOrUnknown(
          data['tanggal_transaksi']!,
          _tanggalTransaksiMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tanggalTransaksiMeta);
    }
    if (data.containsKey('no_pesanan')) {
      context.handle(
        _noPesananMeta,
        noPesanan.isAcceptableOrUnknown(data['no_pesanan']!, _noPesananMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrdersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrdersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_local'],
      )!,
      kunjunganId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kunjungan_id'],
      ),
      pelangganId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pelanggan_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      itemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      promosJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}promos_json'],
      ),
      totalTagihan: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_tagihan'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      clientRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_ref'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      tanggalTransaksi: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tanggal_transaksi'],
      )!,
      noPesanan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}no_pesanan'],
      ),
    );
  }

  @override
  $OrdersTableTable createAlias(String alias) {
    return $OrdersTableTable(attachedDatabase, alias);
  }
}

class OrdersTableData extends DataClass implements Insertable<OrdersTableData> {
  final String id;
  final int isLocal;
  final String? kunjunganId;
  final String? pelangganId;
  final String status;
  final String itemsJson;
  final String? notes;
  final String? promosJson;
  final double totalTagihan;
  final String? serverId;
  final String? clientRef;
  final int createdAt;
  final int updatedAt;
  final int tanggalTransaksi;
  final String? noPesanan;
  const OrdersTableData({
    required this.id,
    required this.isLocal,
    this.kunjunganId,
    this.pelangganId,
    required this.status,
    required this.itemsJson,
    this.notes,
    this.promosJson,
    required this.totalTagihan,
    this.serverId,
    this.clientRef,
    required this.createdAt,
    required this.updatedAt,
    required this.tanggalTransaksi,
    this.noPesanan,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_local'] = Variable<int>(isLocal);
    if (!nullToAbsent || kunjunganId != null) {
      map['kunjungan_id'] = Variable<String>(kunjunganId);
    }
    if (!nullToAbsent || pelangganId != null) {
      map['pelanggan_id'] = Variable<String>(pelangganId);
    }
    map['status'] = Variable<String>(status);
    map['items_json'] = Variable<String>(itemsJson);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || promosJson != null) {
      map['promos_json'] = Variable<String>(promosJson);
    }
    map['total_tagihan'] = Variable<double>(totalTagihan);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    if (!nullToAbsent || clientRef != null) {
      map['client_ref'] = Variable<String>(clientRef);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['tanggal_transaksi'] = Variable<int>(tanggalTransaksi);
    if (!nullToAbsent || noPesanan != null) {
      map['no_pesanan'] = Variable<String>(noPesanan);
    }
    return map;
  }

  OrdersTableCompanion toCompanion(bool nullToAbsent) {
    return OrdersTableCompanion(
      id: Value(id),
      isLocal: Value(isLocal),
      kunjunganId: kunjunganId == null && nullToAbsent
          ? const Value.absent()
          : Value(kunjunganId),
      pelangganId: pelangganId == null && nullToAbsent
          ? const Value.absent()
          : Value(pelangganId),
      status: Value(status),
      itemsJson: Value(itemsJson),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      promosJson: promosJson == null && nullToAbsent
          ? const Value.absent()
          : Value(promosJson),
      totalTagihan: Value(totalTagihan),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      clientRef: clientRef == null && nullToAbsent
          ? const Value.absent()
          : Value(clientRef),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      tanggalTransaksi: Value(tanggalTransaksi),
      noPesanan: noPesanan == null && nullToAbsent
          ? const Value.absent()
          : Value(noPesanan),
    );
  }

  factory OrdersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrdersTableData(
      id: serializer.fromJson<String>(json['id']),
      isLocal: serializer.fromJson<int>(json['isLocal']),
      kunjunganId: serializer.fromJson<String?>(json['kunjunganId']),
      pelangganId: serializer.fromJson<String?>(json['pelangganId']),
      status: serializer.fromJson<String>(json['status']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
      notes: serializer.fromJson<String?>(json['notes']),
      promosJson: serializer.fromJson<String?>(json['promosJson']),
      totalTagihan: serializer.fromJson<double>(json['totalTagihan']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      clientRef: serializer.fromJson<String?>(json['clientRef']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      tanggalTransaksi: serializer.fromJson<int>(json['tanggalTransaksi']),
      noPesanan: serializer.fromJson<String?>(json['noPesanan']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isLocal': serializer.toJson<int>(isLocal),
      'kunjunganId': serializer.toJson<String?>(kunjunganId),
      'pelangganId': serializer.toJson<String?>(pelangganId),
      'status': serializer.toJson<String>(status),
      'itemsJson': serializer.toJson<String>(itemsJson),
      'notes': serializer.toJson<String?>(notes),
      'promosJson': serializer.toJson<String?>(promosJson),
      'totalTagihan': serializer.toJson<double>(totalTagihan),
      'serverId': serializer.toJson<String?>(serverId),
      'clientRef': serializer.toJson<String?>(clientRef),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'tanggalTransaksi': serializer.toJson<int>(tanggalTransaksi),
      'noPesanan': serializer.toJson<String?>(noPesanan),
    };
  }

  OrdersTableData copyWith({
    String? id,
    int? isLocal,
    Value<String?> kunjunganId = const Value.absent(),
    Value<String?> pelangganId = const Value.absent(),
    String? status,
    String? itemsJson,
    Value<String?> notes = const Value.absent(),
    Value<String?> promosJson = const Value.absent(),
    double? totalTagihan,
    Value<String?> serverId = const Value.absent(),
    Value<String?> clientRef = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    int? tanggalTransaksi,
    Value<String?> noPesanan = const Value.absent(),
  }) => OrdersTableData(
    id: id ?? this.id,
    isLocal: isLocal ?? this.isLocal,
    kunjunganId: kunjunganId.present ? kunjunganId.value : this.kunjunganId,
    pelangganId: pelangganId.present ? pelangganId.value : this.pelangganId,
    status: status ?? this.status,
    itemsJson: itemsJson ?? this.itemsJson,
    notes: notes.present ? notes.value : this.notes,
    promosJson: promosJson.present ? promosJson.value : this.promosJson,
    totalTagihan: totalTagihan ?? this.totalTagihan,
    serverId: serverId.present ? serverId.value : this.serverId,
    clientRef: clientRef.present ? clientRef.value : this.clientRef,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    tanggalTransaksi: tanggalTransaksi ?? this.tanggalTransaksi,
    noPesanan: noPesanan.present ? noPesanan.value : this.noPesanan,
  );
  OrdersTableData copyWithCompanion(OrdersTableCompanion data) {
    return OrdersTableData(
      id: data.id.present ? data.id.value : this.id,
      isLocal: data.isLocal.present ? data.isLocal.value : this.isLocal,
      kunjunganId: data.kunjunganId.present
          ? data.kunjunganId.value
          : this.kunjunganId,
      pelangganId: data.pelangganId.present
          ? data.pelangganId.value
          : this.pelangganId,
      status: data.status.present ? data.status.value : this.status,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      notes: data.notes.present ? data.notes.value : this.notes,
      promosJson: data.promosJson.present
          ? data.promosJson.value
          : this.promosJson,
      totalTagihan: data.totalTagihan.present
          ? data.totalTagihan.value
          : this.totalTagihan,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      clientRef: data.clientRef.present ? data.clientRef.value : this.clientRef,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      tanggalTransaksi: data.tanggalTransaksi.present
          ? data.tanggalTransaksi.value
          : this.tanggalTransaksi,
      noPesanan: data.noPesanan.present ? data.noPesanan.value : this.noPesanan,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrdersTableData(')
          ..write('id: $id, ')
          ..write('isLocal: $isLocal, ')
          ..write('kunjunganId: $kunjunganId, ')
          ..write('pelangganId: $pelangganId, ')
          ..write('status: $status, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('notes: $notes, ')
          ..write('promosJson: $promosJson, ')
          ..write('totalTagihan: $totalTagihan, ')
          ..write('serverId: $serverId, ')
          ..write('clientRef: $clientRef, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tanggalTransaksi: $tanggalTransaksi, ')
          ..write('noPesanan: $noPesanan')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isLocal,
    kunjunganId,
    pelangganId,
    status,
    itemsJson,
    notes,
    promosJson,
    totalTagihan,
    serverId,
    clientRef,
    createdAt,
    updatedAt,
    tanggalTransaksi,
    noPesanan,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrdersTableData &&
          other.id == this.id &&
          other.isLocal == this.isLocal &&
          other.kunjunganId == this.kunjunganId &&
          other.pelangganId == this.pelangganId &&
          other.status == this.status &&
          other.itemsJson == this.itemsJson &&
          other.notes == this.notes &&
          other.promosJson == this.promosJson &&
          other.totalTagihan == this.totalTagihan &&
          other.serverId == this.serverId &&
          other.clientRef == this.clientRef &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.tanggalTransaksi == this.tanggalTransaksi &&
          other.noPesanan == this.noPesanan);
}

class OrdersTableCompanion extends UpdateCompanion<OrdersTableData> {
  final Value<String> id;
  final Value<int> isLocal;
  final Value<String?> kunjunganId;
  final Value<String?> pelangganId;
  final Value<String> status;
  final Value<String> itemsJson;
  final Value<String?> notes;
  final Value<String?> promosJson;
  final Value<double> totalTagihan;
  final Value<String?> serverId;
  final Value<String?> clientRef;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> tanggalTransaksi;
  final Value<String?> noPesanan;
  final Value<int> rowid;
  const OrdersTableCompanion({
    this.id = const Value.absent(),
    this.isLocal = const Value.absent(),
    this.kunjunganId = const Value.absent(),
    this.pelangganId = const Value.absent(),
    this.status = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.promosJson = const Value.absent(),
    this.totalTagihan = const Value.absent(),
    this.serverId = const Value.absent(),
    this.clientRef = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.tanggalTransaksi = const Value.absent(),
    this.noPesanan = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersTableCompanion.insert({
    required String id,
    this.isLocal = const Value.absent(),
    this.kunjunganId = const Value.absent(),
    this.pelangganId = const Value.absent(),
    this.status = const Value.absent(),
    required String itemsJson,
    this.notes = const Value.absent(),
    this.promosJson = const Value.absent(),
    this.totalTagihan = const Value.absent(),
    this.serverId = const Value.absent(),
    this.clientRef = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    required int tanggalTransaksi,
    this.noPesanan = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemsJson = Value(itemsJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       tanggalTransaksi = Value(tanggalTransaksi);
  static Insertable<OrdersTableData> custom({
    Expression<String>? id,
    Expression<int>? isLocal,
    Expression<String>? kunjunganId,
    Expression<String>? pelangganId,
    Expression<String>? status,
    Expression<String>? itemsJson,
    Expression<String>? notes,
    Expression<String>? promosJson,
    Expression<double>? totalTagihan,
    Expression<String>? serverId,
    Expression<String>? clientRef,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? tanggalTransaksi,
    Expression<String>? noPesanan,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isLocal != null) 'is_local': isLocal,
      if (kunjunganId != null) 'kunjungan_id': kunjunganId,
      if (pelangganId != null) 'pelanggan_id': pelangganId,
      if (status != null) 'status': status,
      if (itemsJson != null) 'items_json': itemsJson,
      if (notes != null) 'notes': notes,
      if (promosJson != null) 'promos_json': promosJson,
      if (totalTagihan != null) 'total_tagihan': totalTagihan,
      if (serverId != null) 'server_id': serverId,
      if (clientRef != null) 'client_ref': clientRef,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (tanggalTransaksi != null) 'tanggal_transaksi': tanggalTransaksi,
      if (noPesanan != null) 'no_pesanan': noPesanan,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersTableCompanion copyWith({
    Value<String>? id,
    Value<int>? isLocal,
    Value<String?>? kunjunganId,
    Value<String?>? pelangganId,
    Value<String>? status,
    Value<String>? itemsJson,
    Value<String?>? notes,
    Value<String?>? promosJson,
    Value<double>? totalTagihan,
    Value<String?>? serverId,
    Value<String?>? clientRef,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? tanggalTransaksi,
    Value<String?>? noPesanan,
    Value<int>? rowid,
  }) {
    return OrdersTableCompanion(
      id: id ?? this.id,
      isLocal: isLocal ?? this.isLocal,
      kunjunganId: kunjunganId ?? this.kunjunganId,
      pelangganId: pelangganId ?? this.pelangganId,
      status: status ?? this.status,
      itemsJson: itemsJson ?? this.itemsJson,
      notes: notes ?? this.notes,
      promosJson: promosJson ?? this.promosJson,
      totalTagihan: totalTagihan ?? this.totalTagihan,
      serverId: serverId ?? this.serverId,
      clientRef: clientRef ?? this.clientRef,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tanggalTransaksi: tanggalTransaksi ?? this.tanggalTransaksi,
      noPesanan: noPesanan ?? this.noPesanan,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isLocal.present) {
      map['is_local'] = Variable<int>(isLocal.value);
    }
    if (kunjunganId.present) {
      map['kunjungan_id'] = Variable<String>(kunjunganId.value);
    }
    if (pelangganId.present) {
      map['pelanggan_id'] = Variable<String>(pelangganId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (promosJson.present) {
      map['promos_json'] = Variable<String>(promosJson.value);
    }
    if (totalTagihan.present) {
      map['total_tagihan'] = Variable<double>(totalTagihan.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (clientRef.present) {
      map['client_ref'] = Variable<String>(clientRef.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (tanggalTransaksi.present) {
      map['tanggal_transaksi'] = Variable<int>(tanggalTransaksi.value);
    }
    if (noPesanan.present) {
      map['no_pesanan'] = Variable<String>(noPesanan.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersTableCompanion(')
          ..write('id: $id, ')
          ..write('isLocal: $isLocal, ')
          ..write('kunjunganId: $kunjunganId, ')
          ..write('pelangganId: $pelangganId, ')
          ..write('status: $status, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('notes: $notes, ')
          ..write('promosJson: $promosJson, ')
          ..write('totalTagihan: $totalTagihan, ')
          ..write('serverId: $serverId, ')
          ..write('clientRef: $clientRef, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tanggalTransaksi: $tanggalTransaksi, ')
          ..write('noPesanan: $noPesanan, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomersTableTable extends CustomersTable
    with TableInfo<$CustomersTableTable, CustomersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isLocalMeta = const VerificationMeta(
    'isLocal',
  );
  @override
  late final GeneratedColumn<int> isLocal = GeneratedColumn<int>(
    'is_local',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientRefMeta = const VerificationMeta(
    'clientRef',
  );
  @override
  late final GeneratedColumn<String> clientRef = GeneratedColumn<String>(
    'client_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kodePelangganMeta = const VerificationMeta(
    'kodePelanggan',
  );
  @override
  late final GeneratedColumn<String> kodePelanggan = GeneratedColumn<String>(
    'kode_pelanggan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _namaTokoMeta = const VerificationMeta(
    'namaToko',
  );
  @override
  late final GeneratedColumn<String> namaToko = GeneratedColumn<String>(
    'nama_toko',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _namaPemilikMeta = const VerificationMeta(
    'namaPemilik',
  );
  @override
  late final GeneratedColumn<String> namaPemilik = GeneratedColumn<String>(
    'nama_pemilik',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noHpPribadiMeta = const VerificationMeta(
    'noHpPribadi',
  );
  @override
  late final GeneratedColumn<String> noHpPribadi = GeneratedColumn<String>(
    'no_hp_pribadi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alamatUsahaMeta = const VerificationMeta(
    'alamatUsaha',
  );
  @override
  late final GeneratedColumn<String> alamatUsaha = GeneratedColumn<String>(
    'alamat_usaha',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fotoTokoPathMeta = const VerificationMeta(
    'fotoTokoPath',
  );
  @override
  late final GeneratedColumn<String> fotoTokoPath = GeneratedColumn<String>(
    'foto_toko_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fotoKtpPathMeta = const VerificationMeta(
    'fotoKtpPath',
  );
  @override
  late final GeneratedColumn<String> fotoKtpPath = GeneratedColumn<String>(
    'foto_ktp_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noKtpPemilikMeta = const VerificationMeta(
    'noKtpPemilik',
  );
  @override
  late final GeneratedColumn<String> noKtpPemilik = GeneratedColumn<String>(
    'no_ktp_pemilik',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sistemPembayaranMeta = const VerificationMeta(
    'sistemPembayaran',
  );
  @override
  late final GeneratedColumn<String> sistemPembayaran = GeneratedColumn<String>(
    'sistem_pembayaran',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caraPembayaranMeta = const VerificationMeta(
    'caraPembayaran',
  );
  @override
  late final GeneratedColumn<String> caraPembayaran = GeneratedColumn<String>(
    'cara_pembayaran',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _namaBankMeta = const VerificationMeta(
    'namaBank',
  );
  @override
  late final GeneratedColumn<String> namaBank = GeneratedColumn<String>(
    'nama_bank',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cabangBankMeta = const VerificationMeta(
    'cabangBank',
  );
  @override
  late final GeneratedColumn<String> cabangBank = GeneratedColumn<String>(
    'cabang_bank',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noRekeningMeta = const VerificationMeta(
    'noRekening',
  );
  @override
  late final GeneratedColumn<String> noRekening = GeneratedColumn<String>(
    'no_rekening',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atasNamaRekeningMeta = const VerificationMeta(
    'atasNamaRekening',
  );
  @override
  late final GeneratedColumn<String> atasNamaRekening = GeneratedColumn<String>(
    'atas_nama_rekening',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topHariMeta = const VerificationMeta(
    'topHari',
  );
  @override
  late final GeneratedColumn<int> topHari = GeneratedColumn<int>(
    'top_hari',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _limitKreditAwalMeta = const VerificationMeta(
    'limitKreditAwal',
  );
  @override
  late final GeneratedColumn<double> limitKreditAwal = GeneratedColumn<double>(
    'limit_kredit_awal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kotaUsahaMeta = const VerificationMeta(
    'kotaUsaha',
  );
  @override
  late final GeneratedColumn<String> kotaUsaha = GeneratedColumn<String>(
    'kota_usaha',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kecamatanUsahaMeta = const VerificationMeta(
    'kecamatanUsaha',
  );
  @override
  late final GeneratedColumn<String> kecamatanUsaha = GeneratedColumn<String>(
    'kecamatan_usaha',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _provinsiUsahaMeta = const VerificationMeta(
    'provinsiUsaha',
  );
  @override
  late final GeneratedColumn<String> provinsiUsaha = GeneratedColumn<String>(
    'provinsi_usaha',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByIdMeta = const VerificationMeta(
    'createdById',
  );
  @override
  late final GeneratedColumn<String> createdById = GeneratedColumn<String>(
    'created_by_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isLocal,
    serverId,
    clientRef,
    kodePelanggan,
    namaToko,
    namaPemilik,
    noHpPribadi,
    alamatUsaha,
    latitude,
    longitude,
    status,
    fotoTokoPath,
    fotoKtpPath,
    noKtpPemilik,
    sistemPembayaran,
    caraPembayaran,
    namaBank,
    cabangBank,
    noRekening,
    atasNamaRekening,
    topHari,
    limitKreditAwal,
    kotaUsaha,
    kecamatanUsaha,
    provinsiUsaha,
    dataJson,
    createdById,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_local')) {
      context.handle(
        _isLocalMeta,
        isLocal.isAcceptableOrUnknown(data['is_local']!, _isLocalMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('client_ref')) {
      context.handle(
        _clientRefMeta,
        clientRef.isAcceptableOrUnknown(data['client_ref']!, _clientRefMeta),
      );
    }
    if (data.containsKey('kode_pelanggan')) {
      context.handle(
        _kodePelangganMeta,
        kodePelanggan.isAcceptableOrUnknown(
          data['kode_pelanggan']!,
          _kodePelangganMeta,
        ),
      );
    }
    if (data.containsKey('nama_toko')) {
      context.handle(
        _namaTokoMeta,
        namaToko.isAcceptableOrUnknown(data['nama_toko']!, _namaTokoMeta),
      );
    }
    if (data.containsKey('nama_pemilik')) {
      context.handle(
        _namaPemilikMeta,
        namaPemilik.isAcceptableOrUnknown(
          data['nama_pemilik']!,
          _namaPemilikMeta,
        ),
      );
    }
    if (data.containsKey('no_hp_pribadi')) {
      context.handle(
        _noHpPribadiMeta,
        noHpPribadi.isAcceptableOrUnknown(
          data['no_hp_pribadi']!,
          _noHpPribadiMeta,
        ),
      );
    }
    if (data.containsKey('alamat_usaha')) {
      context.handle(
        _alamatUsahaMeta,
        alamatUsaha.isAcceptableOrUnknown(
          data['alamat_usaha']!,
          _alamatUsahaMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('foto_toko_path')) {
      context.handle(
        _fotoTokoPathMeta,
        fotoTokoPath.isAcceptableOrUnknown(
          data['foto_toko_path']!,
          _fotoTokoPathMeta,
        ),
      );
    }
    if (data.containsKey('foto_ktp_path')) {
      context.handle(
        _fotoKtpPathMeta,
        fotoKtpPath.isAcceptableOrUnknown(
          data['foto_ktp_path']!,
          _fotoKtpPathMeta,
        ),
      );
    }
    if (data.containsKey('no_ktp_pemilik')) {
      context.handle(
        _noKtpPemilikMeta,
        noKtpPemilik.isAcceptableOrUnknown(
          data['no_ktp_pemilik']!,
          _noKtpPemilikMeta,
        ),
      );
    }
    if (data.containsKey('sistem_pembayaran')) {
      context.handle(
        _sistemPembayaranMeta,
        sistemPembayaran.isAcceptableOrUnknown(
          data['sistem_pembayaran']!,
          _sistemPembayaranMeta,
        ),
      );
    }
    if (data.containsKey('cara_pembayaran')) {
      context.handle(
        _caraPembayaranMeta,
        caraPembayaran.isAcceptableOrUnknown(
          data['cara_pembayaran']!,
          _caraPembayaranMeta,
        ),
      );
    }
    if (data.containsKey('nama_bank')) {
      context.handle(
        _namaBankMeta,
        namaBank.isAcceptableOrUnknown(data['nama_bank']!, _namaBankMeta),
      );
    }
    if (data.containsKey('cabang_bank')) {
      context.handle(
        _cabangBankMeta,
        cabangBank.isAcceptableOrUnknown(data['cabang_bank']!, _cabangBankMeta),
      );
    }
    if (data.containsKey('no_rekening')) {
      context.handle(
        _noRekeningMeta,
        noRekening.isAcceptableOrUnknown(data['no_rekening']!, _noRekeningMeta),
      );
    }
    if (data.containsKey('atas_nama_rekening')) {
      context.handle(
        _atasNamaRekeningMeta,
        atasNamaRekening.isAcceptableOrUnknown(
          data['atas_nama_rekening']!,
          _atasNamaRekeningMeta,
        ),
      );
    }
    if (data.containsKey('top_hari')) {
      context.handle(
        _topHariMeta,
        topHari.isAcceptableOrUnknown(data['top_hari']!, _topHariMeta),
      );
    }
    if (data.containsKey('limit_kredit_awal')) {
      context.handle(
        _limitKreditAwalMeta,
        limitKreditAwal.isAcceptableOrUnknown(
          data['limit_kredit_awal']!,
          _limitKreditAwalMeta,
        ),
      );
    }
    if (data.containsKey('kota_usaha')) {
      context.handle(
        _kotaUsahaMeta,
        kotaUsaha.isAcceptableOrUnknown(data['kota_usaha']!, _kotaUsahaMeta),
      );
    }
    if (data.containsKey('kecamatan_usaha')) {
      context.handle(
        _kecamatanUsahaMeta,
        kecamatanUsaha.isAcceptableOrUnknown(
          data['kecamatan_usaha']!,
          _kecamatanUsahaMeta,
        ),
      );
    }
    if (data.containsKey('provinsi_usaha')) {
      context.handle(
        _provinsiUsahaMeta,
        provinsiUsaha.isAcceptableOrUnknown(
          data['provinsi_usaha']!,
          _provinsiUsahaMeta,
        ),
      );
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    }
    if (data.containsKey('created_by_id')) {
      context.handle(
        _createdByIdMeta,
        createdById.isAcceptableOrUnknown(
          data['created_by_id']!,
          _createdByIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_local'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      clientRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_ref'],
      ),
      kodePelanggan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kode_pelanggan'],
      ),
      namaToko: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama_toko'],
      ),
      namaPemilik: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama_pemilik'],
      ),
      noHpPribadi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}no_hp_pribadi'],
      ),
      alamatUsaha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alamat_usaha'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      fotoTokoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foto_toko_path'],
      ),
      fotoKtpPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foto_ktp_path'],
      ),
      noKtpPemilik: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}no_ktp_pemilik'],
      ),
      sistemPembayaran: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sistem_pembayaran'],
      ),
      caraPembayaran: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cara_pembayaran'],
      ),
      namaBank: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama_bank'],
      ),
      cabangBank: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cabang_bank'],
      ),
      noRekening: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}no_rekening'],
      ),
      atasNamaRekening: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}atas_nama_rekening'],
      ),
      topHari: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}top_hari'],
      ),
      limitKreditAwal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}limit_kredit_awal'],
      ),
      kotaUsaha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kota_usaha'],
      ),
      kecamatanUsaha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kecamatan_usaha'],
      ),
      provinsiUsaha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provinsi_usaha'],
      ),
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      ),
      createdById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CustomersTableTable createAlias(String alias) {
    return $CustomersTableTable(attachedDatabase, alias);
  }
}

class CustomersTableData extends DataClass
    implements Insertable<CustomersTableData> {
  final String id;
  final int isLocal;
  final String? serverId;
  final String? clientRef;
  final String? kodePelanggan;
  final String? namaToko;
  final String? namaPemilik;
  final String? noHpPribadi;
  final String? alamatUsaha;
  final double? latitude;
  final double? longitude;
  final String? status;
  final String? fotoTokoPath;
  final String? fotoKtpPath;
  final String? noKtpPemilik;
  final String? sistemPembayaran;
  final String? caraPembayaran;
  final String? namaBank;
  final String? cabangBank;
  final String? noRekening;
  final String? atasNamaRekening;
  final int? topHari;
  final double? limitKreditAwal;
  final String? kotaUsaha;
  final String? kecamatanUsaha;
  final String? provinsiUsaha;
  final String? dataJson;
  final String? createdById;
  final int createdAt;
  final int updatedAt;
  const CustomersTableData({
    required this.id,
    required this.isLocal,
    this.serverId,
    this.clientRef,
    this.kodePelanggan,
    this.namaToko,
    this.namaPemilik,
    this.noHpPribadi,
    this.alamatUsaha,
    this.latitude,
    this.longitude,
    this.status,
    this.fotoTokoPath,
    this.fotoKtpPath,
    this.noKtpPemilik,
    this.sistemPembayaran,
    this.caraPembayaran,
    this.namaBank,
    this.cabangBank,
    this.noRekening,
    this.atasNamaRekening,
    this.topHari,
    this.limitKreditAwal,
    this.kotaUsaha,
    this.kecamatanUsaha,
    this.provinsiUsaha,
    this.dataJson,
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_local'] = Variable<int>(isLocal);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    if (!nullToAbsent || clientRef != null) {
      map['client_ref'] = Variable<String>(clientRef);
    }
    if (!nullToAbsent || kodePelanggan != null) {
      map['kode_pelanggan'] = Variable<String>(kodePelanggan);
    }
    if (!nullToAbsent || namaToko != null) {
      map['nama_toko'] = Variable<String>(namaToko);
    }
    if (!nullToAbsent || namaPemilik != null) {
      map['nama_pemilik'] = Variable<String>(namaPemilik);
    }
    if (!nullToAbsent || noHpPribadi != null) {
      map['no_hp_pribadi'] = Variable<String>(noHpPribadi);
    }
    if (!nullToAbsent || alamatUsaha != null) {
      map['alamat_usaha'] = Variable<String>(alamatUsaha);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || fotoTokoPath != null) {
      map['foto_toko_path'] = Variable<String>(fotoTokoPath);
    }
    if (!nullToAbsent || fotoKtpPath != null) {
      map['foto_ktp_path'] = Variable<String>(fotoKtpPath);
    }
    if (!nullToAbsent || noKtpPemilik != null) {
      map['no_ktp_pemilik'] = Variable<String>(noKtpPemilik);
    }
    if (!nullToAbsent || sistemPembayaran != null) {
      map['sistem_pembayaran'] = Variable<String>(sistemPembayaran);
    }
    if (!nullToAbsent || caraPembayaran != null) {
      map['cara_pembayaran'] = Variable<String>(caraPembayaran);
    }
    if (!nullToAbsent || namaBank != null) {
      map['nama_bank'] = Variable<String>(namaBank);
    }
    if (!nullToAbsent || cabangBank != null) {
      map['cabang_bank'] = Variable<String>(cabangBank);
    }
    if (!nullToAbsent || noRekening != null) {
      map['no_rekening'] = Variable<String>(noRekening);
    }
    if (!nullToAbsent || atasNamaRekening != null) {
      map['atas_nama_rekening'] = Variable<String>(atasNamaRekening);
    }
    if (!nullToAbsent || topHari != null) {
      map['top_hari'] = Variable<int>(topHari);
    }
    if (!nullToAbsent || limitKreditAwal != null) {
      map['limit_kredit_awal'] = Variable<double>(limitKreditAwal);
    }
    if (!nullToAbsent || kotaUsaha != null) {
      map['kota_usaha'] = Variable<String>(kotaUsaha);
    }
    if (!nullToAbsent || kecamatanUsaha != null) {
      map['kecamatan_usaha'] = Variable<String>(kecamatanUsaha);
    }
    if (!nullToAbsent || provinsiUsaha != null) {
      map['provinsi_usaha'] = Variable<String>(provinsiUsaha);
    }
    if (!nullToAbsent || dataJson != null) {
      map['data_json'] = Variable<String>(dataJson);
    }
    if (!nullToAbsent || createdById != null) {
      map['created_by_id'] = Variable<String>(createdById);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CustomersTableCompanion toCompanion(bool nullToAbsent) {
    return CustomersTableCompanion(
      id: Value(id),
      isLocal: Value(isLocal),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      clientRef: clientRef == null && nullToAbsent
          ? const Value.absent()
          : Value(clientRef),
      kodePelanggan: kodePelanggan == null && nullToAbsent
          ? const Value.absent()
          : Value(kodePelanggan),
      namaToko: namaToko == null && nullToAbsent
          ? const Value.absent()
          : Value(namaToko),
      namaPemilik: namaPemilik == null && nullToAbsent
          ? const Value.absent()
          : Value(namaPemilik),
      noHpPribadi: noHpPribadi == null && nullToAbsent
          ? const Value.absent()
          : Value(noHpPribadi),
      alamatUsaha: alamatUsaha == null && nullToAbsent
          ? const Value.absent()
          : Value(alamatUsaha),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      fotoTokoPath: fotoTokoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoTokoPath),
      fotoKtpPath: fotoKtpPath == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoKtpPath),
      noKtpPemilik: noKtpPemilik == null && nullToAbsent
          ? const Value.absent()
          : Value(noKtpPemilik),
      sistemPembayaran: sistemPembayaran == null && nullToAbsent
          ? const Value.absent()
          : Value(sistemPembayaran),
      caraPembayaran: caraPembayaran == null && nullToAbsent
          ? const Value.absent()
          : Value(caraPembayaran),
      namaBank: namaBank == null && nullToAbsent
          ? const Value.absent()
          : Value(namaBank),
      cabangBank: cabangBank == null && nullToAbsent
          ? const Value.absent()
          : Value(cabangBank),
      noRekening: noRekening == null && nullToAbsent
          ? const Value.absent()
          : Value(noRekening),
      atasNamaRekening: atasNamaRekening == null && nullToAbsent
          ? const Value.absent()
          : Value(atasNamaRekening),
      topHari: topHari == null && nullToAbsent
          ? const Value.absent()
          : Value(topHari),
      limitKreditAwal: limitKreditAwal == null && nullToAbsent
          ? const Value.absent()
          : Value(limitKreditAwal),
      kotaUsaha: kotaUsaha == null && nullToAbsent
          ? const Value.absent()
          : Value(kotaUsaha),
      kecamatanUsaha: kecamatanUsaha == null && nullToAbsent
          ? const Value.absent()
          : Value(kecamatanUsaha),
      provinsiUsaha: provinsiUsaha == null && nullToAbsent
          ? const Value.absent()
          : Value(provinsiUsaha),
      dataJson: dataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(dataJson),
      createdById: createdById == null && nullToAbsent
          ? const Value.absent()
          : Value(createdById),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomersTableData(
      id: serializer.fromJson<String>(json['id']),
      isLocal: serializer.fromJson<int>(json['isLocal']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      clientRef: serializer.fromJson<String?>(json['clientRef']),
      kodePelanggan: serializer.fromJson<String?>(json['kodePelanggan']),
      namaToko: serializer.fromJson<String?>(json['namaToko']),
      namaPemilik: serializer.fromJson<String?>(json['namaPemilik']),
      noHpPribadi: serializer.fromJson<String?>(json['noHpPribadi']),
      alamatUsaha: serializer.fromJson<String?>(json['alamatUsaha']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      status: serializer.fromJson<String?>(json['status']),
      fotoTokoPath: serializer.fromJson<String?>(json['fotoTokoPath']),
      fotoKtpPath: serializer.fromJson<String?>(json['fotoKtpPath']),
      noKtpPemilik: serializer.fromJson<String?>(json['noKtpPemilik']),
      sistemPembayaran: serializer.fromJson<String?>(json['sistemPembayaran']),
      caraPembayaran: serializer.fromJson<String?>(json['caraPembayaran']),
      namaBank: serializer.fromJson<String?>(json['namaBank']),
      cabangBank: serializer.fromJson<String?>(json['cabangBank']),
      noRekening: serializer.fromJson<String?>(json['noRekening']),
      atasNamaRekening: serializer.fromJson<String?>(json['atasNamaRekening']),
      topHari: serializer.fromJson<int?>(json['topHari']),
      limitKreditAwal: serializer.fromJson<double?>(json['limitKreditAwal']),
      kotaUsaha: serializer.fromJson<String?>(json['kotaUsaha']),
      kecamatanUsaha: serializer.fromJson<String?>(json['kecamatanUsaha']),
      provinsiUsaha: serializer.fromJson<String?>(json['provinsiUsaha']),
      dataJson: serializer.fromJson<String?>(json['dataJson']),
      createdById: serializer.fromJson<String?>(json['createdById']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isLocal': serializer.toJson<int>(isLocal),
      'serverId': serializer.toJson<String?>(serverId),
      'clientRef': serializer.toJson<String?>(clientRef),
      'kodePelanggan': serializer.toJson<String?>(kodePelanggan),
      'namaToko': serializer.toJson<String?>(namaToko),
      'namaPemilik': serializer.toJson<String?>(namaPemilik),
      'noHpPribadi': serializer.toJson<String?>(noHpPribadi),
      'alamatUsaha': serializer.toJson<String?>(alamatUsaha),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'status': serializer.toJson<String?>(status),
      'fotoTokoPath': serializer.toJson<String?>(fotoTokoPath),
      'fotoKtpPath': serializer.toJson<String?>(fotoKtpPath),
      'noKtpPemilik': serializer.toJson<String?>(noKtpPemilik),
      'sistemPembayaran': serializer.toJson<String?>(sistemPembayaran),
      'caraPembayaran': serializer.toJson<String?>(caraPembayaran),
      'namaBank': serializer.toJson<String?>(namaBank),
      'cabangBank': serializer.toJson<String?>(cabangBank),
      'noRekening': serializer.toJson<String?>(noRekening),
      'atasNamaRekening': serializer.toJson<String?>(atasNamaRekening),
      'topHari': serializer.toJson<int?>(topHari),
      'limitKreditAwal': serializer.toJson<double?>(limitKreditAwal),
      'kotaUsaha': serializer.toJson<String?>(kotaUsaha),
      'kecamatanUsaha': serializer.toJson<String?>(kecamatanUsaha),
      'provinsiUsaha': serializer.toJson<String?>(provinsiUsaha),
      'dataJson': serializer.toJson<String?>(dataJson),
      'createdById': serializer.toJson<String?>(createdById),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CustomersTableData copyWith({
    String? id,
    int? isLocal,
    Value<String?> serverId = const Value.absent(),
    Value<String?> clientRef = const Value.absent(),
    Value<String?> kodePelanggan = const Value.absent(),
    Value<String?> namaToko = const Value.absent(),
    Value<String?> namaPemilik = const Value.absent(),
    Value<String?> noHpPribadi = const Value.absent(),
    Value<String?> alamatUsaha = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> status = const Value.absent(),
    Value<String?> fotoTokoPath = const Value.absent(),
    Value<String?> fotoKtpPath = const Value.absent(),
    Value<String?> noKtpPemilik = const Value.absent(),
    Value<String?> sistemPembayaran = const Value.absent(),
    Value<String?> caraPembayaran = const Value.absent(),
    Value<String?> namaBank = const Value.absent(),
    Value<String?> cabangBank = const Value.absent(),
    Value<String?> noRekening = const Value.absent(),
    Value<String?> atasNamaRekening = const Value.absent(),
    Value<int?> topHari = const Value.absent(),
    Value<double?> limitKreditAwal = const Value.absent(),
    Value<String?> kotaUsaha = const Value.absent(),
    Value<String?> kecamatanUsaha = const Value.absent(),
    Value<String?> provinsiUsaha = const Value.absent(),
    Value<String?> dataJson = const Value.absent(),
    Value<String?> createdById = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => CustomersTableData(
    id: id ?? this.id,
    isLocal: isLocal ?? this.isLocal,
    serverId: serverId.present ? serverId.value : this.serverId,
    clientRef: clientRef.present ? clientRef.value : this.clientRef,
    kodePelanggan: kodePelanggan.present
        ? kodePelanggan.value
        : this.kodePelanggan,
    namaToko: namaToko.present ? namaToko.value : this.namaToko,
    namaPemilik: namaPemilik.present ? namaPemilik.value : this.namaPemilik,
    noHpPribadi: noHpPribadi.present ? noHpPribadi.value : this.noHpPribadi,
    alamatUsaha: alamatUsaha.present ? alamatUsaha.value : this.alamatUsaha,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    status: status.present ? status.value : this.status,
    fotoTokoPath: fotoTokoPath.present ? fotoTokoPath.value : this.fotoTokoPath,
    fotoKtpPath: fotoKtpPath.present ? fotoKtpPath.value : this.fotoKtpPath,
    noKtpPemilik: noKtpPemilik.present ? noKtpPemilik.value : this.noKtpPemilik,
    sistemPembayaran: sistemPembayaran.present
        ? sistemPembayaran.value
        : this.sistemPembayaran,
    caraPembayaran: caraPembayaran.present
        ? caraPembayaran.value
        : this.caraPembayaran,
    namaBank: namaBank.present ? namaBank.value : this.namaBank,
    cabangBank: cabangBank.present ? cabangBank.value : this.cabangBank,
    noRekening: noRekening.present ? noRekening.value : this.noRekening,
    atasNamaRekening: atasNamaRekening.present
        ? atasNamaRekening.value
        : this.atasNamaRekening,
    topHari: topHari.present ? topHari.value : this.topHari,
    limitKreditAwal: limitKreditAwal.present
        ? limitKreditAwal.value
        : this.limitKreditAwal,
    kotaUsaha: kotaUsaha.present ? kotaUsaha.value : this.kotaUsaha,
    kecamatanUsaha: kecamatanUsaha.present
        ? kecamatanUsaha.value
        : this.kecamatanUsaha,
    provinsiUsaha: provinsiUsaha.present
        ? provinsiUsaha.value
        : this.provinsiUsaha,
    dataJson: dataJson.present ? dataJson.value : this.dataJson,
    createdById: createdById.present ? createdById.value : this.createdById,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CustomersTableData copyWithCompanion(CustomersTableCompanion data) {
    return CustomersTableData(
      id: data.id.present ? data.id.value : this.id,
      isLocal: data.isLocal.present ? data.isLocal.value : this.isLocal,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      clientRef: data.clientRef.present ? data.clientRef.value : this.clientRef,
      kodePelanggan: data.kodePelanggan.present
          ? data.kodePelanggan.value
          : this.kodePelanggan,
      namaToko: data.namaToko.present ? data.namaToko.value : this.namaToko,
      namaPemilik: data.namaPemilik.present
          ? data.namaPemilik.value
          : this.namaPemilik,
      noHpPribadi: data.noHpPribadi.present
          ? data.noHpPribadi.value
          : this.noHpPribadi,
      alamatUsaha: data.alamatUsaha.present
          ? data.alamatUsaha.value
          : this.alamatUsaha,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      status: data.status.present ? data.status.value : this.status,
      fotoTokoPath: data.fotoTokoPath.present
          ? data.fotoTokoPath.value
          : this.fotoTokoPath,
      fotoKtpPath: data.fotoKtpPath.present
          ? data.fotoKtpPath.value
          : this.fotoKtpPath,
      noKtpPemilik: data.noKtpPemilik.present
          ? data.noKtpPemilik.value
          : this.noKtpPemilik,
      sistemPembayaran: data.sistemPembayaran.present
          ? data.sistemPembayaran.value
          : this.sistemPembayaran,
      caraPembayaran: data.caraPembayaran.present
          ? data.caraPembayaran.value
          : this.caraPembayaran,
      namaBank: data.namaBank.present ? data.namaBank.value : this.namaBank,
      cabangBank: data.cabangBank.present
          ? data.cabangBank.value
          : this.cabangBank,
      noRekening: data.noRekening.present
          ? data.noRekening.value
          : this.noRekening,
      atasNamaRekening: data.atasNamaRekening.present
          ? data.atasNamaRekening.value
          : this.atasNamaRekening,
      topHari: data.topHari.present ? data.topHari.value : this.topHari,
      limitKreditAwal: data.limitKreditAwal.present
          ? data.limitKreditAwal.value
          : this.limitKreditAwal,
      kotaUsaha: data.kotaUsaha.present ? data.kotaUsaha.value : this.kotaUsaha,
      kecamatanUsaha: data.kecamatanUsaha.present
          ? data.kecamatanUsaha.value
          : this.kecamatanUsaha,
      provinsiUsaha: data.provinsiUsaha.present
          ? data.provinsiUsaha.value
          : this.provinsiUsaha,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      createdById: data.createdById.present
          ? data.createdById.value
          : this.createdById,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomersTableData(')
          ..write('id: $id, ')
          ..write('isLocal: $isLocal, ')
          ..write('serverId: $serverId, ')
          ..write('clientRef: $clientRef, ')
          ..write('kodePelanggan: $kodePelanggan, ')
          ..write('namaToko: $namaToko, ')
          ..write('namaPemilik: $namaPemilik, ')
          ..write('noHpPribadi: $noHpPribadi, ')
          ..write('alamatUsaha: $alamatUsaha, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('status: $status, ')
          ..write('fotoTokoPath: $fotoTokoPath, ')
          ..write('fotoKtpPath: $fotoKtpPath, ')
          ..write('noKtpPemilik: $noKtpPemilik, ')
          ..write('sistemPembayaran: $sistemPembayaran, ')
          ..write('caraPembayaran: $caraPembayaran, ')
          ..write('namaBank: $namaBank, ')
          ..write('cabangBank: $cabangBank, ')
          ..write('noRekening: $noRekening, ')
          ..write('atasNamaRekening: $atasNamaRekening, ')
          ..write('topHari: $topHari, ')
          ..write('limitKreditAwal: $limitKreditAwal, ')
          ..write('kotaUsaha: $kotaUsaha, ')
          ..write('kecamatanUsaha: $kecamatanUsaha, ')
          ..write('provinsiUsaha: $provinsiUsaha, ')
          ..write('dataJson: $dataJson, ')
          ..write('createdById: $createdById, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    isLocal,
    serverId,
    clientRef,
    kodePelanggan,
    namaToko,
    namaPemilik,
    noHpPribadi,
    alamatUsaha,
    latitude,
    longitude,
    status,
    fotoTokoPath,
    fotoKtpPath,
    noKtpPemilik,
    sistemPembayaran,
    caraPembayaran,
    namaBank,
    cabangBank,
    noRekening,
    atasNamaRekening,
    topHari,
    limitKreditAwal,
    kotaUsaha,
    kecamatanUsaha,
    provinsiUsaha,
    dataJson,
    createdById,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomersTableData &&
          other.id == this.id &&
          other.isLocal == this.isLocal &&
          other.serverId == this.serverId &&
          other.clientRef == this.clientRef &&
          other.kodePelanggan == this.kodePelanggan &&
          other.namaToko == this.namaToko &&
          other.namaPemilik == this.namaPemilik &&
          other.noHpPribadi == this.noHpPribadi &&
          other.alamatUsaha == this.alamatUsaha &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.status == this.status &&
          other.fotoTokoPath == this.fotoTokoPath &&
          other.fotoKtpPath == this.fotoKtpPath &&
          other.noKtpPemilik == this.noKtpPemilik &&
          other.sistemPembayaran == this.sistemPembayaran &&
          other.caraPembayaran == this.caraPembayaran &&
          other.namaBank == this.namaBank &&
          other.cabangBank == this.cabangBank &&
          other.noRekening == this.noRekening &&
          other.atasNamaRekening == this.atasNamaRekening &&
          other.topHari == this.topHari &&
          other.limitKreditAwal == this.limitKreditAwal &&
          other.kotaUsaha == this.kotaUsaha &&
          other.kecamatanUsaha == this.kecamatanUsaha &&
          other.provinsiUsaha == this.provinsiUsaha &&
          other.dataJson == this.dataJson &&
          other.createdById == this.createdById &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomersTableCompanion extends UpdateCompanion<CustomersTableData> {
  final Value<String> id;
  final Value<int> isLocal;
  final Value<String?> serverId;
  final Value<String?> clientRef;
  final Value<String?> kodePelanggan;
  final Value<String?> namaToko;
  final Value<String?> namaPemilik;
  final Value<String?> noHpPribadi;
  final Value<String?> alamatUsaha;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> status;
  final Value<String?> fotoTokoPath;
  final Value<String?> fotoKtpPath;
  final Value<String?> noKtpPemilik;
  final Value<String?> sistemPembayaran;
  final Value<String?> caraPembayaran;
  final Value<String?> namaBank;
  final Value<String?> cabangBank;
  final Value<String?> noRekening;
  final Value<String?> atasNamaRekening;
  final Value<int?> topHari;
  final Value<double?> limitKreditAwal;
  final Value<String?> kotaUsaha;
  final Value<String?> kecamatanUsaha;
  final Value<String?> provinsiUsaha;
  final Value<String?> dataJson;
  final Value<String?> createdById;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const CustomersTableCompanion({
    this.id = const Value.absent(),
    this.isLocal = const Value.absent(),
    this.serverId = const Value.absent(),
    this.clientRef = const Value.absent(),
    this.kodePelanggan = const Value.absent(),
    this.namaToko = const Value.absent(),
    this.namaPemilik = const Value.absent(),
    this.noHpPribadi = const Value.absent(),
    this.alamatUsaha = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.status = const Value.absent(),
    this.fotoTokoPath = const Value.absent(),
    this.fotoKtpPath = const Value.absent(),
    this.noKtpPemilik = const Value.absent(),
    this.sistemPembayaran = const Value.absent(),
    this.caraPembayaran = const Value.absent(),
    this.namaBank = const Value.absent(),
    this.cabangBank = const Value.absent(),
    this.noRekening = const Value.absent(),
    this.atasNamaRekening = const Value.absent(),
    this.topHari = const Value.absent(),
    this.limitKreditAwal = const Value.absent(),
    this.kotaUsaha = const Value.absent(),
    this.kecamatanUsaha = const Value.absent(),
    this.provinsiUsaha = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.createdById = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersTableCompanion.insert({
    required String id,
    this.isLocal = const Value.absent(),
    this.serverId = const Value.absent(),
    this.clientRef = const Value.absent(),
    this.kodePelanggan = const Value.absent(),
    this.namaToko = const Value.absent(),
    this.namaPemilik = const Value.absent(),
    this.noHpPribadi = const Value.absent(),
    this.alamatUsaha = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.status = const Value.absent(),
    this.fotoTokoPath = const Value.absent(),
    this.fotoKtpPath = const Value.absent(),
    this.noKtpPemilik = const Value.absent(),
    this.sistemPembayaran = const Value.absent(),
    this.caraPembayaran = const Value.absent(),
    this.namaBank = const Value.absent(),
    this.cabangBank = const Value.absent(),
    this.noRekening = const Value.absent(),
    this.atasNamaRekening = const Value.absent(),
    this.topHari = const Value.absent(),
    this.limitKreditAwal = const Value.absent(),
    this.kotaUsaha = const Value.absent(),
    this.kecamatanUsaha = const Value.absent(),
    this.provinsiUsaha = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.createdById = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CustomersTableData> custom({
    Expression<String>? id,
    Expression<int>? isLocal,
    Expression<String>? serverId,
    Expression<String>? clientRef,
    Expression<String>? kodePelanggan,
    Expression<String>? namaToko,
    Expression<String>? namaPemilik,
    Expression<String>? noHpPribadi,
    Expression<String>? alamatUsaha,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? status,
    Expression<String>? fotoTokoPath,
    Expression<String>? fotoKtpPath,
    Expression<String>? noKtpPemilik,
    Expression<String>? sistemPembayaran,
    Expression<String>? caraPembayaran,
    Expression<String>? namaBank,
    Expression<String>? cabangBank,
    Expression<String>? noRekening,
    Expression<String>? atasNamaRekening,
    Expression<int>? topHari,
    Expression<double>? limitKreditAwal,
    Expression<String>? kotaUsaha,
    Expression<String>? kecamatanUsaha,
    Expression<String>? provinsiUsaha,
    Expression<String>? dataJson,
    Expression<String>? createdById,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isLocal != null) 'is_local': isLocal,
      if (serverId != null) 'server_id': serverId,
      if (clientRef != null) 'client_ref': clientRef,
      if (kodePelanggan != null) 'kode_pelanggan': kodePelanggan,
      if (namaToko != null) 'nama_toko': namaToko,
      if (namaPemilik != null) 'nama_pemilik': namaPemilik,
      if (noHpPribadi != null) 'no_hp_pribadi': noHpPribadi,
      if (alamatUsaha != null) 'alamat_usaha': alamatUsaha,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (status != null) 'status': status,
      if (fotoTokoPath != null) 'foto_toko_path': fotoTokoPath,
      if (fotoKtpPath != null) 'foto_ktp_path': fotoKtpPath,
      if (noKtpPemilik != null) 'no_ktp_pemilik': noKtpPemilik,
      if (sistemPembayaran != null) 'sistem_pembayaran': sistemPembayaran,
      if (caraPembayaran != null) 'cara_pembayaran': caraPembayaran,
      if (namaBank != null) 'nama_bank': namaBank,
      if (cabangBank != null) 'cabang_bank': cabangBank,
      if (noRekening != null) 'no_rekening': noRekening,
      if (atasNamaRekening != null) 'atas_nama_rekening': atasNamaRekening,
      if (topHari != null) 'top_hari': topHari,
      if (limitKreditAwal != null) 'limit_kredit_awal': limitKreditAwal,
      if (kotaUsaha != null) 'kota_usaha': kotaUsaha,
      if (kecamatanUsaha != null) 'kecamatan_usaha': kecamatanUsaha,
      if (provinsiUsaha != null) 'provinsi_usaha': provinsiUsaha,
      if (dataJson != null) 'data_json': dataJson,
      if (createdById != null) 'created_by_id': createdById,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersTableCompanion copyWith({
    Value<String>? id,
    Value<int>? isLocal,
    Value<String?>? serverId,
    Value<String?>? clientRef,
    Value<String?>? kodePelanggan,
    Value<String?>? namaToko,
    Value<String?>? namaPemilik,
    Value<String?>? noHpPribadi,
    Value<String?>? alamatUsaha,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? status,
    Value<String?>? fotoTokoPath,
    Value<String?>? fotoKtpPath,
    Value<String?>? noKtpPemilik,
    Value<String?>? sistemPembayaran,
    Value<String?>? caraPembayaran,
    Value<String?>? namaBank,
    Value<String?>? cabangBank,
    Value<String?>? noRekening,
    Value<String?>? atasNamaRekening,
    Value<int?>? topHari,
    Value<double?>? limitKreditAwal,
    Value<String?>? kotaUsaha,
    Value<String?>? kecamatanUsaha,
    Value<String?>? provinsiUsaha,
    Value<String?>? dataJson,
    Value<String?>? createdById,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return CustomersTableCompanion(
      id: id ?? this.id,
      isLocal: isLocal ?? this.isLocal,
      serverId: serverId ?? this.serverId,
      clientRef: clientRef ?? this.clientRef,
      kodePelanggan: kodePelanggan ?? this.kodePelanggan,
      namaToko: namaToko ?? this.namaToko,
      namaPemilik: namaPemilik ?? this.namaPemilik,
      noHpPribadi: noHpPribadi ?? this.noHpPribadi,
      alamatUsaha: alamatUsaha ?? this.alamatUsaha,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      fotoTokoPath: fotoTokoPath ?? this.fotoTokoPath,
      fotoKtpPath: fotoKtpPath ?? this.fotoKtpPath,
      noKtpPemilik: noKtpPemilik ?? this.noKtpPemilik,
      sistemPembayaran: sistemPembayaran ?? this.sistemPembayaran,
      caraPembayaran: caraPembayaran ?? this.caraPembayaran,
      namaBank: namaBank ?? this.namaBank,
      cabangBank: cabangBank ?? this.cabangBank,
      noRekening: noRekening ?? this.noRekening,
      atasNamaRekening: atasNamaRekening ?? this.atasNamaRekening,
      topHari: topHari ?? this.topHari,
      limitKreditAwal: limitKreditAwal ?? this.limitKreditAwal,
      kotaUsaha: kotaUsaha ?? this.kotaUsaha,
      kecamatanUsaha: kecamatanUsaha ?? this.kecamatanUsaha,
      provinsiUsaha: provinsiUsaha ?? this.provinsiUsaha,
      dataJson: dataJson ?? this.dataJson,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isLocal.present) {
      map['is_local'] = Variable<int>(isLocal.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (clientRef.present) {
      map['client_ref'] = Variable<String>(clientRef.value);
    }
    if (kodePelanggan.present) {
      map['kode_pelanggan'] = Variable<String>(kodePelanggan.value);
    }
    if (namaToko.present) {
      map['nama_toko'] = Variable<String>(namaToko.value);
    }
    if (namaPemilik.present) {
      map['nama_pemilik'] = Variable<String>(namaPemilik.value);
    }
    if (noHpPribadi.present) {
      map['no_hp_pribadi'] = Variable<String>(noHpPribadi.value);
    }
    if (alamatUsaha.present) {
      map['alamat_usaha'] = Variable<String>(alamatUsaha.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (fotoTokoPath.present) {
      map['foto_toko_path'] = Variable<String>(fotoTokoPath.value);
    }
    if (fotoKtpPath.present) {
      map['foto_ktp_path'] = Variable<String>(fotoKtpPath.value);
    }
    if (noKtpPemilik.present) {
      map['no_ktp_pemilik'] = Variable<String>(noKtpPemilik.value);
    }
    if (sistemPembayaran.present) {
      map['sistem_pembayaran'] = Variable<String>(sistemPembayaran.value);
    }
    if (caraPembayaran.present) {
      map['cara_pembayaran'] = Variable<String>(caraPembayaran.value);
    }
    if (namaBank.present) {
      map['nama_bank'] = Variable<String>(namaBank.value);
    }
    if (cabangBank.present) {
      map['cabang_bank'] = Variable<String>(cabangBank.value);
    }
    if (noRekening.present) {
      map['no_rekening'] = Variable<String>(noRekening.value);
    }
    if (atasNamaRekening.present) {
      map['atas_nama_rekening'] = Variable<String>(atasNamaRekening.value);
    }
    if (topHari.present) {
      map['top_hari'] = Variable<int>(topHari.value);
    }
    if (limitKreditAwal.present) {
      map['limit_kredit_awal'] = Variable<double>(limitKreditAwal.value);
    }
    if (kotaUsaha.present) {
      map['kota_usaha'] = Variable<String>(kotaUsaha.value);
    }
    if (kecamatanUsaha.present) {
      map['kecamatan_usaha'] = Variable<String>(kecamatanUsaha.value);
    }
    if (provinsiUsaha.present) {
      map['provinsi_usaha'] = Variable<String>(provinsiUsaha.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (createdById.present) {
      map['created_by_id'] = Variable<String>(createdById.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersTableCompanion(')
          ..write('id: $id, ')
          ..write('isLocal: $isLocal, ')
          ..write('serverId: $serverId, ')
          ..write('clientRef: $clientRef, ')
          ..write('kodePelanggan: $kodePelanggan, ')
          ..write('namaToko: $namaToko, ')
          ..write('namaPemilik: $namaPemilik, ')
          ..write('noHpPribadi: $noHpPribadi, ')
          ..write('alamatUsaha: $alamatUsaha, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('status: $status, ')
          ..write('fotoTokoPath: $fotoTokoPath, ')
          ..write('fotoKtpPath: $fotoKtpPath, ')
          ..write('noKtpPemilik: $noKtpPemilik, ')
          ..write('sistemPembayaran: $sistemPembayaran, ')
          ..write('caraPembayaran: $caraPembayaran, ')
          ..write('namaBank: $namaBank, ')
          ..write('cabangBank: $cabangBank, ')
          ..write('noRekening: $noRekening, ')
          ..write('atasNamaRekening: $atasNamaRekening, ')
          ..write('topHari: $topHari, ')
          ..write('limitKreditAwal: $limitKreditAwal, ')
          ..write('kotaUsaha: $kotaUsaha, ')
          ..write('kecamatanUsaha: $kecamatanUsaha, ')
          ..write('provinsiUsaha: $provinsiUsaha, ')
          ..write('dataJson: $dataJson, ')
          ..write('createdById: $createdById, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTableTable extends ProductsTable
    with TableInfo<$ProductsTableTable, ProductsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _perusahaanIdMeta = const VerificationMeta(
    'perusahaanId',
  );
  @override
  late final GeneratedColumn<String> perusahaanId = GeneratedColumn<String>(
    'perusahaan_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kodeBarangMeta = const VerificationMeta(
    'kodeBarang',
  );
  @override
  late final GeneratedColumn<String> kodeBarang = GeneratedColumn<String>(
    'kode_barang',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _namaProdukMeta = const VerificationMeta(
    'namaProduk',
  );
  @override
  late final GeneratedColumn<String> namaProduk = GeneratedColumn<String>(
    'nama_produk',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kategoriIdMeta = const VerificationMeta(
    'kategoriId',
  );
  @override
  late final GeneratedColumn<String> kategoriId = GeneratedColumn<String>(
    'kategori_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kategoriMeta = const VerificationMeta(
    'kategori',
  );
  @override
  late final GeneratedColumn<String> kategori = GeneratedColumn<String>(
    'kategori',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _satuanMeta = const VerificationMeta('satuan');
  @override
  late final GeneratedColumn<String> satuan = GeneratedColumn<String>(
    'satuan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deskripsiMeta = const VerificationMeta(
    'deskripsi',
  );
  @override
  late final GeneratedColumn<String> deskripsi = GeneratedColumn<String>(
    'deskripsi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hargaDasarMeta = const VerificationMeta(
    'hargaDasar',
  );
  @override
  late final GeneratedColumn<double> hargaDasar = GeneratedColumn<double>(
    'harga_dasar',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hargaJualMeta = const VerificationMeta(
    'hargaJual',
  );
  @override
  late final GeneratedColumn<double> hargaJual = GeneratedColumn<double>(
    'harga_jual',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stokTersediaMeta = const VerificationMeta(
    'stokTersedia',
  );
  @override
  late final GeneratedColumn<int> stokTersedia = GeneratedColumn<int>(
    'stok_tersedia',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _gambarUrlMeta = const VerificationMeta(
    'gambarUrl',
  );
  @override
  late final GeneratedColumn<String> gambarUrl = GeneratedColumn<String>(
    'gambar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    perusahaanId,
    sku,
    kodeBarang,
    namaProduk,
    kategoriId,
    kategori,
    satuan,
    deskripsi,
    hargaDasar,
    hargaJual,
    stokTersedia,
    gambarUrl,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('perusahaan_id')) {
      context.handle(
        _perusahaanIdMeta,
        perusahaanId.isAcceptableOrUnknown(
          data['perusahaan_id']!,
          _perusahaanIdMeta,
        ),
      );
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('kode_barang')) {
      context.handle(
        _kodeBarangMeta,
        kodeBarang.isAcceptableOrUnknown(data['kode_barang']!, _kodeBarangMeta),
      );
    }
    if (data.containsKey('nama_produk')) {
      context.handle(
        _namaProdukMeta,
        namaProduk.isAcceptableOrUnknown(data['nama_produk']!, _namaProdukMeta),
      );
    } else if (isInserting) {
      context.missing(_namaProdukMeta);
    }
    if (data.containsKey('kategori_id')) {
      context.handle(
        _kategoriIdMeta,
        kategoriId.isAcceptableOrUnknown(data['kategori_id']!, _kategoriIdMeta),
      );
    }
    if (data.containsKey('kategori')) {
      context.handle(
        _kategoriMeta,
        kategori.isAcceptableOrUnknown(data['kategori']!, _kategoriMeta),
      );
    }
    if (data.containsKey('satuan')) {
      context.handle(
        _satuanMeta,
        satuan.isAcceptableOrUnknown(data['satuan']!, _satuanMeta),
      );
    }
    if (data.containsKey('deskripsi')) {
      context.handle(
        _deskripsiMeta,
        deskripsi.isAcceptableOrUnknown(data['deskripsi']!, _deskripsiMeta),
      );
    }
    if (data.containsKey('harga_dasar')) {
      context.handle(
        _hargaDasarMeta,
        hargaDasar.isAcceptableOrUnknown(data['harga_dasar']!, _hargaDasarMeta),
      );
    }
    if (data.containsKey('harga_jual')) {
      context.handle(
        _hargaJualMeta,
        hargaJual.isAcceptableOrUnknown(data['harga_jual']!, _hargaJualMeta),
      );
    }
    if (data.containsKey('stok_tersedia')) {
      context.handle(
        _stokTersediaMeta,
        stokTersedia.isAcceptableOrUnknown(
          data['stok_tersedia']!,
          _stokTersediaMeta,
        ),
      );
    }
    if (data.containsKey('gambar_url')) {
      context.handle(
        _gambarUrlMeta,
        gambarUrl.isAcceptableOrUnknown(data['gambar_url']!, _gambarUrlMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      perusahaanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}perusahaan_id'],
      ),
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      kodeBarang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kode_barang'],
      ),
      namaProduk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama_produk'],
      )!,
      kategoriId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kategori_id'],
      ),
      kategori: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kategori'],
      ),
      satuan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}satuan'],
      ),
      deskripsi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deskripsi'],
      ),
      hargaDasar: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}harga_dasar'],
      ),
      hargaJual: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}harga_jual'],
      ),
      stokTersedia: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stok_tersedia'],
      )!,
      gambarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gambar_url'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductsTableTable createAlias(String alias) {
    return $ProductsTableTable(attachedDatabase, alias);
  }
}

class ProductsTableData extends DataClass
    implements Insertable<ProductsTableData> {
  final String id;
  final String? perusahaanId;
  final String? sku;
  final String? kodeBarang;
  final String namaProduk;
  final String? kategoriId;
  final String? kategori;
  final String? satuan;
  final String? deskripsi;
  final double? hargaDasar;
  final double? hargaJual;
  final int stokTersedia;
  final String? gambarUrl;
  final String status;
  final int createdAt;
  final int updatedAt;
  const ProductsTableData({
    required this.id,
    this.perusahaanId,
    this.sku,
    this.kodeBarang,
    required this.namaProduk,
    this.kategoriId,
    this.kategori,
    this.satuan,
    this.deskripsi,
    this.hargaDasar,
    this.hargaJual,
    required this.stokTersedia,
    this.gambarUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || perusahaanId != null) {
      map['perusahaan_id'] = Variable<String>(perusahaanId);
    }
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || kodeBarang != null) {
      map['kode_barang'] = Variable<String>(kodeBarang);
    }
    map['nama_produk'] = Variable<String>(namaProduk);
    if (!nullToAbsent || kategoriId != null) {
      map['kategori_id'] = Variable<String>(kategoriId);
    }
    if (!nullToAbsent || kategori != null) {
      map['kategori'] = Variable<String>(kategori);
    }
    if (!nullToAbsent || satuan != null) {
      map['satuan'] = Variable<String>(satuan);
    }
    if (!nullToAbsent || deskripsi != null) {
      map['deskripsi'] = Variable<String>(deskripsi);
    }
    if (!nullToAbsent || hargaDasar != null) {
      map['harga_dasar'] = Variable<double>(hargaDasar);
    }
    if (!nullToAbsent || hargaJual != null) {
      map['harga_jual'] = Variable<double>(hargaJual);
    }
    map['stok_tersedia'] = Variable<int>(stokTersedia);
    if (!nullToAbsent || gambarUrl != null) {
      map['gambar_url'] = Variable<String>(gambarUrl);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ProductsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductsTableCompanion(
      id: Value(id),
      perusahaanId: perusahaanId == null && nullToAbsent
          ? const Value.absent()
          : Value(perusahaanId),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      kodeBarang: kodeBarang == null && nullToAbsent
          ? const Value.absent()
          : Value(kodeBarang),
      namaProduk: Value(namaProduk),
      kategoriId: kategoriId == null && nullToAbsent
          ? const Value.absent()
          : Value(kategoriId),
      kategori: kategori == null && nullToAbsent
          ? const Value.absent()
          : Value(kategori),
      satuan: satuan == null && nullToAbsent
          ? const Value.absent()
          : Value(satuan),
      deskripsi: deskripsi == null && nullToAbsent
          ? const Value.absent()
          : Value(deskripsi),
      hargaDasar: hargaDasar == null && nullToAbsent
          ? const Value.absent()
          : Value(hargaDasar),
      hargaJual: hargaJual == null && nullToAbsent
          ? const Value.absent()
          : Value(hargaJual),
      stokTersedia: Value(stokTersedia),
      gambarUrl: gambarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(gambarUrl),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductsTableData(
      id: serializer.fromJson<String>(json['id']),
      perusahaanId: serializer.fromJson<String?>(json['perusahaanId']),
      sku: serializer.fromJson<String?>(json['sku']),
      kodeBarang: serializer.fromJson<String?>(json['kodeBarang']),
      namaProduk: serializer.fromJson<String>(json['namaProduk']),
      kategoriId: serializer.fromJson<String?>(json['kategoriId']),
      kategori: serializer.fromJson<String?>(json['kategori']),
      satuan: serializer.fromJson<String?>(json['satuan']),
      deskripsi: serializer.fromJson<String?>(json['deskripsi']),
      hargaDasar: serializer.fromJson<double?>(json['hargaDasar']),
      hargaJual: serializer.fromJson<double?>(json['hargaJual']),
      stokTersedia: serializer.fromJson<int>(json['stokTersedia']),
      gambarUrl: serializer.fromJson<String?>(json['gambarUrl']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'perusahaanId': serializer.toJson<String?>(perusahaanId),
      'sku': serializer.toJson<String?>(sku),
      'kodeBarang': serializer.toJson<String?>(kodeBarang),
      'namaProduk': serializer.toJson<String>(namaProduk),
      'kategoriId': serializer.toJson<String?>(kategoriId),
      'kategori': serializer.toJson<String?>(kategori),
      'satuan': serializer.toJson<String?>(satuan),
      'deskripsi': serializer.toJson<String?>(deskripsi),
      'hargaDasar': serializer.toJson<double?>(hargaDasar),
      'hargaJual': serializer.toJson<double?>(hargaJual),
      'stokTersedia': serializer.toJson<int>(stokTersedia),
      'gambarUrl': serializer.toJson<String?>(gambarUrl),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ProductsTableData copyWith({
    String? id,
    Value<String?> perusahaanId = const Value.absent(),
    Value<String?> sku = const Value.absent(),
    Value<String?> kodeBarang = const Value.absent(),
    String? namaProduk,
    Value<String?> kategoriId = const Value.absent(),
    Value<String?> kategori = const Value.absent(),
    Value<String?> satuan = const Value.absent(),
    Value<String?> deskripsi = const Value.absent(),
    Value<double?> hargaDasar = const Value.absent(),
    Value<double?> hargaJual = const Value.absent(),
    int? stokTersedia,
    Value<String?> gambarUrl = const Value.absent(),
    String? status,
    int? createdAt,
    int? updatedAt,
  }) => ProductsTableData(
    id: id ?? this.id,
    perusahaanId: perusahaanId.present ? perusahaanId.value : this.perusahaanId,
    sku: sku.present ? sku.value : this.sku,
    kodeBarang: kodeBarang.present ? kodeBarang.value : this.kodeBarang,
    namaProduk: namaProduk ?? this.namaProduk,
    kategoriId: kategoriId.present ? kategoriId.value : this.kategoriId,
    kategori: kategori.present ? kategori.value : this.kategori,
    satuan: satuan.present ? satuan.value : this.satuan,
    deskripsi: deskripsi.present ? deskripsi.value : this.deskripsi,
    hargaDasar: hargaDasar.present ? hargaDasar.value : this.hargaDasar,
    hargaJual: hargaJual.present ? hargaJual.value : this.hargaJual,
    stokTersedia: stokTersedia ?? this.stokTersedia,
    gambarUrl: gambarUrl.present ? gambarUrl.value : this.gambarUrl,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProductsTableData copyWithCompanion(ProductsTableCompanion data) {
    return ProductsTableData(
      id: data.id.present ? data.id.value : this.id,
      perusahaanId: data.perusahaanId.present
          ? data.perusahaanId.value
          : this.perusahaanId,
      sku: data.sku.present ? data.sku.value : this.sku,
      kodeBarang: data.kodeBarang.present
          ? data.kodeBarang.value
          : this.kodeBarang,
      namaProduk: data.namaProduk.present
          ? data.namaProduk.value
          : this.namaProduk,
      kategoriId: data.kategoriId.present
          ? data.kategoriId.value
          : this.kategoriId,
      kategori: data.kategori.present ? data.kategori.value : this.kategori,
      satuan: data.satuan.present ? data.satuan.value : this.satuan,
      deskripsi: data.deskripsi.present ? data.deskripsi.value : this.deskripsi,
      hargaDasar: data.hargaDasar.present
          ? data.hargaDasar.value
          : this.hargaDasar,
      hargaJual: data.hargaJual.present ? data.hargaJual.value : this.hargaJual,
      stokTersedia: data.stokTersedia.present
          ? data.stokTersedia.value
          : this.stokTersedia,
      gambarUrl: data.gambarUrl.present ? data.gambarUrl.value : this.gambarUrl,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableData(')
          ..write('id: $id, ')
          ..write('perusahaanId: $perusahaanId, ')
          ..write('sku: $sku, ')
          ..write('kodeBarang: $kodeBarang, ')
          ..write('namaProduk: $namaProduk, ')
          ..write('kategoriId: $kategoriId, ')
          ..write('kategori: $kategori, ')
          ..write('satuan: $satuan, ')
          ..write('deskripsi: $deskripsi, ')
          ..write('hargaDasar: $hargaDasar, ')
          ..write('hargaJual: $hargaJual, ')
          ..write('stokTersedia: $stokTersedia, ')
          ..write('gambarUrl: $gambarUrl, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    perusahaanId,
    sku,
    kodeBarang,
    namaProduk,
    kategoriId,
    kategori,
    satuan,
    deskripsi,
    hargaDasar,
    hargaJual,
    stokTersedia,
    gambarUrl,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductsTableData &&
          other.id == this.id &&
          other.perusahaanId == this.perusahaanId &&
          other.sku == this.sku &&
          other.kodeBarang == this.kodeBarang &&
          other.namaProduk == this.namaProduk &&
          other.kategoriId == this.kategoriId &&
          other.kategori == this.kategori &&
          other.satuan == this.satuan &&
          other.deskripsi == this.deskripsi &&
          other.hargaDasar == this.hargaDasar &&
          other.hargaJual == this.hargaJual &&
          other.stokTersedia == this.stokTersedia &&
          other.gambarUrl == this.gambarUrl &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsTableCompanion extends UpdateCompanion<ProductsTableData> {
  final Value<String> id;
  final Value<String?> perusahaanId;
  final Value<String?> sku;
  final Value<String?> kodeBarang;
  final Value<String> namaProduk;
  final Value<String?> kategoriId;
  final Value<String?> kategori;
  final Value<String?> satuan;
  final Value<String?> deskripsi;
  final Value<double?> hargaDasar;
  final Value<double?> hargaJual;
  final Value<int> stokTersedia;
  final Value<String?> gambarUrl;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ProductsTableCompanion({
    this.id = const Value.absent(),
    this.perusahaanId = const Value.absent(),
    this.sku = const Value.absent(),
    this.kodeBarang = const Value.absent(),
    this.namaProduk = const Value.absent(),
    this.kategoriId = const Value.absent(),
    this.kategori = const Value.absent(),
    this.satuan = const Value.absent(),
    this.deskripsi = const Value.absent(),
    this.hargaDasar = const Value.absent(),
    this.hargaJual = const Value.absent(),
    this.stokTersedia = const Value.absent(),
    this.gambarUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsTableCompanion.insert({
    required String id,
    this.perusahaanId = const Value.absent(),
    this.sku = const Value.absent(),
    this.kodeBarang = const Value.absent(),
    required String namaProduk,
    this.kategoriId = const Value.absent(),
    this.kategori = const Value.absent(),
    this.satuan = const Value.absent(),
    this.deskripsi = const Value.absent(),
    this.hargaDasar = const Value.absent(),
    this.hargaJual = const Value.absent(),
    this.stokTersedia = const Value.absent(),
    this.gambarUrl = const Value.absent(),
    this.status = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       namaProduk = Value(namaProduk),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProductsTableData> custom({
    Expression<String>? id,
    Expression<String>? perusahaanId,
    Expression<String>? sku,
    Expression<String>? kodeBarang,
    Expression<String>? namaProduk,
    Expression<String>? kategoriId,
    Expression<String>? kategori,
    Expression<String>? satuan,
    Expression<String>? deskripsi,
    Expression<double>? hargaDasar,
    Expression<double>? hargaJual,
    Expression<int>? stokTersedia,
    Expression<String>? gambarUrl,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (perusahaanId != null) 'perusahaan_id': perusahaanId,
      if (sku != null) 'sku': sku,
      if (kodeBarang != null) 'kode_barang': kodeBarang,
      if (namaProduk != null) 'nama_produk': namaProduk,
      if (kategoriId != null) 'kategori_id': kategoriId,
      if (kategori != null) 'kategori': kategori,
      if (satuan != null) 'satuan': satuan,
      if (deskripsi != null) 'deskripsi': deskripsi,
      if (hargaDasar != null) 'harga_dasar': hargaDasar,
      if (hargaJual != null) 'harga_jual': hargaJual,
      if (stokTersedia != null) 'stok_tersedia': stokTersedia,
      if (gambarUrl != null) 'gambar_url': gambarUrl,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? perusahaanId,
    Value<String?>? sku,
    Value<String?>? kodeBarang,
    Value<String>? namaProduk,
    Value<String?>? kategoriId,
    Value<String?>? kategori,
    Value<String?>? satuan,
    Value<String?>? deskripsi,
    Value<double?>? hargaDasar,
    Value<double?>? hargaJual,
    Value<int>? stokTersedia,
    Value<String?>? gambarUrl,
    Value<String>? status,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProductsTableCompanion(
      id: id ?? this.id,
      perusahaanId: perusahaanId ?? this.perusahaanId,
      sku: sku ?? this.sku,
      kodeBarang: kodeBarang ?? this.kodeBarang,
      namaProduk: namaProduk ?? this.namaProduk,
      kategoriId: kategoriId ?? this.kategoriId,
      kategori: kategori ?? this.kategori,
      satuan: satuan ?? this.satuan,
      deskripsi: deskripsi ?? this.deskripsi,
      hargaDasar: hargaDasar ?? this.hargaDasar,
      hargaJual: hargaJual ?? this.hargaJual,
      stokTersedia: stokTersedia ?? this.stokTersedia,
      gambarUrl: gambarUrl ?? this.gambarUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (perusahaanId.present) {
      map['perusahaan_id'] = Variable<String>(perusahaanId.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (kodeBarang.present) {
      map['kode_barang'] = Variable<String>(kodeBarang.value);
    }
    if (namaProduk.present) {
      map['nama_produk'] = Variable<String>(namaProduk.value);
    }
    if (kategoriId.present) {
      map['kategori_id'] = Variable<String>(kategoriId.value);
    }
    if (kategori.present) {
      map['kategori'] = Variable<String>(kategori.value);
    }
    if (satuan.present) {
      map['satuan'] = Variable<String>(satuan.value);
    }
    if (deskripsi.present) {
      map['deskripsi'] = Variable<String>(deskripsi.value);
    }
    if (hargaDasar.present) {
      map['harga_dasar'] = Variable<double>(hargaDasar.value);
    }
    if (hargaJual.present) {
      map['harga_jual'] = Variable<double>(hargaJual.value);
    }
    if (stokTersedia.present) {
      map['stok_tersedia'] = Variable<int>(stokTersedia.value);
    }
    if (gambarUrl.present) {
      map['gambar_url'] = Variable<String>(gambarUrl.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableCompanion(')
          ..write('id: $id, ')
          ..write('perusahaanId: $perusahaanId, ')
          ..write('sku: $sku, ')
          ..write('kodeBarang: $kodeBarang, ')
          ..write('namaProduk: $namaProduk, ')
          ..write('kategoriId: $kategoriId, ')
          ..write('kategori: $kategori, ')
          ..write('satuan: $satuan, ')
          ..write('deskripsi: $deskripsi, ')
          ..write('hargaDasar: $hargaDasar, ')
          ..write('hargaJual: $hargaJual, ')
          ..write('stokTersedia: $stokTersedia, ')
          ..write('gambarUrl: $gambarUrl, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductUnitsTableTable extends ProductUnitsTable
    with TableInfo<$ProductUnitsTableTable, ProductUnitsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductUnitsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _namaMeta = const VerificationMeta('nama');
  @override
  late final GeneratedColumn<String> nama = GeneratedColumn<String>(
    'nama',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _konversiMeta = const VerificationMeta(
    'konversi',
  );
  @override
  late final GeneratedColumn<double> konversi = GeneratedColumn<double>(
    'konversi',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hargaJualMeta = const VerificationMeta(
    'hargaJual',
  );
  @override
  late final GeneratedColumn<double> hargaJual = GeneratedColumn<double>(
    'harga_jual',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isBaseMeta = const VerificationMeta('isBase');
  @override
  late final GeneratedColumn<bool> isBase = GeneratedColumn<bool>(
    'is_base',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_base" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    nama,
    konversi,
    hargaJual,
    isBase,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_units_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductUnitsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('nama')) {
      context.handle(
        _namaMeta,
        nama.isAcceptableOrUnknown(data['nama']!, _namaMeta),
      );
    } else if (isInserting) {
      context.missing(_namaMeta);
    }
    if (data.containsKey('konversi')) {
      context.handle(
        _konversiMeta,
        konversi.isAcceptableOrUnknown(data['konversi']!, _konversiMeta),
      );
    } else if (isInserting) {
      context.missing(_konversiMeta);
    }
    if (data.containsKey('harga_jual')) {
      context.handle(
        _hargaJualMeta,
        hargaJual.isAcceptableOrUnknown(data['harga_jual']!, _hargaJualMeta),
      );
    }
    if (data.containsKey('is_base')) {
      context.handle(
        _isBaseMeta,
        isBase.isAcceptableOrUnknown(data['is_base']!, _isBaseMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductUnitsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductUnitsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      nama: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama'],
      )!,
      konversi: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}konversi'],
      )!,
      hargaJual: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}harga_jual'],
      ),
      isBase: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_base'],
      )!,
    );
  }

  @override
  $ProductUnitsTableTable createAlias(String alias) {
    return $ProductUnitsTableTable(attachedDatabase, alias);
  }
}

class ProductUnitsTableData extends DataClass
    implements Insertable<ProductUnitsTableData> {
  final String id;
  final String productId;
  final String nama;
  final double konversi;
  final double? hargaJual;
  final bool isBase;
  const ProductUnitsTableData({
    required this.id,
    required this.productId,
    required this.nama,
    required this.konversi,
    this.hargaJual,
    required this.isBase,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['nama'] = Variable<String>(nama);
    map['konversi'] = Variable<double>(konversi);
    if (!nullToAbsent || hargaJual != null) {
      map['harga_jual'] = Variable<double>(hargaJual);
    }
    map['is_base'] = Variable<bool>(isBase);
    return map;
  }

  ProductUnitsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductUnitsTableCompanion(
      id: Value(id),
      productId: Value(productId),
      nama: Value(nama),
      konversi: Value(konversi),
      hargaJual: hargaJual == null && nullToAbsent
          ? const Value.absent()
          : Value(hargaJual),
      isBase: Value(isBase),
    );
  }

  factory ProductUnitsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductUnitsTableData(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      nama: serializer.fromJson<String>(json['nama']),
      konversi: serializer.fromJson<double>(json['konversi']),
      hargaJual: serializer.fromJson<double?>(json['hargaJual']),
      isBase: serializer.fromJson<bool>(json['isBase']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'nama': serializer.toJson<String>(nama),
      'konversi': serializer.toJson<double>(konversi),
      'hargaJual': serializer.toJson<double?>(hargaJual),
      'isBase': serializer.toJson<bool>(isBase),
    };
  }

  ProductUnitsTableData copyWith({
    String? id,
    String? productId,
    String? nama,
    double? konversi,
    Value<double?> hargaJual = const Value.absent(),
    bool? isBase,
  }) => ProductUnitsTableData(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    nama: nama ?? this.nama,
    konversi: konversi ?? this.konversi,
    hargaJual: hargaJual.present ? hargaJual.value : this.hargaJual,
    isBase: isBase ?? this.isBase,
  );
  ProductUnitsTableData copyWithCompanion(ProductUnitsTableCompanion data) {
    return ProductUnitsTableData(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      nama: data.nama.present ? data.nama.value : this.nama,
      konversi: data.konversi.present ? data.konversi.value : this.konversi,
      hargaJual: data.hargaJual.present ? data.hargaJual.value : this.hargaJual,
      isBase: data.isBase.present ? data.isBase.value : this.isBase,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductUnitsTableData(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('nama: $nama, ')
          ..write('konversi: $konversi, ')
          ..write('hargaJual: $hargaJual, ')
          ..write('isBase: $isBase')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, nama, konversi, hargaJual, isBase);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductUnitsTableData &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.nama == this.nama &&
          other.konversi == this.konversi &&
          other.hargaJual == this.hargaJual &&
          other.isBase == this.isBase);
}

class ProductUnitsTableCompanion
    extends UpdateCompanion<ProductUnitsTableData> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> nama;
  final Value<double> konversi;
  final Value<double?> hargaJual;
  final Value<bool> isBase;
  final Value<int> rowid;
  const ProductUnitsTableCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.nama = const Value.absent(),
    this.konversi = const Value.absent(),
    this.hargaJual = const Value.absent(),
    this.isBase = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductUnitsTableCompanion.insert({
    required String id,
    required String productId,
    required String nama,
    required double konversi,
    this.hargaJual = const Value.absent(),
    this.isBase = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       nama = Value(nama),
       konversi = Value(konversi);
  static Insertable<ProductUnitsTableData> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? nama,
    Expression<double>? konversi,
    Expression<double>? hargaJual,
    Expression<bool>? isBase,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (nama != null) 'nama': nama,
      if (konversi != null) 'konversi': konversi,
      if (hargaJual != null) 'harga_jual': hargaJual,
      if (isBase != null) 'is_base': isBase,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductUnitsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? nama,
    Value<double>? konversi,
    Value<double?>? hargaJual,
    Value<bool>? isBase,
    Value<int>? rowid,
  }) {
    return ProductUnitsTableCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      nama: nama ?? this.nama,
      konversi: konversi ?? this.konversi,
      hargaJual: hargaJual ?? this.hargaJual,
      isBase: isBase ?? this.isBase,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (nama.present) {
      map['nama'] = Variable<String>(nama.value);
    }
    if (konversi.present) {
      map['konversi'] = Variable<double>(konversi.value);
    }
    if (hargaJual.present) {
      map['harga_jual'] = Variable<double>(hargaJual.value);
    }
    if (isBase.present) {
      map['is_base'] = Variable<bool>(isBase.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductUnitsTableCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('nama: $nama, ')
          ..write('konversi: $konversi, ')
          ..write('hargaJual: $hargaJual, ')
          ..write('isBase: $isBase, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTableTable extends CategoriesTable
    with TableInfo<$CategoriesTableTable, CategoriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _namaKategoriMeta = const VerificationMeta(
    'namaKategori',
  );
  @override
  late final GeneratedColumn<String> namaKategori = GeneratedColumn<String>(
    'nama_kategori',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, namaKategori, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nama_kategori')) {
      context.handle(
        _namaKategoriMeta,
        namaKategori.isAcceptableOrUnknown(
          data['nama_kategori']!,
          _namaKategoriMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_namaKategoriMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoriesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoriesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      namaKategori: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama_kategori'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CategoriesTableTable createAlias(String alias) {
    return $CategoriesTableTable(attachedDatabase, alias);
  }
}

class CategoriesTableData extends DataClass
    implements Insertable<CategoriesTableData> {
  final String id;
  final String namaKategori;
  final int createdAt;
  const CategoriesTableData({
    required this.id,
    required this.namaKategori,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nama_kategori'] = Variable<String>(namaKategori);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CategoriesTableCompanion toCompanion(bool nullToAbsent) {
    return CategoriesTableCompanion(
      id: Value(id),
      namaKategori: Value(namaKategori),
      createdAt: Value(createdAt),
    );
  }

  factory CategoriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoriesTableData(
      id: serializer.fromJson<String>(json['id']),
      namaKategori: serializer.fromJson<String>(json['namaKategori']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'namaKategori': serializer.toJson<String>(namaKategori),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CategoriesTableData copyWith({
    String? id,
    String? namaKategori,
    int? createdAt,
  }) => CategoriesTableData(
    id: id ?? this.id,
    namaKategori: namaKategori ?? this.namaKategori,
    createdAt: createdAt ?? this.createdAt,
  );
  CategoriesTableData copyWithCompanion(CategoriesTableCompanion data) {
    return CategoriesTableData(
      id: data.id.present ? data.id.value : this.id,
      namaKategori: data.namaKategori.present
          ? data.namaKategori.value
          : this.namaKategori,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableData(')
          ..write('id: $id, ')
          ..write('namaKategori: $namaKategori, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, namaKategori, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoriesTableData &&
          other.id == this.id &&
          other.namaKategori == this.namaKategori &&
          other.createdAt == this.createdAt);
}

class CategoriesTableCompanion extends UpdateCompanion<CategoriesTableData> {
  final Value<String> id;
  final Value<String> namaKategori;
  final Value<int> createdAt;
  final Value<int> rowid;
  const CategoriesTableCompanion({
    this.id = const Value.absent(),
    this.namaKategori = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesTableCompanion.insert({
    required String id,
    required String namaKategori,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       namaKategori = Value(namaKategori),
       createdAt = Value(createdAt);
  static Insertable<CategoriesTableData> custom({
    Expression<String>? id,
    Expression<String>? namaKategori,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (namaKategori != null) 'nama_kategori': namaKategori,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? namaKategori,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return CategoriesTableCompanion(
      id: id ?? this.id,
      namaKategori: namaKategori ?? this.namaKategori,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (namaKategori.present) {
      map['nama_kategori'] = Variable<String>(namaKategori.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableCompanion(')
          ..write('id: $id, ')
          ..write('namaKategori: $namaKategori, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScheduleTableTable extends ScheduleTable
    with TableInfo<$ScheduleTableTable, ScheduleTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jadwalIdMeta = const VerificationMeta(
    'jadwalId',
  );
  @override
  late final GeneratedColumn<String> jadwalId = GeneratedColumn<String>(
    'jadwal_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _karyawanIdMeta = const VerificationMeta(
    'karyawanId',
  );
  @override
  late final GeneratedColumn<String> karyawanId = GeneratedColumn<String>(
    'karyawan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tanggalMeta = const VerificationMeta(
    'tanggal',
  );
  @override
  late final GeneratedColumn<String> tanggal = GeneratedColumn<String>(
    'tanggal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _divisiIdMeta = const VerificationMeta(
    'divisiId',
  );
  @override
  late final GeneratedColumn<String> divisiId = GeneratedColumn<String>(
    'divisi_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pelangganIdMeta = const VerificationMeta(
    'pelangganId',
  );
  @override
  late final GeneratedColumn<String> pelangganId = GeneratedColumn<String>(
    'pelanggan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _namaRuteMeta = const VerificationMeta(
    'namaRute',
  );
  @override
  late final GeneratedColumn<String> namaRute = GeneratedColumn<String>(
    'nama_rute',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urutanMeta = const VerificationMeta('urutan');
  @override
  late final GeneratedColumn<int> urutan = GeneratedColumn<int>(
    'urutan',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('scheduled'),
  );
  static const VerificationMeta _waktuCheckInMeta = const VerificationMeta(
    'waktuCheckIn',
  );
  @override
  late final GeneratedColumn<String> waktuCheckIn = GeneratedColumn<String>(
    'waktu_check_in',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waktuCheckOutMeta = const VerificationMeta(
    'waktuCheckOut',
  );
  @override
  late final GeneratedColumn<String> waktuCheckOut = GeneratedColumn<String>(
    'waktu_check_out',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    jadwalId,
    karyawanId,
    tanggal,
    divisiId,
    pelangganId,
    namaRute,
    urutan,
    status,
    waktuCheckIn,
    waktuCheckOut,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('jadwal_id')) {
      context.handle(
        _jadwalIdMeta,
        jadwalId.isAcceptableOrUnknown(data['jadwal_id']!, _jadwalIdMeta),
      );
    }
    if (data.containsKey('karyawan_id')) {
      context.handle(
        _karyawanIdMeta,
        karyawanId.isAcceptableOrUnknown(data['karyawan_id']!, _karyawanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_karyawanIdMeta);
    }
    if (data.containsKey('tanggal')) {
      context.handle(
        _tanggalMeta,
        tanggal.isAcceptableOrUnknown(data['tanggal']!, _tanggalMeta),
      );
    } else if (isInserting) {
      context.missing(_tanggalMeta);
    }
    if (data.containsKey('divisi_id')) {
      context.handle(
        _divisiIdMeta,
        divisiId.isAcceptableOrUnknown(data['divisi_id']!, _divisiIdMeta),
      );
    }
    if (data.containsKey('pelanggan_id')) {
      context.handle(
        _pelangganIdMeta,
        pelangganId.isAcceptableOrUnknown(
          data['pelanggan_id']!,
          _pelangganIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pelangganIdMeta);
    }
    if (data.containsKey('nama_rute')) {
      context.handle(
        _namaRuteMeta,
        namaRute.isAcceptableOrUnknown(data['nama_rute']!, _namaRuteMeta),
      );
    }
    if (data.containsKey('urutan')) {
      context.handle(
        _urutanMeta,
        urutan.isAcceptableOrUnknown(data['urutan']!, _urutanMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('waktu_check_in')) {
      context.handle(
        _waktuCheckInMeta,
        waktuCheckIn.isAcceptableOrUnknown(
          data['waktu_check_in']!,
          _waktuCheckInMeta,
        ),
      );
    }
    if (data.containsKey('waktu_check_out')) {
      context.handle(
        _waktuCheckOutMeta,
        waktuCheckOut.isAcceptableOrUnknown(
          data['waktu_check_out']!,
          _waktuCheckOutMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduleTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      jadwalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jadwal_id'],
      ),
      karyawanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}karyawan_id'],
      )!,
      tanggal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tanggal'],
      )!,
      divisiId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}divisi_id'],
      ),
      pelangganId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pelanggan_id'],
      )!,
      namaRute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama_rute'],
      ),
      urutan: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}urutan'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      waktuCheckIn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}waktu_check_in'],
      ),
      waktuCheckOut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}waktu_check_out'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ScheduleTableTable createAlias(String alias) {
    return $ScheduleTableTable(attachedDatabase, alias);
  }
}

class ScheduleTableData extends DataClass
    implements Insertable<ScheduleTableData> {
  final String id;
  final String? jadwalId;
  final String karyawanId;
  final String tanggal;
  final String? divisiId;
  final String pelangganId;
  final String? namaRute;
  final int urutan;
  final String status;
  final String? waktuCheckIn;
  final String? waktuCheckOut;
  final int createdAt;
  final int updatedAt;
  const ScheduleTableData({
    required this.id,
    this.jadwalId,
    required this.karyawanId,
    required this.tanggal,
    this.divisiId,
    required this.pelangganId,
    this.namaRute,
    required this.urutan,
    required this.status,
    this.waktuCheckIn,
    this.waktuCheckOut,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || jadwalId != null) {
      map['jadwal_id'] = Variable<String>(jadwalId);
    }
    map['karyawan_id'] = Variable<String>(karyawanId);
    map['tanggal'] = Variable<String>(tanggal);
    if (!nullToAbsent || divisiId != null) {
      map['divisi_id'] = Variable<String>(divisiId);
    }
    map['pelanggan_id'] = Variable<String>(pelangganId);
    if (!nullToAbsent || namaRute != null) {
      map['nama_rute'] = Variable<String>(namaRute);
    }
    map['urutan'] = Variable<int>(urutan);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || waktuCheckIn != null) {
      map['waktu_check_in'] = Variable<String>(waktuCheckIn);
    }
    if (!nullToAbsent || waktuCheckOut != null) {
      map['waktu_check_out'] = Variable<String>(waktuCheckOut);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ScheduleTableCompanion toCompanion(bool nullToAbsent) {
    return ScheduleTableCompanion(
      id: Value(id),
      jadwalId: jadwalId == null && nullToAbsent
          ? const Value.absent()
          : Value(jadwalId),
      karyawanId: Value(karyawanId),
      tanggal: Value(tanggal),
      divisiId: divisiId == null && nullToAbsent
          ? const Value.absent()
          : Value(divisiId),
      pelangganId: Value(pelangganId),
      namaRute: namaRute == null && nullToAbsent
          ? const Value.absent()
          : Value(namaRute),
      urutan: Value(urutan),
      status: Value(status),
      waktuCheckIn: waktuCheckIn == null && nullToAbsent
          ? const Value.absent()
          : Value(waktuCheckIn),
      waktuCheckOut: waktuCheckOut == null && nullToAbsent
          ? const Value.absent()
          : Value(waktuCheckOut),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ScheduleTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleTableData(
      id: serializer.fromJson<String>(json['id']),
      jadwalId: serializer.fromJson<String?>(json['jadwalId']),
      karyawanId: serializer.fromJson<String>(json['karyawanId']),
      tanggal: serializer.fromJson<String>(json['tanggal']),
      divisiId: serializer.fromJson<String?>(json['divisiId']),
      pelangganId: serializer.fromJson<String>(json['pelangganId']),
      namaRute: serializer.fromJson<String?>(json['namaRute']),
      urutan: serializer.fromJson<int>(json['urutan']),
      status: serializer.fromJson<String>(json['status']),
      waktuCheckIn: serializer.fromJson<String?>(json['waktuCheckIn']),
      waktuCheckOut: serializer.fromJson<String?>(json['waktuCheckOut']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jadwalId': serializer.toJson<String?>(jadwalId),
      'karyawanId': serializer.toJson<String>(karyawanId),
      'tanggal': serializer.toJson<String>(tanggal),
      'divisiId': serializer.toJson<String?>(divisiId),
      'pelangganId': serializer.toJson<String>(pelangganId),
      'namaRute': serializer.toJson<String?>(namaRute),
      'urutan': serializer.toJson<int>(urutan),
      'status': serializer.toJson<String>(status),
      'waktuCheckIn': serializer.toJson<String?>(waktuCheckIn),
      'waktuCheckOut': serializer.toJson<String?>(waktuCheckOut),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ScheduleTableData copyWith({
    String? id,
    Value<String?> jadwalId = const Value.absent(),
    String? karyawanId,
    String? tanggal,
    Value<String?> divisiId = const Value.absent(),
    String? pelangganId,
    Value<String?> namaRute = const Value.absent(),
    int? urutan,
    String? status,
    Value<String?> waktuCheckIn = const Value.absent(),
    Value<String?> waktuCheckOut = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => ScheduleTableData(
    id: id ?? this.id,
    jadwalId: jadwalId.present ? jadwalId.value : this.jadwalId,
    karyawanId: karyawanId ?? this.karyawanId,
    tanggal: tanggal ?? this.tanggal,
    divisiId: divisiId.present ? divisiId.value : this.divisiId,
    pelangganId: pelangganId ?? this.pelangganId,
    namaRute: namaRute.present ? namaRute.value : this.namaRute,
    urutan: urutan ?? this.urutan,
    status: status ?? this.status,
    waktuCheckIn: waktuCheckIn.present ? waktuCheckIn.value : this.waktuCheckIn,
    waktuCheckOut: waktuCheckOut.present
        ? waktuCheckOut.value
        : this.waktuCheckOut,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ScheduleTableData copyWithCompanion(ScheduleTableCompanion data) {
    return ScheduleTableData(
      id: data.id.present ? data.id.value : this.id,
      jadwalId: data.jadwalId.present ? data.jadwalId.value : this.jadwalId,
      karyawanId: data.karyawanId.present
          ? data.karyawanId.value
          : this.karyawanId,
      tanggal: data.tanggal.present ? data.tanggal.value : this.tanggal,
      divisiId: data.divisiId.present ? data.divisiId.value : this.divisiId,
      pelangganId: data.pelangganId.present
          ? data.pelangganId.value
          : this.pelangganId,
      namaRute: data.namaRute.present ? data.namaRute.value : this.namaRute,
      urutan: data.urutan.present ? data.urutan.value : this.urutan,
      status: data.status.present ? data.status.value : this.status,
      waktuCheckIn: data.waktuCheckIn.present
          ? data.waktuCheckIn.value
          : this.waktuCheckIn,
      waktuCheckOut: data.waktuCheckOut.present
          ? data.waktuCheckOut.value
          : this.waktuCheckOut,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleTableData(')
          ..write('id: $id, ')
          ..write('jadwalId: $jadwalId, ')
          ..write('karyawanId: $karyawanId, ')
          ..write('tanggal: $tanggal, ')
          ..write('divisiId: $divisiId, ')
          ..write('pelangganId: $pelangganId, ')
          ..write('namaRute: $namaRute, ')
          ..write('urutan: $urutan, ')
          ..write('status: $status, ')
          ..write('waktuCheckIn: $waktuCheckIn, ')
          ..write('waktuCheckOut: $waktuCheckOut, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    jadwalId,
    karyawanId,
    tanggal,
    divisiId,
    pelangganId,
    namaRute,
    urutan,
    status,
    waktuCheckIn,
    waktuCheckOut,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleTableData &&
          other.id == this.id &&
          other.jadwalId == this.jadwalId &&
          other.karyawanId == this.karyawanId &&
          other.tanggal == this.tanggal &&
          other.divisiId == this.divisiId &&
          other.pelangganId == this.pelangganId &&
          other.namaRute == this.namaRute &&
          other.urutan == this.urutan &&
          other.status == this.status &&
          other.waktuCheckIn == this.waktuCheckIn &&
          other.waktuCheckOut == this.waktuCheckOut &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ScheduleTableCompanion extends UpdateCompanion<ScheduleTableData> {
  final Value<String> id;
  final Value<String?> jadwalId;
  final Value<String> karyawanId;
  final Value<String> tanggal;
  final Value<String?> divisiId;
  final Value<String> pelangganId;
  final Value<String?> namaRute;
  final Value<int> urutan;
  final Value<String> status;
  final Value<String?> waktuCheckIn;
  final Value<String?> waktuCheckOut;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ScheduleTableCompanion({
    this.id = const Value.absent(),
    this.jadwalId = const Value.absent(),
    this.karyawanId = const Value.absent(),
    this.tanggal = const Value.absent(),
    this.divisiId = const Value.absent(),
    this.pelangganId = const Value.absent(),
    this.namaRute = const Value.absent(),
    this.urutan = const Value.absent(),
    this.status = const Value.absent(),
    this.waktuCheckIn = const Value.absent(),
    this.waktuCheckOut = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScheduleTableCompanion.insert({
    required String id,
    this.jadwalId = const Value.absent(),
    required String karyawanId,
    required String tanggal,
    this.divisiId = const Value.absent(),
    required String pelangganId,
    this.namaRute = const Value.absent(),
    this.urutan = const Value.absent(),
    this.status = const Value.absent(),
    this.waktuCheckIn = const Value.absent(),
    this.waktuCheckOut = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       karyawanId = Value(karyawanId),
       tanggal = Value(tanggal),
       pelangganId = Value(pelangganId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ScheduleTableData> custom({
    Expression<String>? id,
    Expression<String>? jadwalId,
    Expression<String>? karyawanId,
    Expression<String>? tanggal,
    Expression<String>? divisiId,
    Expression<String>? pelangganId,
    Expression<String>? namaRute,
    Expression<int>? urutan,
    Expression<String>? status,
    Expression<String>? waktuCheckIn,
    Expression<String>? waktuCheckOut,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jadwalId != null) 'jadwal_id': jadwalId,
      if (karyawanId != null) 'karyawan_id': karyawanId,
      if (tanggal != null) 'tanggal': tanggal,
      if (divisiId != null) 'divisi_id': divisiId,
      if (pelangganId != null) 'pelanggan_id': pelangganId,
      if (namaRute != null) 'nama_rute': namaRute,
      if (urutan != null) 'urutan': urutan,
      if (status != null) 'status': status,
      if (waktuCheckIn != null) 'waktu_check_in': waktuCheckIn,
      if (waktuCheckOut != null) 'waktu_check_out': waktuCheckOut,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScheduleTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? jadwalId,
    Value<String>? karyawanId,
    Value<String>? tanggal,
    Value<String?>? divisiId,
    Value<String>? pelangganId,
    Value<String?>? namaRute,
    Value<int>? urutan,
    Value<String>? status,
    Value<String?>? waktuCheckIn,
    Value<String?>? waktuCheckOut,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ScheduleTableCompanion(
      id: id ?? this.id,
      jadwalId: jadwalId ?? this.jadwalId,
      karyawanId: karyawanId ?? this.karyawanId,
      tanggal: tanggal ?? this.tanggal,
      divisiId: divisiId ?? this.divisiId,
      pelangganId: pelangganId ?? this.pelangganId,
      namaRute: namaRute ?? this.namaRute,
      urutan: urutan ?? this.urutan,
      status: status ?? this.status,
      waktuCheckIn: waktuCheckIn ?? this.waktuCheckIn,
      waktuCheckOut: waktuCheckOut ?? this.waktuCheckOut,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (jadwalId.present) {
      map['jadwal_id'] = Variable<String>(jadwalId.value);
    }
    if (karyawanId.present) {
      map['karyawan_id'] = Variable<String>(karyawanId.value);
    }
    if (tanggal.present) {
      map['tanggal'] = Variable<String>(tanggal.value);
    }
    if (divisiId.present) {
      map['divisi_id'] = Variable<String>(divisiId.value);
    }
    if (pelangganId.present) {
      map['pelanggan_id'] = Variable<String>(pelangganId.value);
    }
    if (namaRute.present) {
      map['nama_rute'] = Variable<String>(namaRute.value);
    }
    if (urutan.present) {
      map['urutan'] = Variable<int>(urutan.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (waktuCheckIn.present) {
      map['waktu_check_in'] = Variable<String>(waktuCheckIn.value);
    }
    if (waktuCheckOut.present) {
      map['waktu_check_out'] = Variable<String>(waktuCheckOut.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleTableCompanion(')
          ..write('id: $id, ')
          ..write('jadwalId: $jadwalId, ')
          ..write('karyawanId: $karyawanId, ')
          ..write('tanggal: $tanggal, ')
          ..write('divisiId: $divisiId, ')
          ..write('pelangganId: $pelangganId, ')
          ..write('namaRute: $namaRute, ')
          ..write('urutan: $urutan, ')
          ..write('status: $status, ')
          ..write('waktuCheckIn: $waktuCheckIn, ')
          ..write('waktuCheckOut: $waktuCheckOut, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PromoTableTable extends PromoTable
    with TableInfo<$PromoTableTable, PromoTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromoTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idPelangganMeta = const VerificationMeta(
    'idPelanggan',
  );
  @override
  late final GeneratedColumn<String> idPelanggan = GeneratedColumn<String>(
    'id_pelanggan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _namaCampaignMeta = const VerificationMeta(
    'namaCampaign',
  );
  @override
  late final GeneratedColumn<String> namaCampaign = GeneratedColumn<String>(
    'nama_campaign',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jenisMeta = const VerificationMeta('jenis');
  @override
  late final GeneratedColumn<String> jenis = GeneratedColumn<String>(
    'jenis',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<int> startDate = GeneratedColumn<int>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<int> endDate = GeneratedColumn<int>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    idPelanggan,
    namaCampaign,
    jenis,
    dataJson,
    status,
    startDate,
    endDate,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'promo_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PromoTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('id_pelanggan')) {
      context.handle(
        _idPelangganMeta,
        idPelanggan.isAcceptableOrUnknown(
          data['id_pelanggan']!,
          _idPelangganMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idPelangganMeta);
    }
    if (data.containsKey('nama_campaign')) {
      context.handle(
        _namaCampaignMeta,
        namaCampaign.isAcceptableOrUnknown(
          data['nama_campaign']!,
          _namaCampaignMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_namaCampaignMeta);
    }
    if (data.containsKey('jenis')) {
      context.handle(
        _jenisMeta,
        jenis.isAcceptableOrUnknown(data['jenis']!, _jenisMeta),
      );
    } else if (isInserting) {
      context.missing(_jenisMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, idPelanggan};
  @override
  PromoTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PromoTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      idPelanggan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_pelanggan'],
      )!,
      namaCampaign: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nama_campaign'],
      )!,
      jenis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jenis'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PromoTableTable createAlias(String alias) {
    return $PromoTableTable(attachedDatabase, alias);
  }
}

class PromoTableData extends DataClass implements Insertable<PromoTableData> {
  final String id;
  final String idPelanggan;
  final String namaCampaign;
  final String jenis;
  final String dataJson;
  final String status;
  final int startDate;
  final int endDate;
  final int createdAt;
  final int updatedAt;
  const PromoTableData({
    required this.id,
    required this.idPelanggan,
    required this.namaCampaign,
    required this.jenis,
    required this.dataJson,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['id_pelanggan'] = Variable<String>(idPelanggan);
    map['nama_campaign'] = Variable<String>(namaCampaign);
    map['jenis'] = Variable<String>(jenis);
    map['data_json'] = Variable<String>(dataJson);
    map['status'] = Variable<String>(status);
    map['start_date'] = Variable<int>(startDate);
    map['end_date'] = Variable<int>(endDate);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PromoTableCompanion toCompanion(bool nullToAbsent) {
    return PromoTableCompanion(
      id: Value(id),
      idPelanggan: Value(idPelanggan),
      namaCampaign: Value(namaCampaign),
      jenis: Value(jenis),
      dataJson: Value(dataJson),
      status: Value(status),
      startDate: Value(startDate),
      endDate: Value(endDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PromoTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PromoTableData(
      id: serializer.fromJson<String>(json['id']),
      idPelanggan: serializer.fromJson<String>(json['idPelanggan']),
      namaCampaign: serializer.fromJson<String>(json['namaCampaign']),
      jenis: serializer.fromJson<String>(json['jenis']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
      status: serializer.fromJson<String>(json['status']),
      startDate: serializer.fromJson<int>(json['startDate']),
      endDate: serializer.fromJson<int>(json['endDate']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'idPelanggan': serializer.toJson<String>(idPelanggan),
      'namaCampaign': serializer.toJson<String>(namaCampaign),
      'jenis': serializer.toJson<String>(jenis),
      'dataJson': serializer.toJson<String>(dataJson),
      'status': serializer.toJson<String>(status),
      'startDate': serializer.toJson<int>(startDate),
      'endDate': serializer.toJson<int>(endDate),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  PromoTableData copyWith({
    String? id,
    String? idPelanggan,
    String? namaCampaign,
    String? jenis,
    String? dataJson,
    String? status,
    int? startDate,
    int? endDate,
    int? createdAt,
    int? updatedAt,
  }) => PromoTableData(
    id: id ?? this.id,
    idPelanggan: idPelanggan ?? this.idPelanggan,
    namaCampaign: namaCampaign ?? this.namaCampaign,
    jenis: jenis ?? this.jenis,
    dataJson: dataJson ?? this.dataJson,
    status: status ?? this.status,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PromoTableData copyWithCompanion(PromoTableCompanion data) {
    return PromoTableData(
      id: data.id.present ? data.id.value : this.id,
      idPelanggan: data.idPelanggan.present
          ? data.idPelanggan.value
          : this.idPelanggan,
      namaCampaign: data.namaCampaign.present
          ? data.namaCampaign.value
          : this.namaCampaign,
      jenis: data.jenis.present ? data.jenis.value : this.jenis,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      status: data.status.present ? data.status.value : this.status,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PromoTableData(')
          ..write('id: $id, ')
          ..write('idPelanggan: $idPelanggan, ')
          ..write('namaCampaign: $namaCampaign, ')
          ..write('jenis: $jenis, ')
          ..write('dataJson: $dataJson, ')
          ..write('status: $status, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    idPelanggan,
    namaCampaign,
    jenis,
    dataJson,
    status,
    startDate,
    endDate,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PromoTableData &&
          other.id == this.id &&
          other.idPelanggan == this.idPelanggan &&
          other.namaCampaign == this.namaCampaign &&
          other.jenis == this.jenis &&
          other.dataJson == this.dataJson &&
          other.status == this.status &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PromoTableCompanion extends UpdateCompanion<PromoTableData> {
  final Value<String> id;
  final Value<String> idPelanggan;
  final Value<String> namaCampaign;
  final Value<String> jenis;
  final Value<String> dataJson;
  final Value<String> status;
  final Value<int> startDate;
  final Value<int> endDate;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const PromoTableCompanion({
    this.id = const Value.absent(),
    this.idPelanggan = const Value.absent(),
    this.namaCampaign = const Value.absent(),
    this.jenis = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.status = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PromoTableCompanion.insert({
    required String id,
    required String idPelanggan,
    required String namaCampaign,
    required String jenis,
    required String dataJson,
    this.status = const Value.absent(),
    required int startDate,
    required int endDate,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       idPelanggan = Value(idPelanggan),
       namaCampaign = Value(namaCampaign),
       jenis = Value(jenis),
       dataJson = Value(dataJson),
       startDate = Value(startDate),
       endDate = Value(endDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PromoTableData> custom({
    Expression<String>? id,
    Expression<String>? idPelanggan,
    Expression<String>? namaCampaign,
    Expression<String>? jenis,
    Expression<String>? dataJson,
    Expression<String>? status,
    Expression<int>? startDate,
    Expression<int>? endDate,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idPelanggan != null) 'id_pelanggan': idPelanggan,
      if (namaCampaign != null) 'nama_campaign': namaCampaign,
      if (jenis != null) 'jenis': jenis,
      if (dataJson != null) 'data_json': dataJson,
      if (status != null) 'status': status,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PromoTableCompanion copyWith({
    Value<String>? id,
    Value<String>? idPelanggan,
    Value<String>? namaCampaign,
    Value<String>? jenis,
    Value<String>? dataJson,
    Value<String>? status,
    Value<int>? startDate,
    Value<int>? endDate,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return PromoTableCompanion(
      id: id ?? this.id,
      idPelanggan: idPelanggan ?? this.idPelanggan,
      namaCampaign: namaCampaign ?? this.namaCampaign,
      jenis: jenis ?? this.jenis,
      dataJson: dataJson ?? this.dataJson,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (idPelanggan.present) {
      map['id_pelanggan'] = Variable<String>(idPelanggan.value);
    }
    if (namaCampaign.present) {
      map['nama_campaign'] = Variable<String>(namaCampaign.value);
    }
    if (jenis.present) {
      map['jenis'] = Variable<String>(jenis.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<int>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<int>(endDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromoTableCompanion(')
          ..write('id: $id, ')
          ..write('idPelanggan: $idPelanggan, ')
          ..write('namaCampaign: $namaCampaign, ')
          ..write('jenis: $jenis, ')
          ..write('dataJson: $dataJson, ')
          ..write('status: $status, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationsTableTable extends NotificationsTable
    with TableInfo<$NotificationsTableTable, NotificationsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _karyawanIdMeta = const VerificationMeta(
    'karyawanId',
  );
  @override
  late final GeneratedColumn<String> karyawanId = GeneratedColumn<String>(
    'karyawan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _judulMeta = const VerificationMeta('judul');
  @override
  late final GeneratedColumn<String> judul = GeneratedColumn<String>(
    'judul',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isiMeta = const VerificationMeta('isi');
  @override
  late final GeneratedColumn<String> isi = GeneratedColumn<String>(
    'isi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipeMeta = const VerificationMeta('tipe');
  @override
  late final GeneratedColumn<String> tipe = GeneratedColumn<String>(
    'tipe',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('info'),
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    karyawanId,
    judul,
    isi,
    tipe,
    isRead,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('karyawan_id')) {
      context.handle(
        _karyawanIdMeta,
        karyawanId.isAcceptableOrUnknown(data['karyawan_id']!, _karyawanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_karyawanIdMeta);
    }
    if (data.containsKey('judul')) {
      context.handle(
        _judulMeta,
        judul.isAcceptableOrUnknown(data['judul']!, _judulMeta),
      );
    } else if (isInserting) {
      context.missing(_judulMeta);
    }
    if (data.containsKey('isi')) {
      context.handle(
        _isiMeta,
        isi.isAcceptableOrUnknown(data['isi']!, _isiMeta),
      );
    } else if (isInserting) {
      context.missing(_isiMeta);
    }
    if (data.containsKey('tipe')) {
      context.handle(
        _tipeMeta,
        tipe.isAcceptableOrUnknown(data['tipe']!, _tipeMeta),
      );
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      karyawanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}karyawan_id'],
      )!,
      judul: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}judul'],
      )!,
      isi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isi'],
      )!,
      tipe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipe'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $NotificationsTableTable createAlias(String alias) {
    return $NotificationsTableTable(attachedDatabase, alias);
  }
}

class NotificationsTableData extends DataClass
    implements Insertable<NotificationsTableData> {
  final String id;
  final String karyawanId;
  final String judul;
  final String isi;
  final String tipe;
  final bool isRead;
  final int createdAt;
  const NotificationsTableData({
    required this.id,
    required this.karyawanId,
    required this.judul,
    required this.isi,
    required this.tipe,
    required this.isRead,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['karyawan_id'] = Variable<String>(karyawanId);
    map['judul'] = Variable<String>(judul);
    map['isi'] = Variable<String>(isi);
    map['tipe'] = Variable<String>(tipe);
    map['is_read'] = Variable<bool>(isRead);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  NotificationsTableCompanion toCompanion(bool nullToAbsent) {
    return NotificationsTableCompanion(
      id: Value(id),
      karyawanId: Value(karyawanId),
      judul: Value(judul),
      isi: Value(isi),
      tipe: Value(tipe),
      isRead: Value(isRead),
      createdAt: Value(createdAt),
    );
  }

  factory NotificationsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationsTableData(
      id: serializer.fromJson<String>(json['id']),
      karyawanId: serializer.fromJson<String>(json['karyawanId']),
      judul: serializer.fromJson<String>(json['judul']),
      isi: serializer.fromJson<String>(json['isi']),
      tipe: serializer.fromJson<String>(json['tipe']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'karyawanId': serializer.toJson<String>(karyawanId),
      'judul': serializer.toJson<String>(judul),
      'isi': serializer.toJson<String>(isi),
      'tipe': serializer.toJson<String>(tipe),
      'isRead': serializer.toJson<bool>(isRead),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  NotificationsTableData copyWith({
    String? id,
    String? karyawanId,
    String? judul,
    String? isi,
    String? tipe,
    bool? isRead,
    int? createdAt,
  }) => NotificationsTableData(
    id: id ?? this.id,
    karyawanId: karyawanId ?? this.karyawanId,
    judul: judul ?? this.judul,
    isi: isi ?? this.isi,
    tipe: tipe ?? this.tipe,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt ?? this.createdAt,
  );
  NotificationsTableData copyWithCompanion(NotificationsTableCompanion data) {
    return NotificationsTableData(
      id: data.id.present ? data.id.value : this.id,
      karyawanId: data.karyawanId.present
          ? data.karyawanId.value
          : this.karyawanId,
      judul: data.judul.present ? data.judul.value : this.judul,
      isi: data.isi.present ? data.isi.value : this.isi,
      tipe: data.tipe.present ? data.tipe.value : this.tipe,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsTableData(')
          ..write('id: $id, ')
          ..write('karyawanId: $karyawanId, ')
          ..write('judul: $judul, ')
          ..write('isi: $isi, ')
          ..write('tipe: $tipe, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, karyawanId, judul, isi, tipe, isRead, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationsTableData &&
          other.id == this.id &&
          other.karyawanId == this.karyawanId &&
          other.judul == this.judul &&
          other.isi == this.isi &&
          other.tipe == this.tipe &&
          other.isRead == this.isRead &&
          other.createdAt == this.createdAt);
}

class NotificationsTableCompanion
    extends UpdateCompanion<NotificationsTableData> {
  final Value<String> id;
  final Value<String> karyawanId;
  final Value<String> judul;
  final Value<String> isi;
  final Value<String> tipe;
  final Value<bool> isRead;
  final Value<int> createdAt;
  final Value<int> rowid;
  const NotificationsTableCompanion({
    this.id = const Value.absent(),
    this.karyawanId = const Value.absent(),
    this.judul = const Value.absent(),
    this.isi = const Value.absent(),
    this.tipe = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationsTableCompanion.insert({
    required String id,
    required String karyawanId,
    required String judul,
    required String isi,
    this.tipe = const Value.absent(),
    this.isRead = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       karyawanId = Value(karyawanId),
       judul = Value(judul),
       isi = Value(isi),
       createdAt = Value(createdAt);
  static Insertable<NotificationsTableData> custom({
    Expression<String>? id,
    Expression<String>? karyawanId,
    Expression<String>? judul,
    Expression<String>? isi,
    Expression<String>? tipe,
    Expression<bool>? isRead,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (karyawanId != null) 'karyawan_id': karyawanId,
      if (judul != null) 'judul': judul,
      if (isi != null) 'isi': isi,
      if (tipe != null) 'tipe': tipe,
      if (isRead != null) 'is_read': isRead,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? karyawanId,
    Value<String>? judul,
    Value<String>? isi,
    Value<String>? tipe,
    Value<bool>? isRead,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return NotificationsTableCompanion(
      id: id ?? this.id,
      karyawanId: karyawanId ?? this.karyawanId,
      judul: judul ?? this.judul,
      isi: isi ?? this.isi,
      tipe: tipe ?? this.tipe,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (karyawanId.present) {
      map['karyawan_id'] = Variable<String>(karyawanId.value);
    }
    if (judul.present) {
      map['judul'] = Variable<String>(judul.value);
    }
    if (isi.present) {
      map['isi'] = Variable<String>(isi.value);
    }
    if (tipe.present) {
      map['tipe'] = Variable<String>(tipe.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsTableCompanion(')
          ..write('id: $id, ')
          ..write('karyawanId: $karyawanId, ')
          ..write('judul: $judul, ')
          ..write('isi: $isi, ')
          ..write('tipe: $tipe, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalCacheTableTable localCacheTable = $LocalCacheTableTable(
    this,
  );
  late final $SyncMetadataTableTable syncMetadataTable =
      $SyncMetadataTableTable(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  late final $RefIdMapTableTable refIdMapTable = $RefIdMapTableTable(this);
  late final $SyncLockTableTable syncLockTable = $SyncLockTableTable(this);
  late final $CartItemsTableTable cartItemsTable = $CartItemsTableTable(this);
  late final $PromoCacheTableTable promoCacheTable = $PromoCacheTableTable(
    this,
  );
  late final $VisitsTableTable visitsTable = $VisitsTableTable(this);
  late final $OrdersTableTable ordersTable = $OrdersTableTable(this);
  late final $CustomersTableTable customersTable = $CustomersTableTable(this);
  late final $ProductsTableTable productsTable = $ProductsTableTable(this);
  late final $ProductUnitsTableTable productUnitsTable =
      $ProductUnitsTableTable(this);
  late final $CategoriesTableTable categoriesTable = $CategoriesTableTable(
    this,
  );
  late final $ScheduleTableTable scheduleTable = $ScheduleTableTable(this);
  late final $PromoTableTable promoTable = $PromoTableTable(this);
  late final $NotificationsTableTable notificationsTable =
      $NotificationsTableTable(this);
  late final CacheDao cacheDao = CacheDao(this as AppDatabase);
  late final CartDao cartDao = CartDao(this as AppDatabase);
  late final CustomerDao customerDao = CustomerDao(this as AppDatabase);
  late final NotificationDao notificationDao = NotificationDao(
    this as AppDatabase,
  );
  late final OrderDao orderDao = OrderDao(this as AppDatabase);
  late final ProductDao productDao = ProductDao(this as AppDatabase);
  late final PromoDao promoDao = PromoDao(this as AppDatabase);
  late final ReportsDao reportsDao = ReportsDao(this as AppDatabase);
  late final ScheduleDao scheduleDao = ScheduleDao(this as AppDatabase);
  late final SyncDao syncDao = SyncDao(this as AppDatabase);
  late final VisitDao visitDao = VisitDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localCacheTable,
    syncMetadataTable,
    syncQueueTable,
    refIdMapTable,
    syncLockTable,
    cartItemsTable,
    promoCacheTable,
    visitsTable,
    ordersTable,
    customersTable,
    productsTable,
    productUnitsTable,
    categoriesTable,
    scheduleTable,
    promoTable,
    notificationsTable,
  ];
}

typedef $$LocalCacheTableTableCreateCompanionBuilder =
    LocalCacheTableCompanion Function({
      Value<int> id,
      required String cacheKey,
      required String data,
      required int cachedAt,
    });
typedef $$LocalCacheTableTableUpdateCompanionBuilder =
    LocalCacheTableCompanion Function({
      Value<int> id,
      Value<String> cacheKey,
      Value<String> data,
      Value<int> cachedAt,
    });

class $$LocalCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCacheTableTable> {
  $$LocalCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCacheTableTable> {
  $$LocalCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCacheTableTable> {
  $$LocalCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$LocalCacheTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCacheTableTable,
          LocalCacheTableData,
          $$LocalCacheTableTableFilterComposer,
          $$LocalCacheTableTableOrderingComposer,
          $$LocalCacheTableTableAnnotationComposer,
          $$LocalCacheTableTableCreateCompanionBuilder,
          $$LocalCacheTableTableUpdateCompanionBuilder,
          (
            LocalCacheTableData,
            BaseReferences<
              _$AppDatabase,
              $LocalCacheTableTable,
              LocalCacheTableData
            >,
          ),
          LocalCacheTableData,
          PrefetchHooks Function()
        > {
  $$LocalCacheTableTableTableManager(
    _$AppDatabase db,
    $LocalCacheTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCacheTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> cacheKey = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
              }) => LocalCacheTableCompanion(
                id: id,
                cacheKey: cacheKey,
                data: data,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String cacheKey,
                required String data,
                required int cachedAt,
              }) => LocalCacheTableCompanion.insert(
                id: id,
                cacheKey: cacheKey,
                data: data,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCacheTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCacheTableTable,
      LocalCacheTableData,
      $$LocalCacheTableTableFilterComposer,
      $$LocalCacheTableTableOrderingComposer,
      $$LocalCacheTableTableAnnotationComposer,
      $$LocalCacheTableTableCreateCompanionBuilder,
      $$LocalCacheTableTableUpdateCompanionBuilder,
      (
        LocalCacheTableData,
        BaseReferences<
          _$AppDatabase,
          $LocalCacheTableTable,
          LocalCacheTableData
        >,
      ),
      LocalCacheTableData,
      PrefetchHooks Function()
    >;
typedef $$SyncMetadataTableTableCreateCompanionBuilder =
    SyncMetadataTableCompanion Function({
      required String resource,
      required int lastSync,
      Value<String?> lastModified,
      Value<int> rowid,
    });
typedef $$SyncMetadataTableTableUpdateCompanionBuilder =
    SyncMetadataTableCompanion Function({
      Value<String> resource,
      Value<int> lastSync,
      Value<String?> lastModified,
      Value<int> rowid,
    });

class $$SyncMetadataTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetadataTableTable> {
  $$SyncMetadataTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get resource => $composableBuilder(
    column: $table.resource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetadataTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetadataTableTable> {
  $$SyncMetadataTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get resource => $composableBuilder(
    column: $table.resource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetadataTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetadataTableTable> {
  $$SyncMetadataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get resource =>
      $composableBuilder(column: $table.resource, builder: (column) => column);

  GeneratedColumn<int> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);

  GeneratedColumn<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );
}

class $$SyncMetadataTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetadataTableTable,
          SyncMetadataTableData,
          $$SyncMetadataTableTableFilterComposer,
          $$SyncMetadataTableTableOrderingComposer,
          $$SyncMetadataTableTableAnnotationComposer,
          $$SyncMetadataTableTableCreateCompanionBuilder,
          $$SyncMetadataTableTableUpdateCompanionBuilder,
          (
            SyncMetadataTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncMetadataTableTable,
              SyncMetadataTableData
            >,
          ),
          SyncMetadataTableData,
          PrefetchHooks Function()
        > {
  $$SyncMetadataTableTableTableManager(
    _$AppDatabase db,
    $SyncMetadataTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetadataTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> resource = const Value.absent(),
                Value<int> lastSync = const Value.absent(),
                Value<String?> lastModified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataTableCompanion(
                resource: resource,
                lastSync: lastSync,
                lastModified: lastModified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String resource,
                required int lastSync,
                Value<String?> lastModified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataTableCompanion.insert(
                resource: resource,
                lastSync: lastSync,
                lastModified: lastModified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetadataTableTable,
      SyncMetadataTableData,
      $$SyncMetadataTableTableFilterComposer,
      $$SyncMetadataTableTableOrderingComposer,
      $$SyncMetadataTableTableAnnotationComposer,
      $$SyncMetadataTableTableCreateCompanionBuilder,
      $$SyncMetadataTableTableUpdateCompanionBuilder,
      (
        SyncMetadataTableData,
        BaseReferences<
          _$AppDatabase,
          $SyncMetadataTableTable,
          SyncMetadataTableData
        >,
      ),
      SyncMetadataTableData,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableTableCreateCompanionBuilder =
    SyncQueueTableCompanion Function({
      Value<int> id,
      required String localRef,
      required String operation,
      required String endpoint,
      required String method,
      required String payload,
      required int createdAt,
      Value<int> retryCount,
      Value<String> status,
      Value<String?> errorMessage,
      Value<String?> lastServerId,
      Value<int?> serverSyncedAt,
    });
typedef $$SyncQueueTableTableUpdateCompanionBuilder =
    SyncQueueTableCompanion Function({
      Value<int> id,
      Value<String> localRef,
      Value<String> operation,
      Value<String> endpoint,
      Value<String> method,
      Value<String> payload,
      Value<int> createdAt,
      Value<int> retryCount,
      Value<String> status,
      Value<String?> errorMessage,
      Value<String?> lastServerId,
      Value<int?> serverSyncedAt,
    });

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localRef => $composableBuilder(
    column: $table.localRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastServerId => $composableBuilder(
    column: $table.lastServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSyncedAt => $composableBuilder(
    column: $table.serverSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localRef => $composableBuilder(
    column: $table.localRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastServerId => $composableBuilder(
    column: $table.lastServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSyncedAt => $composableBuilder(
    column: $table.serverSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localRef =>
      $composableBuilder(column: $table.localRef, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastServerId => $composableBuilder(
    column: $table.lastServerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSyncedAt => $composableBuilder(
    column: $table.serverSyncedAt,
    builder: (column) => column,
  );
}

class $$SyncQueueTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTableTable,
          SyncQueueTableData,
          $$SyncQueueTableTableFilterComposer,
          $$SyncQueueTableTableOrderingComposer,
          $$SyncQueueTableTableAnnotationComposer,
          $$SyncQueueTableTableCreateCompanionBuilder,
          $$SyncQueueTableTableUpdateCompanionBuilder,
          (
            SyncQueueTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncQueueTableTable,
              SyncQueueTableData
            >,
          ),
          SyncQueueTableData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableTableManager(
    _$AppDatabase db,
    $SyncQueueTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> localRef = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> endpoint = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> lastServerId = const Value.absent(),
                Value<int?> serverSyncedAt = const Value.absent(),
              }) => SyncQueueTableCompanion(
                id: id,
                localRef: localRef,
                operation: operation,
                endpoint: endpoint,
                method: method,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                status: status,
                errorMessage: errorMessage,
                lastServerId: lastServerId,
                serverSyncedAt: serverSyncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String localRef,
                required String operation,
                required String endpoint,
                required String method,
                required String payload,
                required int createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> lastServerId = const Value.absent(),
                Value<int?> serverSyncedAt = const Value.absent(),
              }) => SyncQueueTableCompanion.insert(
                id: id,
                localRef: localRef,
                operation: operation,
                endpoint: endpoint,
                method: method,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                status: status,
                errorMessage: errorMessage,
                lastServerId: lastServerId,
                serverSyncedAt: serverSyncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTableTable,
      SyncQueueTableData,
      $$SyncQueueTableTableFilterComposer,
      $$SyncQueueTableTableOrderingComposer,
      $$SyncQueueTableTableAnnotationComposer,
      $$SyncQueueTableTableCreateCompanionBuilder,
      $$SyncQueueTableTableUpdateCompanionBuilder,
      (
        SyncQueueTableData,
        BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>,
      ),
      SyncQueueTableData,
      PrefetchHooks Function()
    >;
typedef $$RefIdMapTableTableCreateCompanionBuilder =
    RefIdMapTableCompanion Function({
      required String localRef,
      required String serverId,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$RefIdMapTableTableUpdateCompanionBuilder =
    RefIdMapTableCompanion Function({
      Value<String> localRef,
      Value<String> serverId,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$RefIdMapTableTableFilterComposer
    extends Composer<_$AppDatabase, $RefIdMapTableTable> {
  $$RefIdMapTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localRef => $composableBuilder(
    column: $table.localRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RefIdMapTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RefIdMapTableTable> {
  $$RefIdMapTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localRef => $composableBuilder(
    column: $table.localRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RefIdMapTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RefIdMapTableTable> {
  $$RefIdMapTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localRef =>
      $composableBuilder(column: $table.localRef, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RefIdMapTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RefIdMapTableTable,
          RefIdMapTableData,
          $$RefIdMapTableTableFilterComposer,
          $$RefIdMapTableTableOrderingComposer,
          $$RefIdMapTableTableAnnotationComposer,
          $$RefIdMapTableTableCreateCompanionBuilder,
          $$RefIdMapTableTableUpdateCompanionBuilder,
          (
            RefIdMapTableData,
            BaseReferences<
              _$AppDatabase,
              $RefIdMapTableTable,
              RefIdMapTableData
            >,
          ),
          RefIdMapTableData,
          PrefetchHooks Function()
        > {
  $$RefIdMapTableTableTableManager(_$AppDatabase db, $RefIdMapTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RefIdMapTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RefIdMapTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RefIdMapTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localRef = const Value.absent(),
                Value<String> serverId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RefIdMapTableCompanion(
                localRef: localRef,
                serverId: serverId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localRef,
                required String serverId,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => RefIdMapTableCompanion.insert(
                localRef: localRef,
                serverId: serverId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RefIdMapTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RefIdMapTableTable,
      RefIdMapTableData,
      $$RefIdMapTableTableFilterComposer,
      $$RefIdMapTableTableOrderingComposer,
      $$RefIdMapTableTableAnnotationComposer,
      $$RefIdMapTableTableCreateCompanionBuilder,
      $$RefIdMapTableTableUpdateCompanionBuilder,
      (
        RefIdMapTableData,
        BaseReferences<_$AppDatabase, $RefIdMapTableTable, RefIdMapTableData>,
      ),
      RefIdMapTableData,
      PrefetchHooks Function()
    >;
typedef $$SyncLockTableTableCreateCompanionBuilder =
    SyncLockTableCompanion Function({
      Value<int> id,
      required String lockName,
      required int acquiredAt,
      required String ownerId,
    });
typedef $$SyncLockTableTableUpdateCompanionBuilder =
    SyncLockTableCompanion Function({
      Value<int> id,
      Value<String> lockName,
      Value<int> acquiredAt,
      Value<String> ownerId,
    });

class $$SyncLockTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncLockTableTable> {
  $$SyncLockTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lockName => $composableBuilder(
    column: $table.lockName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get acquiredAt => $composableBuilder(
    column: $table.acquiredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncLockTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncLockTableTable> {
  $$SyncLockTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lockName => $composableBuilder(
    column: $table.lockName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get acquiredAt => $composableBuilder(
    column: $table.acquiredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncLockTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncLockTableTable> {
  $$SyncLockTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get lockName =>
      $composableBuilder(column: $table.lockName, builder: (column) => column);

  GeneratedColumn<int> get acquiredAt => $composableBuilder(
    column: $table.acquiredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);
}

class $$SyncLockTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncLockTableTable,
          SyncLockTableData,
          $$SyncLockTableTableFilterComposer,
          $$SyncLockTableTableOrderingComposer,
          $$SyncLockTableTableAnnotationComposer,
          $$SyncLockTableTableCreateCompanionBuilder,
          $$SyncLockTableTableUpdateCompanionBuilder,
          (
            SyncLockTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncLockTableTable,
              SyncLockTableData
            >,
          ),
          SyncLockTableData,
          PrefetchHooks Function()
        > {
  $$SyncLockTableTableTableManager(_$AppDatabase db, $SyncLockTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncLockTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncLockTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncLockTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> lockName = const Value.absent(),
                Value<int> acquiredAt = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
              }) => SyncLockTableCompanion(
                id: id,
                lockName: lockName,
                acquiredAt: acquiredAt,
                ownerId: ownerId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String lockName,
                required int acquiredAt,
                required String ownerId,
              }) => SyncLockTableCompanion.insert(
                id: id,
                lockName: lockName,
                acquiredAt: acquiredAt,
                ownerId: ownerId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncLockTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncLockTableTable,
      SyncLockTableData,
      $$SyncLockTableTableFilterComposer,
      $$SyncLockTableTableOrderingComposer,
      $$SyncLockTableTableAnnotationComposer,
      $$SyncLockTableTableCreateCompanionBuilder,
      $$SyncLockTableTableUpdateCompanionBuilder,
      (
        SyncLockTableData,
        BaseReferences<_$AppDatabase, $SyncLockTableTable, SyncLockTableData>,
      ),
      SyncLockTableData,
      PrefetchHooks Function()
    >;
typedef $$CartItemsTableTableCreateCompanionBuilder =
    CartItemsTableCompanion Function({
      Value<int> id,
      Value<String?> pelangganId,
      required String productJson,
      required String productId,
      required int quantity,
      Value<double?> negotiatedPrice,
      Value<String?> unitId,
      Value<String?> unitName,
      required int createdAt,
    });
typedef $$CartItemsTableTableUpdateCompanionBuilder =
    CartItemsTableCompanion Function({
      Value<int> id,
      Value<String?> pelangganId,
      Value<String> productJson,
      Value<String> productId,
      Value<int> quantity,
      Value<double?> negotiatedPrice,
      Value<String?> unitId,
      Value<String?> unitName,
      Value<int> createdAt,
    });

class $$CartItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CartItemsTableTable> {
  $$CartItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pelangganId => $composableBuilder(
    column: $table.pelangganId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productJson => $composableBuilder(
    column: $table.productJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get negotiatedPrice => $composableBuilder(
    column: $table.negotiatedPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitName => $composableBuilder(
    column: $table.unitName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CartItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CartItemsTableTable> {
  $$CartItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pelangganId => $composableBuilder(
    column: $table.pelangganId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productJson => $composableBuilder(
    column: $table.productJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get negotiatedPrice => $composableBuilder(
    column: $table.negotiatedPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitName => $composableBuilder(
    column: $table.unitName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CartItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CartItemsTableTable> {
  $$CartItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pelangganId => $composableBuilder(
    column: $table.pelangganId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productJson => $composableBuilder(
    column: $table.productJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get negotiatedPrice => $composableBuilder(
    column: $table.negotiatedPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => column);

  GeneratedColumn<String> get unitName =>
      $composableBuilder(column: $table.unitName, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CartItemsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CartItemsTableTable,
          CartItemsTableData,
          $$CartItemsTableTableFilterComposer,
          $$CartItemsTableTableOrderingComposer,
          $$CartItemsTableTableAnnotationComposer,
          $$CartItemsTableTableCreateCompanionBuilder,
          $$CartItemsTableTableUpdateCompanionBuilder,
          (
            CartItemsTableData,
            BaseReferences<
              _$AppDatabase,
              $CartItemsTableTable,
              CartItemsTableData
            >,
          ),
          CartItemsTableData,
          PrefetchHooks Function()
        > {
  $$CartItemsTableTableTableManager(
    _$AppDatabase db,
    $CartItemsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CartItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CartItemsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CartItemsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> pelangganId = const Value.absent(),
                Value<String> productJson = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double?> negotiatedPrice = const Value.absent(),
                Value<String?> unitId = const Value.absent(),
                Value<String?> unitName = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => CartItemsTableCompanion(
                id: id,
                pelangganId: pelangganId,
                productJson: productJson,
                productId: productId,
                quantity: quantity,
                negotiatedPrice: negotiatedPrice,
                unitId: unitId,
                unitName: unitName,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> pelangganId = const Value.absent(),
                required String productJson,
                required String productId,
                required int quantity,
                Value<double?> negotiatedPrice = const Value.absent(),
                Value<String?> unitId = const Value.absent(),
                Value<String?> unitName = const Value.absent(),
                required int createdAt,
              }) => CartItemsTableCompanion.insert(
                id: id,
                pelangganId: pelangganId,
                productJson: productJson,
                productId: productId,
                quantity: quantity,
                negotiatedPrice: negotiatedPrice,
                unitId: unitId,
                unitName: unitName,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CartItemsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CartItemsTableTable,
      CartItemsTableData,
      $$CartItemsTableTableFilterComposer,
      $$CartItemsTableTableOrderingComposer,
      $$CartItemsTableTableAnnotationComposer,
      $$CartItemsTableTableCreateCompanionBuilder,
      $$CartItemsTableTableUpdateCompanionBuilder,
      (
        CartItemsTableData,
        BaseReferences<_$AppDatabase, $CartItemsTableTable, CartItemsTableData>,
      ),
      CartItemsTableData,
      PrefetchHooks Function()
    >;
typedef $$PromoCacheTableTableCreateCompanionBuilder =
    PromoCacheTableCompanion Function({
      required String idPelanggan,
      required String data,
      required int syncedAt,
      Value<int> rowid,
    });
typedef $$PromoCacheTableTableUpdateCompanionBuilder =
    PromoCacheTableCompanion Function({
      Value<String> idPelanggan,
      Value<String> data,
      Value<int> syncedAt,
      Value<int> rowid,
    });

class $$PromoCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $PromoCacheTableTable> {
  $$PromoCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idPelanggan => $composableBuilder(
    column: $table.idPelanggan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PromoCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PromoCacheTableTable> {
  $$PromoCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idPelanggan => $composableBuilder(
    column: $table.idPelanggan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PromoCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromoCacheTableTable> {
  $$PromoCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idPelanggan => $composableBuilder(
    column: $table.idPelanggan,
    builder: (column) => column,
  );

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$PromoCacheTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PromoCacheTableTable,
          PromoCacheTableData,
          $$PromoCacheTableTableFilterComposer,
          $$PromoCacheTableTableOrderingComposer,
          $$PromoCacheTableTableAnnotationComposer,
          $$PromoCacheTableTableCreateCompanionBuilder,
          $$PromoCacheTableTableUpdateCompanionBuilder,
          (
            PromoCacheTableData,
            BaseReferences<
              _$AppDatabase,
              $PromoCacheTableTable,
              PromoCacheTableData
            >,
          ),
          PromoCacheTableData,
          PrefetchHooks Function()
        > {
  $$PromoCacheTableTableTableManager(
    _$AppDatabase db,
    $PromoCacheTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromoCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PromoCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PromoCacheTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idPelanggan = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PromoCacheTableCompanion(
                idPelanggan: idPelanggan,
                data: data,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idPelanggan,
                required String data,
                required int syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => PromoCacheTableCompanion.insert(
                idPelanggan: idPelanggan,
                data: data,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PromoCacheTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PromoCacheTableTable,
      PromoCacheTableData,
      $$PromoCacheTableTableFilterComposer,
      $$PromoCacheTableTableOrderingComposer,
      $$PromoCacheTableTableAnnotationComposer,
      $$PromoCacheTableTableCreateCompanionBuilder,
      $$PromoCacheTableTableUpdateCompanionBuilder,
      (
        PromoCacheTableData,
        BaseReferences<
          _$AppDatabase,
          $PromoCacheTableTable,
          PromoCacheTableData
        >,
      ),
      PromoCacheTableData,
      PrefetchHooks Function()
    >;
typedef $$VisitsTableTableCreateCompanionBuilder =
    VisitsTableCompanion Function({
      required String id,
      Value<int> isLocal,
      Value<String?> scheduleId,
      Value<String?> pelangganId,
      Value<String> status,
      Value<double?> latIn,
      Value<double?> longIn,
      Value<double?> latOut,
      Value<double?> longOut,
      Value<String?> waktuCheckIn,
      Value<String?> waktuCheckOut,
      Value<String?> alasanTidak,
      Value<String?> catatan,
      Value<String?> serverId,
      Value<int> photosPending,
      Value<String?> localPhotoPaths,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$VisitsTableTableUpdateCompanionBuilder =
    VisitsTableCompanion Function({
      Value<String> id,
      Value<int> isLocal,
      Value<String?> scheduleId,
      Value<String?> pelangganId,
      Value<String> status,
      Value<double?> latIn,
      Value<double?> longIn,
      Value<double?> latOut,
      Value<double?> longOut,
      Value<String?> waktuCheckIn,
      Value<String?> waktuCheckOut,
      Value<String?> alasanTidak,
      Value<String?> catatan,
      Value<String?> serverId,
      Value<int> photosPending,
      Value<String?> localPhotoPaths,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$VisitsTableTableFilterComposer
    extends Composer<_$AppDatabase, $VisitsTableTable> {
  $$VisitsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isLocal => $composableBuilder(
    column: $table.isLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pelangganId => $composableBuilder(
    column: $table.pelangganId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latIn => $composableBuilder(
    column: $table.latIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longIn => $composableBuilder(
    column: $table.longIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latOut => $composableBuilder(
    column: $table.latOut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longOut => $composableBuilder(
    column: $table.longOut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waktuCheckIn => $composableBuilder(
    column: $table.waktuCheckIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waktuCheckOut => $composableBuilder(
    column: $table.waktuCheckOut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alasanTidak => $composableBuilder(
    column: $table.alasanTidak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get photosPending => $composableBuilder(
    column: $table.photosPending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPhotoPaths => $composableBuilder(
    column: $table.localPhotoPaths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VisitsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitsTableTable> {
  $$VisitsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isLocal => $composableBuilder(
    column: $table.isLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pelangganId => $composableBuilder(
    column: $table.pelangganId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latIn => $composableBuilder(
    column: $table.latIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longIn => $composableBuilder(
    column: $table.longIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latOut => $composableBuilder(
    column: $table.latOut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longOut => $composableBuilder(
    column: $table.longOut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waktuCheckIn => $composableBuilder(
    column: $table.waktuCheckIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waktuCheckOut => $composableBuilder(
    column: $table.waktuCheckOut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alasanTidak => $composableBuilder(
    column: $table.alasanTidak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get photosPending => $composableBuilder(
    column: $table.photosPending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPhotoPaths => $composableBuilder(
    column: $table.localPhotoPaths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VisitsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitsTableTable> {
  $$VisitsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get isLocal =>
      $composableBuilder(column: $table.isLocal, builder: (column) => column);

  GeneratedColumn<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pelangganId => $composableBuilder(
    column: $table.pelangganId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get latIn =>
      $composableBuilder(column: $table.latIn, builder: (column) => column);

  GeneratedColumn<double> get longIn =>
      $composableBuilder(column: $table.longIn, builder: (column) => column);

  GeneratedColumn<double> get latOut =>
      $composableBuilder(column: $table.latOut, builder: (column) => column);

  GeneratedColumn<double> get longOut =>
      $composableBuilder(column: $table.longOut, builder: (column) => column);

  GeneratedColumn<String> get waktuCheckIn => $composableBuilder(
    column: $table.waktuCheckIn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get waktuCheckOut => $composableBuilder(
    column: $table.waktuCheckOut,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alasanTidak => $composableBuilder(
    column: $table.alasanTidak,
    builder: (column) => column,
  );

  GeneratedColumn<String> get catatan =>
      $composableBuilder(column: $table.catatan, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get photosPending => $composableBuilder(
    column: $table.photosPending,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPhotoPaths => $composableBuilder(
    column: $table.localPhotoPaths,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VisitsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitsTableTable,
          VisitsTableData,
          $$VisitsTableTableFilterComposer,
          $$VisitsTableTableOrderingComposer,
          $$VisitsTableTableAnnotationComposer,
          $$VisitsTableTableCreateCompanionBuilder,
          $$VisitsTableTableUpdateCompanionBuilder,
          (
            VisitsTableData,
            BaseReferences<_$AppDatabase, $VisitsTableTable, VisitsTableData>,
          ),
          VisitsTableData,
          PrefetchHooks Function()
        > {
  $$VisitsTableTableTableManager(_$AppDatabase db, $VisitsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> isLocal = const Value.absent(),
                Value<String?> scheduleId = const Value.absent(),
                Value<String?> pelangganId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double?> latIn = const Value.absent(),
                Value<double?> longIn = const Value.absent(),
                Value<double?> latOut = const Value.absent(),
                Value<double?> longOut = const Value.absent(),
                Value<String?> waktuCheckIn = const Value.absent(),
                Value<String?> waktuCheckOut = const Value.absent(),
                Value<String?> alasanTidak = const Value.absent(),
                Value<String?> catatan = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> photosPending = const Value.absent(),
                Value<String?> localPhotoPaths = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitsTableCompanion(
                id: id,
                isLocal: isLocal,
                scheduleId: scheduleId,
                pelangganId: pelangganId,
                status: status,
                latIn: latIn,
                longIn: longIn,
                latOut: latOut,
                longOut: longOut,
                waktuCheckIn: waktuCheckIn,
                waktuCheckOut: waktuCheckOut,
                alasanTidak: alasanTidak,
                catatan: catatan,
                serverId: serverId,
                photosPending: photosPending,
                localPhotoPaths: localPhotoPaths,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> isLocal = const Value.absent(),
                Value<String?> scheduleId = const Value.absent(),
                Value<String?> pelangganId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double?> latIn = const Value.absent(),
                Value<double?> longIn = const Value.absent(),
                Value<double?> latOut = const Value.absent(),
                Value<double?> longOut = const Value.absent(),
                Value<String?> waktuCheckIn = const Value.absent(),
                Value<String?> waktuCheckOut = const Value.absent(),
                Value<String?> alasanTidak = const Value.absent(),
                Value<String?> catatan = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> photosPending = const Value.absent(),
                Value<String?> localPhotoPaths = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VisitsTableCompanion.insert(
                id: id,
                isLocal: isLocal,
                scheduleId: scheduleId,
                pelangganId: pelangganId,
                status: status,
                latIn: latIn,
                longIn: longIn,
                latOut: latOut,
                longOut: longOut,
                waktuCheckIn: waktuCheckIn,
                waktuCheckOut: waktuCheckOut,
                alasanTidak: alasanTidak,
                catatan: catatan,
                serverId: serverId,
                photosPending: photosPending,
                localPhotoPaths: localPhotoPaths,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VisitsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitsTableTable,
      VisitsTableData,
      $$VisitsTableTableFilterComposer,
      $$VisitsTableTableOrderingComposer,
      $$VisitsTableTableAnnotationComposer,
      $$VisitsTableTableCreateCompanionBuilder,
      $$VisitsTableTableUpdateCompanionBuilder,
      (
        VisitsTableData,
        BaseReferences<_$AppDatabase, $VisitsTableTable, VisitsTableData>,
      ),
      VisitsTableData,
      PrefetchHooks Function()
    >;
typedef $$OrdersTableTableCreateCompanionBuilder =
    OrdersTableCompanion Function({
      required String id,
      Value<int> isLocal,
      Value<String?> kunjunganId,
      Value<String?> pelangganId,
      Value<String> status,
      required String itemsJson,
      Value<String?> notes,
      Value<String?> promosJson,
      Value<double> totalTagihan,
      Value<String?> serverId,
      Value<String?> clientRef,
      required int createdAt,
      required int updatedAt,
      required int tanggalTransaksi,
      Value<String?> noPesanan,
      Value<int> rowid,
    });
typedef $$OrdersTableTableUpdateCompanionBuilder =
    OrdersTableCompanion Function({
      Value<String> id,
      Value<int> isLocal,
      Value<String?> kunjunganId,
      Value<String?> pelangganId,
      Value<String> status,
      Value<String> itemsJson,
      Value<String?> notes,
      Value<String?> promosJson,
      Value<double> totalTagihan,
      Value<String?> serverId,
      Value<String?> clientRef,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> tanggalTransaksi,
      Value<String?> noPesanan,
      Value<int> rowid,
    });

class $$OrdersTableTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTableTable> {
  $$OrdersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isLocal => $composableBuilder(
    column: $table.isLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kunjunganId => $composableBuilder(
    column: $table.kunjunganId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pelangganId => $composableBuilder(
    column: $table.pelangganId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promosJson => $composableBuilder(
    column: $table.promosJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalTagihan => $composableBuilder(
    column: $table.totalTagihan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientRef => $composableBuilder(
    column: $table.clientRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tanggalTransaksi => $composableBuilder(
    column: $table.tanggalTransaksi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noPesanan => $composableBuilder(
    column: $table.noPesanan,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrdersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTableTable> {
  $$OrdersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isLocal => $composableBuilder(
    column: $table.isLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kunjunganId => $composableBuilder(
    column: $table.kunjunganId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pelangganId => $composableBuilder(
    column: $table.pelangganId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promosJson => $composableBuilder(
    column: $table.promosJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalTagihan => $composableBuilder(
    column: $table.totalTagihan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientRef => $composableBuilder(
    column: $table.clientRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tanggalTransaksi => $composableBuilder(
    column: $table.tanggalTransaksi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noPesanan => $composableBuilder(
    column: $table.noPesanan,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrdersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTableTable> {
  $$OrdersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get isLocal =>
      $composableBuilder(column: $table.isLocal, builder: (column) => column);

  GeneratedColumn<String> get kunjunganId => $composableBuilder(
    column: $table.kunjunganId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pelangganId => $composableBuilder(
    column: $table.pelangganId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get promosJson => $composableBuilder(
    column: $table.promosJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalTagihan => $composableBuilder(
    column: $table.totalTagihan,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get clientRef =>
      $composableBuilder(column: $table.clientRef, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get tanggalTransaksi => $composableBuilder(
    column: $table.tanggalTransaksi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get noPesanan =>
      $composableBuilder(column: $table.noPesanan, builder: (column) => column);
}

class $$OrdersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdersTableTable,
          OrdersTableData,
          $$OrdersTableTableFilterComposer,
          $$OrdersTableTableOrderingComposer,
          $$OrdersTableTableAnnotationComposer,
          $$OrdersTableTableCreateCompanionBuilder,
          $$OrdersTableTableUpdateCompanionBuilder,
          (
            OrdersTableData,
            BaseReferences<_$AppDatabase, $OrdersTableTable, OrdersTableData>,
          ),
          OrdersTableData,
          PrefetchHooks Function()
        > {
  $$OrdersTableTableTableManager(_$AppDatabase db, $OrdersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> isLocal = const Value.absent(),
                Value<String?> kunjunganId = const Value.absent(),
                Value<String?> pelangganId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> promosJson = const Value.absent(),
                Value<double> totalTagihan = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> clientRef = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> tanggalTransaksi = const Value.absent(),
                Value<String?> noPesanan = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersTableCompanion(
                id: id,
                isLocal: isLocal,
                kunjunganId: kunjunganId,
                pelangganId: pelangganId,
                status: status,
                itemsJson: itemsJson,
                notes: notes,
                promosJson: promosJson,
                totalTagihan: totalTagihan,
                serverId: serverId,
                clientRef: clientRef,
                createdAt: createdAt,
                updatedAt: updatedAt,
                tanggalTransaksi: tanggalTransaksi,
                noPesanan: noPesanan,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> isLocal = const Value.absent(),
                Value<String?> kunjunganId = const Value.absent(),
                Value<String?> pelangganId = const Value.absent(),
                Value<String> status = const Value.absent(),
                required String itemsJson,
                Value<String?> notes = const Value.absent(),
                Value<String?> promosJson = const Value.absent(),
                Value<double> totalTagihan = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> clientRef = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                required int tanggalTransaksi,
                Value<String?> noPesanan = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersTableCompanion.insert(
                id: id,
                isLocal: isLocal,
                kunjunganId: kunjunganId,
                pelangganId: pelangganId,
                status: status,
                itemsJson: itemsJson,
                notes: notes,
                promosJson: promosJson,
                totalTagihan: totalTagihan,
                serverId: serverId,
                clientRef: clientRef,
                createdAt: createdAt,
                updatedAt: updatedAt,
                tanggalTransaksi: tanggalTransaksi,
                noPesanan: noPesanan,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrdersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdersTableTable,
      OrdersTableData,
      $$OrdersTableTableFilterComposer,
      $$OrdersTableTableOrderingComposer,
      $$OrdersTableTableAnnotationComposer,
      $$OrdersTableTableCreateCompanionBuilder,
      $$OrdersTableTableUpdateCompanionBuilder,
      (
        OrdersTableData,
        BaseReferences<_$AppDatabase, $OrdersTableTable, OrdersTableData>,
      ),
      OrdersTableData,
      PrefetchHooks Function()
    >;
typedef $$CustomersTableTableCreateCompanionBuilder =
    CustomersTableCompanion Function({
      required String id,
      Value<int> isLocal,
      Value<String?> serverId,
      Value<String?> clientRef,
      Value<String?> kodePelanggan,
      Value<String?> namaToko,
      Value<String?> namaPemilik,
      Value<String?> noHpPribadi,
      Value<String?> alamatUsaha,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> status,
      Value<String?> fotoTokoPath,
      Value<String?> fotoKtpPath,
      Value<String?> noKtpPemilik,
      Value<String?> sistemPembayaran,
      Value<String?> caraPembayaran,
      Value<String?> namaBank,
      Value<String?> cabangBank,
      Value<String?> noRekening,
      Value<String?> atasNamaRekening,
      Value<int?> topHari,
      Value<double?> limitKreditAwal,
      Value<String?> kotaUsaha,
      Value<String?> kecamatanUsaha,
      Value<String?> provinsiUsaha,
      Value<String?> dataJson,
      Value<String?> createdById,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$CustomersTableTableUpdateCompanionBuilder =
    CustomersTableCompanion Function({
      Value<String> id,
      Value<int> isLocal,
      Value<String?> serverId,
      Value<String?> clientRef,
      Value<String?> kodePelanggan,
      Value<String?> namaToko,
      Value<String?> namaPemilik,
      Value<String?> noHpPribadi,
      Value<String?> alamatUsaha,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> status,
      Value<String?> fotoTokoPath,
      Value<String?> fotoKtpPath,
      Value<String?> noKtpPemilik,
      Value<String?> sistemPembayaran,
      Value<String?> caraPembayaran,
      Value<String?> namaBank,
      Value<String?> cabangBank,
      Value<String?> noRekening,
      Value<String?> atasNamaRekening,
      Value<int?> topHari,
      Value<double?> limitKreditAwal,
      Value<String?> kotaUsaha,
      Value<String?> kecamatanUsaha,
      Value<String?> provinsiUsaha,
      Value<String?> dataJson,
      Value<String?> createdById,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$CustomersTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isLocal => $composableBuilder(
    column: $table.isLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientRef => $composableBuilder(
    column: $table.clientRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kodePelanggan => $composableBuilder(
    column: $table.kodePelanggan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namaToko => $composableBuilder(
    column: $table.namaToko,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namaPemilik => $composableBuilder(
    column: $table.namaPemilik,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noHpPribadi => $composableBuilder(
    column: $table.noHpPribadi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alamatUsaha => $composableBuilder(
    column: $table.alamatUsaha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fotoTokoPath => $composableBuilder(
    column: $table.fotoTokoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fotoKtpPath => $composableBuilder(
    column: $table.fotoKtpPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noKtpPemilik => $composableBuilder(
    column: $table.noKtpPemilik,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sistemPembayaran => $composableBuilder(
    column: $table.sistemPembayaran,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caraPembayaran => $composableBuilder(
    column: $table.caraPembayaran,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namaBank => $composableBuilder(
    column: $table.namaBank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cabangBank => $composableBuilder(
    column: $table.cabangBank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noRekening => $composableBuilder(
    column: $table.noRekening,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get atasNamaRekening => $composableBuilder(
    column: $table.atasNamaRekening,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get topHari => $composableBuilder(
    column: $table.topHari,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get limitKreditAwal => $composableBuilder(
    column: $table.limitKreditAwal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kotaUsaha => $composableBuilder(
    column: $table.kotaUsaha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kecamatanUsaha => $composableBuilder(
    column: $table.kecamatanUsaha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provinsiUsaha => $composableBuilder(
    column: $table.provinsiUsaha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isLocal => $composableBuilder(
    column: $table.isLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientRef => $composableBuilder(
    column: $table.clientRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kodePelanggan => $composableBuilder(
    column: $table.kodePelanggan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namaToko => $composableBuilder(
    column: $table.namaToko,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namaPemilik => $composableBuilder(
    column: $table.namaPemilik,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noHpPribadi => $composableBuilder(
    column: $table.noHpPribadi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alamatUsaha => $composableBuilder(
    column: $table.alamatUsaha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fotoTokoPath => $composableBuilder(
    column: $table.fotoTokoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fotoKtpPath => $composableBuilder(
    column: $table.fotoKtpPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noKtpPemilik => $composableBuilder(
    column: $table.noKtpPemilik,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sistemPembayaran => $composableBuilder(
    column: $table.sistemPembayaran,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caraPembayaran => $composableBuilder(
    column: $table.caraPembayaran,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namaBank => $composableBuilder(
    column: $table.namaBank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cabangBank => $composableBuilder(
    column: $table.cabangBank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noRekening => $composableBuilder(
    column: $table.noRekening,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get atasNamaRekening => $composableBuilder(
    column: $table.atasNamaRekening,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get topHari => $composableBuilder(
    column: $table.topHari,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get limitKreditAwal => $composableBuilder(
    column: $table.limitKreditAwal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kotaUsaha => $composableBuilder(
    column: $table.kotaUsaha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kecamatanUsaha => $composableBuilder(
    column: $table.kecamatanUsaha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provinsiUsaha => $composableBuilder(
    column: $table.provinsiUsaha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get isLocal =>
      $composableBuilder(column: $table.isLocal, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get clientRef =>
      $composableBuilder(column: $table.clientRef, builder: (column) => column);

  GeneratedColumn<String> get kodePelanggan => $composableBuilder(
    column: $table.kodePelanggan,
    builder: (column) => column,
  );

  GeneratedColumn<String> get namaToko =>
      $composableBuilder(column: $table.namaToko, builder: (column) => column);

  GeneratedColumn<String> get namaPemilik => $composableBuilder(
    column: $table.namaPemilik,
    builder: (column) => column,
  );

  GeneratedColumn<String> get noHpPribadi => $composableBuilder(
    column: $table.noHpPribadi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alamatUsaha => $composableBuilder(
    column: $table.alamatUsaha,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get fotoTokoPath => $composableBuilder(
    column: $table.fotoTokoPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fotoKtpPath => $composableBuilder(
    column: $table.fotoKtpPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get noKtpPemilik => $composableBuilder(
    column: $table.noKtpPemilik,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sistemPembayaran => $composableBuilder(
    column: $table.sistemPembayaran,
    builder: (column) => column,
  );

  GeneratedColumn<String> get caraPembayaran => $composableBuilder(
    column: $table.caraPembayaran,
    builder: (column) => column,
  );

  GeneratedColumn<String> get namaBank =>
      $composableBuilder(column: $table.namaBank, builder: (column) => column);

  GeneratedColumn<String> get cabangBank => $composableBuilder(
    column: $table.cabangBank,
    builder: (column) => column,
  );

  GeneratedColumn<String> get noRekening => $composableBuilder(
    column: $table.noRekening,
    builder: (column) => column,
  );

  GeneratedColumn<String> get atasNamaRekening => $composableBuilder(
    column: $table.atasNamaRekening,
    builder: (column) => column,
  );

  GeneratedColumn<int> get topHari =>
      $composableBuilder(column: $table.topHari, builder: (column) => column);

  GeneratedColumn<double> get limitKreditAwal => $composableBuilder(
    column: $table.limitKreditAwal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kotaUsaha =>
      $composableBuilder(column: $table.kotaUsaha, builder: (column) => column);

  GeneratedColumn<String> get kecamatanUsaha => $composableBuilder(
    column: $table.kecamatanUsaha,
    builder: (column) => column,
  );

  GeneratedColumn<String> get provinsiUsaha => $composableBuilder(
    column: $table.provinsiUsaha,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<String> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CustomersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTableTable,
          CustomersTableData,
          $$CustomersTableTableFilterComposer,
          $$CustomersTableTableOrderingComposer,
          $$CustomersTableTableAnnotationComposer,
          $$CustomersTableTableCreateCompanionBuilder,
          $$CustomersTableTableUpdateCompanionBuilder,
          (
            CustomersTableData,
            BaseReferences<
              _$AppDatabase,
              $CustomersTableTable,
              CustomersTableData
            >,
          ),
          CustomersTableData,
          PrefetchHooks Function()
        > {
  $$CustomersTableTableTableManager(
    _$AppDatabase db,
    $CustomersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> isLocal = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> clientRef = const Value.absent(),
                Value<String?> kodePelanggan = const Value.absent(),
                Value<String?> namaToko = const Value.absent(),
                Value<String?> namaPemilik = const Value.absent(),
                Value<String?> noHpPribadi = const Value.absent(),
                Value<String?> alamatUsaha = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> fotoTokoPath = const Value.absent(),
                Value<String?> fotoKtpPath = const Value.absent(),
                Value<String?> noKtpPemilik = const Value.absent(),
                Value<String?> sistemPembayaran = const Value.absent(),
                Value<String?> caraPembayaran = const Value.absent(),
                Value<String?> namaBank = const Value.absent(),
                Value<String?> cabangBank = const Value.absent(),
                Value<String?> noRekening = const Value.absent(),
                Value<String?> atasNamaRekening = const Value.absent(),
                Value<int?> topHari = const Value.absent(),
                Value<double?> limitKreditAwal = const Value.absent(),
                Value<String?> kotaUsaha = const Value.absent(),
                Value<String?> kecamatanUsaha = const Value.absent(),
                Value<String?> provinsiUsaha = const Value.absent(),
                Value<String?> dataJson = const Value.absent(),
                Value<String?> createdById = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersTableCompanion(
                id: id,
                isLocal: isLocal,
                serverId: serverId,
                clientRef: clientRef,
                kodePelanggan: kodePelanggan,
                namaToko: namaToko,
                namaPemilik: namaPemilik,
                noHpPribadi: noHpPribadi,
                alamatUsaha: alamatUsaha,
                latitude: latitude,
                longitude: longitude,
                status: status,
                fotoTokoPath: fotoTokoPath,
                fotoKtpPath: fotoKtpPath,
                noKtpPemilik: noKtpPemilik,
                sistemPembayaran: sistemPembayaran,
                caraPembayaran: caraPembayaran,
                namaBank: namaBank,
                cabangBank: cabangBank,
                noRekening: noRekening,
                atasNamaRekening: atasNamaRekening,
                topHari: topHari,
                limitKreditAwal: limitKreditAwal,
                kotaUsaha: kotaUsaha,
                kecamatanUsaha: kecamatanUsaha,
                provinsiUsaha: provinsiUsaha,
                dataJson: dataJson,
                createdById: createdById,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> isLocal = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> clientRef = const Value.absent(),
                Value<String?> kodePelanggan = const Value.absent(),
                Value<String?> namaToko = const Value.absent(),
                Value<String?> namaPemilik = const Value.absent(),
                Value<String?> noHpPribadi = const Value.absent(),
                Value<String?> alamatUsaha = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> fotoTokoPath = const Value.absent(),
                Value<String?> fotoKtpPath = const Value.absent(),
                Value<String?> noKtpPemilik = const Value.absent(),
                Value<String?> sistemPembayaran = const Value.absent(),
                Value<String?> caraPembayaran = const Value.absent(),
                Value<String?> namaBank = const Value.absent(),
                Value<String?> cabangBank = const Value.absent(),
                Value<String?> noRekening = const Value.absent(),
                Value<String?> atasNamaRekening = const Value.absent(),
                Value<int?> topHari = const Value.absent(),
                Value<double?> limitKreditAwal = const Value.absent(),
                Value<String?> kotaUsaha = const Value.absent(),
                Value<String?> kecamatanUsaha = const Value.absent(),
                Value<String?> provinsiUsaha = const Value.absent(),
                Value<String?> dataJson = const Value.absent(),
                Value<String?> createdById = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CustomersTableCompanion.insert(
                id: id,
                isLocal: isLocal,
                serverId: serverId,
                clientRef: clientRef,
                kodePelanggan: kodePelanggan,
                namaToko: namaToko,
                namaPemilik: namaPemilik,
                noHpPribadi: noHpPribadi,
                alamatUsaha: alamatUsaha,
                latitude: latitude,
                longitude: longitude,
                status: status,
                fotoTokoPath: fotoTokoPath,
                fotoKtpPath: fotoKtpPath,
                noKtpPemilik: noKtpPemilik,
                sistemPembayaran: sistemPembayaran,
                caraPembayaran: caraPembayaran,
                namaBank: namaBank,
                cabangBank: cabangBank,
                noRekening: noRekening,
                atasNamaRekening: atasNamaRekening,
                topHari: topHari,
                limitKreditAwal: limitKreditAwal,
                kotaUsaha: kotaUsaha,
                kecamatanUsaha: kecamatanUsaha,
                provinsiUsaha: provinsiUsaha,
                dataJson: dataJson,
                createdById: createdById,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTableTable,
      CustomersTableData,
      $$CustomersTableTableFilterComposer,
      $$CustomersTableTableOrderingComposer,
      $$CustomersTableTableAnnotationComposer,
      $$CustomersTableTableCreateCompanionBuilder,
      $$CustomersTableTableUpdateCompanionBuilder,
      (
        CustomersTableData,
        BaseReferences<_$AppDatabase, $CustomersTableTable, CustomersTableData>,
      ),
      CustomersTableData,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableTableCreateCompanionBuilder =
    ProductsTableCompanion Function({
      required String id,
      Value<String?> perusahaanId,
      Value<String?> sku,
      Value<String?> kodeBarang,
      required String namaProduk,
      Value<String?> kategoriId,
      Value<String?> kategori,
      Value<String?> satuan,
      Value<String?> deskripsi,
      Value<double?> hargaDasar,
      Value<double?> hargaJual,
      Value<int> stokTersedia,
      Value<String?> gambarUrl,
      Value<String> status,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$ProductsTableTableUpdateCompanionBuilder =
    ProductsTableCompanion Function({
      Value<String> id,
      Value<String?> perusahaanId,
      Value<String?> sku,
      Value<String?> kodeBarang,
      Value<String> namaProduk,
      Value<String?> kategoriId,
      Value<String?> kategori,
      Value<String?> satuan,
      Value<String?> deskripsi,
      Value<double?> hargaDasar,
      Value<double?> hargaJual,
      Value<int> stokTersedia,
      Value<String?> gambarUrl,
      Value<String> status,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$ProductsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get perusahaanId => $composableBuilder(
    column: $table.perusahaanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kodeBarang => $composableBuilder(
    column: $table.kodeBarang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namaProduk => $composableBuilder(
    column: $table.namaProduk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kategoriId => $composableBuilder(
    column: $table.kategoriId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kategori => $composableBuilder(
    column: $table.kategori,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get satuan => $composableBuilder(
    column: $table.satuan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deskripsi => $composableBuilder(
    column: $table.deskripsi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hargaDasar => $composableBuilder(
    column: $table.hargaDasar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hargaJual => $composableBuilder(
    column: $table.hargaJual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stokTersedia => $composableBuilder(
    column: $table.stokTersedia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gambarUrl => $composableBuilder(
    column: $table.gambarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get perusahaanId => $composableBuilder(
    column: $table.perusahaanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kodeBarang => $composableBuilder(
    column: $table.kodeBarang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namaProduk => $composableBuilder(
    column: $table.namaProduk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kategoriId => $composableBuilder(
    column: $table.kategoriId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kategori => $composableBuilder(
    column: $table.kategori,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get satuan => $composableBuilder(
    column: $table.satuan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deskripsi => $composableBuilder(
    column: $table.deskripsi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hargaDasar => $composableBuilder(
    column: $table.hargaDasar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hargaJual => $composableBuilder(
    column: $table.hargaJual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stokTersedia => $composableBuilder(
    column: $table.stokTersedia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gambarUrl => $composableBuilder(
    column: $table.gambarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get perusahaanId => $composableBuilder(
    column: $table.perusahaanId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get kodeBarang => $composableBuilder(
    column: $table.kodeBarang,
    builder: (column) => column,
  );

  GeneratedColumn<String> get namaProduk => $composableBuilder(
    column: $table.namaProduk,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kategoriId => $composableBuilder(
    column: $table.kategoriId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kategori =>
      $composableBuilder(column: $table.kategori, builder: (column) => column);

  GeneratedColumn<String> get satuan =>
      $composableBuilder(column: $table.satuan, builder: (column) => column);

  GeneratedColumn<String> get deskripsi =>
      $composableBuilder(column: $table.deskripsi, builder: (column) => column);

  GeneratedColumn<double> get hargaDasar => $composableBuilder(
    column: $table.hargaDasar,
    builder: (column) => column,
  );

  GeneratedColumn<double> get hargaJual =>
      $composableBuilder(column: $table.hargaJual, builder: (column) => column);

  GeneratedColumn<int> get stokTersedia => $composableBuilder(
    column: $table.stokTersedia,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gambarUrl =>
      $composableBuilder(column: $table.gambarUrl, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTableTable,
          ProductsTableData,
          $$ProductsTableTableFilterComposer,
          $$ProductsTableTableOrderingComposer,
          $$ProductsTableTableAnnotationComposer,
          $$ProductsTableTableCreateCompanionBuilder,
          $$ProductsTableTableUpdateCompanionBuilder,
          (
            ProductsTableData,
            BaseReferences<
              _$AppDatabase,
              $ProductsTableTable,
              ProductsTableData
            >,
          ),
          ProductsTableData,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableTableManager(_$AppDatabase db, $ProductsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> perusahaanId = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> kodeBarang = const Value.absent(),
                Value<String> namaProduk = const Value.absent(),
                Value<String?> kategoriId = const Value.absent(),
                Value<String?> kategori = const Value.absent(),
                Value<String?> satuan = const Value.absent(),
                Value<String?> deskripsi = const Value.absent(),
                Value<double?> hargaDasar = const Value.absent(),
                Value<double?> hargaJual = const Value.absent(),
                Value<int> stokTersedia = const Value.absent(),
                Value<String?> gambarUrl = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion(
                id: id,
                perusahaanId: perusahaanId,
                sku: sku,
                kodeBarang: kodeBarang,
                namaProduk: namaProduk,
                kategoriId: kategoriId,
                kategori: kategori,
                satuan: satuan,
                deskripsi: deskripsi,
                hargaDasar: hargaDasar,
                hargaJual: hargaJual,
                stokTersedia: stokTersedia,
                gambarUrl: gambarUrl,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> perusahaanId = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> kodeBarang = const Value.absent(),
                required String namaProduk,
                Value<String?> kategoriId = const Value.absent(),
                Value<String?> kategori = const Value.absent(),
                Value<String?> satuan = const Value.absent(),
                Value<String?> deskripsi = const Value.absent(),
                Value<double?> hargaDasar = const Value.absent(),
                Value<double?> hargaJual = const Value.absent(),
                Value<int> stokTersedia = const Value.absent(),
                Value<String?> gambarUrl = const Value.absent(),
                Value<String> status = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion.insert(
                id: id,
                perusahaanId: perusahaanId,
                sku: sku,
                kodeBarang: kodeBarang,
                namaProduk: namaProduk,
                kategoriId: kategoriId,
                kategori: kategori,
                satuan: satuan,
                deskripsi: deskripsi,
                hargaDasar: hargaDasar,
                hargaJual: hargaJual,
                stokTersedia: stokTersedia,
                gambarUrl: gambarUrl,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTableTable,
      ProductsTableData,
      $$ProductsTableTableFilterComposer,
      $$ProductsTableTableOrderingComposer,
      $$ProductsTableTableAnnotationComposer,
      $$ProductsTableTableCreateCompanionBuilder,
      $$ProductsTableTableUpdateCompanionBuilder,
      (
        ProductsTableData,
        BaseReferences<_$AppDatabase, $ProductsTableTable, ProductsTableData>,
      ),
      ProductsTableData,
      PrefetchHooks Function()
    >;
typedef $$ProductUnitsTableTableCreateCompanionBuilder =
    ProductUnitsTableCompanion Function({
      required String id,
      required String productId,
      required String nama,
      required double konversi,
      Value<double?> hargaJual,
      Value<bool> isBase,
      Value<int> rowid,
    });
typedef $$ProductUnitsTableTableUpdateCompanionBuilder =
    ProductUnitsTableCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> nama,
      Value<double> konversi,
      Value<double?> hargaJual,
      Value<bool> isBase,
      Value<int> rowid,
    });

class $$ProductUnitsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductUnitsTableTable> {
  $$ProductUnitsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nama => $composableBuilder(
    column: $table.nama,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get konversi => $composableBuilder(
    column: $table.konversi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hargaJual => $composableBuilder(
    column: $table.hargaJual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBase => $composableBuilder(
    column: $table.isBase,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductUnitsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductUnitsTableTable> {
  $$ProductUnitsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nama => $composableBuilder(
    column: $table.nama,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get konversi => $composableBuilder(
    column: $table.konversi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hargaJual => $composableBuilder(
    column: $table.hargaJual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBase => $composableBuilder(
    column: $table.isBase,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductUnitsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductUnitsTableTable> {
  $$ProductUnitsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get nama =>
      $composableBuilder(column: $table.nama, builder: (column) => column);

  GeneratedColumn<double> get konversi =>
      $composableBuilder(column: $table.konversi, builder: (column) => column);

  GeneratedColumn<double> get hargaJual =>
      $composableBuilder(column: $table.hargaJual, builder: (column) => column);

  GeneratedColumn<bool> get isBase =>
      $composableBuilder(column: $table.isBase, builder: (column) => column);
}

class $$ProductUnitsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductUnitsTableTable,
          ProductUnitsTableData,
          $$ProductUnitsTableTableFilterComposer,
          $$ProductUnitsTableTableOrderingComposer,
          $$ProductUnitsTableTableAnnotationComposer,
          $$ProductUnitsTableTableCreateCompanionBuilder,
          $$ProductUnitsTableTableUpdateCompanionBuilder,
          (
            ProductUnitsTableData,
            BaseReferences<
              _$AppDatabase,
              $ProductUnitsTableTable,
              ProductUnitsTableData
            >,
          ),
          ProductUnitsTableData,
          PrefetchHooks Function()
        > {
  $$ProductUnitsTableTableTableManager(
    _$AppDatabase db,
    $ProductUnitsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductUnitsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductUnitsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductUnitsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> nama = const Value.absent(),
                Value<double> konversi = const Value.absent(),
                Value<double?> hargaJual = const Value.absent(),
                Value<bool> isBase = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductUnitsTableCompanion(
                id: id,
                productId: productId,
                nama: nama,
                konversi: konversi,
                hargaJual: hargaJual,
                isBase: isBase,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String nama,
                required double konversi,
                Value<double?> hargaJual = const Value.absent(),
                Value<bool> isBase = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductUnitsTableCompanion.insert(
                id: id,
                productId: productId,
                nama: nama,
                konversi: konversi,
                hargaJual: hargaJual,
                isBase: isBase,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductUnitsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductUnitsTableTable,
      ProductUnitsTableData,
      $$ProductUnitsTableTableFilterComposer,
      $$ProductUnitsTableTableOrderingComposer,
      $$ProductUnitsTableTableAnnotationComposer,
      $$ProductUnitsTableTableCreateCompanionBuilder,
      $$ProductUnitsTableTableUpdateCompanionBuilder,
      (
        ProductUnitsTableData,
        BaseReferences<
          _$AppDatabase,
          $ProductUnitsTableTable,
          ProductUnitsTableData
        >,
      ),
      ProductUnitsTableData,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableTableCreateCompanionBuilder =
    CategoriesTableCompanion Function({
      required String id,
      required String namaKategori,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$CategoriesTableTableUpdateCompanionBuilder =
    CategoriesTableCompanion Function({
      Value<String> id,
      Value<String> namaKategori,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$CategoriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namaKategori => $composableBuilder(
    column: $table.namaKategori,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namaKategori => $composableBuilder(
    column: $table.namaKategori,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get namaKategori => $composableBuilder(
    column: $table.namaKategori,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CategoriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTableTable,
          CategoriesTableData,
          $$CategoriesTableTableFilterComposer,
          $$CategoriesTableTableOrderingComposer,
          $$CategoriesTableTableAnnotationComposer,
          $$CategoriesTableTableCreateCompanionBuilder,
          $$CategoriesTableTableUpdateCompanionBuilder,
          (
            CategoriesTableData,
            BaseReferences<
              _$AppDatabase,
              $CategoriesTableTable,
              CategoriesTableData
            >,
          ),
          CategoriesTableData,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableTableManager(
    _$AppDatabase db,
    $CategoriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> namaKategori = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesTableCompanion(
                id: id,
                namaKategori: namaKategori,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String namaKategori,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesTableCompanion.insert(
                id: id,
                namaKategori: namaKategori,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTableTable,
      CategoriesTableData,
      $$CategoriesTableTableFilterComposer,
      $$CategoriesTableTableOrderingComposer,
      $$CategoriesTableTableAnnotationComposer,
      $$CategoriesTableTableCreateCompanionBuilder,
      $$CategoriesTableTableUpdateCompanionBuilder,
      (
        CategoriesTableData,
        BaseReferences<
          _$AppDatabase,
          $CategoriesTableTable,
          CategoriesTableData
        >,
      ),
      CategoriesTableData,
      PrefetchHooks Function()
    >;
typedef $$ScheduleTableTableCreateCompanionBuilder =
    ScheduleTableCompanion Function({
      required String id,
      Value<String?> jadwalId,
      required String karyawanId,
      required String tanggal,
      Value<String?> divisiId,
      required String pelangganId,
      Value<String?> namaRute,
      Value<int> urutan,
      Value<String> status,
      Value<String?> waktuCheckIn,
      Value<String?> waktuCheckOut,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$ScheduleTableTableUpdateCompanionBuilder =
    ScheduleTableCompanion Function({
      Value<String> id,
      Value<String?> jadwalId,
      Value<String> karyawanId,
      Value<String> tanggal,
      Value<String?> divisiId,
      Value<String> pelangganId,
      Value<String?> namaRute,
      Value<int> urutan,
      Value<String> status,
      Value<String?> waktuCheckIn,
      Value<String?> waktuCheckOut,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$ScheduleTableTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleTableTable> {
  $$ScheduleTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jadwalId => $composableBuilder(
    column: $table.jadwalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get karyawanId => $composableBuilder(
    column: $table.karyawanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tanggal => $composableBuilder(
    column: $table.tanggal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get divisiId => $composableBuilder(
    column: $table.divisiId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pelangganId => $composableBuilder(
    column: $table.pelangganId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namaRute => $composableBuilder(
    column: $table.namaRute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get urutan => $composableBuilder(
    column: $table.urutan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waktuCheckIn => $composableBuilder(
    column: $table.waktuCheckIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waktuCheckOut => $composableBuilder(
    column: $table.waktuCheckOut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScheduleTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleTableTable> {
  $$ScheduleTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jadwalId => $composableBuilder(
    column: $table.jadwalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get karyawanId => $composableBuilder(
    column: $table.karyawanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tanggal => $composableBuilder(
    column: $table.tanggal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get divisiId => $composableBuilder(
    column: $table.divisiId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pelangganId => $composableBuilder(
    column: $table.pelangganId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namaRute => $composableBuilder(
    column: $table.namaRute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get urutan => $composableBuilder(
    column: $table.urutan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waktuCheckIn => $composableBuilder(
    column: $table.waktuCheckIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waktuCheckOut => $composableBuilder(
    column: $table.waktuCheckOut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScheduleTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleTableTable> {
  $$ScheduleTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jadwalId =>
      $composableBuilder(column: $table.jadwalId, builder: (column) => column);

  GeneratedColumn<String> get karyawanId => $composableBuilder(
    column: $table.karyawanId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tanggal =>
      $composableBuilder(column: $table.tanggal, builder: (column) => column);

  GeneratedColumn<String> get divisiId =>
      $composableBuilder(column: $table.divisiId, builder: (column) => column);

  GeneratedColumn<String> get pelangganId => $composableBuilder(
    column: $table.pelangganId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get namaRute =>
      $composableBuilder(column: $table.namaRute, builder: (column) => column);

  GeneratedColumn<int> get urutan =>
      $composableBuilder(column: $table.urutan, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get waktuCheckIn => $composableBuilder(
    column: $table.waktuCheckIn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get waktuCheckOut => $composableBuilder(
    column: $table.waktuCheckOut,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ScheduleTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduleTableTable,
          ScheduleTableData,
          $$ScheduleTableTableFilterComposer,
          $$ScheduleTableTableOrderingComposer,
          $$ScheduleTableTableAnnotationComposer,
          $$ScheduleTableTableCreateCompanionBuilder,
          $$ScheduleTableTableUpdateCompanionBuilder,
          (
            ScheduleTableData,
            BaseReferences<
              _$AppDatabase,
              $ScheduleTableTable,
              ScheduleTableData
            >,
          ),
          ScheduleTableData,
          PrefetchHooks Function()
        > {
  $$ScheduleTableTableTableManager(_$AppDatabase db, $ScheduleTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduleTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> jadwalId = const Value.absent(),
                Value<String> karyawanId = const Value.absent(),
                Value<String> tanggal = const Value.absent(),
                Value<String?> divisiId = const Value.absent(),
                Value<String> pelangganId = const Value.absent(),
                Value<String?> namaRute = const Value.absent(),
                Value<int> urutan = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> waktuCheckIn = const Value.absent(),
                Value<String?> waktuCheckOut = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScheduleTableCompanion(
                id: id,
                jadwalId: jadwalId,
                karyawanId: karyawanId,
                tanggal: tanggal,
                divisiId: divisiId,
                pelangganId: pelangganId,
                namaRute: namaRute,
                urutan: urutan,
                status: status,
                waktuCheckIn: waktuCheckIn,
                waktuCheckOut: waktuCheckOut,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> jadwalId = const Value.absent(),
                required String karyawanId,
                required String tanggal,
                Value<String?> divisiId = const Value.absent(),
                required String pelangganId,
                Value<String?> namaRute = const Value.absent(),
                Value<int> urutan = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> waktuCheckIn = const Value.absent(),
                Value<String?> waktuCheckOut = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ScheduleTableCompanion.insert(
                id: id,
                jadwalId: jadwalId,
                karyawanId: karyawanId,
                tanggal: tanggal,
                divisiId: divisiId,
                pelangganId: pelangganId,
                namaRute: namaRute,
                urutan: urutan,
                status: status,
                waktuCheckIn: waktuCheckIn,
                waktuCheckOut: waktuCheckOut,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScheduleTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduleTableTable,
      ScheduleTableData,
      $$ScheduleTableTableFilterComposer,
      $$ScheduleTableTableOrderingComposer,
      $$ScheduleTableTableAnnotationComposer,
      $$ScheduleTableTableCreateCompanionBuilder,
      $$ScheduleTableTableUpdateCompanionBuilder,
      (
        ScheduleTableData,
        BaseReferences<_$AppDatabase, $ScheduleTableTable, ScheduleTableData>,
      ),
      ScheduleTableData,
      PrefetchHooks Function()
    >;
typedef $$PromoTableTableCreateCompanionBuilder =
    PromoTableCompanion Function({
      required String id,
      required String idPelanggan,
      required String namaCampaign,
      required String jenis,
      required String dataJson,
      Value<String> status,
      required int startDate,
      required int endDate,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$PromoTableTableUpdateCompanionBuilder =
    PromoTableCompanion Function({
      Value<String> id,
      Value<String> idPelanggan,
      Value<String> namaCampaign,
      Value<String> jenis,
      Value<String> dataJson,
      Value<String> status,
      Value<int> startDate,
      Value<int> endDate,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$PromoTableTableFilterComposer
    extends Composer<_$AppDatabase, $PromoTableTable> {
  $$PromoTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idPelanggan => $composableBuilder(
    column: $table.idPelanggan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namaCampaign => $composableBuilder(
    column: $table.namaCampaign,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jenis => $composableBuilder(
    column: $table.jenis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PromoTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PromoTableTable> {
  $$PromoTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idPelanggan => $composableBuilder(
    column: $table.idPelanggan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namaCampaign => $composableBuilder(
    column: $table.namaCampaign,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jenis => $composableBuilder(
    column: $table.jenis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PromoTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromoTableTable> {
  $$PromoTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idPelanggan => $composableBuilder(
    column: $table.idPelanggan,
    builder: (column) => column,
  );

  GeneratedColumn<String> get namaCampaign => $composableBuilder(
    column: $table.namaCampaign,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jenis =>
      $composableBuilder(column: $table.jenis, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PromoTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PromoTableTable,
          PromoTableData,
          $$PromoTableTableFilterComposer,
          $$PromoTableTableOrderingComposer,
          $$PromoTableTableAnnotationComposer,
          $$PromoTableTableCreateCompanionBuilder,
          $$PromoTableTableUpdateCompanionBuilder,
          (
            PromoTableData,
            BaseReferences<_$AppDatabase, $PromoTableTable, PromoTableData>,
          ),
          PromoTableData,
          PrefetchHooks Function()
        > {
  $$PromoTableTableTableManager(_$AppDatabase db, $PromoTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromoTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PromoTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PromoTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> idPelanggan = const Value.absent(),
                Value<String> namaCampaign = const Value.absent(),
                Value<String> jenis = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> startDate = const Value.absent(),
                Value<int> endDate = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PromoTableCompanion(
                id: id,
                idPelanggan: idPelanggan,
                namaCampaign: namaCampaign,
                jenis: jenis,
                dataJson: dataJson,
                status: status,
                startDate: startDate,
                endDate: endDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String idPelanggan,
                required String namaCampaign,
                required String jenis,
                required String dataJson,
                Value<String> status = const Value.absent(),
                required int startDate,
                required int endDate,
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PromoTableCompanion.insert(
                id: id,
                idPelanggan: idPelanggan,
                namaCampaign: namaCampaign,
                jenis: jenis,
                dataJson: dataJson,
                status: status,
                startDate: startDate,
                endDate: endDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PromoTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PromoTableTable,
      PromoTableData,
      $$PromoTableTableFilterComposer,
      $$PromoTableTableOrderingComposer,
      $$PromoTableTableAnnotationComposer,
      $$PromoTableTableCreateCompanionBuilder,
      $$PromoTableTableUpdateCompanionBuilder,
      (
        PromoTableData,
        BaseReferences<_$AppDatabase, $PromoTableTable, PromoTableData>,
      ),
      PromoTableData,
      PrefetchHooks Function()
    >;
typedef $$NotificationsTableTableCreateCompanionBuilder =
    NotificationsTableCompanion Function({
      required String id,
      required String karyawanId,
      required String judul,
      required String isi,
      Value<String> tipe,
      Value<bool> isRead,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$NotificationsTableTableUpdateCompanionBuilder =
    NotificationsTableCompanion Function({
      Value<String> id,
      Value<String> karyawanId,
      Value<String> judul,
      Value<String> isi,
      Value<String> tipe,
      Value<bool> isRead,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$NotificationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationsTableTable> {
  $$NotificationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get karyawanId => $composableBuilder(
    column: $table.karyawanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get judul => $composableBuilder(
    column: $table.judul,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isi => $composableBuilder(
    column: $table.isi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipe => $composableBuilder(
    column: $table.tipe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationsTableTable> {
  $$NotificationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get karyawanId => $composableBuilder(
    column: $table.karyawanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get judul => $composableBuilder(
    column: $table.judul,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isi => $composableBuilder(
    column: $table.isi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipe => $composableBuilder(
    column: $table.tipe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationsTableTable> {
  $$NotificationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get karyawanId => $composableBuilder(
    column: $table.karyawanId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get judul =>
      $composableBuilder(column: $table.judul, builder: (column) => column);

  GeneratedColumn<String> get isi =>
      $composableBuilder(column: $table.isi, builder: (column) => column);

  GeneratedColumn<String> get tipe =>
      $composableBuilder(column: $table.tipe, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NotificationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationsTableTable,
          NotificationsTableData,
          $$NotificationsTableTableFilterComposer,
          $$NotificationsTableTableOrderingComposer,
          $$NotificationsTableTableAnnotationComposer,
          $$NotificationsTableTableCreateCompanionBuilder,
          $$NotificationsTableTableUpdateCompanionBuilder,
          (
            NotificationsTableData,
            BaseReferences<
              _$AppDatabase,
              $NotificationsTableTable,
              NotificationsTableData
            >,
          ),
          NotificationsTableData,
          PrefetchHooks Function()
        > {
  $$NotificationsTableTableTableManager(
    _$AppDatabase db,
    $NotificationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> karyawanId = const Value.absent(),
                Value<String> judul = const Value.absent(),
                Value<String> isi = const Value.absent(),
                Value<String> tipe = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationsTableCompanion(
                id: id,
                karyawanId: karyawanId,
                judul: judul,
                isi: isi,
                tipe: tipe,
                isRead: isRead,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String karyawanId,
                required String judul,
                required String isi,
                Value<String> tipe = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => NotificationsTableCompanion.insert(
                id: id,
                karyawanId: karyawanId,
                judul: judul,
                isi: isi,
                tipe: tipe,
                isRead: isRead,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationsTableTable,
      NotificationsTableData,
      $$NotificationsTableTableFilterComposer,
      $$NotificationsTableTableOrderingComposer,
      $$NotificationsTableTableAnnotationComposer,
      $$NotificationsTableTableCreateCompanionBuilder,
      $$NotificationsTableTableUpdateCompanionBuilder,
      (
        NotificationsTableData,
        BaseReferences<
          _$AppDatabase,
          $NotificationsTableTable,
          NotificationsTableData
        >,
      ),
      NotificationsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalCacheTableTableTableManager get localCacheTable =>
      $$LocalCacheTableTableTableManager(_db, _db.localCacheTable);
  $$SyncMetadataTableTableTableManager get syncMetadataTable =>
      $$SyncMetadataTableTableTableManager(_db, _db.syncMetadataTable);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
  $$RefIdMapTableTableTableManager get refIdMapTable =>
      $$RefIdMapTableTableTableManager(_db, _db.refIdMapTable);
  $$SyncLockTableTableTableManager get syncLockTable =>
      $$SyncLockTableTableTableManager(_db, _db.syncLockTable);
  $$CartItemsTableTableTableManager get cartItemsTable =>
      $$CartItemsTableTableTableManager(_db, _db.cartItemsTable);
  $$PromoCacheTableTableTableManager get promoCacheTable =>
      $$PromoCacheTableTableTableManager(_db, _db.promoCacheTable);
  $$VisitsTableTableTableManager get visitsTable =>
      $$VisitsTableTableTableManager(_db, _db.visitsTable);
  $$OrdersTableTableTableManager get ordersTable =>
      $$OrdersTableTableTableManager(_db, _db.ordersTable);
  $$CustomersTableTableTableManager get customersTable =>
      $$CustomersTableTableTableManager(_db, _db.customersTable);
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db, _db.productsTable);
  $$ProductUnitsTableTableTableManager get productUnitsTable =>
      $$ProductUnitsTableTableTableManager(_db, _db.productUnitsTable);
  $$CategoriesTableTableTableManager get categoriesTable =>
      $$CategoriesTableTableTableManager(_db, _db.categoriesTable);
  $$ScheduleTableTableTableManager get scheduleTable =>
      $$ScheduleTableTableTableManager(_db, _db.scheduleTable);
  $$PromoTableTableTableManager get promoTable =>
      $$PromoTableTableTableManager(_db, _db.promoTable);
  $$NotificationsTableTableTableManager get notificationsTable =>
      $$NotificationsTableTableTableManager(_db, _db.notificationsTable);
}
