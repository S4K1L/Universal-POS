// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $KvTable extends Kv with TableInfo<$KvTable, KvData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kv';
  @override
  VerificationContext validateIntegrity(
    Insertable<KvData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KvData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KvTable createAlias(String alias) {
    return $KvTable(attachedDatabase, alias);
  }
}

class KvData extends DataClass implements Insertable<KvData> {
  final String key;
  final String value;
  const KvData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KvCompanion toCompanion(bool nullToAbsent) {
    return KvCompanion(key: Value(key), value: Value(value));
  }

  factory KvData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KvData copyWith({String? key, String? value}) =>
      KvData(key: key ?? this.key, value: value ?? this.value);
  KvData copyWithCompanion(KvCompanion data) {
    return KvData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KvData && other.key == this.key && other.value == this.value);
}

class KvCompanion extends UpdateCompanion<KvData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KvCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KvCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KvData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KvCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KvCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KvCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LCategoriesTable extends LCategories
    with TableInfo<$LCategoriesTable, LCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, parentId, sortOrder, active];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'l_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<LCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $LCategoriesTable createAlias(String alias) {
    return $LCategoriesTable(attachedDatabase, alias);
  }
}

class LCategory extends DataClass implements Insertable<LCategory> {
  final String id;
  final String name;
  final String? parentId;
  final int sortOrder;
  final bool active;
  const LCategory({
    required this.id,
    required this.name,
    this.parentId,
    required this.sortOrder,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['active'] = Variable<bool>(active);
    return map;
  }

  LCategoriesCompanion toCompanion(bool nullToAbsent) {
    return LCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      sortOrder: Value(sortOrder),
      active: Value(active),
    );
  }

  factory LCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'active': serializer.toJson<bool>(active),
    };
  }

  LCategory copyWith({
    String? id,
    String? name,
    Value<String?> parentId = const Value.absent(),
    int? sortOrder,
    bool? active,
  }) => LCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    sortOrder: sortOrder ?? this.sortOrder,
    active: active ?? this.active,
  );
  LCategory copyWithCompanion(LCategoriesCompanion data) {
    return LCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, parentId, sortOrder, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.sortOrder == this.sortOrder &&
          other.active == this.active);
}

class LCategoriesCompanion extends UpdateCompanion<LCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<int> sortOrder;
  final Value<bool> active;
  final Value<int> rowid;
  const LCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LCategoriesCompanion.insert({
    required String id,
    required String name,
    this.parentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<LCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<int>? sortOrder,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? parentId,
    Value<int>? sortOrder,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return LCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LTaxClassesTable extends LTaxClasses
    with TableInfo<$LTaxClassesTable, LTaxClassesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LTaxClassesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateBpMeta = const VerificationMeta('rateBp');
  @override
  late final GeneratedColumn<int> rateBp = GeneratedColumn<int>(
    'rate_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, rateBp, isDefault];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'l_tax_classes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LTaxClassesData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('rate_bp')) {
      context.handle(
        _rateBpMeta,
        rateBp.isAcceptableOrUnknown(data['rate_bp']!, _rateBpMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LTaxClassesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LTaxClassesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      rateBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_bp'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $LTaxClassesTable createAlias(String alias) {
    return $LTaxClassesTable(attachedDatabase, alias);
  }
}

class LTaxClassesData extends DataClass implements Insertable<LTaxClassesData> {
  final String id;
  final String name;
  final int rateBp;
  final bool isDefault;
  const LTaxClassesData({
    required this.id,
    required this.name,
    required this.rateBp,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['rate_bp'] = Variable<int>(rateBp);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  LTaxClassesCompanion toCompanion(bool nullToAbsent) {
    return LTaxClassesCompanion(
      id: Value(id),
      name: Value(name),
      rateBp: Value(rateBp),
      isDefault: Value(isDefault),
    );
  }

  factory LTaxClassesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LTaxClassesData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      rateBp: serializer.fromJson<int>(json['rateBp']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'rateBp': serializer.toJson<int>(rateBp),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  LTaxClassesData copyWith({
    String? id,
    String? name,
    int? rateBp,
    bool? isDefault,
  }) => LTaxClassesData(
    id: id ?? this.id,
    name: name ?? this.name,
    rateBp: rateBp ?? this.rateBp,
    isDefault: isDefault ?? this.isDefault,
  );
  LTaxClassesData copyWithCompanion(LTaxClassesCompanion data) {
    return LTaxClassesData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      rateBp: data.rateBp.present ? data.rateBp.value : this.rateBp,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LTaxClassesData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rateBp: $rateBp, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, rateBp, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LTaxClassesData &&
          other.id == this.id &&
          other.name == this.name &&
          other.rateBp == this.rateBp &&
          other.isDefault == this.isDefault);
}

class LTaxClassesCompanion extends UpdateCompanion<LTaxClassesData> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> rateBp;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const LTaxClassesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rateBp = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LTaxClassesCompanion.insert({
    required String id,
    required String name,
    this.rateBp = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<LTaxClassesData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rateBp,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rateBp != null) 'rate_bp': rateBp,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LTaxClassesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? rateBp,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return LTaxClassesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rateBp: rateBp ?? this.rateBp,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rateBp.present) {
      map['rate_bp'] = Variable<int>(rateBp.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LTaxClassesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rateBp: $rateBp, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LProductsTable extends LProducts
    with TableInfo<$LProductsTable, LProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameLocalMeta = const VerificationMeta(
    'nameLocal',
  );
  @override
  late final GeneratedColumn<String> nameLocal = GeneratedColumn<String>(
    'name_local',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('stockable'),
  );
  static const VerificationMeta _baseUnitMeta = const VerificationMeta(
    'baseUnit',
  );
  @override
  late final GeneratedColumn<String> baseUnit = GeneratedColumn<String>(
    'base_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pc'),
  );
  static const VerificationMeta _altUnitsMeta = const VerificationMeta(
    'altUnits',
  );
  @override
  late final GeneratedColumn<String> altUnits = GeneratedColumn<String>(
    'alt_units',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _allowFractionMeta = const VerificationMeta(
    'allowFraction',
  );
  @override
  late final GeneratedColumn<bool> allowFraction = GeneratedColumn<bool>(
    'allow_fraction',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_fraction" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _trackingMeta = const VerificationMeta(
    'tracking',
  );
  @override
  late final GeneratedColumn<String> tracking = GeneratedColumn<String>(
    'tracking',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _trackExpiryMeta = const VerificationMeta(
    'trackExpiry',
  );
  @override
  late final GeneratedColumn<bool> trackExpiry = GeneratedColumn<bool>(
    'track_expiry',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("track_expiry" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _taxClassIdMeta = const VerificationMeta(
    'taxClassId',
  );
  @override
  late final GeneratedColumn<String> taxClassId = GeneratedColumn<String>(
    'tax_class_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attributesMeta = const VerificationMeta(
    'attributes',
  );
  @override
  late final GeneratedColumn<String> attributes = GeneratedColumn<String>(
    'attributes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _reorderMilliMeta = const VerificationMeta(
    'reorderMilli',
  );
  @override
  late final GeneratedColumn<int> reorderMilli = GeneratedColumn<int>(
    'reorder_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _warrantyMonthsMeta = const VerificationMeta(
    'warrantyMonths',
  );
  @override
  late final GeneratedColumn<int> warrantyMonths = GeneratedColumn<int>(
    'warranty_months',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _searchMeta = const VerificationMeta('search');
  @override
  late final GeneratedColumn<String> search = GeneratedColumn<String>(
    'search',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    nameLocal,
    categoryId,
    type,
    baseUnit,
    altUnits,
    allowFraction,
    tracking,
    trackExpiry,
    taxClassId,
    attributes,
    imageUrl,
    reorderMilli,
    warrantyMonths,
    active,
    search,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'l_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<LProduct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_local')) {
      context.handle(
        _nameLocalMeta,
        nameLocal.isAcceptableOrUnknown(data['name_local']!, _nameLocalMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('base_unit')) {
      context.handle(
        _baseUnitMeta,
        baseUnit.isAcceptableOrUnknown(data['base_unit']!, _baseUnitMeta),
      );
    }
    if (data.containsKey('alt_units')) {
      context.handle(
        _altUnitsMeta,
        altUnits.isAcceptableOrUnknown(data['alt_units']!, _altUnitsMeta),
      );
    }
    if (data.containsKey('allow_fraction')) {
      context.handle(
        _allowFractionMeta,
        allowFraction.isAcceptableOrUnknown(
          data['allow_fraction']!,
          _allowFractionMeta,
        ),
      );
    }
    if (data.containsKey('tracking')) {
      context.handle(
        _trackingMeta,
        tracking.isAcceptableOrUnknown(data['tracking']!, _trackingMeta),
      );
    }
    if (data.containsKey('track_expiry')) {
      context.handle(
        _trackExpiryMeta,
        trackExpiry.isAcceptableOrUnknown(
          data['track_expiry']!,
          _trackExpiryMeta,
        ),
      );
    }
    if (data.containsKey('tax_class_id')) {
      context.handle(
        _taxClassIdMeta,
        taxClassId.isAcceptableOrUnknown(
          data['tax_class_id']!,
          _taxClassIdMeta,
        ),
      );
    }
    if (data.containsKey('attributes')) {
      context.handle(
        _attributesMeta,
        attributes.isAcceptableOrUnknown(data['attributes']!, _attributesMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('reorder_milli')) {
      context.handle(
        _reorderMilliMeta,
        reorderMilli.isAcceptableOrUnknown(
          data['reorder_milli']!,
          _reorderMilliMeta,
        ),
      );
    }
    if (data.containsKey('warranty_months')) {
      context.handle(
        _warrantyMonthsMeta,
        warrantyMonths.isAcceptableOrUnknown(
          data['warranty_months']!,
          _warrantyMonthsMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('search')) {
      context.handle(
        _searchMeta,
        search.isAcceptableOrUnknown(data['search']!, _searchMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LProduct(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_local'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      baseUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_unit'],
      )!,
      altUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alt_units'],
      )!,
      allowFraction: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_fraction'],
      )!,
      tracking: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tracking'],
      )!,
      trackExpiry: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}track_expiry'],
      )!,
      taxClassId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_class_id'],
      ),
      attributes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attributes'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      )!,
      reorderMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reorder_milli'],
      )!,
      warrantyMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warranty_months'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      search: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search'],
      )!,
    );
  }

  @override
  $LProductsTable createAlias(String alias) {
    return $LProductsTable(attachedDatabase, alias);
  }
}

class LProduct extends DataClass implements Insertable<LProduct> {
  final String id;
  final String name;
  final String nameLocal;
  final String? categoryId;
  final String type;
  final String baseUnit;
  final String altUnits;
  final bool allowFraction;
  final String tracking;
  final bool trackExpiry;
  final String? taxClassId;
  final String attributes;
  final String imageUrl;
  final int reorderMilli;
  final int warrantyMonths;
  final bool active;
  final String search;
  const LProduct({
    required this.id,
    required this.name,
    required this.nameLocal,
    this.categoryId,
    required this.type,
    required this.baseUnit,
    required this.altUnits,
    required this.allowFraction,
    required this.tracking,
    required this.trackExpiry,
    this.taxClassId,
    required this.attributes,
    required this.imageUrl,
    required this.reorderMilli,
    required this.warrantyMonths,
    required this.active,
    required this.search,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['name_local'] = Variable<String>(nameLocal);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['type'] = Variable<String>(type);
    map['base_unit'] = Variable<String>(baseUnit);
    map['alt_units'] = Variable<String>(altUnits);
    map['allow_fraction'] = Variable<bool>(allowFraction);
    map['tracking'] = Variable<String>(tracking);
    map['track_expiry'] = Variable<bool>(trackExpiry);
    if (!nullToAbsent || taxClassId != null) {
      map['tax_class_id'] = Variable<String>(taxClassId);
    }
    map['attributes'] = Variable<String>(attributes);
    map['image_url'] = Variable<String>(imageUrl);
    map['reorder_milli'] = Variable<int>(reorderMilli);
    map['warranty_months'] = Variable<int>(warrantyMonths);
    map['active'] = Variable<bool>(active);
    map['search'] = Variable<String>(search);
    return map;
  }

  LProductsCompanion toCompanion(bool nullToAbsent) {
    return LProductsCompanion(
      id: Value(id),
      name: Value(name),
      nameLocal: Value(nameLocal),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      type: Value(type),
      baseUnit: Value(baseUnit),
      altUnits: Value(altUnits),
      allowFraction: Value(allowFraction),
      tracking: Value(tracking),
      trackExpiry: Value(trackExpiry),
      taxClassId: taxClassId == null && nullToAbsent
          ? const Value.absent()
          : Value(taxClassId),
      attributes: Value(attributes),
      imageUrl: Value(imageUrl),
      reorderMilli: Value(reorderMilli),
      warrantyMonths: Value(warrantyMonths),
      active: Value(active),
      search: Value(search),
    );
  }

  factory LProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LProduct(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nameLocal: serializer.fromJson<String>(json['nameLocal']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      type: serializer.fromJson<String>(json['type']),
      baseUnit: serializer.fromJson<String>(json['baseUnit']),
      altUnits: serializer.fromJson<String>(json['altUnits']),
      allowFraction: serializer.fromJson<bool>(json['allowFraction']),
      tracking: serializer.fromJson<String>(json['tracking']),
      trackExpiry: serializer.fromJson<bool>(json['trackExpiry']),
      taxClassId: serializer.fromJson<String?>(json['taxClassId']),
      attributes: serializer.fromJson<String>(json['attributes']),
      imageUrl: serializer.fromJson<String>(json['imageUrl']),
      reorderMilli: serializer.fromJson<int>(json['reorderMilli']),
      warrantyMonths: serializer.fromJson<int>(json['warrantyMonths']),
      active: serializer.fromJson<bool>(json['active']),
      search: serializer.fromJson<String>(json['search']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'nameLocal': serializer.toJson<String>(nameLocal),
      'categoryId': serializer.toJson<String?>(categoryId),
      'type': serializer.toJson<String>(type),
      'baseUnit': serializer.toJson<String>(baseUnit),
      'altUnits': serializer.toJson<String>(altUnits),
      'allowFraction': serializer.toJson<bool>(allowFraction),
      'tracking': serializer.toJson<String>(tracking),
      'trackExpiry': serializer.toJson<bool>(trackExpiry),
      'taxClassId': serializer.toJson<String?>(taxClassId),
      'attributes': serializer.toJson<String>(attributes),
      'imageUrl': serializer.toJson<String>(imageUrl),
      'reorderMilli': serializer.toJson<int>(reorderMilli),
      'warrantyMonths': serializer.toJson<int>(warrantyMonths),
      'active': serializer.toJson<bool>(active),
      'search': serializer.toJson<String>(search),
    };
  }

  LProduct copyWith({
    String? id,
    String? name,
    String? nameLocal,
    Value<String?> categoryId = const Value.absent(),
    String? type,
    String? baseUnit,
    String? altUnits,
    bool? allowFraction,
    String? tracking,
    bool? trackExpiry,
    Value<String?> taxClassId = const Value.absent(),
    String? attributes,
    String? imageUrl,
    int? reorderMilli,
    int? warrantyMonths,
    bool? active,
    String? search,
  }) => LProduct(
    id: id ?? this.id,
    name: name ?? this.name,
    nameLocal: nameLocal ?? this.nameLocal,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    type: type ?? this.type,
    baseUnit: baseUnit ?? this.baseUnit,
    altUnits: altUnits ?? this.altUnits,
    allowFraction: allowFraction ?? this.allowFraction,
    tracking: tracking ?? this.tracking,
    trackExpiry: trackExpiry ?? this.trackExpiry,
    taxClassId: taxClassId.present ? taxClassId.value : this.taxClassId,
    attributes: attributes ?? this.attributes,
    imageUrl: imageUrl ?? this.imageUrl,
    reorderMilli: reorderMilli ?? this.reorderMilli,
    warrantyMonths: warrantyMonths ?? this.warrantyMonths,
    active: active ?? this.active,
    search: search ?? this.search,
  );
  LProduct copyWithCompanion(LProductsCompanion data) {
    return LProduct(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nameLocal: data.nameLocal.present ? data.nameLocal.value : this.nameLocal,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      type: data.type.present ? data.type.value : this.type,
      baseUnit: data.baseUnit.present ? data.baseUnit.value : this.baseUnit,
      altUnits: data.altUnits.present ? data.altUnits.value : this.altUnits,
      allowFraction: data.allowFraction.present
          ? data.allowFraction.value
          : this.allowFraction,
      tracking: data.tracking.present ? data.tracking.value : this.tracking,
      trackExpiry: data.trackExpiry.present
          ? data.trackExpiry.value
          : this.trackExpiry,
      taxClassId: data.taxClassId.present
          ? data.taxClassId.value
          : this.taxClassId,
      attributes: data.attributes.present
          ? data.attributes.value
          : this.attributes,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      reorderMilli: data.reorderMilli.present
          ? data.reorderMilli.value
          : this.reorderMilli,
      warrantyMonths: data.warrantyMonths.present
          ? data.warrantyMonths.value
          : this.warrantyMonths,
      active: data.active.present ? data.active.value : this.active,
      search: data.search.present ? data.search.value : this.search,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LProduct(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameLocal: $nameLocal, ')
          ..write('categoryId: $categoryId, ')
          ..write('type: $type, ')
          ..write('baseUnit: $baseUnit, ')
          ..write('altUnits: $altUnits, ')
          ..write('allowFraction: $allowFraction, ')
          ..write('tracking: $tracking, ')
          ..write('trackExpiry: $trackExpiry, ')
          ..write('taxClassId: $taxClassId, ')
          ..write('attributes: $attributes, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('reorderMilli: $reorderMilli, ')
          ..write('warrantyMonths: $warrantyMonths, ')
          ..write('active: $active, ')
          ..write('search: $search')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    nameLocal,
    categoryId,
    type,
    baseUnit,
    altUnits,
    allowFraction,
    tracking,
    trackExpiry,
    taxClassId,
    attributes,
    imageUrl,
    reorderMilli,
    warrantyMonths,
    active,
    search,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LProduct &&
          other.id == this.id &&
          other.name == this.name &&
          other.nameLocal == this.nameLocal &&
          other.categoryId == this.categoryId &&
          other.type == this.type &&
          other.baseUnit == this.baseUnit &&
          other.altUnits == this.altUnits &&
          other.allowFraction == this.allowFraction &&
          other.tracking == this.tracking &&
          other.trackExpiry == this.trackExpiry &&
          other.taxClassId == this.taxClassId &&
          other.attributes == this.attributes &&
          other.imageUrl == this.imageUrl &&
          other.reorderMilli == this.reorderMilli &&
          other.warrantyMonths == this.warrantyMonths &&
          other.active == this.active &&
          other.search == this.search);
}

class LProductsCompanion extends UpdateCompanion<LProduct> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> nameLocal;
  final Value<String?> categoryId;
  final Value<String> type;
  final Value<String> baseUnit;
  final Value<String> altUnits;
  final Value<bool> allowFraction;
  final Value<String> tracking;
  final Value<bool> trackExpiry;
  final Value<String?> taxClassId;
  final Value<String> attributes;
  final Value<String> imageUrl;
  final Value<int> reorderMilli;
  final Value<int> warrantyMonths;
  final Value<bool> active;
  final Value<String> search;
  final Value<int> rowid;
  const LProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nameLocal = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.type = const Value.absent(),
    this.baseUnit = const Value.absent(),
    this.altUnits = const Value.absent(),
    this.allowFraction = const Value.absent(),
    this.tracking = const Value.absent(),
    this.trackExpiry = const Value.absent(),
    this.taxClassId = const Value.absent(),
    this.attributes = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.reorderMilli = const Value.absent(),
    this.warrantyMonths = const Value.absent(),
    this.active = const Value.absent(),
    this.search = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LProductsCompanion.insert({
    required String id,
    required String name,
    this.nameLocal = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.type = const Value.absent(),
    this.baseUnit = const Value.absent(),
    this.altUnits = const Value.absent(),
    this.allowFraction = const Value.absent(),
    this.tracking = const Value.absent(),
    this.trackExpiry = const Value.absent(),
    this.taxClassId = const Value.absent(),
    this.attributes = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.reorderMilli = const Value.absent(),
    this.warrantyMonths = const Value.absent(),
    this.active = const Value.absent(),
    this.search = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<LProduct> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? nameLocal,
    Expression<String>? categoryId,
    Expression<String>? type,
    Expression<String>? baseUnit,
    Expression<String>? altUnits,
    Expression<bool>? allowFraction,
    Expression<String>? tracking,
    Expression<bool>? trackExpiry,
    Expression<String>? taxClassId,
    Expression<String>? attributes,
    Expression<String>? imageUrl,
    Expression<int>? reorderMilli,
    Expression<int>? warrantyMonths,
    Expression<bool>? active,
    Expression<String>? search,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nameLocal != null) 'name_local': nameLocal,
      if (categoryId != null) 'category_id': categoryId,
      if (type != null) 'type': type,
      if (baseUnit != null) 'base_unit': baseUnit,
      if (altUnits != null) 'alt_units': altUnits,
      if (allowFraction != null) 'allow_fraction': allowFraction,
      if (tracking != null) 'tracking': tracking,
      if (trackExpiry != null) 'track_expiry': trackExpiry,
      if (taxClassId != null) 'tax_class_id': taxClassId,
      if (attributes != null) 'attributes': attributes,
      if (imageUrl != null) 'image_url': imageUrl,
      if (reorderMilli != null) 'reorder_milli': reorderMilli,
      if (warrantyMonths != null) 'warranty_months': warrantyMonths,
      if (active != null) 'active': active,
      if (search != null) 'search': search,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? nameLocal,
    Value<String?>? categoryId,
    Value<String>? type,
    Value<String>? baseUnit,
    Value<String>? altUnits,
    Value<bool>? allowFraction,
    Value<String>? tracking,
    Value<bool>? trackExpiry,
    Value<String?>? taxClassId,
    Value<String>? attributes,
    Value<String>? imageUrl,
    Value<int>? reorderMilli,
    Value<int>? warrantyMonths,
    Value<bool>? active,
    Value<String>? search,
    Value<int>? rowid,
  }) {
    return LProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nameLocal: nameLocal ?? this.nameLocal,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      baseUnit: baseUnit ?? this.baseUnit,
      altUnits: altUnits ?? this.altUnits,
      allowFraction: allowFraction ?? this.allowFraction,
      tracking: tracking ?? this.tracking,
      trackExpiry: trackExpiry ?? this.trackExpiry,
      taxClassId: taxClassId ?? this.taxClassId,
      attributes: attributes ?? this.attributes,
      imageUrl: imageUrl ?? this.imageUrl,
      reorderMilli: reorderMilli ?? this.reorderMilli,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      active: active ?? this.active,
      search: search ?? this.search,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameLocal.present) {
      map['name_local'] = Variable<String>(nameLocal.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (baseUnit.present) {
      map['base_unit'] = Variable<String>(baseUnit.value);
    }
    if (altUnits.present) {
      map['alt_units'] = Variable<String>(altUnits.value);
    }
    if (allowFraction.present) {
      map['allow_fraction'] = Variable<bool>(allowFraction.value);
    }
    if (tracking.present) {
      map['tracking'] = Variable<String>(tracking.value);
    }
    if (trackExpiry.present) {
      map['track_expiry'] = Variable<bool>(trackExpiry.value);
    }
    if (taxClassId.present) {
      map['tax_class_id'] = Variable<String>(taxClassId.value);
    }
    if (attributes.present) {
      map['attributes'] = Variable<String>(attributes.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (reorderMilli.present) {
      map['reorder_milli'] = Variable<int>(reorderMilli.value);
    }
    if (warrantyMonths.present) {
      map['warranty_months'] = Variable<int>(warrantyMonths.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (search.present) {
      map['search'] = Variable<String>(search.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameLocal: $nameLocal, ')
          ..write('categoryId: $categoryId, ')
          ..write('type: $type, ')
          ..write('baseUnit: $baseUnit, ')
          ..write('altUnits: $altUnits, ')
          ..write('allowFraction: $allowFraction, ')
          ..write('tracking: $tracking, ')
          ..write('trackExpiry: $trackExpiry, ')
          ..write('taxClassId: $taxClassId, ')
          ..write('attributes: $attributes, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('reorderMilli: $reorderMilli, ')
          ..write('warrantyMonths: $warrantyMonths, ')
          ..write('active: $active, ')
          ..write('search: $search, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LVariantsTable extends LVariants
    with TableInfo<$LVariantsTable, LVariant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LVariantsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _optionValuesMeta = const VerificationMeta(
    'optionValues',
  );
  @override
  late final GeneratedColumn<String> optionValues = GeneratedColumn<String>(
    'option_values',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _pricePMeta = const VerificationMeta('priceP');
  @override
  late final GeneratedColumn<int> priceP = GeneratedColumn<int>(
    'price_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mrpPMeta = const VerificationMeta('mrpP');
  @override
  late final GeneratedColumn<int> mrpP = GeneratedColumn<int>(
    'mrp_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _costPMeta = const VerificationMeta('costP');
  @override
  late final GeneratedColumn<int> costP = GeneratedColumn<int>(
    'cost_p',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pluMeta = const VerificationMeta('plu');
  @override
  late final GeneratedColumn<String> plu = GeneratedColumn<String>(
    'plu',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    sku,
    label,
    optionValues,
    priceP,
    mrpP,
    costP,
    plu,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'l_variants';
  @override
  VerificationContext validateIntegrity(
    Insertable<LVariant> instance, {
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
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('option_values')) {
      context.handle(
        _optionValuesMeta,
        optionValues.isAcceptableOrUnknown(
          data['option_values']!,
          _optionValuesMeta,
        ),
      );
    }
    if (data.containsKey('price_p')) {
      context.handle(
        _pricePMeta,
        priceP.isAcceptableOrUnknown(data['price_p']!, _pricePMeta),
      );
    } else if (isInserting) {
      context.missing(_pricePMeta);
    }
    if (data.containsKey('mrp_p')) {
      context.handle(
        _mrpPMeta,
        mrpP.isAcceptableOrUnknown(data['mrp_p']!, _mrpPMeta),
      );
    }
    if (data.containsKey('cost_p')) {
      context.handle(
        _costPMeta,
        costP.isAcceptableOrUnknown(data['cost_p']!, _costPMeta),
      );
    }
    if (data.containsKey('plu')) {
      context.handle(
        _pluMeta,
        plu.isAcceptableOrUnknown(data['plu']!, _pluMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LVariant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LVariant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      optionValues: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}option_values'],
      )!,
      priceP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_p'],
      )!,
      mrpP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mrp_p'],
      )!,
      costP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_p'],
      ),
      plu: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plu'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $LVariantsTable createAlias(String alias) {
    return $LVariantsTable(attachedDatabase, alias);
  }
}

class LVariant extends DataClass implements Insertable<LVariant> {
  final String id;
  final String productId;
  final String sku;
  final String label;
  final String optionValues;
  final int priceP;
  final int mrpP;
  final int? costP;
  final String? plu;
  final bool active;
  const LVariant({
    required this.id,
    required this.productId,
    required this.sku,
    required this.label,
    required this.optionValues,
    required this.priceP,
    required this.mrpP,
    this.costP,
    this.plu,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['sku'] = Variable<String>(sku);
    map['label'] = Variable<String>(label);
    map['option_values'] = Variable<String>(optionValues);
    map['price_p'] = Variable<int>(priceP);
    map['mrp_p'] = Variable<int>(mrpP);
    if (!nullToAbsent || costP != null) {
      map['cost_p'] = Variable<int>(costP);
    }
    if (!nullToAbsent || plu != null) {
      map['plu'] = Variable<String>(plu);
    }
    map['active'] = Variable<bool>(active);
    return map;
  }

  LVariantsCompanion toCompanion(bool nullToAbsent) {
    return LVariantsCompanion(
      id: Value(id),
      productId: Value(productId),
      sku: Value(sku),
      label: Value(label),
      optionValues: Value(optionValues),
      priceP: Value(priceP),
      mrpP: Value(mrpP),
      costP: costP == null && nullToAbsent
          ? const Value.absent()
          : Value(costP),
      plu: plu == null && nullToAbsent ? const Value.absent() : Value(plu),
      active: Value(active),
    );
  }

  factory LVariant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LVariant(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      sku: serializer.fromJson<String>(json['sku']),
      label: serializer.fromJson<String>(json['label']),
      optionValues: serializer.fromJson<String>(json['optionValues']),
      priceP: serializer.fromJson<int>(json['priceP']),
      mrpP: serializer.fromJson<int>(json['mrpP']),
      costP: serializer.fromJson<int?>(json['costP']),
      plu: serializer.fromJson<String?>(json['plu']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'sku': serializer.toJson<String>(sku),
      'label': serializer.toJson<String>(label),
      'optionValues': serializer.toJson<String>(optionValues),
      'priceP': serializer.toJson<int>(priceP),
      'mrpP': serializer.toJson<int>(mrpP),
      'costP': serializer.toJson<int?>(costP),
      'plu': serializer.toJson<String?>(plu),
      'active': serializer.toJson<bool>(active),
    };
  }

  LVariant copyWith({
    String? id,
    String? productId,
    String? sku,
    String? label,
    String? optionValues,
    int? priceP,
    int? mrpP,
    Value<int?> costP = const Value.absent(),
    Value<String?> plu = const Value.absent(),
    bool? active,
  }) => LVariant(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    sku: sku ?? this.sku,
    label: label ?? this.label,
    optionValues: optionValues ?? this.optionValues,
    priceP: priceP ?? this.priceP,
    mrpP: mrpP ?? this.mrpP,
    costP: costP.present ? costP.value : this.costP,
    plu: plu.present ? plu.value : this.plu,
    active: active ?? this.active,
  );
  LVariant copyWithCompanion(LVariantsCompanion data) {
    return LVariant(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      sku: data.sku.present ? data.sku.value : this.sku,
      label: data.label.present ? data.label.value : this.label,
      optionValues: data.optionValues.present
          ? data.optionValues.value
          : this.optionValues,
      priceP: data.priceP.present ? data.priceP.value : this.priceP,
      mrpP: data.mrpP.present ? data.mrpP.value : this.mrpP,
      costP: data.costP.present ? data.costP.value : this.costP,
      plu: data.plu.present ? data.plu.value : this.plu,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LVariant(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('sku: $sku, ')
          ..write('label: $label, ')
          ..write('optionValues: $optionValues, ')
          ..write('priceP: $priceP, ')
          ..write('mrpP: $mrpP, ')
          ..write('costP: $costP, ')
          ..write('plu: $plu, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    sku,
    label,
    optionValues,
    priceP,
    mrpP,
    costP,
    plu,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LVariant &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.sku == this.sku &&
          other.label == this.label &&
          other.optionValues == this.optionValues &&
          other.priceP == this.priceP &&
          other.mrpP == this.mrpP &&
          other.costP == this.costP &&
          other.plu == this.plu &&
          other.active == this.active);
}

class LVariantsCompanion extends UpdateCompanion<LVariant> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> sku;
  final Value<String> label;
  final Value<String> optionValues;
  final Value<int> priceP;
  final Value<int> mrpP;
  final Value<int?> costP;
  final Value<String?> plu;
  final Value<bool> active;
  final Value<int> rowid;
  const LVariantsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.sku = const Value.absent(),
    this.label = const Value.absent(),
    this.optionValues = const Value.absent(),
    this.priceP = const Value.absent(),
    this.mrpP = const Value.absent(),
    this.costP = const Value.absent(),
    this.plu = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LVariantsCompanion.insert({
    required String id,
    required String productId,
    this.sku = const Value.absent(),
    this.label = const Value.absent(),
    this.optionValues = const Value.absent(),
    required int priceP,
    this.mrpP = const Value.absent(),
    this.costP = const Value.absent(),
    this.plu = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       priceP = Value(priceP);
  static Insertable<LVariant> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? sku,
    Expression<String>? label,
    Expression<String>? optionValues,
    Expression<int>? priceP,
    Expression<int>? mrpP,
    Expression<int>? costP,
    Expression<String>? plu,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (sku != null) 'sku': sku,
      if (label != null) 'label': label,
      if (optionValues != null) 'option_values': optionValues,
      if (priceP != null) 'price_p': priceP,
      if (mrpP != null) 'mrp_p': mrpP,
      if (costP != null) 'cost_p': costP,
      if (plu != null) 'plu': plu,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LVariantsCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? sku,
    Value<String>? label,
    Value<String>? optionValues,
    Value<int>? priceP,
    Value<int>? mrpP,
    Value<int?>? costP,
    Value<String?>? plu,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return LVariantsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      sku: sku ?? this.sku,
      label: label ?? this.label,
      optionValues: optionValues ?? this.optionValues,
      priceP: priceP ?? this.priceP,
      mrpP: mrpP ?? this.mrpP,
      costP: costP ?? this.costP,
      plu: plu ?? this.plu,
      active: active ?? this.active,
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
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (optionValues.present) {
      map['option_values'] = Variable<String>(optionValues.value);
    }
    if (priceP.present) {
      map['price_p'] = Variable<int>(priceP.value);
    }
    if (mrpP.present) {
      map['mrp_p'] = Variable<int>(mrpP.value);
    }
    if (costP.present) {
      map['cost_p'] = Variable<int>(costP.value);
    }
    if (plu.present) {
      map['plu'] = Variable<String>(plu.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LVariantsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('sku: $sku, ')
          ..write('label: $label, ')
          ..write('optionValues: $optionValues, ')
          ..write('priceP: $priceP, ')
          ..write('mrpP: $mrpP, ')
          ..write('costP: $costP, ')
          ..write('plu: $plu, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LBarcodesTable extends LBarcodes
    with TableInfo<$LBarcodesTable, LBarcode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LBarcodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
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
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qtyPerScanMilliMeta = const VerificationMeta(
    'qtyPerScanMilli',
  );
  @override
  late final GeneratedColumn<int> qtyPerScanMilli = GeneratedColumn<int>(
    'qty_per_scan_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1000),
  );
  @override
  List<GeneratedColumn> get $columns => [
    code,
    variantId,
    productId,
    unit,
    qtyPerScanMilli,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'l_barcodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LBarcode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('qty_per_scan_milli')) {
      context.handle(
        _qtyPerScanMilliMeta,
        qtyPerScanMilli.isAcceptableOrUnknown(
          data['qty_per_scan_milli']!,
          _qtyPerScanMilliMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  LBarcode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LBarcode(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      qtyPerScanMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty_per_scan_milli'],
      )!,
    );
  }

  @override
  $LBarcodesTable createAlias(String alias) {
    return $LBarcodesTable(attachedDatabase, alias);
  }
}

class LBarcode extends DataClass implements Insertable<LBarcode> {
  final String code;
  final String variantId;
  final String productId;
  final String? unit;
  final int qtyPerScanMilli;
  const LBarcode({
    required this.code,
    required this.variantId,
    required this.productId,
    this.unit,
    required this.qtyPerScanMilli,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['variant_id'] = Variable<String>(variantId);
    map['product_id'] = Variable<String>(productId);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['qty_per_scan_milli'] = Variable<int>(qtyPerScanMilli);
    return map;
  }

  LBarcodesCompanion toCompanion(bool nullToAbsent) {
    return LBarcodesCompanion(
      code: Value(code),
      variantId: Value(variantId),
      productId: Value(productId),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      qtyPerScanMilli: Value(qtyPerScanMilli),
    );
  }

  factory LBarcode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LBarcode(
      code: serializer.fromJson<String>(json['code']),
      variantId: serializer.fromJson<String>(json['variantId']),
      productId: serializer.fromJson<String>(json['productId']),
      unit: serializer.fromJson<String?>(json['unit']),
      qtyPerScanMilli: serializer.fromJson<int>(json['qtyPerScanMilli']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'variantId': serializer.toJson<String>(variantId),
      'productId': serializer.toJson<String>(productId),
      'unit': serializer.toJson<String?>(unit),
      'qtyPerScanMilli': serializer.toJson<int>(qtyPerScanMilli),
    };
  }

  LBarcode copyWith({
    String? code,
    String? variantId,
    String? productId,
    Value<String?> unit = const Value.absent(),
    int? qtyPerScanMilli,
  }) => LBarcode(
    code: code ?? this.code,
    variantId: variantId ?? this.variantId,
    productId: productId ?? this.productId,
    unit: unit.present ? unit.value : this.unit,
    qtyPerScanMilli: qtyPerScanMilli ?? this.qtyPerScanMilli,
  );
  LBarcode copyWithCompanion(LBarcodesCompanion data) {
    return LBarcode(
      code: data.code.present ? data.code.value : this.code,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      productId: data.productId.present ? data.productId.value : this.productId,
      unit: data.unit.present ? data.unit.value : this.unit,
      qtyPerScanMilli: data.qtyPerScanMilli.present
          ? data.qtyPerScanMilli.value
          : this.qtyPerScanMilli,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LBarcode(')
          ..write('code: $code, ')
          ..write('variantId: $variantId, ')
          ..write('productId: $productId, ')
          ..write('unit: $unit, ')
          ..write('qtyPerScanMilli: $qtyPerScanMilli')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(code, variantId, productId, unit, qtyPerScanMilli);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LBarcode &&
          other.code == this.code &&
          other.variantId == this.variantId &&
          other.productId == this.productId &&
          other.unit == this.unit &&
          other.qtyPerScanMilli == this.qtyPerScanMilli);
}

class LBarcodesCompanion extends UpdateCompanion<LBarcode> {
  final Value<String> code;
  final Value<String> variantId;
  final Value<String> productId;
  final Value<String?> unit;
  final Value<int> qtyPerScanMilli;
  final Value<int> rowid;
  const LBarcodesCompanion({
    this.code = const Value.absent(),
    this.variantId = const Value.absent(),
    this.productId = const Value.absent(),
    this.unit = const Value.absent(),
    this.qtyPerScanMilli = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LBarcodesCompanion.insert({
    required String code,
    required String variantId,
    required String productId,
    this.unit = const Value.absent(),
    this.qtyPerScanMilli = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       variantId = Value(variantId),
       productId = Value(productId);
  static Insertable<LBarcode> custom({
    Expression<String>? code,
    Expression<String>? variantId,
    Expression<String>? productId,
    Expression<String>? unit,
    Expression<int>? qtyPerScanMilli,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (variantId != null) 'variant_id': variantId,
      if (productId != null) 'product_id': productId,
      if (unit != null) 'unit': unit,
      if (qtyPerScanMilli != null) 'qty_per_scan_milli': qtyPerScanMilli,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LBarcodesCompanion copyWith({
    Value<String>? code,
    Value<String>? variantId,
    Value<String>? productId,
    Value<String?>? unit,
    Value<int>? qtyPerScanMilli,
    Value<int>? rowid,
  }) {
    return LBarcodesCompanion(
      code: code ?? this.code,
      variantId: variantId ?? this.variantId,
      productId: productId ?? this.productId,
      unit: unit ?? this.unit,
      qtyPerScanMilli: qtyPerScanMilli ?? this.qtyPerScanMilli,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (qtyPerScanMilli.present) {
      map['qty_per_scan_milli'] = Variable<int>(qtyPerScanMilli.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LBarcodesCompanion(')
          ..write('code: $code, ')
          ..write('variantId: $variantId, ')
          ..write('productId: $productId, ')
          ..write('unit: $unit, ')
          ..write('qtyPerScanMilli: $qtyPerScanMilli, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LCustomersTable extends LCustomers
    with TableInfo<$LCustomersTable, LCustomer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LCustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _creditLimitPMeta = const VerificationMeta(
    'creditLimitP',
  );
  @override
  late final GeneratedColumn<int> creditLimitP = GeneratedColumn<int>(
    'credit_limit_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _balancePMeta = const VerificationMeta(
    'balanceP',
  );
  @override
  late final GeneratedColumn<int> balanceP = GeneratedColumn<int>(
    'balance_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    phone,
    address,
    creditLimitP,
    balanceP,
    points,
    notes,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'l_customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<LCustomer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('credit_limit_p')) {
      context.handle(
        _creditLimitPMeta,
        creditLimitP.isAcceptableOrUnknown(
          data['credit_limit_p']!,
          _creditLimitPMeta,
        ),
      );
    }
    if (data.containsKey('balance_p')) {
      context.handle(
        _balancePMeta,
        balanceP.isAcceptableOrUnknown(data['balance_p']!, _balancePMeta),
      );
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LCustomer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LCustomer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      creditLimitP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credit_limit_p'],
      )!,
      balanceP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_p'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $LCustomersTable createAlias(String alias) {
    return $LCustomersTable(attachedDatabase, alias);
  }
}

class LCustomer extends DataClass implements Insertable<LCustomer> {
  final String id;
  final String name;
  final String phone;
  final String address;
  final int creditLimitP;
  final int balanceP;
  final int points;
  final String notes;
  final bool active;
  const LCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.creditLimitP,
    required this.balanceP,
    required this.points,
    required this.notes,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['address'] = Variable<String>(address);
    map['credit_limit_p'] = Variable<int>(creditLimitP);
    map['balance_p'] = Variable<int>(balanceP);
    map['points'] = Variable<int>(points);
    map['notes'] = Variable<String>(notes);
    map['active'] = Variable<bool>(active);
    return map;
  }

  LCustomersCompanion toCompanion(bool nullToAbsent) {
    return LCustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      address: Value(address),
      creditLimitP: Value(creditLimitP),
      balanceP: Value(balanceP),
      points: Value(points),
      notes: Value(notes),
      active: Value(active),
    );
  }

  factory LCustomer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LCustomer(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      address: serializer.fromJson<String>(json['address']),
      creditLimitP: serializer.fromJson<int>(json['creditLimitP']),
      balanceP: serializer.fromJson<int>(json['balanceP']),
      points: serializer.fromJson<int>(json['points']),
      notes: serializer.fromJson<String>(json['notes']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'address': serializer.toJson<String>(address),
      'creditLimitP': serializer.toJson<int>(creditLimitP),
      'balanceP': serializer.toJson<int>(balanceP),
      'points': serializer.toJson<int>(points),
      'notes': serializer.toJson<String>(notes),
      'active': serializer.toJson<bool>(active),
    };
  }

  LCustomer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    int? creditLimitP,
    int? balanceP,
    int? points,
    String? notes,
    bool? active,
  }) => LCustomer(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    creditLimitP: creditLimitP ?? this.creditLimitP,
    balanceP: balanceP ?? this.balanceP,
    points: points ?? this.points,
    notes: notes ?? this.notes,
    active: active ?? this.active,
  );
  LCustomer copyWithCompanion(LCustomersCompanion data) {
    return LCustomer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      creditLimitP: data.creditLimitP.present
          ? data.creditLimitP.value
          : this.creditLimitP,
      balanceP: data.balanceP.present ? data.balanceP.value : this.balanceP,
      points: data.points.present ? data.points.value : this.points,
      notes: data.notes.present ? data.notes.value : this.notes,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LCustomer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('creditLimitP: $creditLimitP, ')
          ..write('balanceP: $balanceP, ')
          ..write('points: $points, ')
          ..write('notes: $notes, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    phone,
    address,
    creditLimitP,
    balanceP,
    points,
    notes,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LCustomer &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.creditLimitP == this.creditLimitP &&
          other.balanceP == this.balanceP &&
          other.points == this.points &&
          other.notes == this.notes &&
          other.active == this.active);
}

class LCustomersCompanion extends UpdateCompanion<LCustomer> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<String> address;
  final Value<int> creditLimitP;
  final Value<int> balanceP;
  final Value<int> points;
  final Value<String> notes;
  final Value<bool> active;
  final Value<int> rowid;
  const LCustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.creditLimitP = const Value.absent(),
    this.balanceP = const Value.absent(),
    this.points = const Value.absent(),
    this.notes = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LCustomersCompanion.insert({
    required String id,
    required String name,
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.creditLimitP = const Value.absent(),
    this.balanceP = const Value.absent(),
    this.points = const Value.absent(),
    this.notes = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<LCustomer> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<int>? creditLimitP,
    Expression<int>? balanceP,
    Expression<int>? points,
    Expression<String>? notes,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (creditLimitP != null) 'credit_limit_p': creditLimitP,
      if (balanceP != null) 'balance_p': balanceP,
      if (points != null) 'points': points,
      if (notes != null) 'notes': notes,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LCustomersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? phone,
    Value<String>? address,
    Value<int>? creditLimitP,
    Value<int>? balanceP,
    Value<int>? points,
    Value<String>? notes,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return LCustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      creditLimitP: creditLimitP ?? this.creditLimitP,
      balanceP: balanceP ?? this.balanceP,
      points: points ?? this.points,
      notes: notes ?? this.notes,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (creditLimitP.present) {
      map['credit_limit_p'] = Variable<int>(creditLimitP.value);
    }
    if (balanceP.present) {
      map['balance_p'] = Variable<int>(balanceP.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LCustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('creditLimitP: $creditLimitP, ')
          ..write('balanceP: $balanceP, ')
          ..write('points: $points, ')
          ..write('notes: $notes, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LStockTable extends LStock with TableInfo<$LStockTable, LStockData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LStockTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _onHandMilliMeta = const VerificationMeta(
    'onHandMilli',
  );
  @override
  late final GeneratedColumn<int> onHandMilli = GeneratedColumn<int>(
    'on_hand_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [branchId, variantId, onHandMilli];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'l_stock';
  @override
  VerificationContext validateIntegrity(
    Insertable<LStockData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('on_hand_milli')) {
      context.handle(
        _onHandMilliMeta,
        onHandMilli.isAcceptableOrUnknown(
          data['on_hand_milli']!,
          _onHandMilliMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_onHandMilliMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {branchId, variantId};
  @override
  LStockData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LStockData(
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      )!,
      onHandMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}on_hand_milli'],
      )!,
    );
  }

  @override
  $LStockTable createAlias(String alias) {
    return $LStockTable(attachedDatabase, alias);
  }
}

class LStockData extends DataClass implements Insertable<LStockData> {
  final String branchId;
  final String variantId;
  final int onHandMilli;
  const LStockData({
    required this.branchId,
    required this.variantId,
    required this.onHandMilli,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['branch_id'] = Variable<String>(branchId);
    map['variant_id'] = Variable<String>(variantId);
    map['on_hand_milli'] = Variable<int>(onHandMilli);
    return map;
  }

  LStockCompanion toCompanion(bool nullToAbsent) {
    return LStockCompanion(
      branchId: Value(branchId),
      variantId: Value(variantId),
      onHandMilli: Value(onHandMilli),
    );
  }

  factory LStockData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LStockData(
      branchId: serializer.fromJson<String>(json['branchId']),
      variantId: serializer.fromJson<String>(json['variantId']),
      onHandMilli: serializer.fromJson<int>(json['onHandMilli']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'branchId': serializer.toJson<String>(branchId),
      'variantId': serializer.toJson<String>(variantId),
      'onHandMilli': serializer.toJson<int>(onHandMilli),
    };
  }

  LStockData copyWith({
    String? branchId,
    String? variantId,
    int? onHandMilli,
  }) => LStockData(
    branchId: branchId ?? this.branchId,
    variantId: variantId ?? this.variantId,
    onHandMilli: onHandMilli ?? this.onHandMilli,
  );
  LStockData copyWithCompanion(LStockCompanion data) {
    return LStockData(
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      onHandMilli: data.onHandMilli.present
          ? data.onHandMilli.value
          : this.onHandMilli,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LStockData(')
          ..write('branchId: $branchId, ')
          ..write('variantId: $variantId, ')
          ..write('onHandMilli: $onHandMilli')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(branchId, variantId, onHandMilli);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LStockData &&
          other.branchId == this.branchId &&
          other.variantId == this.variantId &&
          other.onHandMilli == this.onHandMilli);
}

class LStockCompanion extends UpdateCompanion<LStockData> {
  final Value<String> branchId;
  final Value<String> variantId;
  final Value<int> onHandMilli;
  final Value<int> rowid;
  const LStockCompanion({
    this.branchId = const Value.absent(),
    this.variantId = const Value.absent(),
    this.onHandMilli = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LStockCompanion.insert({
    required String branchId,
    required String variantId,
    required int onHandMilli,
    this.rowid = const Value.absent(),
  }) : branchId = Value(branchId),
       variantId = Value(variantId),
       onHandMilli = Value(onHandMilli);
  static Insertable<LStockData> custom({
    Expression<String>? branchId,
    Expression<String>? variantId,
    Expression<int>? onHandMilli,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (branchId != null) 'branch_id': branchId,
      if (variantId != null) 'variant_id': variantId,
      if (onHandMilli != null) 'on_hand_milli': onHandMilli,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LStockCompanion copyWith({
    Value<String>? branchId,
    Value<String>? variantId,
    Value<int>? onHandMilli,
    Value<int>? rowid,
  }) {
    return LStockCompanion(
      branchId: branchId ?? this.branchId,
      variantId: variantId ?? this.variantId,
      onHandMilli: onHandMilli ?? this.onHandMilli,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (onHandMilli.present) {
      map['on_hand_milli'] = Variable<int>(onHandMilli.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LStockCompanion(')
          ..write('branchId: $branchId, ')
          ..write('variantId: $variantId, ')
          ..write('onHandMilli: $onHandMilli, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LSalesTable extends LSales with TableInfo<$LSalesTable, LSale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LSalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invoiceNoMeta = const VerificationMeta(
    'invoiceNo',
  );
  @override
  late final GeneratedColumn<String> invoiceNo = GeneratedColumn<String>(
    'invoice_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _soldAtMeta = const VerificationMeta('soldAt');
  @override
  late final GeneratedColumn<DateTime> soldAt = GeneratedColumn<DateTime>(
    'sold_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
    defaultValue: const Constant('completed'),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Walk-in'),
  );
  static const VerificationMeta _subtotalPMeta = const VerificationMeta(
    'subtotalP',
  );
  @override
  late final GeneratedColumn<int> subtotalP = GeneratedColumn<int>(
    'subtotal_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountPMeta = const VerificationMeta(
    'discountP',
  );
  @override
  late final GeneratedColumn<int> discountP = GeneratedColumn<int>(
    'discount_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxPMeta = const VerificationMeta('taxP');
  @override
  late final GeneratedColumn<int> taxP = GeneratedColumn<int>(
    'tax_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _roundingPMeta = const VerificationMeta(
    'roundingP',
  );
  @override
  late final GeneratedColumn<int> roundingP = GeneratedColumn<int>(
    'rounding_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalPMeta = const VerificationMeta('totalP');
  @override
  late final GeneratedColumn<int> totalP = GeneratedColumn<int>(
    'total_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidPMeta = const VerificationMeta('paidP');
  @override
  late final GeneratedColumn<int> paidP = GeneratedColumn<int>(
    'paid_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxModeMeta = const VerificationMeta(
    'taxMode',
  );
  @override
  late final GeneratedColumn<String> taxMode = GeneratedColumn<String>(
    'tax_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('inclusive'),
  );
  static const VerificationMeta _cashRoundingMeta = const VerificationMeta(
    'cashRounding',
  );
  @override
  late final GeneratedColumn<bool> cashRounding = GeneratedColumn<bool>(
    'cash_rounding',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cash_rounding" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
    'cashier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashierNameMeta = const VerificationMeta(
    'cashierName',
  );
  @override
  late final GeneratedColumn<String> cashierName = GeneratedColumn<String>(
    'cashier_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pointsEarnedMeta = const VerificationMeta(
    'pointsEarned',
  );
  @override
  late final GeneratedColumn<int> pointsEarned = GeneratedColumn<int>(
    'points_earned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _flagsMeta = const VerificationMeta('flags');
  @override
  late final GeneratedColumn<String> flags = GeneratedColumn<String>(
    'flags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    invoiceNo,
    soldAt,
    status,
    customerId,
    customerName,
    subtotalP,
    discountP,
    taxP,
    roundingP,
    totalP,
    paidP,
    taxMode,
    cashRounding,
    note,
    cashierId,
    cashierName,
    branchId,
    shiftId,
    pointsEarned,
    syncState,
    flags,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'l_sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<LSale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('invoice_no')) {
      context.handle(
        _invoiceNoMeta,
        invoiceNo.isAcceptableOrUnknown(data['invoice_no']!, _invoiceNoMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceNoMeta);
    }
    if (data.containsKey('sold_at')) {
      context.handle(
        _soldAtMeta,
        soldAt.isAcceptableOrUnknown(data['sold_at']!, _soldAtMeta),
      );
    } else if (isInserting) {
      context.missing(_soldAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('subtotal_p')) {
      context.handle(
        _subtotalPMeta,
        subtotalP.isAcceptableOrUnknown(data['subtotal_p']!, _subtotalPMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalPMeta);
    }
    if (data.containsKey('discount_p')) {
      context.handle(
        _discountPMeta,
        discountP.isAcceptableOrUnknown(data['discount_p']!, _discountPMeta),
      );
    }
    if (data.containsKey('tax_p')) {
      context.handle(
        _taxPMeta,
        taxP.isAcceptableOrUnknown(data['tax_p']!, _taxPMeta),
      );
    }
    if (data.containsKey('rounding_p')) {
      context.handle(
        _roundingPMeta,
        roundingP.isAcceptableOrUnknown(data['rounding_p']!, _roundingPMeta),
      );
    }
    if (data.containsKey('total_p')) {
      context.handle(
        _totalPMeta,
        totalP.isAcceptableOrUnknown(data['total_p']!, _totalPMeta),
      );
    } else if (isInserting) {
      context.missing(_totalPMeta);
    }
    if (data.containsKey('paid_p')) {
      context.handle(
        _paidPMeta,
        paidP.isAcceptableOrUnknown(data['paid_p']!, _paidPMeta),
      );
    } else if (isInserting) {
      context.missing(_paidPMeta);
    }
    if (data.containsKey('tax_mode')) {
      context.handle(
        _taxModeMeta,
        taxMode.isAcceptableOrUnknown(data['tax_mode']!, _taxModeMeta),
      );
    }
    if (data.containsKey('cash_rounding')) {
      context.handle(
        _cashRoundingMeta,
        cashRounding.isAcceptableOrUnknown(
          data['cash_rounding']!,
          _cashRoundingMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('cashier_name')) {
      context.handle(
        _cashierNameMeta,
        cashierName.isAcceptableOrUnknown(
          data['cashier_name']!,
          _cashierNameMeta,
        ),
      );
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    }
    if (data.containsKey('points_earned')) {
      context.handle(
        _pointsEarnedMeta,
        pointsEarned.isAcceptableOrUnknown(
          data['points_earned']!,
          _pointsEarnedMeta,
        ),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('flags')) {
      context.handle(
        _flagsMeta,
        flags.isAcceptableOrUnknown(data['flags']!, _flagsMeta),
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
  LSale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LSale(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      invoiceNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_no'],
      )!,
      soldAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sold_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      subtotalP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal_p'],
      )!,
      discountP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_p'],
      )!,
      taxP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_p'],
      )!,
      roundingP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rounding_p'],
      )!,
      totalP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_p'],
      )!,
      paidP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_p'],
      )!,
      taxMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_mode'],
      )!,
      cashRounding: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cash_rounding'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      cashierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_id'],
      )!,
      cashierName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_name'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      ),
      pointsEarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points_earned'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      flags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flags'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LSalesTable createAlias(String alias) {
    return $LSalesTable(attachedDatabase, alias);
  }
}

class LSale extends DataClass implements Insertable<LSale> {
  final String id;
  final String invoiceNo;
  final DateTime soldAt;
  final String status;
  final String? customerId;
  final String customerName;
  final int subtotalP;
  final int discountP;
  final int taxP;
  final int roundingP;
  final int totalP;
  final int paidP;
  final String taxMode;
  final bool cashRounding;
  final String note;
  final String cashierId;
  final String cashierName;
  final String branchId;
  final String? shiftId;
  final int pointsEarned;

  /// pending (waiting to sync) | synced | failed (the server refused it — see Sync Center)
  final String syncState;
  final String flags;
  final DateTime createdAt;
  const LSale({
    required this.id,
    required this.invoiceNo,
    required this.soldAt,
    required this.status,
    this.customerId,
    required this.customerName,
    required this.subtotalP,
    required this.discountP,
    required this.taxP,
    required this.roundingP,
    required this.totalP,
    required this.paidP,
    required this.taxMode,
    required this.cashRounding,
    required this.note,
    required this.cashierId,
    required this.cashierName,
    required this.branchId,
    this.shiftId,
    required this.pointsEarned,
    required this.syncState,
    required this.flags,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['invoice_no'] = Variable<String>(invoiceNo);
    map['sold_at'] = Variable<DateTime>(soldAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['customer_name'] = Variable<String>(customerName);
    map['subtotal_p'] = Variable<int>(subtotalP);
    map['discount_p'] = Variable<int>(discountP);
    map['tax_p'] = Variable<int>(taxP);
    map['rounding_p'] = Variable<int>(roundingP);
    map['total_p'] = Variable<int>(totalP);
    map['paid_p'] = Variable<int>(paidP);
    map['tax_mode'] = Variable<String>(taxMode);
    map['cash_rounding'] = Variable<bool>(cashRounding);
    map['note'] = Variable<String>(note);
    map['cashier_id'] = Variable<String>(cashierId);
    map['cashier_name'] = Variable<String>(cashierName);
    map['branch_id'] = Variable<String>(branchId);
    if (!nullToAbsent || shiftId != null) {
      map['shift_id'] = Variable<String>(shiftId);
    }
    map['points_earned'] = Variable<int>(pointsEarned);
    map['sync_state'] = Variable<String>(syncState);
    map['flags'] = Variable<String>(flags);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LSalesCompanion toCompanion(bool nullToAbsent) {
    return LSalesCompanion(
      id: Value(id),
      invoiceNo: Value(invoiceNo),
      soldAt: Value(soldAt),
      status: Value(status),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      customerName: Value(customerName),
      subtotalP: Value(subtotalP),
      discountP: Value(discountP),
      taxP: Value(taxP),
      roundingP: Value(roundingP),
      totalP: Value(totalP),
      paidP: Value(paidP),
      taxMode: Value(taxMode),
      cashRounding: Value(cashRounding),
      note: Value(note),
      cashierId: Value(cashierId),
      cashierName: Value(cashierName),
      branchId: Value(branchId),
      shiftId: shiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftId),
      pointsEarned: Value(pointsEarned),
      syncState: Value(syncState),
      flags: Value(flags),
      createdAt: Value(createdAt),
    );
  }

  factory LSale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LSale(
      id: serializer.fromJson<String>(json['id']),
      invoiceNo: serializer.fromJson<String>(json['invoiceNo']),
      soldAt: serializer.fromJson<DateTime>(json['soldAt']),
      status: serializer.fromJson<String>(json['status']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      customerName: serializer.fromJson<String>(json['customerName']),
      subtotalP: serializer.fromJson<int>(json['subtotalP']),
      discountP: serializer.fromJson<int>(json['discountP']),
      taxP: serializer.fromJson<int>(json['taxP']),
      roundingP: serializer.fromJson<int>(json['roundingP']),
      totalP: serializer.fromJson<int>(json['totalP']),
      paidP: serializer.fromJson<int>(json['paidP']),
      taxMode: serializer.fromJson<String>(json['taxMode']),
      cashRounding: serializer.fromJson<bool>(json['cashRounding']),
      note: serializer.fromJson<String>(json['note']),
      cashierId: serializer.fromJson<String>(json['cashierId']),
      cashierName: serializer.fromJson<String>(json['cashierName']),
      branchId: serializer.fromJson<String>(json['branchId']),
      shiftId: serializer.fromJson<String?>(json['shiftId']),
      pointsEarned: serializer.fromJson<int>(json['pointsEarned']),
      syncState: serializer.fromJson<String>(json['syncState']),
      flags: serializer.fromJson<String>(json['flags']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'invoiceNo': serializer.toJson<String>(invoiceNo),
      'soldAt': serializer.toJson<DateTime>(soldAt),
      'status': serializer.toJson<String>(status),
      'customerId': serializer.toJson<String?>(customerId),
      'customerName': serializer.toJson<String>(customerName),
      'subtotalP': serializer.toJson<int>(subtotalP),
      'discountP': serializer.toJson<int>(discountP),
      'taxP': serializer.toJson<int>(taxP),
      'roundingP': serializer.toJson<int>(roundingP),
      'totalP': serializer.toJson<int>(totalP),
      'paidP': serializer.toJson<int>(paidP),
      'taxMode': serializer.toJson<String>(taxMode),
      'cashRounding': serializer.toJson<bool>(cashRounding),
      'note': serializer.toJson<String>(note),
      'cashierId': serializer.toJson<String>(cashierId),
      'cashierName': serializer.toJson<String>(cashierName),
      'branchId': serializer.toJson<String>(branchId),
      'shiftId': serializer.toJson<String?>(shiftId),
      'pointsEarned': serializer.toJson<int>(pointsEarned),
      'syncState': serializer.toJson<String>(syncState),
      'flags': serializer.toJson<String>(flags),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LSale copyWith({
    String? id,
    String? invoiceNo,
    DateTime? soldAt,
    String? status,
    Value<String?> customerId = const Value.absent(),
    String? customerName,
    int? subtotalP,
    int? discountP,
    int? taxP,
    int? roundingP,
    int? totalP,
    int? paidP,
    String? taxMode,
    bool? cashRounding,
    String? note,
    String? cashierId,
    String? cashierName,
    String? branchId,
    Value<String?> shiftId = const Value.absent(),
    int? pointsEarned,
    String? syncState,
    String? flags,
    DateTime? createdAt,
  }) => LSale(
    id: id ?? this.id,
    invoiceNo: invoiceNo ?? this.invoiceNo,
    soldAt: soldAt ?? this.soldAt,
    status: status ?? this.status,
    customerId: customerId.present ? customerId.value : this.customerId,
    customerName: customerName ?? this.customerName,
    subtotalP: subtotalP ?? this.subtotalP,
    discountP: discountP ?? this.discountP,
    taxP: taxP ?? this.taxP,
    roundingP: roundingP ?? this.roundingP,
    totalP: totalP ?? this.totalP,
    paidP: paidP ?? this.paidP,
    taxMode: taxMode ?? this.taxMode,
    cashRounding: cashRounding ?? this.cashRounding,
    note: note ?? this.note,
    cashierId: cashierId ?? this.cashierId,
    cashierName: cashierName ?? this.cashierName,
    branchId: branchId ?? this.branchId,
    shiftId: shiftId.present ? shiftId.value : this.shiftId,
    pointsEarned: pointsEarned ?? this.pointsEarned,
    syncState: syncState ?? this.syncState,
    flags: flags ?? this.flags,
    createdAt: createdAt ?? this.createdAt,
  );
  LSale copyWithCompanion(LSalesCompanion data) {
    return LSale(
      id: data.id.present ? data.id.value : this.id,
      invoiceNo: data.invoiceNo.present ? data.invoiceNo.value : this.invoiceNo,
      soldAt: data.soldAt.present ? data.soldAt.value : this.soldAt,
      status: data.status.present ? data.status.value : this.status,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      subtotalP: data.subtotalP.present ? data.subtotalP.value : this.subtotalP,
      discountP: data.discountP.present ? data.discountP.value : this.discountP,
      taxP: data.taxP.present ? data.taxP.value : this.taxP,
      roundingP: data.roundingP.present ? data.roundingP.value : this.roundingP,
      totalP: data.totalP.present ? data.totalP.value : this.totalP,
      paidP: data.paidP.present ? data.paidP.value : this.paidP,
      taxMode: data.taxMode.present ? data.taxMode.value : this.taxMode,
      cashRounding: data.cashRounding.present
          ? data.cashRounding.value
          : this.cashRounding,
      note: data.note.present ? data.note.value : this.note,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      cashierName: data.cashierName.present
          ? data.cashierName.value
          : this.cashierName,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      pointsEarned: data.pointsEarned.present
          ? data.pointsEarned.value
          : this.pointsEarned,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      flags: data.flags.present ? data.flags.value : this.flags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LSale(')
          ..write('id: $id, ')
          ..write('invoiceNo: $invoiceNo, ')
          ..write('soldAt: $soldAt, ')
          ..write('status: $status, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('subtotalP: $subtotalP, ')
          ..write('discountP: $discountP, ')
          ..write('taxP: $taxP, ')
          ..write('roundingP: $roundingP, ')
          ..write('totalP: $totalP, ')
          ..write('paidP: $paidP, ')
          ..write('taxMode: $taxMode, ')
          ..write('cashRounding: $cashRounding, ')
          ..write('note: $note, ')
          ..write('cashierId: $cashierId, ')
          ..write('cashierName: $cashierName, ')
          ..write('branchId: $branchId, ')
          ..write('shiftId: $shiftId, ')
          ..write('pointsEarned: $pointsEarned, ')
          ..write('syncState: $syncState, ')
          ..write('flags: $flags, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    invoiceNo,
    soldAt,
    status,
    customerId,
    customerName,
    subtotalP,
    discountP,
    taxP,
    roundingP,
    totalP,
    paidP,
    taxMode,
    cashRounding,
    note,
    cashierId,
    cashierName,
    branchId,
    shiftId,
    pointsEarned,
    syncState,
    flags,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LSale &&
          other.id == this.id &&
          other.invoiceNo == this.invoiceNo &&
          other.soldAt == this.soldAt &&
          other.status == this.status &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName &&
          other.subtotalP == this.subtotalP &&
          other.discountP == this.discountP &&
          other.taxP == this.taxP &&
          other.roundingP == this.roundingP &&
          other.totalP == this.totalP &&
          other.paidP == this.paidP &&
          other.taxMode == this.taxMode &&
          other.cashRounding == this.cashRounding &&
          other.note == this.note &&
          other.cashierId == this.cashierId &&
          other.cashierName == this.cashierName &&
          other.branchId == this.branchId &&
          other.shiftId == this.shiftId &&
          other.pointsEarned == this.pointsEarned &&
          other.syncState == this.syncState &&
          other.flags == this.flags &&
          other.createdAt == this.createdAt);
}

class LSalesCompanion extends UpdateCompanion<LSale> {
  final Value<String> id;
  final Value<String> invoiceNo;
  final Value<DateTime> soldAt;
  final Value<String> status;
  final Value<String?> customerId;
  final Value<String> customerName;
  final Value<int> subtotalP;
  final Value<int> discountP;
  final Value<int> taxP;
  final Value<int> roundingP;
  final Value<int> totalP;
  final Value<int> paidP;
  final Value<String> taxMode;
  final Value<bool> cashRounding;
  final Value<String> note;
  final Value<String> cashierId;
  final Value<String> cashierName;
  final Value<String> branchId;
  final Value<String?> shiftId;
  final Value<int> pointsEarned;
  final Value<String> syncState;
  final Value<String> flags;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LSalesCompanion({
    this.id = const Value.absent(),
    this.invoiceNo = const Value.absent(),
    this.soldAt = const Value.absent(),
    this.status = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.subtotalP = const Value.absent(),
    this.discountP = const Value.absent(),
    this.taxP = const Value.absent(),
    this.roundingP = const Value.absent(),
    this.totalP = const Value.absent(),
    this.paidP = const Value.absent(),
    this.taxMode = const Value.absent(),
    this.cashRounding = const Value.absent(),
    this.note = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.cashierName = const Value.absent(),
    this.branchId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.pointsEarned = const Value.absent(),
    this.syncState = const Value.absent(),
    this.flags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LSalesCompanion.insert({
    required String id,
    required String invoiceNo,
    required DateTime soldAt,
    this.status = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    required int subtotalP,
    this.discountP = const Value.absent(),
    this.taxP = const Value.absent(),
    this.roundingP = const Value.absent(),
    required int totalP,
    required int paidP,
    this.taxMode = const Value.absent(),
    this.cashRounding = const Value.absent(),
    this.note = const Value.absent(),
    required String cashierId,
    this.cashierName = const Value.absent(),
    required String branchId,
    this.shiftId = const Value.absent(),
    this.pointsEarned = const Value.absent(),
    this.syncState = const Value.absent(),
    this.flags = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       invoiceNo = Value(invoiceNo),
       soldAt = Value(soldAt),
       subtotalP = Value(subtotalP),
       totalP = Value(totalP),
       paidP = Value(paidP),
       cashierId = Value(cashierId),
       branchId = Value(branchId),
       createdAt = Value(createdAt);
  static Insertable<LSale> custom({
    Expression<String>? id,
    Expression<String>? invoiceNo,
    Expression<DateTime>? soldAt,
    Expression<String>? status,
    Expression<String>? customerId,
    Expression<String>? customerName,
    Expression<int>? subtotalP,
    Expression<int>? discountP,
    Expression<int>? taxP,
    Expression<int>? roundingP,
    Expression<int>? totalP,
    Expression<int>? paidP,
    Expression<String>? taxMode,
    Expression<bool>? cashRounding,
    Expression<String>? note,
    Expression<String>? cashierId,
    Expression<String>? cashierName,
    Expression<String>? branchId,
    Expression<String>? shiftId,
    Expression<int>? pointsEarned,
    Expression<String>? syncState,
    Expression<String>? flags,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceNo != null) 'invoice_no': invoiceNo,
      if (soldAt != null) 'sold_at': soldAt,
      if (status != null) 'status': status,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (subtotalP != null) 'subtotal_p': subtotalP,
      if (discountP != null) 'discount_p': discountP,
      if (taxP != null) 'tax_p': taxP,
      if (roundingP != null) 'rounding_p': roundingP,
      if (totalP != null) 'total_p': totalP,
      if (paidP != null) 'paid_p': paidP,
      if (taxMode != null) 'tax_mode': taxMode,
      if (cashRounding != null) 'cash_rounding': cashRounding,
      if (note != null) 'note': note,
      if (cashierId != null) 'cashier_id': cashierId,
      if (cashierName != null) 'cashier_name': cashierName,
      if (branchId != null) 'branch_id': branchId,
      if (shiftId != null) 'shift_id': shiftId,
      if (pointsEarned != null) 'points_earned': pointsEarned,
      if (syncState != null) 'sync_state': syncState,
      if (flags != null) 'flags': flags,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LSalesCompanion copyWith({
    Value<String>? id,
    Value<String>? invoiceNo,
    Value<DateTime>? soldAt,
    Value<String>? status,
    Value<String?>? customerId,
    Value<String>? customerName,
    Value<int>? subtotalP,
    Value<int>? discountP,
    Value<int>? taxP,
    Value<int>? roundingP,
    Value<int>? totalP,
    Value<int>? paidP,
    Value<String>? taxMode,
    Value<bool>? cashRounding,
    Value<String>? note,
    Value<String>? cashierId,
    Value<String>? cashierName,
    Value<String>? branchId,
    Value<String?>? shiftId,
    Value<int>? pointsEarned,
    Value<String>? syncState,
    Value<String>? flags,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LSalesCompanion(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      soldAt: soldAt ?? this.soldAt,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      subtotalP: subtotalP ?? this.subtotalP,
      discountP: discountP ?? this.discountP,
      taxP: taxP ?? this.taxP,
      roundingP: roundingP ?? this.roundingP,
      totalP: totalP ?? this.totalP,
      paidP: paidP ?? this.paidP,
      taxMode: taxMode ?? this.taxMode,
      cashRounding: cashRounding ?? this.cashRounding,
      note: note ?? this.note,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      branchId: branchId ?? this.branchId,
      shiftId: shiftId ?? this.shiftId,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      syncState: syncState ?? this.syncState,
      flags: flags ?? this.flags,
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
    if (invoiceNo.present) {
      map['invoice_no'] = Variable<String>(invoiceNo.value);
    }
    if (soldAt.present) {
      map['sold_at'] = Variable<DateTime>(soldAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (subtotalP.present) {
      map['subtotal_p'] = Variable<int>(subtotalP.value);
    }
    if (discountP.present) {
      map['discount_p'] = Variable<int>(discountP.value);
    }
    if (taxP.present) {
      map['tax_p'] = Variable<int>(taxP.value);
    }
    if (roundingP.present) {
      map['rounding_p'] = Variable<int>(roundingP.value);
    }
    if (totalP.present) {
      map['total_p'] = Variable<int>(totalP.value);
    }
    if (paidP.present) {
      map['paid_p'] = Variable<int>(paidP.value);
    }
    if (taxMode.present) {
      map['tax_mode'] = Variable<String>(taxMode.value);
    }
    if (cashRounding.present) {
      map['cash_rounding'] = Variable<bool>(cashRounding.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (cashierName.present) {
      map['cashier_name'] = Variable<String>(cashierName.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (pointsEarned.present) {
      map['points_earned'] = Variable<int>(pointsEarned.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (flags.present) {
      map['flags'] = Variable<String>(flags.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LSalesCompanion(')
          ..write('id: $id, ')
          ..write('invoiceNo: $invoiceNo, ')
          ..write('soldAt: $soldAt, ')
          ..write('status: $status, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('subtotalP: $subtotalP, ')
          ..write('discountP: $discountP, ')
          ..write('taxP: $taxP, ')
          ..write('roundingP: $roundingP, ')
          ..write('totalP: $totalP, ')
          ..write('paidP: $paidP, ')
          ..write('taxMode: $taxMode, ')
          ..write('cashRounding: $cashRounding, ')
          ..write('note: $note, ')
          ..write('cashierId: $cashierId, ')
          ..write('cashierName: $cashierName, ')
          ..write('branchId: $branchId, ')
          ..write('shiftId: $shiftId, ')
          ..write('pointsEarned: $pointsEarned, ')
          ..write('syncState: $syncState, ')
          ..write('flags: $flags, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LSaleLinesTable extends LSaleLines
    with TableInfo<$LSaleLinesTable, LSaleLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LSaleLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
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
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantLabelMeta = const VerificationMeta(
    'variantLabel',
  );
  @override
  late final GeneratedColumn<String> variantLabel = GeneratedColumn<String>(
    'variant_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pc'),
  );
  static const VerificationMeta _unitFactorMilliMeta = const VerificationMeta(
    'unitFactorMilli',
  );
  @override
  late final GeneratedColumn<int> unitFactorMilli = GeneratedColumn<int>(
    'unit_factor_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1000),
  );
  static const VerificationMeta _qtyMilliMeta = const VerificationMeta(
    'qtyMilli',
  );
  @override
  late final GeneratedColumn<int> qtyMilli = GeneratedColumn<int>(
    'qty_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPricePMeta = const VerificationMeta(
    'unitPriceP',
  );
  @override
  late final GeneratedColumn<int> unitPriceP = GeneratedColumn<int>(
    'unit_price_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountPMeta = const VerificationMeta(
    'discountP',
  );
  @override
  late final GeneratedColumn<int> discountP = GeneratedColumn<int>(
    'discount_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxRateBpMeta = const VerificationMeta(
    'taxRateBp',
  );
  @override
  late final GeneratedColumn<int> taxRateBp = GeneratedColumn<int>(
    'tax_rate_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxAmountPMeta = const VerificationMeta(
    'taxAmountP',
  );
  @override
  late final GeneratedColumn<int> taxAmountP = GeneratedColumn<int>(
    'tax_amount_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _netPMeta = const VerificationMeta('netP');
  @override
  late final GeneratedColumn<int> netP = GeneratedColumn<int>(
    'net_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chargedPMeta = const VerificationMeta(
    'chargedP',
  );
  @override
  late final GeneratedColumn<int> chargedP = GeneratedColumn<int>(
    'charged_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _returnedQtyMilliMeta = const VerificationMeta(
    'returnedQtyMilli',
  );
  @override
  late final GeneratedColumn<int> returnedQtyMilli = GeneratedColumn<int>(
    'returned_qty_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _warrantyMonthsMeta = const VerificationMeta(
    'warrantyMonths',
  );
  @override
  late final GeneratedColumn<int> warrantyMonths = GeneratedColumn<int>(
    'warranty_months',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    position,
    variantId,
    productId,
    productName,
    variantLabel,
    sku,
    unit,
    unitFactorMilli,
    qtyMilli,
    unitPriceP,
    discountP,
    taxRateBp,
    taxAmountP,
    netP,
    chargedP,
    returnedQtyMilli,
    warrantyMonths,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'l_sale_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<LSaleLine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('variant_label')) {
      context.handle(
        _variantLabelMeta,
        variantLabel.isAcceptableOrUnknown(
          data['variant_label']!,
          _variantLabelMeta,
        ),
      );
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('unit_factor_milli')) {
      context.handle(
        _unitFactorMilliMeta,
        unitFactorMilli.isAcceptableOrUnknown(
          data['unit_factor_milli']!,
          _unitFactorMilliMeta,
        ),
      );
    }
    if (data.containsKey('qty_milli')) {
      context.handle(
        _qtyMilliMeta,
        qtyMilli.isAcceptableOrUnknown(data['qty_milli']!, _qtyMilliMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMilliMeta);
    }
    if (data.containsKey('unit_price_p')) {
      context.handle(
        _unitPricePMeta,
        unitPriceP.isAcceptableOrUnknown(
          data['unit_price_p']!,
          _unitPricePMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitPricePMeta);
    }
    if (data.containsKey('discount_p')) {
      context.handle(
        _discountPMeta,
        discountP.isAcceptableOrUnknown(data['discount_p']!, _discountPMeta),
      );
    }
    if (data.containsKey('tax_rate_bp')) {
      context.handle(
        _taxRateBpMeta,
        taxRateBp.isAcceptableOrUnknown(data['tax_rate_bp']!, _taxRateBpMeta),
      );
    }
    if (data.containsKey('tax_amount_p')) {
      context.handle(
        _taxAmountPMeta,
        taxAmountP.isAcceptableOrUnknown(
          data['tax_amount_p']!,
          _taxAmountPMeta,
        ),
      );
    }
    if (data.containsKey('net_p')) {
      context.handle(
        _netPMeta,
        netP.isAcceptableOrUnknown(data['net_p']!, _netPMeta),
      );
    } else if (isInserting) {
      context.missing(_netPMeta);
    }
    if (data.containsKey('charged_p')) {
      context.handle(
        _chargedPMeta,
        chargedP.isAcceptableOrUnknown(data['charged_p']!, _chargedPMeta),
      );
    } else if (isInserting) {
      context.missing(_chargedPMeta);
    }
    if (data.containsKey('returned_qty_milli')) {
      context.handle(
        _returnedQtyMilliMeta,
        returnedQtyMilli.isAcceptableOrUnknown(
          data['returned_qty_milli']!,
          _returnedQtyMilliMeta,
        ),
      );
    }
    if (data.containsKey('warranty_months')) {
      context.handle(
        _warrantyMonthsMeta,
        warrantyMonths.isAcceptableOrUnknown(
          data['warranty_months']!,
          _warrantyMonthsMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LSaleLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LSaleLine(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      variantLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_label'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      unitFactorMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_factor_milli'],
      )!,
      qtyMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty_milli'],
      )!,
      unitPriceP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_p'],
      )!,
      discountP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_p'],
      )!,
      taxRateBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_rate_bp'],
      )!,
      taxAmountP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_amount_p'],
      )!,
      netP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}net_p'],
      )!,
      chargedP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}charged_p'],
      )!,
      returnedQtyMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}returned_qty_milli'],
      )!,
      warrantyMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warranty_months'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $LSaleLinesTable createAlias(String alias) {
    return $LSaleLinesTable(attachedDatabase, alias);
  }
}

class LSaleLine extends DataClass implements Insertable<LSaleLine> {
  final String id;
  final String saleId;
  final int position;
  final String variantId;
  final String productId;
  final String productName;
  final String variantLabel;
  final String sku;
  final String unit;
  final int unitFactorMilli;
  final int qtyMilli;
  final int unitPriceP;
  final int discountP;
  final int taxRateBp;
  final int taxAmountP;
  final int netP;
  final int chargedP;
  final int returnedQtyMilli;
  final int warrantyMonths;
  final String note;
  const LSaleLine({
    required this.id,
    required this.saleId,
    required this.position,
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantLabel,
    required this.sku,
    required this.unit,
    required this.unitFactorMilli,
    required this.qtyMilli,
    required this.unitPriceP,
    required this.discountP,
    required this.taxRateBp,
    required this.taxAmountP,
    required this.netP,
    required this.chargedP,
    required this.returnedQtyMilli,
    required this.warrantyMonths,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    map['position'] = Variable<int>(position);
    map['variant_id'] = Variable<String>(variantId);
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    map['variant_label'] = Variable<String>(variantLabel);
    map['sku'] = Variable<String>(sku);
    map['unit'] = Variable<String>(unit);
    map['unit_factor_milli'] = Variable<int>(unitFactorMilli);
    map['qty_milli'] = Variable<int>(qtyMilli);
    map['unit_price_p'] = Variable<int>(unitPriceP);
    map['discount_p'] = Variable<int>(discountP);
    map['tax_rate_bp'] = Variable<int>(taxRateBp);
    map['tax_amount_p'] = Variable<int>(taxAmountP);
    map['net_p'] = Variable<int>(netP);
    map['charged_p'] = Variable<int>(chargedP);
    map['returned_qty_milli'] = Variable<int>(returnedQtyMilli);
    map['warranty_months'] = Variable<int>(warrantyMonths);
    map['note'] = Variable<String>(note);
    return map;
  }

  LSaleLinesCompanion toCompanion(bool nullToAbsent) {
    return LSaleLinesCompanion(
      id: Value(id),
      saleId: Value(saleId),
      position: Value(position),
      variantId: Value(variantId),
      productId: Value(productId),
      productName: Value(productName),
      variantLabel: Value(variantLabel),
      sku: Value(sku),
      unit: Value(unit),
      unitFactorMilli: Value(unitFactorMilli),
      qtyMilli: Value(qtyMilli),
      unitPriceP: Value(unitPriceP),
      discountP: Value(discountP),
      taxRateBp: Value(taxRateBp),
      taxAmountP: Value(taxAmountP),
      netP: Value(netP),
      chargedP: Value(chargedP),
      returnedQtyMilli: Value(returnedQtyMilli),
      warrantyMonths: Value(warrantyMonths),
      note: Value(note),
    );
  }

  factory LSaleLine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LSaleLine(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      position: serializer.fromJson<int>(json['position']),
      variantId: serializer.fromJson<String>(json['variantId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      variantLabel: serializer.fromJson<String>(json['variantLabel']),
      sku: serializer.fromJson<String>(json['sku']),
      unit: serializer.fromJson<String>(json['unit']),
      unitFactorMilli: serializer.fromJson<int>(json['unitFactorMilli']),
      qtyMilli: serializer.fromJson<int>(json['qtyMilli']),
      unitPriceP: serializer.fromJson<int>(json['unitPriceP']),
      discountP: serializer.fromJson<int>(json['discountP']),
      taxRateBp: serializer.fromJson<int>(json['taxRateBp']),
      taxAmountP: serializer.fromJson<int>(json['taxAmountP']),
      netP: serializer.fromJson<int>(json['netP']),
      chargedP: serializer.fromJson<int>(json['chargedP']),
      returnedQtyMilli: serializer.fromJson<int>(json['returnedQtyMilli']),
      warrantyMonths: serializer.fromJson<int>(json['warrantyMonths']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'position': serializer.toJson<int>(position),
      'variantId': serializer.toJson<String>(variantId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'variantLabel': serializer.toJson<String>(variantLabel),
      'sku': serializer.toJson<String>(sku),
      'unit': serializer.toJson<String>(unit),
      'unitFactorMilli': serializer.toJson<int>(unitFactorMilli),
      'qtyMilli': serializer.toJson<int>(qtyMilli),
      'unitPriceP': serializer.toJson<int>(unitPriceP),
      'discountP': serializer.toJson<int>(discountP),
      'taxRateBp': serializer.toJson<int>(taxRateBp),
      'taxAmountP': serializer.toJson<int>(taxAmountP),
      'netP': serializer.toJson<int>(netP),
      'chargedP': serializer.toJson<int>(chargedP),
      'returnedQtyMilli': serializer.toJson<int>(returnedQtyMilli),
      'warrantyMonths': serializer.toJson<int>(warrantyMonths),
      'note': serializer.toJson<String>(note),
    };
  }

  LSaleLine copyWith({
    String? id,
    String? saleId,
    int? position,
    String? variantId,
    String? productId,
    String? productName,
    String? variantLabel,
    String? sku,
    String? unit,
    int? unitFactorMilli,
    int? qtyMilli,
    int? unitPriceP,
    int? discountP,
    int? taxRateBp,
    int? taxAmountP,
    int? netP,
    int? chargedP,
    int? returnedQtyMilli,
    int? warrantyMonths,
    String? note,
  }) => LSaleLine(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    position: position ?? this.position,
    variantId: variantId ?? this.variantId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    variantLabel: variantLabel ?? this.variantLabel,
    sku: sku ?? this.sku,
    unit: unit ?? this.unit,
    unitFactorMilli: unitFactorMilli ?? this.unitFactorMilli,
    qtyMilli: qtyMilli ?? this.qtyMilli,
    unitPriceP: unitPriceP ?? this.unitPriceP,
    discountP: discountP ?? this.discountP,
    taxRateBp: taxRateBp ?? this.taxRateBp,
    taxAmountP: taxAmountP ?? this.taxAmountP,
    netP: netP ?? this.netP,
    chargedP: chargedP ?? this.chargedP,
    returnedQtyMilli: returnedQtyMilli ?? this.returnedQtyMilli,
    warrantyMonths: warrantyMonths ?? this.warrantyMonths,
    note: note ?? this.note,
  );
  LSaleLine copyWithCompanion(LSaleLinesCompanion data) {
    return LSaleLine(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      position: data.position.present ? data.position.value : this.position,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      variantLabel: data.variantLabel.present
          ? data.variantLabel.value
          : this.variantLabel,
      sku: data.sku.present ? data.sku.value : this.sku,
      unit: data.unit.present ? data.unit.value : this.unit,
      unitFactorMilli: data.unitFactorMilli.present
          ? data.unitFactorMilli.value
          : this.unitFactorMilli,
      qtyMilli: data.qtyMilli.present ? data.qtyMilli.value : this.qtyMilli,
      unitPriceP: data.unitPriceP.present
          ? data.unitPriceP.value
          : this.unitPriceP,
      discountP: data.discountP.present ? data.discountP.value : this.discountP,
      taxRateBp: data.taxRateBp.present ? data.taxRateBp.value : this.taxRateBp,
      taxAmountP: data.taxAmountP.present
          ? data.taxAmountP.value
          : this.taxAmountP,
      netP: data.netP.present ? data.netP.value : this.netP,
      chargedP: data.chargedP.present ? data.chargedP.value : this.chargedP,
      returnedQtyMilli: data.returnedQtyMilli.present
          ? data.returnedQtyMilli.value
          : this.returnedQtyMilli,
      warrantyMonths: data.warrantyMonths.present
          ? data.warrantyMonths.value
          : this.warrantyMonths,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LSaleLine(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('position: $position, ')
          ..write('variantId: $variantId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('variantLabel: $variantLabel, ')
          ..write('sku: $sku, ')
          ..write('unit: $unit, ')
          ..write('unitFactorMilli: $unitFactorMilli, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('unitPriceP: $unitPriceP, ')
          ..write('discountP: $discountP, ')
          ..write('taxRateBp: $taxRateBp, ')
          ..write('taxAmountP: $taxAmountP, ')
          ..write('netP: $netP, ')
          ..write('chargedP: $chargedP, ')
          ..write('returnedQtyMilli: $returnedQtyMilli, ')
          ..write('warrantyMonths: $warrantyMonths, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleId,
    position,
    variantId,
    productId,
    productName,
    variantLabel,
    sku,
    unit,
    unitFactorMilli,
    qtyMilli,
    unitPriceP,
    discountP,
    taxRateBp,
    taxAmountP,
    netP,
    chargedP,
    returnedQtyMilli,
    warrantyMonths,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LSaleLine &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.position == this.position &&
          other.variantId == this.variantId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.variantLabel == this.variantLabel &&
          other.sku == this.sku &&
          other.unit == this.unit &&
          other.unitFactorMilli == this.unitFactorMilli &&
          other.qtyMilli == this.qtyMilli &&
          other.unitPriceP == this.unitPriceP &&
          other.discountP == this.discountP &&
          other.taxRateBp == this.taxRateBp &&
          other.taxAmountP == this.taxAmountP &&
          other.netP == this.netP &&
          other.chargedP == this.chargedP &&
          other.returnedQtyMilli == this.returnedQtyMilli &&
          other.warrantyMonths == this.warrantyMonths &&
          other.note == this.note);
}

class LSaleLinesCompanion extends UpdateCompanion<LSaleLine> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<int> position;
  final Value<String> variantId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<String> variantLabel;
  final Value<String> sku;
  final Value<String> unit;
  final Value<int> unitFactorMilli;
  final Value<int> qtyMilli;
  final Value<int> unitPriceP;
  final Value<int> discountP;
  final Value<int> taxRateBp;
  final Value<int> taxAmountP;
  final Value<int> netP;
  final Value<int> chargedP;
  final Value<int> returnedQtyMilli;
  final Value<int> warrantyMonths;
  final Value<String> note;
  final Value<int> rowid;
  const LSaleLinesCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.position = const Value.absent(),
    this.variantId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.variantLabel = const Value.absent(),
    this.sku = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitFactorMilli = const Value.absent(),
    this.qtyMilli = const Value.absent(),
    this.unitPriceP = const Value.absent(),
    this.discountP = const Value.absent(),
    this.taxRateBp = const Value.absent(),
    this.taxAmountP = const Value.absent(),
    this.netP = const Value.absent(),
    this.chargedP = const Value.absent(),
    this.returnedQtyMilli = const Value.absent(),
    this.warrantyMonths = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LSaleLinesCompanion.insert({
    required String id,
    required String saleId,
    this.position = const Value.absent(),
    required String variantId,
    required String productId,
    required String productName,
    this.variantLabel = const Value.absent(),
    this.sku = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitFactorMilli = const Value.absent(),
    required int qtyMilli,
    required int unitPriceP,
    this.discountP = const Value.absent(),
    this.taxRateBp = const Value.absent(),
    this.taxAmountP = const Value.absent(),
    required int netP,
    required int chargedP,
    this.returnedQtyMilli = const Value.absent(),
    this.warrantyMonths = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       saleId = Value(saleId),
       variantId = Value(variantId),
       productId = Value(productId),
       productName = Value(productName),
       qtyMilli = Value(qtyMilli),
       unitPriceP = Value(unitPriceP),
       netP = Value(netP),
       chargedP = Value(chargedP);
  static Insertable<LSaleLine> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<int>? position,
    Expression<String>? variantId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<String>? variantLabel,
    Expression<String>? sku,
    Expression<String>? unit,
    Expression<int>? unitFactorMilli,
    Expression<int>? qtyMilli,
    Expression<int>? unitPriceP,
    Expression<int>? discountP,
    Expression<int>? taxRateBp,
    Expression<int>? taxAmountP,
    Expression<int>? netP,
    Expression<int>? chargedP,
    Expression<int>? returnedQtyMilli,
    Expression<int>? warrantyMonths,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (position != null) 'position': position,
      if (variantId != null) 'variant_id': variantId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (variantLabel != null) 'variant_label': variantLabel,
      if (sku != null) 'sku': sku,
      if (unit != null) 'unit': unit,
      if (unitFactorMilli != null) 'unit_factor_milli': unitFactorMilli,
      if (qtyMilli != null) 'qty_milli': qtyMilli,
      if (unitPriceP != null) 'unit_price_p': unitPriceP,
      if (discountP != null) 'discount_p': discountP,
      if (taxRateBp != null) 'tax_rate_bp': taxRateBp,
      if (taxAmountP != null) 'tax_amount_p': taxAmountP,
      if (netP != null) 'net_p': netP,
      if (chargedP != null) 'charged_p': chargedP,
      if (returnedQtyMilli != null) 'returned_qty_milli': returnedQtyMilli,
      if (warrantyMonths != null) 'warranty_months': warrantyMonths,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LSaleLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? saleId,
    Value<int>? position,
    Value<String>? variantId,
    Value<String>? productId,
    Value<String>? productName,
    Value<String>? variantLabel,
    Value<String>? sku,
    Value<String>? unit,
    Value<int>? unitFactorMilli,
    Value<int>? qtyMilli,
    Value<int>? unitPriceP,
    Value<int>? discountP,
    Value<int>? taxRateBp,
    Value<int>? taxAmountP,
    Value<int>? netP,
    Value<int>? chargedP,
    Value<int>? returnedQtyMilli,
    Value<int>? warrantyMonths,
    Value<String>? note,
    Value<int>? rowid,
  }) {
    return LSaleLinesCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      position: position ?? this.position,
      variantId: variantId ?? this.variantId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      variantLabel: variantLabel ?? this.variantLabel,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      unitFactorMilli: unitFactorMilli ?? this.unitFactorMilli,
      qtyMilli: qtyMilli ?? this.qtyMilli,
      unitPriceP: unitPriceP ?? this.unitPriceP,
      discountP: discountP ?? this.discountP,
      taxRateBp: taxRateBp ?? this.taxRateBp,
      taxAmountP: taxAmountP ?? this.taxAmountP,
      netP: netP ?? this.netP,
      chargedP: chargedP ?? this.chargedP,
      returnedQtyMilli: returnedQtyMilli ?? this.returnedQtyMilli,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (variantLabel.present) {
      map['variant_label'] = Variable<String>(variantLabel.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (unitFactorMilli.present) {
      map['unit_factor_milli'] = Variable<int>(unitFactorMilli.value);
    }
    if (qtyMilli.present) {
      map['qty_milli'] = Variable<int>(qtyMilli.value);
    }
    if (unitPriceP.present) {
      map['unit_price_p'] = Variable<int>(unitPriceP.value);
    }
    if (discountP.present) {
      map['discount_p'] = Variable<int>(discountP.value);
    }
    if (taxRateBp.present) {
      map['tax_rate_bp'] = Variable<int>(taxRateBp.value);
    }
    if (taxAmountP.present) {
      map['tax_amount_p'] = Variable<int>(taxAmountP.value);
    }
    if (netP.present) {
      map['net_p'] = Variable<int>(netP.value);
    }
    if (chargedP.present) {
      map['charged_p'] = Variable<int>(chargedP.value);
    }
    if (returnedQtyMilli.present) {
      map['returned_qty_milli'] = Variable<int>(returnedQtyMilli.value);
    }
    if (warrantyMonths.present) {
      map['warranty_months'] = Variable<int>(warrantyMonths.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LSaleLinesCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('position: $position, ')
          ..write('variantId: $variantId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('variantLabel: $variantLabel, ')
          ..write('sku: $sku, ')
          ..write('unit: $unit, ')
          ..write('unitFactorMilli: $unitFactorMilli, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('unitPriceP: $unitPriceP, ')
          ..write('discountP: $discountP, ')
          ..write('taxRateBp: $taxRateBp, ')
          ..write('taxAmountP: $taxAmountP, ')
          ..write('netP: $netP, ')
          ..write('chargedP: $chargedP, ')
          ..write('returnedQtyMilli: $returnedQtyMilli, ')
          ..write('warrantyMonths: $warrantyMonths, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LSalePaymentsTable extends LSalePayments
    with TableInfo<$LSalePaymentsTable, LSalePayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LSalePaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
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
  static const VerificationMeta _amountPMeta = const VerificationMeta(
    'amountP',
  );
  @override
  late final GeneratedColumn<int> amountP = GeneratedColumn<int>(
    'amount_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sale'),
  );
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
    'paid_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    method,
    amountP,
    reference,
    kind,
    paidAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'l_sale_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<LSalePayment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('amount_p')) {
      context.handle(
        _amountPMeta,
        amountP.isAcceptableOrUnknown(data['amount_p']!, _amountPMeta),
      );
    } else if (isInserting) {
      context.missing(_amountPMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('paid_at')) {
      context.handle(
        _paidAtMeta,
        paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta),
      );
    } else if (isInserting) {
      context.missing(_paidAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LSalePayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LSalePayment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      amountP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_p'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      paidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_at'],
      )!,
    );
  }

  @override
  $LSalePaymentsTable createAlias(String alias) {
    return $LSalePaymentsTable(attachedDatabase, alias);
  }
}

class LSalePayment extends DataClass implements Insertable<LSalePayment> {
  final String id;
  final String saleId;
  final String method;
  final int amountP;
  final String reference;
  final String kind;
  final DateTime paidAt;
  const LSalePayment({
    required this.id,
    required this.saleId,
    required this.method,
    required this.amountP,
    required this.reference,
    required this.kind,
    required this.paidAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    map['method'] = Variable<String>(method);
    map['amount_p'] = Variable<int>(amountP);
    map['reference'] = Variable<String>(reference);
    map['kind'] = Variable<String>(kind);
    map['paid_at'] = Variable<DateTime>(paidAt);
    return map;
  }

  LSalePaymentsCompanion toCompanion(bool nullToAbsent) {
    return LSalePaymentsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      method: Value(method),
      amountP: Value(amountP),
      reference: Value(reference),
      kind: Value(kind),
      paidAt: Value(paidAt),
    );
  }

  factory LSalePayment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LSalePayment(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      method: serializer.fromJson<String>(json['method']),
      amountP: serializer.fromJson<int>(json['amountP']),
      reference: serializer.fromJson<String>(json['reference']),
      kind: serializer.fromJson<String>(json['kind']),
      paidAt: serializer.fromJson<DateTime>(json['paidAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'method': serializer.toJson<String>(method),
      'amountP': serializer.toJson<int>(amountP),
      'reference': serializer.toJson<String>(reference),
      'kind': serializer.toJson<String>(kind),
      'paidAt': serializer.toJson<DateTime>(paidAt),
    };
  }

  LSalePayment copyWith({
    String? id,
    String? saleId,
    String? method,
    int? amountP,
    String? reference,
    String? kind,
    DateTime? paidAt,
  }) => LSalePayment(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    method: method ?? this.method,
    amountP: amountP ?? this.amountP,
    reference: reference ?? this.reference,
    kind: kind ?? this.kind,
    paidAt: paidAt ?? this.paidAt,
  );
  LSalePayment copyWithCompanion(LSalePaymentsCompanion data) {
    return LSalePayment(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      method: data.method.present ? data.method.value : this.method,
      amountP: data.amountP.present ? data.amountP.value : this.amountP,
      reference: data.reference.present ? data.reference.value : this.reference,
      kind: data.kind.present ? data.kind.value : this.kind,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LSalePayment(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('method: $method, ')
          ..write('amountP: $amountP, ')
          ..write('reference: $reference, ')
          ..write('kind: $kind, ')
          ..write('paidAt: $paidAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, saleId, method, amountP, reference, kind, paidAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LSalePayment &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.method == this.method &&
          other.amountP == this.amountP &&
          other.reference == this.reference &&
          other.kind == this.kind &&
          other.paidAt == this.paidAt);
}

class LSalePaymentsCompanion extends UpdateCompanion<LSalePayment> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<String> method;
  final Value<int> amountP;
  final Value<String> reference;
  final Value<String> kind;
  final Value<DateTime> paidAt;
  final Value<int> rowid;
  const LSalePaymentsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.method = const Value.absent(),
    this.amountP = const Value.absent(),
    this.reference = const Value.absent(),
    this.kind = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LSalePaymentsCompanion.insert({
    required String id,
    required String saleId,
    required String method,
    required int amountP,
    this.reference = const Value.absent(),
    this.kind = const Value.absent(),
    required DateTime paidAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       saleId = Value(saleId),
       method = Value(method),
       amountP = Value(amountP),
       paidAt = Value(paidAt);
  static Insertable<LSalePayment> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<String>? method,
    Expression<int>? amountP,
    Expression<String>? reference,
    Expression<String>? kind,
    Expression<DateTime>? paidAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (method != null) 'method': method,
      if (amountP != null) 'amount_p': amountP,
      if (reference != null) 'reference': reference,
      if (kind != null) 'kind': kind,
      if (paidAt != null) 'paid_at': paidAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LSalePaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? saleId,
    Value<String>? method,
    Value<int>? amountP,
    Value<String>? reference,
    Value<String>? kind,
    Value<DateTime>? paidAt,
    Value<int>? rowid,
  }) {
    return LSalePaymentsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      method: method ?? this.method,
      amountP: amountP ?? this.amountP,
      reference: reference ?? this.reference,
      kind: kind ?? this.kind,
      paidAt: paidAt ?? this.paidAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (amountP.present) {
      map['amount_p'] = Variable<int>(amountP.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LSalePaymentsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('method: $method, ')
          ..write('amountP: $amountP, ')
          ..write('reference: $reference, ')
          ..write('kind: $kind, ')
          ..write('paidAt: $paidAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LExpensesTable extends LExpenses
    with TableInfo<$LExpensesTable, LExpense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPMeta = const VerificationMeta(
    'amountP',
  );
  @override
  late final GeneratedColumn<int> amountP = GeneratedColumn<int>(
    'amount_p',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _spentAtMeta = const VerificationMeta(
    'spentAt',
  );
  @override
  late final GeneratedColumn<DateTime> spentAt = GeneratedColumn<DateTime>(
    'spent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    branchId,
    category,
    amountP,
    method,
    note,
    spentAt,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'l_expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<LExpense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('amount_p')) {
      context.handle(
        _amountPMeta,
        amountP.isAcceptableOrUnknown(data['amount_p']!, _amountPMeta),
      );
    } else if (isInserting) {
      context.missing(_amountPMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('spent_at')) {
      context.handle(
        _spentAtMeta,
        spentAt.isAcceptableOrUnknown(data['spent_at']!, _spentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_spentAtMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LExpense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LExpense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      amountP: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_p'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      spentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}spent_at'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
    );
  }

  @override
  $LExpensesTable createAlias(String alias) {
    return $LExpensesTable(attachedDatabase, alias);
  }
}

class LExpense extends DataClass implements Insertable<LExpense> {
  final String id;
  final String branchId;
  final String category;
  final int amountP;
  final String method;
  final String note;
  final DateTime spentAt;
  final String syncState;
  const LExpense({
    required this.id,
    required this.branchId,
    required this.category,
    required this.amountP,
    required this.method,
    required this.note,
    required this.spentAt,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['branch_id'] = Variable<String>(branchId);
    map['category'] = Variable<String>(category);
    map['amount_p'] = Variable<int>(amountP);
    map['method'] = Variable<String>(method);
    map['note'] = Variable<String>(note);
    map['spent_at'] = Variable<DateTime>(spentAt);
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  LExpensesCompanion toCompanion(bool nullToAbsent) {
    return LExpensesCompanion(
      id: Value(id),
      branchId: Value(branchId),
      category: Value(category),
      amountP: Value(amountP),
      method: Value(method),
      note: Value(note),
      spentAt: Value(spentAt),
      syncState: Value(syncState),
    );
  }

  factory LExpense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LExpense(
      id: serializer.fromJson<String>(json['id']),
      branchId: serializer.fromJson<String>(json['branchId']),
      category: serializer.fromJson<String>(json['category']),
      amountP: serializer.fromJson<int>(json['amountP']),
      method: serializer.fromJson<String>(json['method']),
      note: serializer.fromJson<String>(json['note']),
      spentAt: serializer.fromJson<DateTime>(json['spentAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'branchId': serializer.toJson<String>(branchId),
      'category': serializer.toJson<String>(category),
      'amountP': serializer.toJson<int>(amountP),
      'method': serializer.toJson<String>(method),
      'note': serializer.toJson<String>(note),
      'spentAt': serializer.toJson<DateTime>(spentAt),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  LExpense copyWith({
    String? id,
    String? branchId,
    String? category,
    int? amountP,
    String? method,
    String? note,
    DateTime? spentAt,
    String? syncState,
  }) => LExpense(
    id: id ?? this.id,
    branchId: branchId ?? this.branchId,
    category: category ?? this.category,
    amountP: amountP ?? this.amountP,
    method: method ?? this.method,
    note: note ?? this.note,
    spentAt: spentAt ?? this.spentAt,
    syncState: syncState ?? this.syncState,
  );
  LExpense copyWithCompanion(LExpensesCompanion data) {
    return LExpense(
      id: data.id.present ? data.id.value : this.id,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      category: data.category.present ? data.category.value : this.category,
      amountP: data.amountP.present ? data.amountP.value : this.amountP,
      method: data.method.present ? data.method.value : this.method,
      note: data.note.present ? data.note.value : this.note,
      spentAt: data.spentAt.present ? data.spentAt.value : this.spentAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LExpense(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('category: $category, ')
          ..write('amountP: $amountP, ')
          ..write('method: $method, ')
          ..write('note: $note, ')
          ..write('spentAt: $spentAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    branchId,
    category,
    amountP,
    method,
    note,
    spentAt,
    syncState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LExpense &&
          other.id == this.id &&
          other.branchId == this.branchId &&
          other.category == this.category &&
          other.amountP == this.amountP &&
          other.method == this.method &&
          other.note == this.note &&
          other.spentAt == this.spentAt &&
          other.syncState == this.syncState);
}

class LExpensesCompanion extends UpdateCompanion<LExpense> {
  final Value<String> id;
  final Value<String> branchId;
  final Value<String> category;
  final Value<int> amountP;
  final Value<String> method;
  final Value<String> note;
  final Value<DateTime> spentAt;
  final Value<String> syncState;
  final Value<int> rowid;
  const LExpensesCompanion({
    this.id = const Value.absent(),
    this.branchId = const Value.absent(),
    this.category = const Value.absent(),
    this.amountP = const Value.absent(),
    this.method = const Value.absent(),
    this.note = const Value.absent(),
    this.spentAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LExpensesCompanion.insert({
    required String id,
    required String branchId,
    required String category,
    required int amountP,
    this.method = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime spentAt,
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       branchId = Value(branchId),
       category = Value(category),
       amountP = Value(amountP),
       spentAt = Value(spentAt);
  static Insertable<LExpense> custom({
    Expression<String>? id,
    Expression<String>? branchId,
    Expression<String>? category,
    Expression<int>? amountP,
    Expression<String>? method,
    Expression<String>? note,
    Expression<DateTime>? spentAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (branchId != null) 'branch_id': branchId,
      if (category != null) 'category': category,
      if (amountP != null) 'amount_p': amountP,
      if (method != null) 'method': method,
      if (note != null) 'note': note,
      if (spentAt != null) 'spent_at': spentAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? branchId,
    Value<String>? category,
    Value<int>? amountP,
    Value<String>? method,
    Value<String>? note,
    Value<DateTime>? spentAt,
    Value<String>? syncState,
    Value<int>? rowid,
  }) {
    return LExpensesCompanion(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      category: category ?? this.category,
      amountP: amountP ?? this.amountP,
      method: method ?? this.method,
      note: note ?? this.note,
      spentAt: spentAt ?? this.spentAt,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amountP.present) {
      map['amount_p'] = Variable<int>(amountP.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (spentAt.present) {
      map['spent_at'] = Variable<DateTime>(spentAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LExpensesCompanion(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('category: $category, ')
          ..write('amountP: $amountP, ')
          ..write('method: $method, ')
          ..write('note: $note, ')
          ..write('spentAt: $spentAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
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
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    id,
    type,
    payload,
    actorId,
    occurredAt,
    status,
    attempts,
    errorCode,
    lastError,
    summary,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
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
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  final int seq;
  final String id;
  final String type;
  final String payload;
  final String? actorId;
  final DateTime occurredAt;

  /// pending | sending | failed | done
  final String status;
  final int attempts;
  final String? errorCode;
  final String? lastError;
  final String summary;
  final DateTime createdAt;
  const OutboxData({
    required this.seq,
    required this.id,
    required this.type,
    required this.payload,
    this.actorId,
    required this.occurredAt,
    required this.status,
    required this.attempts,
    this.errorCode,
    this.lastError,
    required this.summary,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || actorId != null) {
      map['actor_id'] = Variable<String>(actorId);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['summary'] = Variable<String>(summary);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      seq: Value(seq),
      id: Value(id),
      type: Value(type),
      payload: Value(payload),
      actorId: actorId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorId),
      occurredAt: Value(occurredAt),
      status: Value(status),
      attempts: Value(attempts),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      summary: Value(summary),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      seq: serializer.fromJson<int>(json['seq']),
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
      actorId: serializer.fromJson<String?>(json['actorId']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      summary: serializer.fromJson<String>(json['summary']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
      'actorId': serializer.toJson<String?>(actorId),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'errorCode': serializer.toJson<String?>(errorCode),
      'lastError': serializer.toJson<String?>(lastError),
      'summary': serializer.toJson<String>(summary),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxData copyWith({
    int? seq,
    String? id,
    String? type,
    String? payload,
    Value<String?> actorId = const Value.absent(),
    DateTime? occurredAt,
    String? status,
    int? attempts,
    Value<String?> errorCode = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    String? summary,
    DateTime? createdAt,
  }) => OutboxData(
    seq: seq ?? this.seq,
    id: id ?? this.id,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    actorId: actorId.present ? actorId.value : this.actorId,
    occurredAt: occurredAt ?? this.occurredAt,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    lastError: lastError.present ? lastError.value : this.lastError,
    summary: summary ?? this.summary,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      seq: data.seq.present ? data.seq.value : this.seq,
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      summary: data.summary.present ? data.summary.value : this.summary,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('seq: $seq, ')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('actorId: $actorId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('errorCode: $errorCode, ')
          ..write('lastError: $lastError, ')
          ..write('summary: $summary, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    id,
    type,
    payload,
    actorId,
    occurredAt,
    status,
    attempts,
    errorCode,
    lastError,
    summary,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.seq == this.seq &&
          other.id == this.id &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.actorId == this.actorId &&
          other.occurredAt == this.occurredAt &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.errorCode == this.errorCode &&
          other.lastError == this.lastError &&
          other.summary == this.summary &&
          other.createdAt == this.createdAt);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<int> seq;
  final Value<String> id;
  final Value<String> type;
  final Value<String> payload;
  final Value<String?> actorId;
  final Value<DateTime> occurredAt;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> errorCode;
  final Value<String?> lastError;
  final Value<String> summary;
  final Value<DateTime> createdAt;
  const OutboxCompanion({
    this.seq = const Value.absent(),
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.actorId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.lastError = const Value.absent(),
    this.summary = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String id,
    required String type,
    required String payload,
    this.actorId = const Value.absent(),
    required DateTime occurredAt,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.lastError = const Value.absent(),
    this.summary = const Value.absent(),
    required DateTime createdAt,
  }) : id = Value(id),
       type = Value(type),
       payload = Value(payload),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt);
  static Insertable<OutboxData> custom({
    Expression<int>? seq,
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<String>? actorId,
    Expression<DateTime>? occurredAt,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? errorCode,
    Expression<String>? lastError,
    Expression<String>? summary,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (actorId != null) 'actor_id': actorId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (errorCode != null) 'error_code': errorCode,
      if (lastError != null) 'last_error': lastError,
      if (summary != null) 'summary': summary,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? seq,
    Value<String>? id,
    Value<String>? type,
    Value<String>? payload,
    Value<String?>? actorId,
    Value<DateTime>? occurredAt,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? errorCode,
    Value<String?>? lastError,
    Value<String>? summary,
    Value<DateTime>? createdAt,
  }) {
    return OutboxCompanion(
      seq: seq ?? this.seq,
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      actorId: actorId ?? this.actorId,
      occurredAt: occurredAt ?? this.occurredAt,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      errorCode: errorCode ?? this.errorCode,
      lastError: lastError ?? this.lastError,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('actorId: $actorId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('errorCode: $errorCode, ')
          ..write('lastError: $lastError, ')
          ..write('summary: $summary, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $HeldCartsTable extends HeldCarts
    with TableInfo<$HeldCartsTable, HeldCart> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeldCartsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, json, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'held_carts';
  @override
  VerificationContext validateIntegrity(
    Insertable<HeldCart> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
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
  HeldCart map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeldCart(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HeldCartsTable createAlias(String alias) {
    return $HeldCartsTable(attachedDatabase, alias);
  }
}

class HeldCart extends DataClass implements Insertable<HeldCart> {
  final String id;
  final String name;
  final String json;
  final DateTime createdAt;
  const HeldCart({
    required this.id,
    required this.name,
    required this.json,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['json'] = Variable<String>(json);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HeldCartsCompanion toCompanion(bool nullToAbsent) {
    return HeldCartsCompanion(
      id: Value(id),
      name: Value(name),
      json: Value(json),
      createdAt: Value(createdAt),
    );
  }

  factory HeldCart.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeldCart(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      json: serializer.fromJson<String>(json['json']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'json': serializer.toJson<String>(json),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  HeldCart copyWith({
    String? id,
    String? name,
    String? json,
    DateTime? createdAt,
  }) => HeldCart(
    id: id ?? this.id,
    name: name ?? this.name,
    json: json ?? this.json,
    createdAt: createdAt ?? this.createdAt,
  );
  HeldCart copyWithCompanion(HeldCartsCompanion data) {
    return HeldCart(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      json: data.json.present ? data.json.value : this.json,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeldCart(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('json: $json, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, json, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeldCart &&
          other.id == this.id &&
          other.name == this.name &&
          other.json == this.json &&
          other.createdAt == this.createdAt);
}

class HeldCartsCompanion extends UpdateCompanion<HeldCart> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> json;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const HeldCartsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.json = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeldCartsCompanion.insert({
    required String id,
    required String name,
    required String json,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       json = Value(json),
       createdAt = Value(createdAt);
  static Insertable<HeldCart> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? json,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (json != null) 'json': json,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeldCartsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? json,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return HeldCartsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      json: json ?? this.json,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeldCartsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('json: $json, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KvTable kv = $KvTable(this);
  late final $LCategoriesTable lCategories = $LCategoriesTable(this);
  late final $LTaxClassesTable lTaxClasses = $LTaxClassesTable(this);
  late final $LProductsTable lProducts = $LProductsTable(this);
  late final $LVariantsTable lVariants = $LVariantsTable(this);
  late final $LBarcodesTable lBarcodes = $LBarcodesTable(this);
  late final $LCustomersTable lCustomers = $LCustomersTable(this);
  late final $LStockTable lStock = $LStockTable(this);
  late final $LSalesTable lSales = $LSalesTable(this);
  late final $LSaleLinesTable lSaleLines = $LSaleLinesTable(this);
  late final $LSalePaymentsTable lSalePayments = $LSalePaymentsTable(this);
  late final $LExpensesTable lExpenses = $LExpensesTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $HeldCartsTable heldCarts = $HeldCartsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    kv,
    lCategories,
    lTaxClasses,
    lProducts,
    lVariants,
    lBarcodes,
    lCustomers,
    lStock,
    lSales,
    lSaleLines,
    lSalePayments,
    lExpenses,
    outbox,
    heldCarts,
  ];
}

typedef $$KvTableCreateCompanionBuilder = KvCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KvTableUpdateCompanionBuilder = KvCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KvTableFilterComposer extends Composer<_$AppDatabase, $KvTable> {
  $$KvTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KvTableOrderingComposer extends Composer<_$AppDatabase, $KvTable> {
  $$KvTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KvTableAnnotationComposer extends Composer<_$AppDatabase, $KvTable> {
  $$KvTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KvTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KvTable,
          KvData,
          $$KvTableFilterComposer,
          $$KvTableOrderingComposer,
          $$KvTableAnnotationComposer,
          $$KvTableCreateCompanionBuilder,
          $$KvTableUpdateCompanionBuilder,
          (KvData, BaseReferences<_$AppDatabase, $KvTable, KvData>),
          KvData,
          PrefetchHooks Function()
        > {
  $$KvTableTableManager(_$AppDatabase db, $KvTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KvCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => KvCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KvTable, KvData>(table),
                  BaseReferences<_$AppDatabase, $KvTable, KvData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KvTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KvTable,
      KvData,
      $$KvTableFilterComposer,
      $$KvTableOrderingComposer,
      $$KvTableAnnotationComposer,
      $$KvTableCreateCompanionBuilder,
      $$KvTableUpdateCompanionBuilder,
      (KvData, BaseReferences<_$AppDatabase, $KvTable, KvData>),
      KvData,
      PrefetchHooks Function()
    >;
typedef $$LCategoriesTableCreateCompanionBuilder =
    LCategoriesCompanion Function({
      required String id,
      required String name,
      Value<String?> parentId,
      Value<int> sortOrder,
      Value<bool> active,
      Value<int> rowid,
    });
typedef $$LCategoriesTableUpdateCompanionBuilder =
    LCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> parentId,
      Value<int> sortOrder,
      Value<bool> active,
      Value<int> rowid,
    });

class $$LCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LCategoriesTable> {
  $$LCategoriesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LCategoriesTable> {
  $$LCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LCategoriesTable> {
  $$LCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$LCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LCategoriesTable,
          LCategory,
          $$LCategoriesTableFilterComposer,
          $$LCategoriesTableOrderingComposer,
          $$LCategoriesTableAnnotationComposer,
          $$LCategoriesTableCreateCompanionBuilder,
          $$LCategoriesTableUpdateCompanionBuilder,
          (
            LCategory,
            BaseReferences<_$AppDatabase, $LCategoriesTable, LCategory>,
          ),
          LCategory,
          PrefetchHooks Function()
        > {
  $$LCategoriesTableTableManager(_$AppDatabase db, $LCategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LCategoriesCompanion(
                id: id,
                name: name,
                parentId: parentId,
                sortOrder: sortOrder,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> parentId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LCategoriesCompanion.insert(
                id: id,
                name: name,
                parentId: parentId,
                sortOrder: sortOrder,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LCategoriesTable, LCategory>(table),
                  BaseReferences<_$AppDatabase, $LCategoriesTable, LCategory>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LCategoriesTable,
      LCategory,
      $$LCategoriesTableFilterComposer,
      $$LCategoriesTableOrderingComposer,
      $$LCategoriesTableAnnotationComposer,
      $$LCategoriesTableCreateCompanionBuilder,
      $$LCategoriesTableUpdateCompanionBuilder,
      (LCategory, BaseReferences<_$AppDatabase, $LCategoriesTable, LCategory>),
      LCategory,
      PrefetchHooks Function()
    >;
typedef $$LTaxClassesTableCreateCompanionBuilder =
    LTaxClassesCompanion Function({
      required String id,
      required String name,
      Value<int> rateBp,
      Value<bool> isDefault,
      Value<int> rowid,
    });
typedef $$LTaxClassesTableUpdateCompanionBuilder =
    LTaxClassesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> rateBp,
      Value<bool> isDefault,
      Value<int> rowid,
    });

class $$LTaxClassesTableFilterComposer
    extends Composer<_$AppDatabase, $LTaxClassesTable> {
  $$LTaxClassesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rateBp => $composableBuilder(
    column: $table.rateBp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LTaxClassesTableOrderingComposer
    extends Composer<_$AppDatabase, $LTaxClassesTable> {
  $$LTaxClassesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rateBp => $composableBuilder(
    column: $table.rateBp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LTaxClassesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LTaxClassesTable> {
  $$LTaxClassesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get rateBp =>
      $composableBuilder(column: $table.rateBp, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);
}

class $$LTaxClassesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LTaxClassesTable,
          LTaxClassesData,
          $$LTaxClassesTableFilterComposer,
          $$LTaxClassesTableOrderingComposer,
          $$LTaxClassesTableAnnotationComposer,
          $$LTaxClassesTableCreateCompanionBuilder,
          $$LTaxClassesTableUpdateCompanionBuilder,
          (
            LTaxClassesData,
            BaseReferences<_$AppDatabase, $LTaxClassesTable, LTaxClassesData>,
          ),
          LTaxClassesData,
          PrefetchHooks Function()
        > {
  $$LTaxClassesTableTableManager(_$AppDatabase db, $LTaxClassesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LTaxClassesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LTaxClassesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LTaxClassesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rateBp = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LTaxClassesCompanion(
                id: id,
                name: name,
                rateBp: rateBp,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> rateBp = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LTaxClassesCompanion.insert(
                id: id,
                name: name,
                rateBp: rateBp,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LTaxClassesTable, LTaxClassesData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LTaxClassesTable,
                    LTaxClassesData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LTaxClassesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LTaxClassesTable,
      LTaxClassesData,
      $$LTaxClassesTableFilterComposer,
      $$LTaxClassesTableOrderingComposer,
      $$LTaxClassesTableAnnotationComposer,
      $$LTaxClassesTableCreateCompanionBuilder,
      $$LTaxClassesTableUpdateCompanionBuilder,
      (
        LTaxClassesData,
        BaseReferences<_$AppDatabase, $LTaxClassesTable, LTaxClassesData>,
      ),
      LTaxClassesData,
      PrefetchHooks Function()
    >;
typedef $$LProductsTableCreateCompanionBuilder = LProductsCompanion Function({
  required String id,
  required String name,
  Value<String> nameLocal,
  Value<String?> categoryId,
  Value<String> type,
  Value<String> baseUnit,
  Value<String> altUnits,
  Value<bool> allowFraction,
  Value<String> tracking,
  Value<bool> trackExpiry,
  Value<String?> taxClassId,
  Value<String> attributes,
  Value<String> imageUrl,
  Value<int> reorderMilli,
  Value<int> warrantyMonths,
  Value<bool> active,
  Value<String> search,
  Value<int> rowid,
});
typedef $$LProductsTableUpdateCompanionBuilder = LProductsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> nameLocal,
  Value<String?> categoryId,
  Value<String> type,
  Value<String> baseUnit,
  Value<String> altUnits,
  Value<bool> allowFraction,
  Value<String> tracking,
  Value<bool> trackExpiry,
  Value<String?> taxClassId,
  Value<String> attributes,
  Value<String> imageUrl,
  Value<int> reorderMilli,
  Value<int> warrantyMonths,
  Value<bool> active,
  Value<String> search,
  Value<int> rowid,
});

class $$LProductsTableFilterComposer
    extends Composer<_$AppDatabase, $LProductsTable> {
  $$LProductsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameLocal => $composableBuilder(
    column: $table.nameLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUnit => $composableBuilder(
    column: $table.baseUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get altUnits => $composableBuilder(
    column: $table.altUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowFraction => $composableBuilder(
    column: $table.allowFraction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tracking => $composableBuilder(
    column: $table.tracking,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trackExpiry => $composableBuilder(
    column: $table.trackExpiry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxClassId => $composableBuilder(
    column: $table.taxClassId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attributes => $composableBuilder(
    column: $table.attributes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reorderMilli => $composableBuilder(
    column: $table.reorderMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warrantyMonths => $composableBuilder(
    column: $table.warrantyMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get search => $composableBuilder(
    column: $table.search,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $LProductsTable> {
  $$LProductsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameLocal => $composableBuilder(
    column: $table.nameLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUnit => $composableBuilder(
    column: $table.baseUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get altUnits => $composableBuilder(
    column: $table.altUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowFraction => $composableBuilder(
    column: $table.allowFraction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tracking => $composableBuilder(
    column: $table.tracking,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trackExpiry => $composableBuilder(
    column: $table.trackExpiry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxClassId => $composableBuilder(
    column: $table.taxClassId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attributes => $composableBuilder(
    column: $table.attributes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reorderMilli => $composableBuilder(
    column: $table.reorderMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warrantyMonths => $composableBuilder(
    column: $table.warrantyMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get search => $composableBuilder(
    column: $table.search,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LProductsTable> {
  $$LProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameLocal =>
      $composableBuilder(column: $table.nameLocal, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get baseUnit =>
      $composableBuilder(column: $table.baseUnit, builder: (column) => column);

  GeneratedColumn<String> get altUnits =>
      $composableBuilder(column: $table.altUnits, builder: (column) => column);

  GeneratedColumn<bool> get allowFraction => $composableBuilder(
    column: $table.allowFraction,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tracking =>
      $composableBuilder(column: $table.tracking, builder: (column) => column);

  GeneratedColumn<bool> get trackExpiry => $composableBuilder(
    column: $table.trackExpiry,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxClassId => $composableBuilder(
    column: $table.taxClassId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attributes => $composableBuilder(
    column: $table.attributes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get reorderMilli => $composableBuilder(
    column: $table.reorderMilli,
    builder: (column) => column,
  );

  GeneratedColumn<int> get warrantyMonths => $composableBuilder(
    column: $table.warrantyMonths,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<String> get search =>
      $composableBuilder(column: $table.search, builder: (column) => column);
}

class $$LProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LProductsTable,
          LProduct,
          $$LProductsTableFilterComposer,
          $$LProductsTableOrderingComposer,
          $$LProductsTableAnnotationComposer,
          $$LProductsTableCreateCompanionBuilder,
          $$LProductsTableUpdateCompanionBuilder,
          (LProduct, BaseReferences<_$AppDatabase, $LProductsTable, LProduct>),
          LProduct,
          PrefetchHooks Function()
        > {
  $$LProductsTableTableManager(_$AppDatabase db, $LProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameLocal = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> baseUnit = const Value.absent(),
                Value<String> altUnits = const Value.absent(),
                Value<bool> allowFraction = const Value.absent(),
                Value<String> tracking = const Value.absent(),
                Value<bool> trackExpiry = const Value.absent(),
                Value<String?> taxClassId = const Value.absent(),
                Value<String> attributes = const Value.absent(),
                Value<String> imageUrl = const Value.absent(),
                Value<int> reorderMilli = const Value.absent(),
                Value<int> warrantyMonths = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String> search = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LProductsCompanion(
                id: id,
                name: name,
                nameLocal: nameLocal,
                categoryId: categoryId,
                type: type,
                baseUnit: baseUnit,
                altUnits: altUnits,
                allowFraction: allowFraction,
                tracking: tracking,
                trackExpiry: trackExpiry,
                taxClassId: taxClassId,
                attributes: attributes,
                imageUrl: imageUrl,
                reorderMilli: reorderMilli,
                warrantyMonths: warrantyMonths,
                active: active,
                search: search,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> nameLocal = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> baseUnit = const Value.absent(),
                Value<String> altUnits = const Value.absent(),
                Value<bool> allowFraction = const Value.absent(),
                Value<String> tracking = const Value.absent(),
                Value<bool> trackExpiry = const Value.absent(),
                Value<String?> taxClassId = const Value.absent(),
                Value<String> attributes = const Value.absent(),
                Value<String> imageUrl = const Value.absent(),
                Value<int> reorderMilli = const Value.absent(),
                Value<int> warrantyMonths = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String> search = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LProductsCompanion.insert(
                id: id,
                name: name,
                nameLocal: nameLocal,
                categoryId: categoryId,
                type: type,
                baseUnit: baseUnit,
                altUnits: altUnits,
                allowFraction: allowFraction,
                tracking: tracking,
                trackExpiry: trackExpiry,
                taxClassId: taxClassId,
                attributes: attributes,
                imageUrl: imageUrl,
                reorderMilli: reorderMilli,
                warrantyMonths: warrantyMonths,
                active: active,
                search: search,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LProductsTable, LProduct>(table),
                  BaseReferences<_$AppDatabase, $LProductsTable, LProduct>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LProductsTable,
      LProduct,
      $$LProductsTableFilterComposer,
      $$LProductsTableOrderingComposer,
      $$LProductsTableAnnotationComposer,
      $$LProductsTableCreateCompanionBuilder,
      $$LProductsTableUpdateCompanionBuilder,
      (LProduct, BaseReferences<_$AppDatabase, $LProductsTable, LProduct>),
      LProduct,
      PrefetchHooks Function()
    >;
typedef $$LVariantsTableCreateCompanionBuilder = LVariantsCompanion Function({
  required String id,
  required String productId,
  Value<String> sku,
  Value<String> label,
  Value<String> optionValues,
  required int priceP,
  Value<int> mrpP,
  Value<int?> costP,
  Value<String?> plu,
  Value<bool> active,
  Value<int> rowid,
});
typedef $$LVariantsTableUpdateCompanionBuilder = LVariantsCompanion Function({
  Value<String> id,
  Value<String> productId,
  Value<String> sku,
  Value<String> label,
  Value<String> optionValues,
  Value<int> priceP,
  Value<int> mrpP,
  Value<int?> costP,
  Value<String?> plu,
  Value<bool> active,
  Value<int> rowid,
});

class $$LVariantsTableFilterComposer
    extends Composer<_$AppDatabase, $LVariantsTable> {
  $$LVariantsTableFilterComposer({
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

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionValues => $composableBuilder(
    column: $table.optionValues,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceP => $composableBuilder(
    column: $table.priceP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mrpP => $composableBuilder(
    column: $table.mrpP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costP => $composableBuilder(
    column: $table.costP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plu => $composableBuilder(
    column: $table.plu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LVariantsTableOrderingComposer
    extends Composer<_$AppDatabase, $LVariantsTable> {
  $$LVariantsTableOrderingComposer({
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

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionValues => $composableBuilder(
    column: $table.optionValues,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceP => $composableBuilder(
    column: $table.priceP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mrpP => $composableBuilder(
    column: $table.mrpP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costP => $composableBuilder(
    column: $table.costP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plu => $composableBuilder(
    column: $table.plu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LVariantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LVariantsTable> {
  $$LVariantsTableAnnotationComposer({
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

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get optionValues => $composableBuilder(
    column: $table.optionValues,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priceP =>
      $composableBuilder(column: $table.priceP, builder: (column) => column);

  GeneratedColumn<int> get mrpP =>
      $composableBuilder(column: $table.mrpP, builder: (column) => column);

  GeneratedColumn<int> get costP =>
      $composableBuilder(column: $table.costP, builder: (column) => column);

  GeneratedColumn<String> get plu =>
      $composableBuilder(column: $table.plu, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$LVariantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LVariantsTable,
          LVariant,
          $$LVariantsTableFilterComposer,
          $$LVariantsTableOrderingComposer,
          $$LVariantsTableAnnotationComposer,
          $$LVariantsTableCreateCompanionBuilder,
          $$LVariantsTableUpdateCompanionBuilder,
          (LVariant, BaseReferences<_$AppDatabase, $LVariantsTable, LVariant>),
          LVariant,
          PrefetchHooks Function()
        > {
  $$LVariantsTableTableManager(_$AppDatabase db, $LVariantsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LVariantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LVariantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LVariantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> optionValues = const Value.absent(),
                Value<int> priceP = const Value.absent(),
                Value<int> mrpP = const Value.absent(),
                Value<int?> costP = const Value.absent(),
                Value<String?> plu = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LVariantsCompanion(
                id: id,
                productId: productId,
                sku: sku,
                label: label,
                optionValues: optionValues,
                priceP: priceP,
                mrpP: mrpP,
                costP: costP,
                plu: plu,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                Value<String> sku = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> optionValues = const Value.absent(),
                required int priceP,
                Value<int> mrpP = const Value.absent(),
                Value<int?> costP = const Value.absent(),
                Value<String?> plu = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LVariantsCompanion.insert(
                id: id,
                productId: productId,
                sku: sku,
                label: label,
                optionValues: optionValues,
                priceP: priceP,
                mrpP: mrpP,
                costP: costP,
                plu: plu,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LVariantsTable, LVariant>(table),
                  BaseReferences<_$AppDatabase, $LVariantsTable, LVariant>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LVariantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LVariantsTable,
      LVariant,
      $$LVariantsTableFilterComposer,
      $$LVariantsTableOrderingComposer,
      $$LVariantsTableAnnotationComposer,
      $$LVariantsTableCreateCompanionBuilder,
      $$LVariantsTableUpdateCompanionBuilder,
      (LVariant, BaseReferences<_$AppDatabase, $LVariantsTable, LVariant>),
      LVariant,
      PrefetchHooks Function()
    >;
typedef $$LBarcodesTableCreateCompanionBuilder = LBarcodesCompanion Function({
  required String code,
  required String variantId,
  required String productId,
  Value<String?> unit,
  Value<int> qtyPerScanMilli,
  Value<int> rowid,
});
typedef $$LBarcodesTableUpdateCompanionBuilder = LBarcodesCompanion Function({
  Value<String> code,
  Value<String> variantId,
  Value<String> productId,
  Value<String?> unit,
  Value<int> qtyPerScanMilli,
  Value<int> rowid,
});

class $$LBarcodesTableFilterComposer
    extends Composer<_$AppDatabase, $LBarcodesTable> {
  $$LBarcodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qtyPerScanMilli => $composableBuilder(
    column: $table.qtyPerScanMilli,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LBarcodesTableOrderingComposer
    extends Composer<_$AppDatabase, $LBarcodesTable> {
  $$LBarcodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qtyPerScanMilli => $composableBuilder(
    column: $table.qtyPerScanMilli,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LBarcodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LBarcodesTable> {
  $$LBarcodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get qtyPerScanMilli => $composableBuilder(
    column: $table.qtyPerScanMilli,
    builder: (column) => column,
  );
}

class $$LBarcodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LBarcodesTable,
          LBarcode,
          $$LBarcodesTableFilterComposer,
          $$LBarcodesTableOrderingComposer,
          $$LBarcodesTableAnnotationComposer,
          $$LBarcodesTableCreateCompanionBuilder,
          $$LBarcodesTableUpdateCompanionBuilder,
          (LBarcode, BaseReferences<_$AppDatabase, $LBarcodesTable, LBarcode>),
          LBarcode,
          PrefetchHooks Function()
        > {
  $$LBarcodesTableTableManager(_$AppDatabase db, $LBarcodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LBarcodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LBarcodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LBarcodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> code = const Value.absent(),
                Value<String> variantId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> qtyPerScanMilli = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LBarcodesCompanion(
                code: code,
                variantId: variantId,
                productId: productId,
                unit: unit,
                qtyPerScanMilli: qtyPerScanMilli,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String code,
                required String variantId,
                required String productId,
                Value<String?> unit = const Value.absent(),
                Value<int> qtyPerScanMilli = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LBarcodesCompanion.insert(
                code: code,
                variantId: variantId,
                productId: productId,
                unit: unit,
                qtyPerScanMilli: qtyPerScanMilli,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LBarcodesTable, LBarcode>(table),
                  BaseReferences<_$AppDatabase, $LBarcodesTable, LBarcode>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LBarcodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LBarcodesTable,
      LBarcode,
      $$LBarcodesTableFilterComposer,
      $$LBarcodesTableOrderingComposer,
      $$LBarcodesTableAnnotationComposer,
      $$LBarcodesTableCreateCompanionBuilder,
      $$LBarcodesTableUpdateCompanionBuilder,
      (LBarcode, BaseReferences<_$AppDatabase, $LBarcodesTable, LBarcode>),
      LBarcode,
      PrefetchHooks Function()
    >;
typedef $$LCustomersTableCreateCompanionBuilder = LCustomersCompanion Function({
  required String id,
  required String name,
  Value<String> phone,
  Value<String> address,
  Value<int> creditLimitP,
  Value<int> balanceP,
  Value<int> points,
  Value<String> notes,
  Value<bool> active,
  Value<int> rowid,
});
typedef $$LCustomersTableUpdateCompanionBuilder = LCustomersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> phone,
  Value<String> address,
  Value<int> creditLimitP,
  Value<int> balanceP,
  Value<int> points,
  Value<String> notes,
  Value<bool> active,
  Value<int> rowid,
});

class $$LCustomersTableFilterComposer
    extends Composer<_$AppDatabase, $LCustomersTable> {
  $$LCustomersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creditLimitP => $composableBuilder(
    column: $table.creditLimitP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balanceP => $composableBuilder(
    column: $table.balanceP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LCustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $LCustomersTable> {
  $$LCustomersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creditLimitP => $composableBuilder(
    column: $table.creditLimitP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balanceP => $composableBuilder(
    column: $table.balanceP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LCustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LCustomersTable> {
  $$LCustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<int> get creditLimitP => $composableBuilder(
    column: $table.creditLimitP,
    builder: (column) => column,
  );

  GeneratedColumn<int> get balanceP =>
      $composableBuilder(column: $table.balanceP, builder: (column) => column);

  GeneratedColumn<int> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$LCustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LCustomersTable,
          LCustomer,
          $$LCustomersTableFilterComposer,
          $$LCustomersTableOrderingComposer,
          $$LCustomersTableAnnotationComposer,
          $$LCustomersTableCreateCompanionBuilder,
          $$LCustomersTableUpdateCompanionBuilder,
          (
            LCustomer,
            BaseReferences<_$AppDatabase, $LCustomersTable, LCustomer>,
          ),
          LCustomer,
          PrefetchHooks Function()
        > {
  $$LCustomersTableTableManager(_$AppDatabase db, $LCustomersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LCustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LCustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LCustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<int> creditLimitP = const Value.absent(),
                Value<int> balanceP = const Value.absent(),
                Value<int> points = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LCustomersCompanion(
                id: id,
                name: name,
                phone: phone,
                address: address,
                creditLimitP: creditLimitP,
                balanceP: balanceP,
                points: points,
                notes: notes,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> phone = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<int> creditLimitP = const Value.absent(),
                Value<int> balanceP = const Value.absent(),
                Value<int> points = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LCustomersCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                address: address,
                creditLimitP: creditLimitP,
                balanceP: balanceP,
                points: points,
                notes: notes,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LCustomersTable, LCustomer>(table),
                  BaseReferences<_$AppDatabase, $LCustomersTable, LCustomer>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LCustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LCustomersTable,
      LCustomer,
      $$LCustomersTableFilterComposer,
      $$LCustomersTableOrderingComposer,
      $$LCustomersTableAnnotationComposer,
      $$LCustomersTableCreateCompanionBuilder,
      $$LCustomersTableUpdateCompanionBuilder,
      (LCustomer, BaseReferences<_$AppDatabase, $LCustomersTable, LCustomer>),
      LCustomer,
      PrefetchHooks Function()
    >;
typedef $$LStockTableCreateCompanionBuilder = LStockCompanion Function({
  required String branchId,
  required String variantId,
  required int onHandMilli,
  Value<int> rowid,
});
typedef $$LStockTableUpdateCompanionBuilder = LStockCompanion Function({
  Value<String> branchId,
  Value<String> variantId,
  Value<int> onHandMilli,
  Value<int> rowid,
});

class $$LStockTableFilterComposer
    extends Composer<_$AppDatabase, $LStockTable> {
  $$LStockTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get onHandMilli => $composableBuilder(
    column: $table.onHandMilli,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LStockTableOrderingComposer
    extends Composer<_$AppDatabase, $LStockTable> {
  $$LStockTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get onHandMilli => $composableBuilder(
    column: $table.onHandMilli,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LStockTableAnnotationComposer
    extends Composer<_$AppDatabase, $LStockTable> {
  $$LStockTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<int> get onHandMilli => $composableBuilder(
    column: $table.onHandMilli,
    builder: (column) => column,
  );
}

class $$LStockTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LStockTable,
          LStockData,
          $$LStockTableFilterComposer,
          $$LStockTableOrderingComposer,
          $$LStockTableAnnotationComposer,
          $$LStockTableCreateCompanionBuilder,
          $$LStockTableUpdateCompanionBuilder,
          (LStockData, BaseReferences<_$AppDatabase, $LStockTable, LStockData>),
          LStockData,
          PrefetchHooks Function()
        > {
  $$LStockTableTableManager(_$AppDatabase db, $LStockTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LStockTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LStockTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LStockTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> branchId = const Value.absent(),
                Value<String> variantId = const Value.absent(),
                Value<int> onHandMilli = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LStockCompanion(
                branchId: branchId,
                variantId: variantId,
                onHandMilli: onHandMilli,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String branchId,
                required String variantId,
                required int onHandMilli,
                Value<int> rowid = const Value.absent(),
              }) => LStockCompanion.insert(
                branchId: branchId,
                variantId: variantId,
                onHandMilli: onHandMilli,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LStockTable, LStockData>(table),
                  BaseReferences<_$AppDatabase, $LStockTable, LStockData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LStockTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LStockTable,
      LStockData,
      $$LStockTableFilterComposer,
      $$LStockTableOrderingComposer,
      $$LStockTableAnnotationComposer,
      $$LStockTableCreateCompanionBuilder,
      $$LStockTableUpdateCompanionBuilder,
      (LStockData, BaseReferences<_$AppDatabase, $LStockTable, LStockData>),
      LStockData,
      PrefetchHooks Function()
    >;
typedef $$LSalesTableCreateCompanionBuilder = LSalesCompanion Function({
  required String id,
  required String invoiceNo,
  required DateTime soldAt,
  Value<String> status,
  Value<String?> customerId,
  Value<String> customerName,
  required int subtotalP,
  Value<int> discountP,
  Value<int> taxP,
  Value<int> roundingP,
  required int totalP,
  required int paidP,
  Value<String> taxMode,
  Value<bool> cashRounding,
  Value<String> note,
  required String cashierId,
  Value<String> cashierName,
  required String branchId,
  Value<String?> shiftId,
  Value<int> pointsEarned,
  Value<String> syncState,
  Value<String> flags,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$LSalesTableUpdateCompanionBuilder = LSalesCompanion Function({
  Value<String> id,
  Value<String> invoiceNo,
  Value<DateTime> soldAt,
  Value<String> status,
  Value<String?> customerId,
  Value<String> customerName,
  Value<int> subtotalP,
  Value<int> discountP,
  Value<int> taxP,
  Value<int> roundingP,
  Value<int> totalP,
  Value<int> paidP,
  Value<String> taxMode,
  Value<bool> cashRounding,
  Value<String> note,
  Value<String> cashierId,
  Value<String> cashierName,
  Value<String> branchId,
  Value<String?> shiftId,
  Value<int> pointsEarned,
  Value<String> syncState,
  Value<String> flags,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$LSalesTableFilterComposer
    extends Composer<_$AppDatabase, $LSalesTable> {
  $$LSalesTableFilterComposer({
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

  ColumnFilters<String> get invoiceNo => $composableBuilder(
    column: $table.invoiceNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get soldAt => $composableBuilder(
    column: $table.soldAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotalP => $composableBuilder(
    column: $table.subtotalP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountP => $composableBuilder(
    column: $table.discountP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxP => $composableBuilder(
    column: $table.taxP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundingP => $composableBuilder(
    column: $table.roundingP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalP => $composableBuilder(
    column: $table.totalP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidP => $composableBuilder(
    column: $table.paidP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxMode => $composableBuilder(
    column: $table.taxMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cashRounding => $composableBuilder(
    column: $table.cashRounding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pointsEarned => $composableBuilder(
    column: $table.pointsEarned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flags => $composableBuilder(
    column: $table.flags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LSalesTableOrderingComposer
    extends Composer<_$AppDatabase, $LSalesTable> {
  $$LSalesTableOrderingComposer({
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

  ColumnOrderings<String> get invoiceNo => $composableBuilder(
    column: $table.invoiceNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get soldAt => $composableBuilder(
    column: $table.soldAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotalP => $composableBuilder(
    column: $table.subtotalP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountP => $composableBuilder(
    column: $table.discountP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxP => $composableBuilder(
    column: $table.taxP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundingP => $composableBuilder(
    column: $table.roundingP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalP => $composableBuilder(
    column: $table.totalP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidP => $composableBuilder(
    column: $table.paidP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxMode => $composableBuilder(
    column: $table.taxMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cashRounding => $composableBuilder(
    column: $table.cashRounding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pointsEarned => $composableBuilder(
    column: $table.pointsEarned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flags => $composableBuilder(
    column: $table.flags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LSalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LSalesTable> {
  $$LSalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get invoiceNo =>
      $composableBuilder(column: $table.invoiceNo, builder: (column) => column);

  GeneratedColumn<DateTime> get soldAt =>
      $composableBuilder(column: $table.soldAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subtotalP =>
      $composableBuilder(column: $table.subtotalP, builder: (column) => column);

  GeneratedColumn<int> get discountP =>
      $composableBuilder(column: $table.discountP, builder: (column) => column);

  GeneratedColumn<int> get taxP =>
      $composableBuilder(column: $table.taxP, builder: (column) => column);

  GeneratedColumn<int> get roundingP =>
      $composableBuilder(column: $table.roundingP, builder: (column) => column);

  GeneratedColumn<int> get totalP =>
      $composableBuilder(column: $table.totalP, builder: (column) => column);

  GeneratedColumn<int> get paidP =>
      $composableBuilder(column: $table.paidP, builder: (column) => column);

  GeneratedColumn<String> get taxMode =>
      $composableBuilder(column: $table.taxMode, builder: (column) => column);

  GeneratedColumn<bool> get cashRounding => $composableBuilder(
    column: $table.cashRounding,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get cashierId =>
      $composableBuilder(column: $table.cashierId, builder: (column) => column);

  GeneratedColumn<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get shiftId =>
      $composableBuilder(column: $table.shiftId, builder: (column) => column);

  GeneratedColumn<int> get pointsEarned => $composableBuilder(
    column: $table.pointsEarned,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get flags =>
      $composableBuilder(column: $table.flags, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LSalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LSalesTable,
          LSale,
          $$LSalesTableFilterComposer,
          $$LSalesTableOrderingComposer,
          $$LSalesTableAnnotationComposer,
          $$LSalesTableCreateCompanionBuilder,
          $$LSalesTableUpdateCompanionBuilder,
          (LSale, BaseReferences<_$AppDatabase, $LSalesTable, LSale>),
          LSale,
          PrefetchHooks Function()
        > {
  $$LSalesTableTableManager(_$AppDatabase db, $LSalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LSalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LSalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LSalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> invoiceNo = const Value.absent(),
                Value<DateTime> soldAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<int> subtotalP = const Value.absent(),
                Value<int> discountP = const Value.absent(),
                Value<int> taxP = const Value.absent(),
                Value<int> roundingP = const Value.absent(),
                Value<int> totalP = const Value.absent(),
                Value<int> paidP = const Value.absent(),
                Value<String> taxMode = const Value.absent(),
                Value<bool> cashRounding = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> cashierId = const Value.absent(),
                Value<String> cashierName = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String?> shiftId = const Value.absent(),
                Value<int> pointsEarned = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String> flags = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LSalesCompanion(
                id: id,
                invoiceNo: invoiceNo,
                soldAt: soldAt,
                status: status,
                customerId: customerId,
                customerName: customerName,
                subtotalP: subtotalP,
                discountP: discountP,
                taxP: taxP,
                roundingP: roundingP,
                totalP: totalP,
                paidP: paidP,
                taxMode: taxMode,
                cashRounding: cashRounding,
                note: note,
                cashierId: cashierId,
                cashierName: cashierName,
                branchId: branchId,
                shiftId: shiftId,
                pointsEarned: pointsEarned,
                syncState: syncState,
                flags: flags,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String invoiceNo,
                required DateTime soldAt,
                Value<String> status = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                required int subtotalP,
                Value<int> discountP = const Value.absent(),
                Value<int> taxP = const Value.absent(),
                Value<int> roundingP = const Value.absent(),
                required int totalP,
                required int paidP,
                Value<String> taxMode = const Value.absent(),
                Value<bool> cashRounding = const Value.absent(),
                Value<String> note = const Value.absent(),
                required String cashierId,
                Value<String> cashierName = const Value.absent(),
                required String branchId,
                Value<String?> shiftId = const Value.absent(),
                Value<int> pointsEarned = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String> flags = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LSalesCompanion.insert(
                id: id,
                invoiceNo: invoiceNo,
                soldAt: soldAt,
                status: status,
                customerId: customerId,
                customerName: customerName,
                subtotalP: subtotalP,
                discountP: discountP,
                taxP: taxP,
                roundingP: roundingP,
                totalP: totalP,
                paidP: paidP,
                taxMode: taxMode,
                cashRounding: cashRounding,
                note: note,
                cashierId: cashierId,
                cashierName: cashierName,
                branchId: branchId,
                shiftId: shiftId,
                pointsEarned: pointsEarned,
                syncState: syncState,
                flags: flags,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LSalesTable, LSale>(table),
                  BaseReferences<_$AppDatabase, $LSalesTable, LSale>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LSalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LSalesTable,
      LSale,
      $$LSalesTableFilterComposer,
      $$LSalesTableOrderingComposer,
      $$LSalesTableAnnotationComposer,
      $$LSalesTableCreateCompanionBuilder,
      $$LSalesTableUpdateCompanionBuilder,
      (LSale, BaseReferences<_$AppDatabase, $LSalesTable, LSale>),
      LSale,
      PrefetchHooks Function()
    >;
typedef $$LSaleLinesTableCreateCompanionBuilder = LSaleLinesCompanion Function({
  required String id,
  required String saleId,
  Value<int> position,
  required String variantId,
  required String productId,
  required String productName,
  Value<String> variantLabel,
  Value<String> sku,
  Value<String> unit,
  Value<int> unitFactorMilli,
  required int qtyMilli,
  required int unitPriceP,
  Value<int> discountP,
  Value<int> taxRateBp,
  Value<int> taxAmountP,
  required int netP,
  required int chargedP,
  Value<int> returnedQtyMilli,
  Value<int> warrantyMonths,
  Value<String> note,
  Value<int> rowid,
});
typedef $$LSaleLinesTableUpdateCompanionBuilder = LSaleLinesCompanion Function({
  Value<String> id,
  Value<String> saleId,
  Value<int> position,
  Value<String> variantId,
  Value<String> productId,
  Value<String> productName,
  Value<String> variantLabel,
  Value<String> sku,
  Value<String> unit,
  Value<int> unitFactorMilli,
  Value<int> qtyMilli,
  Value<int> unitPriceP,
  Value<int> discountP,
  Value<int> taxRateBp,
  Value<int> taxAmountP,
  Value<int> netP,
  Value<int> chargedP,
  Value<int> returnedQtyMilli,
  Value<int> warrantyMonths,
  Value<String> note,
  Value<int> rowid,
});

class $$LSaleLinesTableFilterComposer
    extends Composer<_$AppDatabase, $LSaleLinesTable> {
  $$LSaleLinesTableFilterComposer({
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

  ColumnFilters<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantLabel => $composableBuilder(
    column: $table.variantLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitFactorMilli => $composableBuilder(
    column: $table.unitFactorMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPriceP => $composableBuilder(
    column: $table.unitPriceP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountP => $composableBuilder(
    column: $table.discountP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxRateBp => $composableBuilder(
    column: $table.taxRateBp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxAmountP => $composableBuilder(
    column: $table.taxAmountP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get netP => $composableBuilder(
    column: $table.netP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chargedP => $composableBuilder(
    column: $table.chargedP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get returnedQtyMilli => $composableBuilder(
    column: $table.returnedQtyMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warrantyMonths => $composableBuilder(
    column: $table.warrantyMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LSaleLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $LSaleLinesTable> {
  $$LSaleLinesTableOrderingComposer({
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

  ColumnOrderings<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantLabel => $composableBuilder(
    column: $table.variantLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitFactorMilli => $composableBuilder(
    column: $table.unitFactorMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPriceP => $composableBuilder(
    column: $table.unitPriceP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountP => $composableBuilder(
    column: $table.discountP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxRateBp => $composableBuilder(
    column: $table.taxRateBp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxAmountP => $composableBuilder(
    column: $table.taxAmountP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get netP => $composableBuilder(
    column: $table.netP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chargedP => $composableBuilder(
    column: $table.chargedP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get returnedQtyMilli => $composableBuilder(
    column: $table.returnedQtyMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warrantyMonths => $composableBuilder(
    column: $table.warrantyMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LSaleLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LSaleLinesTable> {
  $$LSaleLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get saleId =>
      $composableBuilder(column: $table.saleId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variantLabel => $composableBuilder(
    column: $table.variantLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get unitFactorMilli => $composableBuilder(
    column: $table.unitFactorMilli,
    builder: (column) => column,
  );

  GeneratedColumn<int> get qtyMilli =>
      $composableBuilder(column: $table.qtyMilli, builder: (column) => column);

  GeneratedColumn<int> get unitPriceP => $composableBuilder(
    column: $table.unitPriceP,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountP =>
      $composableBuilder(column: $table.discountP, builder: (column) => column);

  GeneratedColumn<int> get taxRateBp =>
      $composableBuilder(column: $table.taxRateBp, builder: (column) => column);

  GeneratedColumn<int> get taxAmountP => $composableBuilder(
    column: $table.taxAmountP,
    builder: (column) => column,
  );

  GeneratedColumn<int> get netP =>
      $composableBuilder(column: $table.netP, builder: (column) => column);

  GeneratedColumn<int> get chargedP =>
      $composableBuilder(column: $table.chargedP, builder: (column) => column);

  GeneratedColumn<int> get returnedQtyMilli => $composableBuilder(
    column: $table.returnedQtyMilli,
    builder: (column) => column,
  );

  GeneratedColumn<int> get warrantyMonths => $composableBuilder(
    column: $table.warrantyMonths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$LSaleLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LSaleLinesTable,
          LSaleLine,
          $$LSaleLinesTableFilterComposer,
          $$LSaleLinesTableOrderingComposer,
          $$LSaleLinesTableAnnotationComposer,
          $$LSaleLinesTableCreateCompanionBuilder,
          $$LSaleLinesTableUpdateCompanionBuilder,
          (
            LSaleLine,
            BaseReferences<_$AppDatabase, $LSaleLinesTable, LSaleLine>,
          ),
          LSaleLine,
          PrefetchHooks Function()
        > {
  $$LSaleLinesTableTableManager(_$AppDatabase db, $LSaleLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LSaleLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LSaleLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LSaleLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> variantId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String> variantLabel = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> unitFactorMilli = const Value.absent(),
                Value<int> qtyMilli = const Value.absent(),
                Value<int> unitPriceP = const Value.absent(),
                Value<int> discountP = const Value.absent(),
                Value<int> taxRateBp = const Value.absent(),
                Value<int> taxAmountP = const Value.absent(),
                Value<int> netP = const Value.absent(),
                Value<int> chargedP = const Value.absent(),
                Value<int> returnedQtyMilli = const Value.absent(),
                Value<int> warrantyMonths = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LSaleLinesCompanion(
                id: id,
                saleId: saleId,
                position: position,
                variantId: variantId,
                productId: productId,
                productName: productName,
                variantLabel: variantLabel,
                sku: sku,
                unit: unit,
                unitFactorMilli: unitFactorMilli,
                qtyMilli: qtyMilli,
                unitPriceP: unitPriceP,
                discountP: discountP,
                taxRateBp: taxRateBp,
                taxAmountP: taxAmountP,
                netP: netP,
                chargedP: chargedP,
                returnedQtyMilli: returnedQtyMilli,
                warrantyMonths: warrantyMonths,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String saleId,
                Value<int> position = const Value.absent(),
                required String variantId,
                required String productId,
                required String productName,
                Value<String> variantLabel = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> unitFactorMilli = const Value.absent(),
                required int qtyMilli,
                required int unitPriceP,
                Value<int> discountP = const Value.absent(),
                Value<int> taxRateBp = const Value.absent(),
                Value<int> taxAmountP = const Value.absent(),
                required int netP,
                required int chargedP,
                Value<int> returnedQtyMilli = const Value.absent(),
                Value<int> warrantyMonths = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LSaleLinesCompanion.insert(
                id: id,
                saleId: saleId,
                position: position,
                variantId: variantId,
                productId: productId,
                productName: productName,
                variantLabel: variantLabel,
                sku: sku,
                unit: unit,
                unitFactorMilli: unitFactorMilli,
                qtyMilli: qtyMilli,
                unitPriceP: unitPriceP,
                discountP: discountP,
                taxRateBp: taxRateBp,
                taxAmountP: taxAmountP,
                netP: netP,
                chargedP: chargedP,
                returnedQtyMilli: returnedQtyMilli,
                warrantyMonths: warrantyMonths,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LSaleLinesTable, LSaleLine>(table),
                  BaseReferences<_$AppDatabase, $LSaleLinesTable, LSaleLine>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LSaleLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LSaleLinesTable,
      LSaleLine,
      $$LSaleLinesTableFilterComposer,
      $$LSaleLinesTableOrderingComposer,
      $$LSaleLinesTableAnnotationComposer,
      $$LSaleLinesTableCreateCompanionBuilder,
      $$LSaleLinesTableUpdateCompanionBuilder,
      (LSaleLine, BaseReferences<_$AppDatabase, $LSaleLinesTable, LSaleLine>),
      LSaleLine,
      PrefetchHooks Function()
    >;
typedef $$LSalePaymentsTableCreateCompanionBuilder =
    LSalePaymentsCompanion Function({
      required String id,
      required String saleId,
      required String method,
      required int amountP,
      Value<String> reference,
      Value<String> kind,
      required DateTime paidAt,
      Value<int> rowid,
    });
typedef $$LSalePaymentsTableUpdateCompanionBuilder =
    LSalePaymentsCompanion Function({
      Value<String> id,
      Value<String> saleId,
      Value<String> method,
      Value<int> amountP,
      Value<String> reference,
      Value<String> kind,
      Value<DateTime> paidAt,
      Value<int> rowid,
    });

class $$LSalePaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $LSalePaymentsTable> {
  $$LSalePaymentsTableFilterComposer({
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

  ColumnFilters<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountP => $composableBuilder(
    column: $table.amountP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LSalePaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LSalePaymentsTable> {
  $$LSalePaymentsTableOrderingComposer({
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

  ColumnOrderings<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountP => $composableBuilder(
    column: $table.amountP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LSalePaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LSalePaymentsTable> {
  $$LSalePaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get saleId =>
      $composableBuilder(column: $table.saleId, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get amountP =>
      $composableBuilder(column: $table.amountP, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);
}

class $$LSalePaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LSalePaymentsTable,
          LSalePayment,
          $$LSalePaymentsTableFilterComposer,
          $$LSalePaymentsTableOrderingComposer,
          $$LSalePaymentsTableAnnotationComposer,
          $$LSalePaymentsTableCreateCompanionBuilder,
          $$LSalePaymentsTableUpdateCompanionBuilder,
          (
            LSalePayment,
            BaseReferences<_$AppDatabase, $LSalePaymentsTable, LSalePayment>,
          ),
          LSalePayment,
          PrefetchHooks Function()
        > {
  $$LSalePaymentsTableTableManager(_$AppDatabase db, $LSalePaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LSalePaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LSalePaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LSalePaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<int> amountP = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<DateTime> paidAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LSalePaymentsCompanion(
                id: id,
                saleId: saleId,
                method: method,
                amountP: amountP,
                reference: reference,
                kind: kind,
                paidAt: paidAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String saleId,
                required String method,
                required int amountP,
                Value<String> reference = const Value.absent(),
                Value<String> kind = const Value.absent(),
                required DateTime paidAt,
                Value<int> rowid = const Value.absent(),
              }) => LSalePaymentsCompanion.insert(
                id: id,
                saleId: saleId,
                method: method,
                amountP: amountP,
                reference: reference,
                kind: kind,
                paidAt: paidAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LSalePaymentsTable, LSalePayment>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LSalePaymentsTable,
                    LSalePayment
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LSalePaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LSalePaymentsTable,
      LSalePayment,
      $$LSalePaymentsTableFilterComposer,
      $$LSalePaymentsTableOrderingComposer,
      $$LSalePaymentsTableAnnotationComposer,
      $$LSalePaymentsTableCreateCompanionBuilder,
      $$LSalePaymentsTableUpdateCompanionBuilder,
      (
        LSalePayment,
        BaseReferences<_$AppDatabase, $LSalePaymentsTable, LSalePayment>,
      ),
      LSalePayment,
      PrefetchHooks Function()
    >;
typedef $$LExpensesTableCreateCompanionBuilder = LExpensesCompanion Function({
  required String id,
  required String branchId,
  required String category,
  required int amountP,
  Value<String> method,
  Value<String> note,
  required DateTime spentAt,
  Value<String> syncState,
  Value<int> rowid,
});
typedef $$LExpensesTableUpdateCompanionBuilder = LExpensesCompanion Function({
  Value<String> id,
  Value<String> branchId,
  Value<String> category,
  Value<int> amountP,
  Value<String> method,
  Value<String> note,
  Value<DateTime> spentAt,
  Value<String> syncState,
  Value<int> rowid,
});

class $$LExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $LExpensesTable> {
  $$LExpensesTableFilterComposer({
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

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountP => $composableBuilder(
    column: $table.amountP,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get spentAt => $composableBuilder(
    column: $table.spentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $LExpensesTable> {
  $$LExpensesTableOrderingComposer({
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

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountP => $composableBuilder(
    column: $table.amountP,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get spentAt => $composableBuilder(
    column: $table.spentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LExpensesTable> {
  $$LExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get amountP =>
      $composableBuilder(column: $table.amountP, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get spentAt =>
      $composableBuilder(column: $table.spentAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);
}

class $$LExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LExpensesTable,
          LExpense,
          $$LExpensesTableFilterComposer,
          $$LExpensesTableOrderingComposer,
          $$LExpensesTableAnnotationComposer,
          $$LExpensesTableCreateCompanionBuilder,
          $$LExpensesTableUpdateCompanionBuilder,
          (LExpense, BaseReferences<_$AppDatabase, $LExpensesTable, LExpense>),
          LExpense,
          PrefetchHooks Function()
        > {
  $$LExpensesTableTableManager(_$AppDatabase db, $LExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> amountP = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> spentAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LExpensesCompanion(
                id: id,
                branchId: branchId,
                category: category,
                amountP: amountP,
                method: method,
                note: note,
                spentAt: spentAt,
                syncState: syncState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String branchId,
                required String category,
                required int amountP,
                Value<String> method = const Value.absent(),
                Value<String> note = const Value.absent(),
                required DateTime spentAt,
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LExpensesCompanion.insert(
                id: id,
                branchId: branchId,
                category: category,
                amountP: amountP,
                method: method,
                note: note,
                spentAt: spentAt,
                syncState: syncState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LExpensesTable, LExpense>(table),
                  BaseReferences<_$AppDatabase, $LExpensesTable, LExpense>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LExpensesTable,
      LExpense,
      $$LExpensesTableFilterComposer,
      $$LExpensesTableOrderingComposer,
      $$LExpensesTableAnnotationComposer,
      $$LExpensesTableCreateCompanionBuilder,
      $$LExpensesTableUpdateCompanionBuilder,
      (LExpense, BaseReferences<_$AppDatabase, $LExpensesTable, LExpense>),
      LExpense,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  required String id,
  required String type,
  required String payload,
  Value<String?> actorId,
  required DateTime occurredAt,
  Value<String> status,
  Value<int> attempts,
  Value<String?> errorCode,
  Value<String?> lastError,
  Value<String> summary,
  required DateTime createdAt,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  Value<String> id,
  Value<String> type,
  Value<String> payload,
  Value<String?> actorId,
  Value<DateTime> occurredAt,
  Value<String> status,
  Value<int> attempts,
  Value<String?> errorCode,
  Value<String?> lastError,
  Value<String> summary,
  Value<DateTime> createdAt,
});

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxData,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxData, BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>),
          OutboxData,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> actorId = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxCompanion(
                seq: seq,
                id: id,
                type: type,
                payload: payload,
                actorId: actorId,
                occurredAt: occurredAt,
                status: status,
                attempts: attempts,
                errorCode: errorCode,
                lastError: lastError,
                summary: summary,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String id,
                required String type,
                required String payload,
                Value<String?> actorId = const Value.absent(),
                required DateTime occurredAt,
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> summary = const Value.absent(),
                required DateTime createdAt,
              }) => OutboxCompanion.insert(
                seq: seq,
                id: id,
                type: type,
                payload: payload,
                actorId: actorId,
                occurredAt: occurredAt,
                status: status,
                attempts: attempts,
                errorCode: errorCode,
                lastError: lastError,
                summary: summary,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxData>(table),
                  BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxData,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxData, BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>),
      OutboxData,
      PrefetchHooks Function()
    >;
typedef $$HeldCartsTableCreateCompanionBuilder = HeldCartsCompanion Function({
  required String id,
  required String name,
  required String json,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$HeldCartsTableUpdateCompanionBuilder = HeldCartsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> json,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$HeldCartsTableFilterComposer
    extends Composer<_$AppDatabase, $HeldCartsTable> {
  $$HeldCartsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HeldCartsTableOrderingComposer
    extends Composer<_$AppDatabase, $HeldCartsTable> {
  $$HeldCartsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HeldCartsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HeldCartsTable> {
  $$HeldCartsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HeldCartsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HeldCartsTable,
          HeldCart,
          $$HeldCartsTableFilterComposer,
          $$HeldCartsTableOrderingComposer,
          $$HeldCartsTableAnnotationComposer,
          $$HeldCartsTableCreateCompanionBuilder,
          $$HeldCartsTableUpdateCompanionBuilder,
          (HeldCart, BaseReferences<_$AppDatabase, $HeldCartsTable, HeldCart>),
          HeldCart,
          PrefetchHooks Function()
        > {
  $$HeldCartsTableTableManager(_$AppDatabase db, $HeldCartsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HeldCartsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HeldCartsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HeldCartsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HeldCartsCompanion(
                id: id,
                name: name,
                json: json,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String json,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => HeldCartsCompanion.insert(
                id: id,
                name: name,
                json: json,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HeldCartsTable, HeldCart>(table),
                  BaseReferences<_$AppDatabase, $HeldCartsTable, HeldCart>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HeldCartsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HeldCartsTable,
      HeldCart,
      $$HeldCartsTableFilterComposer,
      $$HeldCartsTableOrderingComposer,
      $$HeldCartsTableAnnotationComposer,
      $$HeldCartsTableCreateCompanionBuilder,
      $$HeldCartsTableUpdateCompanionBuilder,
      (HeldCart, BaseReferences<_$AppDatabase, $HeldCartsTable, HeldCart>),
      HeldCart,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KvTableTableManager get kv => $$KvTableTableManager(_db, _db.kv);
  $$LCategoriesTableTableManager get lCategories =>
      $$LCategoriesTableTableManager(_db, _db.lCategories);
  $$LTaxClassesTableTableManager get lTaxClasses =>
      $$LTaxClassesTableTableManager(_db, _db.lTaxClasses);
  $$LProductsTableTableManager get lProducts =>
      $$LProductsTableTableManager(_db, _db.lProducts);
  $$LVariantsTableTableManager get lVariants =>
      $$LVariantsTableTableManager(_db, _db.lVariants);
  $$LBarcodesTableTableManager get lBarcodes =>
      $$LBarcodesTableTableManager(_db, _db.lBarcodes);
  $$LCustomersTableTableManager get lCustomers =>
      $$LCustomersTableTableManager(_db, _db.lCustomers);
  $$LStockTableTableManager get lStock =>
      $$LStockTableTableManager(_db, _db.lStock);
  $$LSalesTableTableManager get lSales =>
      $$LSalesTableTableManager(_db, _db.lSales);
  $$LSaleLinesTableTableManager get lSaleLines =>
      $$LSaleLinesTableTableManager(_db, _db.lSaleLines);
  $$LSalePaymentsTableTableManager get lSalePayments =>
      $$LSalePaymentsTableTableManager(_db, _db.lSalePayments);
  $$LExpensesTableTableManager get lExpenses =>
      $$LExpensesTableTableManager(_db, _db.lExpenses);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$HeldCartsTableTableManager get heldCarts =>
      $$HeldCartsTableTableManager(_db, _db.heldCarts);
}
