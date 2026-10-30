// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'careerspeak_database.dart';

// ignore_for_file: type=lint
class $AppPreferencesTable extends AppPreferences
    with TableInfo<$AppPreferencesTable, AppPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uiLocaleMeta = const VerificationMeta(
    'uiLocale',
  );
  @override
  late final GeneratedColumn<String> uiLocale = GeneratedColumn<String>(
    'ui_locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationLocaleMeta = const VerificationMeta(
    'translationLocale',
  );
  @override
  late final GeneratedColumn<String> translationLocale =
      GeneratedColumn<String>(
        'translation_locale',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _preferredAccentMeta = const VerificationMeta(
    'preferredAccent',
  );
  @override
  late final GeneratedColumn<String> preferredAccent = GeneratedColumn<String>(
    'preferred_accent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _themeCodeMeta = const VerificationMeta(
    'themeCode',
  );
  @override
  late final GeneratedColumn<String> themeCode = GeneratedColumn<String>(
    'theme_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _focusModeMeta = const VerificationMeta(
    'focusMode',
  );
  @override
  late final GeneratedColumn<bool> focusMode = GeneratedColumn<bool>(
    'focus_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("focus_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _storageQuotaBytesMeta = const VerificationMeta(
    'storageQuotaBytes',
  );
  @override
  late final GeneratedColumn<int> storageQuotaBytes = GeneratedColumn<int>(
    'storage_quota_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uiLocale,
    translationLocale,
    preferredAccent,
    themeCode,
    focusMode,
    storageQuotaBytes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ui_locale')) {
      context.handle(
        _uiLocaleMeta,
        uiLocale.isAcceptableOrUnknown(data['ui_locale']!, _uiLocaleMeta),
      );
    } else if (isInserting) {
      context.missing(_uiLocaleMeta);
    }
    if (data.containsKey('translation_locale')) {
      context.handle(
        _translationLocaleMeta,
        translationLocale.isAcceptableOrUnknown(
          data['translation_locale']!,
          _translationLocaleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationLocaleMeta);
    }
    if (data.containsKey('preferred_accent')) {
      context.handle(
        _preferredAccentMeta,
        preferredAccent.isAcceptableOrUnknown(
          data['preferred_accent']!,
          _preferredAccentMeta,
        ),
      );
    }
    if (data.containsKey('theme_code')) {
      context.handle(
        _themeCodeMeta,
        themeCode.isAcceptableOrUnknown(data['theme_code']!, _themeCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_themeCodeMeta);
    }
    if (data.containsKey('focus_mode')) {
      context.handle(
        _focusModeMeta,
        focusMode.isAcceptableOrUnknown(data['focus_mode']!, _focusModeMeta),
      );
    }
    if (data.containsKey('storage_quota_bytes')) {
      context.handle(
        _storageQuotaBytesMeta,
        storageQuotaBytes.isAcceptableOrUnknown(
          data['storage_quota_bytes']!,
          _storageQuotaBytesMeta,
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
  AppPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppPreference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uiLocale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ui_locale'],
      )!,
      translationLocale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation_locale'],
      )!,
      preferredAccent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_accent'],
      ),
      themeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_code'],
      )!,
      focusMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}focus_mode'],
      )!,
      storageQuotaBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}storage_quota_bytes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppPreferencesTable createAlias(String alias) {
    return $AppPreferencesTable(attachedDatabase, alias);
  }
}

class AppPreference extends DataClass implements Insertable<AppPreference> {
  final int id;
  final String uiLocale;
  final String translationLocale;
  final String? preferredAccent;
  final String themeCode;
  final bool focusMode;
  final int? storageQuotaBytes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AppPreference({
    required this.id,
    required this.uiLocale,
    required this.translationLocale,
    this.preferredAccent,
    required this.themeCode,
    required this.focusMode,
    this.storageQuotaBytes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ui_locale'] = Variable<String>(uiLocale);
    map['translation_locale'] = Variable<String>(translationLocale);
    if (!nullToAbsent || preferredAccent != null) {
      map['preferred_accent'] = Variable<String>(preferredAccent);
    }
    map['theme_code'] = Variable<String>(themeCode);
    map['focus_mode'] = Variable<bool>(focusMode);
    if (!nullToAbsent || storageQuotaBytes != null) {
      map['storage_quota_bytes'] = Variable<int>(storageQuotaBytes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppPreferencesCompanion toCompanion(bool nullToAbsent) {
    return AppPreferencesCompanion(
      id: Value(id),
      uiLocale: Value(uiLocale),
      translationLocale: Value(translationLocale),
      preferredAccent: preferredAccent == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredAccent),
      themeCode: Value(themeCode),
      focusMode: Value(focusMode),
      storageQuotaBytes: storageQuotaBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(storageQuotaBytes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppPreference(
      id: serializer.fromJson<int>(json['id']),
      uiLocale: serializer.fromJson<String>(json['uiLocale']),
      translationLocale: serializer.fromJson<String>(json['translationLocale']),
      preferredAccent: serializer.fromJson<String?>(json['preferredAccent']),
      themeCode: serializer.fromJson<String>(json['themeCode']),
      focusMode: serializer.fromJson<bool>(json['focusMode']),
      storageQuotaBytes: serializer.fromJson<int?>(json['storageQuotaBytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uiLocale': serializer.toJson<String>(uiLocale),
      'translationLocale': serializer.toJson<String>(translationLocale),
      'preferredAccent': serializer.toJson<String?>(preferredAccent),
      'themeCode': serializer.toJson<String>(themeCode),
      'focusMode': serializer.toJson<bool>(focusMode),
      'storageQuotaBytes': serializer.toJson<int?>(storageQuotaBytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppPreference copyWith({
    int? id,
    String? uiLocale,
    String? translationLocale,
    Value<String?> preferredAccent = const Value.absent(),
    String? themeCode,
    bool? focusMode,
    Value<int?> storageQuotaBytes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AppPreference(
    id: id ?? this.id,
    uiLocale: uiLocale ?? this.uiLocale,
    translationLocale: translationLocale ?? this.translationLocale,
    preferredAccent: preferredAccent.present
        ? preferredAccent.value
        : this.preferredAccent,
    themeCode: themeCode ?? this.themeCode,
    focusMode: focusMode ?? this.focusMode,
    storageQuotaBytes: storageQuotaBytes.present
        ? storageQuotaBytes.value
        : this.storageQuotaBytes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppPreference copyWithCompanion(AppPreferencesCompanion data) {
    return AppPreference(
      id: data.id.present ? data.id.value : this.id,
      uiLocale: data.uiLocale.present ? data.uiLocale.value : this.uiLocale,
      translationLocale: data.translationLocale.present
          ? data.translationLocale.value
          : this.translationLocale,
      preferredAccent: data.preferredAccent.present
          ? data.preferredAccent.value
          : this.preferredAccent,
      themeCode: data.themeCode.present ? data.themeCode.value : this.themeCode,
      focusMode: data.focusMode.present ? data.focusMode.value : this.focusMode,
      storageQuotaBytes: data.storageQuotaBytes.present
          ? data.storageQuotaBytes.value
          : this.storageQuotaBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppPreference(')
          ..write('id: $id, ')
          ..write('uiLocale: $uiLocale, ')
          ..write('translationLocale: $translationLocale, ')
          ..write('preferredAccent: $preferredAccent, ')
          ..write('themeCode: $themeCode, ')
          ..write('focusMode: $focusMode, ')
          ..write('storageQuotaBytes: $storageQuotaBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uiLocale,
    translationLocale,
    preferredAccent,
    themeCode,
    focusMode,
    storageQuotaBytes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppPreference &&
          other.id == this.id &&
          other.uiLocale == this.uiLocale &&
          other.translationLocale == this.translationLocale &&
          other.preferredAccent == this.preferredAccent &&
          other.themeCode == this.themeCode &&
          other.focusMode == this.focusMode &&
          other.storageQuotaBytes == this.storageQuotaBytes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AppPreferencesCompanion extends UpdateCompanion<AppPreference> {
  final Value<int> id;
  final Value<String> uiLocale;
  final Value<String> translationLocale;
  final Value<String?> preferredAccent;
  final Value<String> themeCode;
  final Value<bool> focusMode;
  final Value<int?> storageQuotaBytes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AppPreferencesCompanion({
    this.id = const Value.absent(),
    this.uiLocale = const Value.absent(),
    this.translationLocale = const Value.absent(),
    this.preferredAccent = const Value.absent(),
    this.themeCode = const Value.absent(),
    this.focusMode = const Value.absent(),
    this.storageQuotaBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppPreferencesCompanion.insert({
    this.id = const Value.absent(),
    required String uiLocale,
    required String translationLocale,
    this.preferredAccent = const Value.absent(),
    required String themeCode,
    this.focusMode = const Value.absent(),
    this.storageQuotaBytes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : uiLocale = Value(uiLocale),
       translationLocale = Value(translationLocale),
       themeCode = Value(themeCode),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AppPreference> custom({
    Expression<int>? id,
    Expression<String>? uiLocale,
    Expression<String>? translationLocale,
    Expression<String>? preferredAccent,
    Expression<String>? themeCode,
    Expression<bool>? focusMode,
    Expression<int>? storageQuotaBytes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uiLocale != null) 'ui_locale': uiLocale,
      if (translationLocale != null) 'translation_locale': translationLocale,
      if (preferredAccent != null) 'preferred_accent': preferredAccent,
      if (themeCode != null) 'theme_code': themeCode,
      if (focusMode != null) 'focus_mode': focusMode,
      if (storageQuotaBytes != null) 'storage_quota_bytes': storageQuotaBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppPreferencesCompanion copyWith({
    Value<int>? id,
    Value<String>? uiLocale,
    Value<String>? translationLocale,
    Value<String?>? preferredAccent,
    Value<String>? themeCode,
    Value<bool>? focusMode,
    Value<int?>? storageQuotaBytes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AppPreferencesCompanion(
      id: id ?? this.id,
      uiLocale: uiLocale ?? this.uiLocale,
      translationLocale: translationLocale ?? this.translationLocale,
      preferredAccent: preferredAccent ?? this.preferredAccent,
      themeCode: themeCode ?? this.themeCode,
      focusMode: focusMode ?? this.focusMode,
      storageQuotaBytes: storageQuotaBytes ?? this.storageQuotaBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uiLocale.present) {
      map['ui_locale'] = Variable<String>(uiLocale.value);
    }
    if (translationLocale.present) {
      map['translation_locale'] = Variable<String>(translationLocale.value);
    }
    if (preferredAccent.present) {
      map['preferred_accent'] = Variable<String>(preferredAccent.value);
    }
    if (themeCode.present) {
      map['theme_code'] = Variable<String>(themeCode.value);
    }
    if (focusMode.present) {
      map['focus_mode'] = Variable<bool>(focusMode.value);
    }
    if (storageQuotaBytes.present) {
      map['storage_quota_bytes'] = Variable<int>(storageQuotaBytes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppPreferencesCompanion(')
          ..write('id: $id, ')
          ..write('uiLocale: $uiLocale, ')
          ..write('translationLocale: $translationLocale, ')
          ..write('preferredAccent: $preferredAccent, ')
          ..write('themeCode: $themeCode, ')
          ..write('focusMode: $focusMode, ')
          ..write('storageQuotaBytes: $storageQuotaBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $InstallationRuntimeStatesTable extends InstallationRuntimeStates
    with TableInfo<$InstallationRuntimeStatesTable, InstallationRuntimeState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstallationRuntimeStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _registrationStateMeta = const VerificationMeta(
    'registrationState',
  );
  @override
  late final GeneratedColumn<String> registrationState =
      GeneratedColumn<String>(
        'registration_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastRegistrationAtMeta =
      const VerificationMeta('lastRegistrationAt');
  @override
  late final GeneratedColumn<DateTime> lastRegistrationAt =
      GeneratedColumn<DateTime>(
        'last_registration_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastTokenRefreshAtMeta =
      const VerificationMeta('lastTokenRefreshAt');
  @override
  late final GeneratedColumn<DateTime> lastTokenRefreshAt =
      GeneratedColumn<DateTime>(
        'last_token_refresh_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSuccessAtMeta = const VerificationMeta(
    'lastSuccessAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSuccessAt =
      GeneratedColumn<DateTime>(
        'last_success_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    registrationState,
    lastRegistrationAt,
    lastTokenRefreshAt,
    lastSuccessAt,
    lastErrorCode,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installation_runtime_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstallationRuntimeState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('registration_state')) {
      context.handle(
        _registrationStateMeta,
        registrationState.isAcceptableOrUnknown(
          data['registration_state']!,
          _registrationStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_registrationStateMeta);
    }
    if (data.containsKey('last_registration_at')) {
      context.handle(
        _lastRegistrationAtMeta,
        lastRegistrationAt.isAcceptableOrUnknown(
          data['last_registration_at']!,
          _lastRegistrationAtMeta,
        ),
      );
    }
    if (data.containsKey('last_token_refresh_at')) {
      context.handle(
        _lastTokenRefreshAtMeta,
        lastTokenRefreshAt.isAcceptableOrUnknown(
          data['last_token_refresh_at']!,
          _lastTokenRefreshAtMeta,
        ),
      );
    }
    if (data.containsKey('last_success_at')) {
      context.handle(
        _lastSuccessAtMeta,
        lastSuccessAt.isAcceptableOrUnknown(
          data['last_success_at']!,
          _lastSuccessAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
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
  InstallationRuntimeState map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstallationRuntimeState(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      registrationState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registration_state'],
      )!,
      lastRegistrationAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_registration_at'],
      ),
      lastTokenRefreshAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_token_refresh_at'],
      ),
      lastSuccessAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_success_at'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InstallationRuntimeStatesTable createAlias(String alias) {
    return $InstallationRuntimeStatesTable(attachedDatabase, alias);
  }
}

class InstallationRuntimeState extends DataClass
    implements Insertable<InstallationRuntimeState> {
  final int id;
  final String registrationState;
  final DateTime? lastRegistrationAt;
  final DateTime? lastTokenRefreshAt;
  final DateTime? lastSuccessAt;
  final String? lastErrorCode;
  final DateTime updatedAt;
  const InstallationRuntimeState({
    required this.id,
    required this.registrationState,
    this.lastRegistrationAt,
    this.lastTokenRefreshAt,
    this.lastSuccessAt,
    this.lastErrorCode,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['registration_state'] = Variable<String>(registrationState);
    if (!nullToAbsent || lastRegistrationAt != null) {
      map['last_registration_at'] = Variable<DateTime>(lastRegistrationAt);
    }
    if (!nullToAbsent || lastTokenRefreshAt != null) {
      map['last_token_refresh_at'] = Variable<DateTime>(lastTokenRefreshAt);
    }
    if (!nullToAbsent || lastSuccessAt != null) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InstallationRuntimeStatesCompanion toCompanion(bool nullToAbsent) {
    return InstallationRuntimeStatesCompanion(
      id: Value(id),
      registrationState: Value(registrationState),
      lastRegistrationAt: lastRegistrationAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRegistrationAt),
      lastTokenRefreshAt: lastTokenRefreshAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTokenRefreshAt),
      lastSuccessAt: lastSuccessAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessAt),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      updatedAt: Value(updatedAt),
    );
  }

  factory InstallationRuntimeState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstallationRuntimeState(
      id: serializer.fromJson<int>(json['id']),
      registrationState: serializer.fromJson<String>(json['registrationState']),
      lastRegistrationAt: serializer.fromJson<DateTime?>(
        json['lastRegistrationAt'],
      ),
      lastTokenRefreshAt: serializer.fromJson<DateTime?>(
        json['lastTokenRefreshAt'],
      ),
      lastSuccessAt: serializer.fromJson<DateTime?>(json['lastSuccessAt']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'registrationState': serializer.toJson<String>(registrationState),
      'lastRegistrationAt': serializer.toJson<DateTime?>(lastRegistrationAt),
      'lastTokenRefreshAt': serializer.toJson<DateTime?>(lastTokenRefreshAt),
      'lastSuccessAt': serializer.toJson<DateTime?>(lastSuccessAt),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InstallationRuntimeState copyWith({
    int? id,
    String? registrationState,
    Value<DateTime?> lastRegistrationAt = const Value.absent(),
    Value<DateTime?> lastTokenRefreshAt = const Value.absent(),
    Value<DateTime?> lastSuccessAt = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
    DateTime? updatedAt,
  }) => InstallationRuntimeState(
    id: id ?? this.id,
    registrationState: registrationState ?? this.registrationState,
    lastRegistrationAt: lastRegistrationAt.present
        ? lastRegistrationAt.value
        : this.lastRegistrationAt,
    lastTokenRefreshAt: lastTokenRefreshAt.present
        ? lastTokenRefreshAt.value
        : this.lastTokenRefreshAt,
    lastSuccessAt: lastSuccessAt.present
        ? lastSuccessAt.value
        : this.lastSuccessAt,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  InstallationRuntimeState copyWithCompanion(
    InstallationRuntimeStatesCompanion data,
  ) {
    return InstallationRuntimeState(
      id: data.id.present ? data.id.value : this.id,
      registrationState: data.registrationState.present
          ? data.registrationState.value
          : this.registrationState,
      lastRegistrationAt: data.lastRegistrationAt.present
          ? data.lastRegistrationAt.value
          : this.lastRegistrationAt,
      lastTokenRefreshAt: data.lastTokenRefreshAt.present
          ? data.lastTokenRefreshAt.value
          : this.lastTokenRefreshAt,
      lastSuccessAt: data.lastSuccessAt.present
          ? data.lastSuccessAt.value
          : this.lastSuccessAt,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstallationRuntimeState(')
          ..write('id: $id, ')
          ..write('registrationState: $registrationState, ')
          ..write('lastRegistrationAt: $lastRegistrationAt, ')
          ..write('lastTokenRefreshAt: $lastTokenRefreshAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    registrationState,
    lastRegistrationAt,
    lastTokenRefreshAt,
    lastSuccessAt,
    lastErrorCode,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstallationRuntimeState &&
          other.id == this.id &&
          other.registrationState == this.registrationState &&
          other.lastRegistrationAt == this.lastRegistrationAt &&
          other.lastTokenRefreshAt == this.lastTokenRefreshAt &&
          other.lastSuccessAt == this.lastSuccessAt &&
          other.lastErrorCode == this.lastErrorCode &&
          other.updatedAt == this.updatedAt);
}

class InstallationRuntimeStatesCompanion
    extends UpdateCompanion<InstallationRuntimeState> {
  final Value<int> id;
  final Value<String> registrationState;
  final Value<DateTime?> lastRegistrationAt;
  final Value<DateTime?> lastTokenRefreshAt;
  final Value<DateTime?> lastSuccessAt;
  final Value<String?> lastErrorCode;
  final Value<DateTime> updatedAt;
  const InstallationRuntimeStatesCompanion({
    this.id = const Value.absent(),
    this.registrationState = const Value.absent(),
    this.lastRegistrationAt = const Value.absent(),
    this.lastTokenRefreshAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  InstallationRuntimeStatesCompanion.insert({
    this.id = const Value.absent(),
    required String registrationState,
    this.lastRegistrationAt = const Value.absent(),
    this.lastTokenRefreshAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    required DateTime updatedAt,
  }) : registrationState = Value(registrationState),
       updatedAt = Value(updatedAt);
  static Insertable<InstallationRuntimeState> custom({
    Expression<int>? id,
    Expression<String>? registrationState,
    Expression<DateTime>? lastRegistrationAt,
    Expression<DateTime>? lastTokenRefreshAt,
    Expression<DateTime>? lastSuccessAt,
    Expression<String>? lastErrorCode,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (registrationState != null) 'registration_state': registrationState,
      if (lastRegistrationAt != null)
        'last_registration_at': lastRegistrationAt,
      if (lastTokenRefreshAt != null)
        'last_token_refresh_at': lastTokenRefreshAt,
      if (lastSuccessAt != null) 'last_success_at': lastSuccessAt,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  InstallationRuntimeStatesCompanion copyWith({
    Value<int>? id,
    Value<String>? registrationState,
    Value<DateTime?>? lastRegistrationAt,
    Value<DateTime?>? lastTokenRefreshAt,
    Value<DateTime?>? lastSuccessAt,
    Value<String?>? lastErrorCode,
    Value<DateTime>? updatedAt,
  }) {
    return InstallationRuntimeStatesCompanion(
      id: id ?? this.id,
      registrationState: registrationState ?? this.registrationState,
      lastRegistrationAt: lastRegistrationAt ?? this.lastRegistrationAt,
      lastTokenRefreshAt: lastTokenRefreshAt ?? this.lastTokenRefreshAt,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (registrationState.present) {
      map['registration_state'] = Variable<String>(registrationState.value);
    }
    if (lastRegistrationAt.present) {
      map['last_registration_at'] = Variable<DateTime>(
        lastRegistrationAt.value,
      );
    }
    if (lastTokenRefreshAt.present) {
      map['last_token_refresh_at'] = Variable<DateTime>(
        lastTokenRefreshAt.value,
      );
    }
    if (lastSuccessAt.present) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstallationRuntimeStatesCompanion(')
          ..write('id: $id, ')
          ..write('registrationState: $registrationState, ')
          ..write('lastRegistrationAt: $lastRegistrationAt, ')
          ..write('lastTokenRefreshAt: $lastTokenRefreshAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ContentManifestStatesTable extends ContentManifestStates
    with TableInfo<$ContentManifestStatesTable, ContentManifestState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentManifestStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentContentVersionMeta =
      const VerificationMeta('currentContentVersion');
  @override
  late final GeneratedColumn<int> currentContentVersion = GeneratedColumn<int>(
    'current_content_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentManifestChecksumMeta =
      const VerificationMeta('currentManifestChecksum');
  @override
  late final GeneratedColumn<String> currentManifestChecksum =
      GeneratedColumn<String>(
        'current_manifest_checksum',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _remoteContentVersionSeenMeta =
      const VerificationMeta('remoteContentVersionSeen');
  @override
  late final GeneratedColumn<int> remoteContentVersionSeen =
      GeneratedColumn<int>(
        'remote_content_version_seen',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _remoteManifestChecksumMeta =
      const VerificationMeta('remoteManifestChecksum');
  @override
  late final GeneratedColumn<String> remoteManifestChecksum =
      GeneratedColumn<String>(
        'remote_manifest_checksum',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastCheckedAtMeta = const VerificationMeta(
    'lastCheckedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastCheckedAt =
      GeneratedColumn<DateTime>(
        'last_checked_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSuccessfulSyncAtMeta =
      const VerificationMeta('lastSuccessfulSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSuccessfulSyncAt =
      GeneratedColumn<DateTime>(
        'last_successful_sync_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    schemaVersion,
    currentContentVersion,
    currentManifestChecksum,
    remoteContentVersionSeen,
    remoteManifestChecksum,
    etag,
    lastCheckedAt,
    lastSuccessfulSyncAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_manifest_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentManifestState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('current_content_version')) {
      context.handle(
        _currentContentVersionMeta,
        currentContentVersion.isAcceptableOrUnknown(
          data['current_content_version']!,
          _currentContentVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentContentVersionMeta);
    }
    if (data.containsKey('current_manifest_checksum')) {
      context.handle(
        _currentManifestChecksumMeta,
        currentManifestChecksum.isAcceptableOrUnknown(
          data['current_manifest_checksum']!,
          _currentManifestChecksumMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentManifestChecksumMeta);
    }
    if (data.containsKey('remote_content_version_seen')) {
      context.handle(
        _remoteContentVersionSeenMeta,
        remoteContentVersionSeen.isAcceptableOrUnknown(
          data['remote_content_version_seen']!,
          _remoteContentVersionSeenMeta,
        ),
      );
    }
    if (data.containsKey('remote_manifest_checksum')) {
      context.handle(
        _remoteManifestChecksumMeta,
        remoteManifestChecksum.isAcceptableOrUnknown(
          data['remote_manifest_checksum']!,
          _remoteManifestChecksumMeta,
        ),
      );
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('last_checked_at')) {
      context.handle(
        _lastCheckedAtMeta,
        lastCheckedAt.isAcceptableOrUnknown(
          data['last_checked_at']!,
          _lastCheckedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_successful_sync_at')) {
      context.handle(
        _lastSuccessfulSyncAtMeta,
        lastSuccessfulSyncAt.isAcceptableOrUnknown(
          data['last_successful_sync_at']!,
          _lastSuccessfulSyncAtMeta,
        ),
      );
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
  ContentManifestState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentManifestState(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      currentContentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_content_version'],
      )!,
      currentManifestChecksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_manifest_checksum'],
      )!,
      remoteContentVersionSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_content_version_seen'],
      ),
      remoteManifestChecksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_manifest_checksum'],
      ),
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      lastCheckedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_checked_at'],
      ),
      lastSuccessfulSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_successful_sync_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ContentManifestStatesTable createAlias(String alias) {
    return $ContentManifestStatesTable(attachedDatabase, alias);
  }
}

class ContentManifestState extends DataClass
    implements Insertable<ContentManifestState> {
  final int id;
  final int schemaVersion;
  final int currentContentVersion;
  final String currentManifestChecksum;
  final int? remoteContentVersionSeen;
  final String? remoteManifestChecksum;
  final String? etag;
  final DateTime? lastCheckedAt;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime updatedAt;
  const ContentManifestState({
    required this.id,
    required this.schemaVersion,
    required this.currentContentVersion,
    required this.currentManifestChecksum,
    this.remoteContentVersionSeen,
    this.remoteManifestChecksum,
    this.etag,
    this.lastCheckedAt,
    this.lastSuccessfulSyncAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['current_content_version'] = Variable<int>(currentContentVersion);
    map['current_manifest_checksum'] = Variable<String>(
      currentManifestChecksum,
    );
    if (!nullToAbsent || remoteContentVersionSeen != null) {
      map['remote_content_version_seen'] = Variable<int>(
        remoteContentVersionSeen,
      );
    }
    if (!nullToAbsent || remoteManifestChecksum != null) {
      map['remote_manifest_checksum'] = Variable<String>(
        remoteManifestChecksum,
      );
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || lastCheckedAt != null) {
      map['last_checked_at'] = Variable<DateTime>(lastCheckedAt);
    }
    if (!nullToAbsent || lastSuccessfulSyncAt != null) {
      map['last_successful_sync_at'] = Variable<DateTime>(lastSuccessfulSyncAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ContentManifestStatesCompanion toCompanion(bool nullToAbsent) {
    return ContentManifestStatesCompanion(
      id: Value(id),
      schemaVersion: Value(schemaVersion),
      currentContentVersion: Value(currentContentVersion),
      currentManifestChecksum: Value(currentManifestChecksum),
      remoteContentVersionSeen: remoteContentVersionSeen == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteContentVersionSeen),
      remoteManifestChecksum: remoteManifestChecksum == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteManifestChecksum),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      lastCheckedAt: lastCheckedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckedAt),
      lastSuccessfulSyncAt: lastSuccessfulSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessfulSyncAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ContentManifestState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentManifestState(
      id: serializer.fromJson<int>(json['id']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      currentContentVersion: serializer.fromJson<int>(
        json['currentContentVersion'],
      ),
      currentManifestChecksum: serializer.fromJson<String>(
        json['currentManifestChecksum'],
      ),
      remoteContentVersionSeen: serializer.fromJson<int?>(
        json['remoteContentVersionSeen'],
      ),
      remoteManifestChecksum: serializer.fromJson<String?>(
        json['remoteManifestChecksum'],
      ),
      etag: serializer.fromJson<String?>(json['etag']),
      lastCheckedAt: serializer.fromJson<DateTime?>(json['lastCheckedAt']),
      lastSuccessfulSyncAt: serializer.fromJson<DateTime?>(
        json['lastSuccessfulSyncAt'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'currentContentVersion': serializer.toJson<int>(currentContentVersion),
      'currentManifestChecksum': serializer.toJson<String>(
        currentManifestChecksum,
      ),
      'remoteContentVersionSeen': serializer.toJson<int?>(
        remoteContentVersionSeen,
      ),
      'remoteManifestChecksum': serializer.toJson<String?>(
        remoteManifestChecksum,
      ),
      'etag': serializer.toJson<String?>(etag),
      'lastCheckedAt': serializer.toJson<DateTime?>(lastCheckedAt),
      'lastSuccessfulSyncAt': serializer.toJson<DateTime?>(
        lastSuccessfulSyncAt,
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ContentManifestState copyWith({
    int? id,
    int? schemaVersion,
    int? currentContentVersion,
    String? currentManifestChecksum,
    Value<int?> remoteContentVersionSeen = const Value.absent(),
    Value<String?> remoteManifestChecksum = const Value.absent(),
    Value<String?> etag = const Value.absent(),
    Value<DateTime?> lastCheckedAt = const Value.absent(),
    Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
    DateTime? updatedAt,
  }) => ContentManifestState(
    id: id ?? this.id,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    currentContentVersion: currentContentVersion ?? this.currentContentVersion,
    currentManifestChecksum:
        currentManifestChecksum ?? this.currentManifestChecksum,
    remoteContentVersionSeen: remoteContentVersionSeen.present
        ? remoteContentVersionSeen.value
        : this.remoteContentVersionSeen,
    remoteManifestChecksum: remoteManifestChecksum.present
        ? remoteManifestChecksum.value
        : this.remoteManifestChecksum,
    etag: etag.present ? etag.value : this.etag,
    lastCheckedAt: lastCheckedAt.present
        ? lastCheckedAt.value
        : this.lastCheckedAt,
    lastSuccessfulSyncAt: lastSuccessfulSyncAt.present
        ? lastSuccessfulSyncAt.value
        : this.lastSuccessfulSyncAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ContentManifestState copyWithCompanion(ContentManifestStatesCompanion data) {
    return ContentManifestState(
      id: data.id.present ? data.id.value : this.id,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      currentContentVersion: data.currentContentVersion.present
          ? data.currentContentVersion.value
          : this.currentContentVersion,
      currentManifestChecksum: data.currentManifestChecksum.present
          ? data.currentManifestChecksum.value
          : this.currentManifestChecksum,
      remoteContentVersionSeen: data.remoteContentVersionSeen.present
          ? data.remoteContentVersionSeen.value
          : this.remoteContentVersionSeen,
      remoteManifestChecksum: data.remoteManifestChecksum.present
          ? data.remoteManifestChecksum.value
          : this.remoteManifestChecksum,
      etag: data.etag.present ? data.etag.value : this.etag,
      lastCheckedAt: data.lastCheckedAt.present
          ? data.lastCheckedAt.value
          : this.lastCheckedAt,
      lastSuccessfulSyncAt: data.lastSuccessfulSyncAt.present
          ? data.lastSuccessfulSyncAt.value
          : this.lastSuccessfulSyncAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentManifestState(')
          ..write('id: $id, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('currentContentVersion: $currentContentVersion, ')
          ..write('currentManifestChecksum: $currentManifestChecksum, ')
          ..write('remoteContentVersionSeen: $remoteContentVersionSeen, ')
          ..write('remoteManifestChecksum: $remoteManifestChecksum, ')
          ..write('etag: $etag, ')
          ..write('lastCheckedAt: $lastCheckedAt, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    schemaVersion,
    currentContentVersion,
    currentManifestChecksum,
    remoteContentVersionSeen,
    remoteManifestChecksum,
    etag,
    lastCheckedAt,
    lastSuccessfulSyncAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentManifestState &&
          other.id == this.id &&
          other.schemaVersion == this.schemaVersion &&
          other.currentContentVersion == this.currentContentVersion &&
          other.currentManifestChecksum == this.currentManifestChecksum &&
          other.remoteContentVersionSeen == this.remoteContentVersionSeen &&
          other.remoteManifestChecksum == this.remoteManifestChecksum &&
          other.etag == this.etag &&
          other.lastCheckedAt == this.lastCheckedAt &&
          other.lastSuccessfulSyncAt == this.lastSuccessfulSyncAt &&
          other.updatedAt == this.updatedAt);
}

class ContentManifestStatesCompanion
    extends UpdateCompanion<ContentManifestState> {
  final Value<int> id;
  final Value<int> schemaVersion;
  final Value<int> currentContentVersion;
  final Value<String> currentManifestChecksum;
  final Value<int?> remoteContentVersionSeen;
  final Value<String?> remoteManifestChecksum;
  final Value<String?> etag;
  final Value<DateTime?> lastCheckedAt;
  final Value<DateTime?> lastSuccessfulSyncAt;
  final Value<DateTime> updatedAt;
  const ContentManifestStatesCompanion({
    this.id = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.currentContentVersion = const Value.absent(),
    this.currentManifestChecksum = const Value.absent(),
    this.remoteContentVersionSeen = const Value.absent(),
    this.remoteManifestChecksum = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastCheckedAt = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ContentManifestStatesCompanion.insert({
    this.id = const Value.absent(),
    required int schemaVersion,
    required int currentContentVersion,
    required String currentManifestChecksum,
    this.remoteContentVersionSeen = const Value.absent(),
    this.remoteManifestChecksum = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastCheckedAt = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    required DateTime updatedAt,
  }) : schemaVersion = Value(schemaVersion),
       currentContentVersion = Value(currentContentVersion),
       currentManifestChecksum = Value(currentManifestChecksum),
       updatedAt = Value(updatedAt);
  static Insertable<ContentManifestState> custom({
    Expression<int>? id,
    Expression<int>? schemaVersion,
    Expression<int>? currentContentVersion,
    Expression<String>? currentManifestChecksum,
    Expression<int>? remoteContentVersionSeen,
    Expression<String>? remoteManifestChecksum,
    Expression<String>? etag,
    Expression<DateTime>? lastCheckedAt,
    Expression<DateTime>? lastSuccessfulSyncAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (currentContentVersion != null)
        'current_content_version': currentContentVersion,
      if (currentManifestChecksum != null)
        'current_manifest_checksum': currentManifestChecksum,
      if (remoteContentVersionSeen != null)
        'remote_content_version_seen': remoteContentVersionSeen,
      if (remoteManifestChecksum != null)
        'remote_manifest_checksum': remoteManifestChecksum,
      if (etag != null) 'etag': etag,
      if (lastCheckedAt != null) 'last_checked_at': lastCheckedAt,
      if (lastSuccessfulSyncAt != null)
        'last_successful_sync_at': lastSuccessfulSyncAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ContentManifestStatesCompanion copyWith({
    Value<int>? id,
    Value<int>? schemaVersion,
    Value<int>? currentContentVersion,
    Value<String>? currentManifestChecksum,
    Value<int?>? remoteContentVersionSeen,
    Value<String?>? remoteManifestChecksum,
    Value<String?>? etag,
    Value<DateTime?>? lastCheckedAt,
    Value<DateTime?>? lastSuccessfulSyncAt,
    Value<DateTime>? updatedAt,
  }) {
    return ContentManifestStatesCompanion(
      id: id ?? this.id,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      currentContentVersion:
          currentContentVersion ?? this.currentContentVersion,
      currentManifestChecksum:
          currentManifestChecksum ?? this.currentManifestChecksum,
      remoteContentVersionSeen:
          remoteContentVersionSeen ?? this.remoteContentVersionSeen,
      remoteManifestChecksum:
          remoteManifestChecksum ?? this.remoteManifestChecksum,
      etag: etag ?? this.etag,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (currentContentVersion.present) {
      map['current_content_version'] = Variable<int>(
        currentContentVersion.value,
      );
    }
    if (currentManifestChecksum.present) {
      map['current_manifest_checksum'] = Variable<String>(
        currentManifestChecksum.value,
      );
    }
    if (remoteContentVersionSeen.present) {
      map['remote_content_version_seen'] = Variable<int>(
        remoteContentVersionSeen.value,
      );
    }
    if (remoteManifestChecksum.present) {
      map['remote_manifest_checksum'] = Variable<String>(
        remoteManifestChecksum.value,
      );
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (lastCheckedAt.present) {
      map['last_checked_at'] = Variable<DateTime>(lastCheckedAt.value);
    }
    if (lastSuccessfulSyncAt.present) {
      map['last_successful_sync_at'] = Variable<DateTime>(
        lastSuccessfulSyncAt.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentManifestStatesCompanion(')
          ..write('id: $id, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('currentContentVersion: $currentContentVersion, ')
          ..write('currentManifestChecksum: $currentManifestChecksum, ')
          ..write('remoteContentVersionSeen: $remoteContentVersionSeen, ')
          ..write('remoteManifestChecksum: $remoteManifestChecksum, ')
          ..write('etag: $etag, ')
          ..write('lastCheckedAt: $lastCheckedAt, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ContentPackRevisionsTable extends ContentPackRevisions
    with TableInfo<$ContentPackRevisionsTable, ContentPackRevision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentPackRevisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _packCodeMeta = const VerificationMeta(
    'packCode',
  );
  @override
  late final GeneratedColumn<String> packCode = GeneratedColumn<String>(
    'pack_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantKeyMeta = const VerificationMeta(
    'variantKey',
  );
  @override
  late final GeneratedColumn<String> variantKey = GeneratedColumn<String>(
    'variant_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceContentVersionMeta =
      const VerificationMeta('sourceContentVersion');
  @override
  late final GeneratedColumn<int> sourceContentVersion = GeneratedColumn<int>(
    'source_content_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stagedAtMeta = const VerificationMeta(
    'stagedAt',
  );
  @override
  late final GeneratedColumn<DateTime> stagedAt = GeneratedColumn<DateTime>(
    'staged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verifiedAtMeta = const VerificationMeta(
    'verifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> verifiedAt = GeneratedColumn<DateTime>(
    'verified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentAtMeta = const VerificationMeta(
    'currentAt',
  );
  @override
  late final GeneratedColumn<DateTime> currentAt = GeneratedColumn<DateTime>(
    'current_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supersededAtMeta = const VerificationMeta(
    'supersededAt',
  );
  @override
  late final GeneratedColumn<DateTime> supersededAt = GeneratedColumn<DateTime>(
    'superseded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    packCode,
    variantKey,
    revision,
    schemaVersion,
    checksum,
    state,
    sourceContentVersion,
    stagedAt,
    verifiedAt,
    currentAt,
    supersededAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_pack_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentPackRevision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pack_code')) {
      context.handle(
        _packCodeMeta,
        packCode.isAcceptableOrUnknown(data['pack_code']!, _packCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_packCodeMeta);
    }
    if (data.containsKey('variant_key')) {
      context.handle(
        _variantKeyMeta,
        variantKey.isAcceptableOrUnknown(data['variant_key']!, _variantKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_variantKeyMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('source_content_version')) {
      context.handle(
        _sourceContentVersionMeta,
        sourceContentVersion.isAcceptableOrUnknown(
          data['source_content_version']!,
          _sourceContentVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceContentVersionMeta);
    }
    if (data.containsKey('staged_at')) {
      context.handle(
        _stagedAtMeta,
        stagedAt.isAcceptableOrUnknown(data['staged_at']!, _stagedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_stagedAtMeta);
    }
    if (data.containsKey('verified_at')) {
      context.handle(
        _verifiedAtMeta,
        verifiedAt.isAcceptableOrUnknown(data['verified_at']!, _verifiedAtMeta),
      );
    }
    if (data.containsKey('current_at')) {
      context.handle(
        _currentAtMeta,
        currentAt.isAcceptableOrUnknown(data['current_at']!, _currentAtMeta),
      );
    }
    if (data.containsKey('superseded_at')) {
      context.handle(
        _supersededAtMeta,
        supersededAt.isAcceptableOrUnknown(
          data['superseded_at']!,
          _supersededAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {packCode, variantKey, revision};
  @override
  ContentPackRevision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentPackRevision(
      packCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack_code'],
      )!,
      variantKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_key'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      sourceContentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_content_version'],
      )!,
      stagedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}staged_at'],
      )!,
      verifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}verified_at'],
      ),
      currentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}current_at'],
      ),
      supersededAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}superseded_at'],
      ),
    );
  }

  @override
  $ContentPackRevisionsTable createAlias(String alias) {
    return $ContentPackRevisionsTable(attachedDatabase, alias);
  }
}

class ContentPackRevision extends DataClass
    implements Insertable<ContentPackRevision> {
  final String packCode;
  final String variantKey;
  final int revision;
  final int schemaVersion;
  final String checksum;
  final String state;
  final int sourceContentVersion;
  final DateTime stagedAt;
  final DateTime? verifiedAt;
  final DateTime? currentAt;
  final DateTime? supersededAt;
  const ContentPackRevision({
    required this.packCode,
    required this.variantKey,
    required this.revision,
    required this.schemaVersion,
    required this.checksum,
    required this.state,
    required this.sourceContentVersion,
    required this.stagedAt,
    this.verifiedAt,
    this.currentAt,
    this.supersededAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pack_code'] = Variable<String>(packCode);
    map['variant_key'] = Variable<String>(variantKey);
    map['revision'] = Variable<int>(revision);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['checksum'] = Variable<String>(checksum);
    map['state'] = Variable<String>(state);
    map['source_content_version'] = Variable<int>(sourceContentVersion);
    map['staged_at'] = Variable<DateTime>(stagedAt);
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<DateTime>(verifiedAt);
    }
    if (!nullToAbsent || currentAt != null) {
      map['current_at'] = Variable<DateTime>(currentAt);
    }
    if (!nullToAbsent || supersededAt != null) {
      map['superseded_at'] = Variable<DateTime>(supersededAt);
    }
    return map;
  }

  ContentPackRevisionsCompanion toCompanion(bool nullToAbsent) {
    return ContentPackRevisionsCompanion(
      packCode: Value(packCode),
      variantKey: Value(variantKey),
      revision: Value(revision),
      schemaVersion: Value(schemaVersion),
      checksum: Value(checksum),
      state: Value(state),
      sourceContentVersion: Value(sourceContentVersion),
      stagedAt: Value(stagedAt),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
      currentAt: currentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(currentAt),
      supersededAt: supersededAt == null && nullToAbsent
          ? const Value.absent()
          : Value(supersededAt),
    );
  }

  factory ContentPackRevision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentPackRevision(
      packCode: serializer.fromJson<String>(json['packCode']),
      variantKey: serializer.fromJson<String>(json['variantKey']),
      revision: serializer.fromJson<int>(json['revision']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      checksum: serializer.fromJson<String>(json['checksum']),
      state: serializer.fromJson<String>(json['state']),
      sourceContentVersion: serializer.fromJson<int>(
        json['sourceContentVersion'],
      ),
      stagedAt: serializer.fromJson<DateTime>(json['stagedAt']),
      verifiedAt: serializer.fromJson<DateTime?>(json['verifiedAt']),
      currentAt: serializer.fromJson<DateTime?>(json['currentAt']),
      supersededAt: serializer.fromJson<DateTime?>(json['supersededAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packCode': serializer.toJson<String>(packCode),
      'variantKey': serializer.toJson<String>(variantKey),
      'revision': serializer.toJson<int>(revision),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'checksum': serializer.toJson<String>(checksum),
      'state': serializer.toJson<String>(state),
      'sourceContentVersion': serializer.toJson<int>(sourceContentVersion),
      'stagedAt': serializer.toJson<DateTime>(stagedAt),
      'verifiedAt': serializer.toJson<DateTime?>(verifiedAt),
      'currentAt': serializer.toJson<DateTime?>(currentAt),
      'supersededAt': serializer.toJson<DateTime?>(supersededAt),
    };
  }

  ContentPackRevision copyWith({
    String? packCode,
    String? variantKey,
    int? revision,
    int? schemaVersion,
    String? checksum,
    String? state,
    int? sourceContentVersion,
    DateTime? stagedAt,
    Value<DateTime?> verifiedAt = const Value.absent(),
    Value<DateTime?> currentAt = const Value.absent(),
    Value<DateTime?> supersededAt = const Value.absent(),
  }) => ContentPackRevision(
    packCode: packCode ?? this.packCode,
    variantKey: variantKey ?? this.variantKey,
    revision: revision ?? this.revision,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    checksum: checksum ?? this.checksum,
    state: state ?? this.state,
    sourceContentVersion: sourceContentVersion ?? this.sourceContentVersion,
    stagedAt: stagedAt ?? this.stagedAt,
    verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
    currentAt: currentAt.present ? currentAt.value : this.currentAt,
    supersededAt: supersededAt.present ? supersededAt.value : this.supersededAt,
  );
  ContentPackRevision copyWithCompanion(ContentPackRevisionsCompanion data) {
    return ContentPackRevision(
      packCode: data.packCode.present ? data.packCode.value : this.packCode,
      variantKey: data.variantKey.present
          ? data.variantKey.value
          : this.variantKey,
      revision: data.revision.present ? data.revision.value : this.revision,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      state: data.state.present ? data.state.value : this.state,
      sourceContentVersion: data.sourceContentVersion.present
          ? data.sourceContentVersion.value
          : this.sourceContentVersion,
      stagedAt: data.stagedAt.present ? data.stagedAt.value : this.stagedAt,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
      currentAt: data.currentAt.present ? data.currentAt.value : this.currentAt,
      supersededAt: data.supersededAt.present
          ? data.supersededAt.value
          : this.supersededAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentPackRevision(')
          ..write('packCode: $packCode, ')
          ..write('variantKey: $variantKey, ')
          ..write('revision: $revision, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('checksum: $checksum, ')
          ..write('state: $state, ')
          ..write('sourceContentVersion: $sourceContentVersion, ')
          ..write('stagedAt: $stagedAt, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('currentAt: $currentAt, ')
          ..write('supersededAt: $supersededAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    packCode,
    variantKey,
    revision,
    schemaVersion,
    checksum,
    state,
    sourceContentVersion,
    stagedAt,
    verifiedAt,
    currentAt,
    supersededAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentPackRevision &&
          other.packCode == this.packCode &&
          other.variantKey == this.variantKey &&
          other.revision == this.revision &&
          other.schemaVersion == this.schemaVersion &&
          other.checksum == this.checksum &&
          other.state == this.state &&
          other.sourceContentVersion == this.sourceContentVersion &&
          other.stagedAt == this.stagedAt &&
          other.verifiedAt == this.verifiedAt &&
          other.currentAt == this.currentAt &&
          other.supersededAt == this.supersededAt);
}

class ContentPackRevisionsCompanion
    extends UpdateCompanion<ContentPackRevision> {
  final Value<String> packCode;
  final Value<String> variantKey;
  final Value<int> revision;
  final Value<int> schemaVersion;
  final Value<String> checksum;
  final Value<String> state;
  final Value<int> sourceContentVersion;
  final Value<DateTime> stagedAt;
  final Value<DateTime?> verifiedAt;
  final Value<DateTime?> currentAt;
  final Value<DateTime?> supersededAt;
  final Value<int> rowid;
  const ContentPackRevisionsCompanion({
    this.packCode = const Value.absent(),
    this.variantKey = const Value.absent(),
    this.revision = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.checksum = const Value.absent(),
    this.state = const Value.absent(),
    this.sourceContentVersion = const Value.absent(),
    this.stagedAt = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.currentAt = const Value.absent(),
    this.supersededAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentPackRevisionsCompanion.insert({
    required String packCode,
    required String variantKey,
    required int revision,
    required int schemaVersion,
    required String checksum,
    required String state,
    required int sourceContentVersion,
    required DateTime stagedAt,
    this.verifiedAt = const Value.absent(),
    this.currentAt = const Value.absent(),
    this.supersededAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : packCode = Value(packCode),
       variantKey = Value(variantKey),
       revision = Value(revision),
       schemaVersion = Value(schemaVersion),
       checksum = Value(checksum),
       state = Value(state),
       sourceContentVersion = Value(sourceContentVersion),
       stagedAt = Value(stagedAt);
  static Insertable<ContentPackRevision> custom({
    Expression<String>? packCode,
    Expression<String>? variantKey,
    Expression<int>? revision,
    Expression<int>? schemaVersion,
    Expression<String>? checksum,
    Expression<String>? state,
    Expression<int>? sourceContentVersion,
    Expression<DateTime>? stagedAt,
    Expression<DateTime>? verifiedAt,
    Expression<DateTime>? currentAt,
    Expression<DateTime>? supersededAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packCode != null) 'pack_code': packCode,
      if (variantKey != null) 'variant_key': variantKey,
      if (revision != null) 'revision': revision,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (checksum != null) 'checksum': checksum,
      if (state != null) 'state': state,
      if (sourceContentVersion != null)
        'source_content_version': sourceContentVersion,
      if (stagedAt != null) 'staged_at': stagedAt,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (currentAt != null) 'current_at': currentAt,
      if (supersededAt != null) 'superseded_at': supersededAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentPackRevisionsCompanion copyWith({
    Value<String>? packCode,
    Value<String>? variantKey,
    Value<int>? revision,
    Value<int>? schemaVersion,
    Value<String>? checksum,
    Value<String>? state,
    Value<int>? sourceContentVersion,
    Value<DateTime>? stagedAt,
    Value<DateTime?>? verifiedAt,
    Value<DateTime?>? currentAt,
    Value<DateTime?>? supersededAt,
    Value<int>? rowid,
  }) {
    return ContentPackRevisionsCompanion(
      packCode: packCode ?? this.packCode,
      variantKey: variantKey ?? this.variantKey,
      revision: revision ?? this.revision,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      checksum: checksum ?? this.checksum,
      state: state ?? this.state,
      sourceContentVersion: sourceContentVersion ?? this.sourceContentVersion,
      stagedAt: stagedAt ?? this.stagedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      currentAt: currentAt ?? this.currentAt,
      supersededAt: supersededAt ?? this.supersededAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packCode.present) {
      map['pack_code'] = Variable<String>(packCode.value);
    }
    if (variantKey.present) {
      map['variant_key'] = Variable<String>(variantKey.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (sourceContentVersion.present) {
      map['source_content_version'] = Variable<int>(sourceContentVersion.value);
    }
    if (stagedAt.present) {
      map['staged_at'] = Variable<DateTime>(stagedAt.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<DateTime>(verifiedAt.value);
    }
    if (currentAt.present) {
      map['current_at'] = Variable<DateTime>(currentAt.value);
    }
    if (supersededAt.present) {
      map['superseded_at'] = Variable<DateTime>(supersededAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentPackRevisionsCompanion(')
          ..write('packCode: $packCode, ')
          ..write('variantKey: $variantKey, ')
          ..write('revision: $revision, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('checksum: $checksum, ')
          ..write('state: $state, ')
          ..write('sourceContentVersion: $sourceContentVersion, ')
          ..write('stagedAt: $stagedAt, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('currentAt: $currentAt, ')
          ..write('supersededAt: $supersededAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalContentRecordsTable extends LocalContentRecords
    with TableInfo<$LocalContentRecordsTable, LocalContentRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalContentRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contentCodeMeta = const VerificationMeta(
    'contentCode',
  );
  @override
  late final GeneratedColumn<String> contentCode = GeneratedColumn<String>(
    'content_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snapshotStateMeta = const VerificationMeta(
    'snapshotState',
  );
  @override
  late final GeneratedColumn<String> snapshotState = GeneratedColumn<String>(
    'snapshot_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceSchemaVersionMeta =
      const VerificationMeta('sourceSchemaVersion');
  @override
  late final GeneratedColumn<int> sourceSchemaVersion = GeneratedColumn<int>(
    'source_schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  List<GeneratedColumn> get $columns => [
    contentCode,
    contentType,
    revision,
    checksum,
    sortOrder,
    publishedAt,
    snapshotState,
    sourceSchemaVersion,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_content_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalContentRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('content_code')) {
      context.handle(
        _contentCodeMeta,
        contentCode.isAcceptableOrUnknown(
          data['content_code']!,
          _contentCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentCodeMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    }
    if (data.containsKey('snapshot_state')) {
      context.handle(
        _snapshotStateMeta,
        snapshotState.isAcceptableOrUnknown(
          data['snapshot_state']!,
          _snapshotStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snapshotStateMeta);
    }
    if (data.containsKey('source_schema_version')) {
      context.handle(
        _sourceSchemaVersionMeta,
        sourceSchemaVersion.isAcceptableOrUnknown(
          data['source_schema_version']!,
          _sourceSchemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceSchemaVersionMeta);
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
  Set<GeneratedColumn> get $primaryKey => {contentCode, contentType, revision};
  @override
  LocalContentRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalContentRecord(
      contentCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_code'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      ),
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      ),
      snapshotState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_state'],
      )!,
      sourceSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_schema_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalContentRecordsTable createAlias(String alias) {
    return $LocalContentRecordsTable(attachedDatabase, alias);
  }
}

class LocalContentRecord extends DataClass
    implements Insertable<LocalContentRecord> {
  final String contentCode;
  final String contentType;
  final int revision;
  final String checksum;
  final int? sortOrder;
  final DateTime? publishedAt;
  final String snapshotState;
  final int sourceSchemaVersion;
  final DateTime createdAt;
  const LocalContentRecord({
    required this.contentCode,
    required this.contentType,
    required this.revision,
    required this.checksum,
    this.sortOrder,
    this.publishedAt,
    required this.snapshotState,
    required this.sourceSchemaVersion,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['content_code'] = Variable<String>(contentCode);
    map['content_type'] = Variable<String>(contentType);
    map['revision'] = Variable<int>(revision);
    map['checksum'] = Variable<String>(checksum);
    if (!nullToAbsent || sortOrder != null) {
      map['sort_order'] = Variable<int>(sortOrder);
    }
    if (!nullToAbsent || publishedAt != null) {
      map['published_at'] = Variable<DateTime>(publishedAt);
    }
    map['snapshot_state'] = Variable<String>(snapshotState);
    map['source_schema_version'] = Variable<int>(sourceSchemaVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalContentRecordsCompanion toCompanion(bool nullToAbsent) {
    return LocalContentRecordsCompanion(
      contentCode: Value(contentCode),
      contentType: Value(contentType),
      revision: Value(revision),
      checksum: Value(checksum),
      sortOrder: sortOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(sortOrder),
      publishedAt: publishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedAt),
      snapshotState: Value(snapshotState),
      sourceSchemaVersion: Value(sourceSchemaVersion),
      createdAt: Value(createdAt),
    );
  }

  factory LocalContentRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalContentRecord(
      contentCode: serializer.fromJson<String>(json['contentCode']),
      contentType: serializer.fromJson<String>(json['contentType']),
      revision: serializer.fromJson<int>(json['revision']),
      checksum: serializer.fromJson<String>(json['checksum']),
      sortOrder: serializer.fromJson<int?>(json['sortOrder']),
      publishedAt: serializer.fromJson<DateTime?>(json['publishedAt']),
      snapshotState: serializer.fromJson<String>(json['snapshotState']),
      sourceSchemaVersion: serializer.fromJson<int>(
        json['sourceSchemaVersion'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contentCode': serializer.toJson<String>(contentCode),
      'contentType': serializer.toJson<String>(contentType),
      'revision': serializer.toJson<int>(revision),
      'checksum': serializer.toJson<String>(checksum),
      'sortOrder': serializer.toJson<int?>(sortOrder),
      'publishedAt': serializer.toJson<DateTime?>(publishedAt),
      'snapshotState': serializer.toJson<String>(snapshotState),
      'sourceSchemaVersion': serializer.toJson<int>(sourceSchemaVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalContentRecord copyWith({
    String? contentCode,
    String? contentType,
    int? revision,
    String? checksum,
    Value<int?> sortOrder = const Value.absent(),
    Value<DateTime?> publishedAt = const Value.absent(),
    String? snapshotState,
    int? sourceSchemaVersion,
    DateTime? createdAt,
  }) => LocalContentRecord(
    contentCode: contentCode ?? this.contentCode,
    contentType: contentType ?? this.contentType,
    revision: revision ?? this.revision,
    checksum: checksum ?? this.checksum,
    sortOrder: sortOrder.present ? sortOrder.value : this.sortOrder,
    publishedAt: publishedAt.present ? publishedAt.value : this.publishedAt,
    snapshotState: snapshotState ?? this.snapshotState,
    sourceSchemaVersion: sourceSchemaVersion ?? this.sourceSchemaVersion,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalContentRecord copyWithCompanion(LocalContentRecordsCompanion data) {
    return LocalContentRecord(
      contentCode: data.contentCode.present
          ? data.contentCode.value
          : this.contentCode,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      revision: data.revision.present ? data.revision.value : this.revision,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      snapshotState: data.snapshotState.present
          ? data.snapshotState.value
          : this.snapshotState,
      sourceSchemaVersion: data.sourceSchemaVersion.present
          ? data.sourceSchemaVersion.value
          : this.sourceSchemaVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalContentRecord(')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('revision: $revision, ')
          ..write('checksum: $checksum, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('snapshotState: $snapshotState, ')
          ..write('sourceSchemaVersion: $sourceSchemaVersion, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    contentCode,
    contentType,
    revision,
    checksum,
    sortOrder,
    publishedAt,
    snapshotState,
    sourceSchemaVersion,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalContentRecord &&
          other.contentCode == this.contentCode &&
          other.contentType == this.contentType &&
          other.revision == this.revision &&
          other.checksum == this.checksum &&
          other.sortOrder == this.sortOrder &&
          other.publishedAt == this.publishedAt &&
          other.snapshotState == this.snapshotState &&
          other.sourceSchemaVersion == this.sourceSchemaVersion &&
          other.createdAt == this.createdAt);
}

class LocalContentRecordsCompanion extends UpdateCompanion<LocalContentRecord> {
  final Value<String> contentCode;
  final Value<String> contentType;
  final Value<int> revision;
  final Value<String> checksum;
  final Value<int?> sortOrder;
  final Value<DateTime?> publishedAt;
  final Value<String> snapshotState;
  final Value<int> sourceSchemaVersion;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalContentRecordsCompanion({
    this.contentCode = const Value.absent(),
    this.contentType = const Value.absent(),
    this.revision = const Value.absent(),
    this.checksum = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.snapshotState = const Value.absent(),
    this.sourceSchemaVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalContentRecordsCompanion.insert({
    required String contentCode,
    required String contentType,
    required int revision,
    required String checksum,
    this.sortOrder = const Value.absent(),
    this.publishedAt = const Value.absent(),
    required String snapshotState,
    required int sourceSchemaVersion,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : contentCode = Value(contentCode),
       contentType = Value(contentType),
       revision = Value(revision),
       checksum = Value(checksum),
       snapshotState = Value(snapshotState),
       sourceSchemaVersion = Value(sourceSchemaVersion),
       createdAt = Value(createdAt);
  static Insertable<LocalContentRecord> custom({
    Expression<String>? contentCode,
    Expression<String>? contentType,
    Expression<int>? revision,
    Expression<String>? checksum,
    Expression<int>? sortOrder,
    Expression<DateTime>? publishedAt,
    Expression<String>? snapshotState,
    Expression<int>? sourceSchemaVersion,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contentCode != null) 'content_code': contentCode,
      if (contentType != null) 'content_type': contentType,
      if (revision != null) 'revision': revision,
      if (checksum != null) 'checksum': checksum,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (publishedAt != null) 'published_at': publishedAt,
      if (snapshotState != null) 'snapshot_state': snapshotState,
      if (sourceSchemaVersion != null)
        'source_schema_version': sourceSchemaVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalContentRecordsCompanion copyWith({
    Value<String>? contentCode,
    Value<String>? contentType,
    Value<int>? revision,
    Value<String>? checksum,
    Value<int?>? sortOrder,
    Value<DateTime?>? publishedAt,
    Value<String>? snapshotState,
    Value<int>? sourceSchemaVersion,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalContentRecordsCompanion(
      contentCode: contentCode ?? this.contentCode,
      contentType: contentType ?? this.contentType,
      revision: revision ?? this.revision,
      checksum: checksum ?? this.checksum,
      sortOrder: sortOrder ?? this.sortOrder,
      publishedAt: publishedAt ?? this.publishedAt,
      snapshotState: snapshotState ?? this.snapshotState,
      sourceSchemaVersion: sourceSchemaVersion ?? this.sourceSchemaVersion,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contentCode.present) {
      map['content_code'] = Variable<String>(contentCode.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (snapshotState.present) {
      map['snapshot_state'] = Variable<String>(snapshotState.value);
    }
    if (sourceSchemaVersion.present) {
      map['source_schema_version'] = Variable<int>(sourceSchemaVersion.value);
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
    return (StringBuffer('LocalContentRecordsCompanion(')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('revision: $revision, ')
          ..write('checksum: $checksum, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('snapshotState: $snapshotState, ')
          ..write('sourceSchemaVersion: $sourceSchemaVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contentCodeMeta = const VerificationMeta(
    'contentCode',
  );
  @override
  late final GeneratedColumn<String> contentCode = GeneratedColumn<String>(
    'content_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
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
  List<GeneratedColumn> get $columns => [contentCode, contentType, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('content_code')) {
      context.handle(
        _contentCodeMeta,
        contentCode.isAcceptableOrUnknown(
          data['content_code']!,
          _contentCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentCodeMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
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
  Set<GeneratedColumn> get $primaryKey => {contentCode, contentType};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      contentCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_code'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final String contentCode;
  final String contentType;
  final DateTime createdAt;
  const Favorite({
    required this.contentCode,
    required this.contentType,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['content_code'] = Variable<String>(contentCode);
    map['content_type'] = Variable<String>(contentType);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      contentCode: Value(contentCode),
      contentType: Value(contentType),
      createdAt: Value(createdAt),
    );
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      contentCode: serializer.fromJson<String>(json['contentCode']),
      contentType: serializer.fromJson<String>(json['contentType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contentCode': serializer.toJson<String>(contentCode),
      'contentType': serializer.toJson<String>(contentType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Favorite copyWith({
    String? contentCode,
    String? contentType,
    DateTime? createdAt,
  }) => Favorite(
    contentCode: contentCode ?? this.contentCode,
    contentType: contentType ?? this.contentType,
    createdAt: createdAt ?? this.createdAt,
  );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      contentCode: data.contentCode.present
          ? data.contentCode.value
          : this.contentCode,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(contentCode, contentType, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.contentCode == this.contentCode &&
          other.contentType == this.contentType &&
          other.createdAt == this.createdAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<String> contentCode;
  final Value<String> contentType;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.contentCode = const Value.absent(),
    this.contentType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({
    required String contentCode,
    required String contentType,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : contentCode = Value(contentCode),
       contentType = Value(contentType),
       createdAt = Value(createdAt);
  static Insertable<Favorite> custom({
    Expression<String>? contentCode,
    Expression<String>? contentType,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contentCode != null) 'content_code': contentCode,
      if (contentType != null) 'content_type': contentType,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith({
    Value<String>? contentCode,
    Value<String>? contentType,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FavoritesCompanion(
      contentCode: contentCode ?? this.contentCode,
      contentType: contentType ?? this.contentType,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contentCode.present) {
      map['content_code'] = Variable<String>(contentCode.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
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
    return (StringBuffer('FavoritesCompanion(')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentLearningStatesTable extends ContentLearningStates
    with TableInfo<$ContentLearningStatesTable, ContentLearningState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentLearningStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contentCodeMeta = const VerificationMeta(
    'contentCode',
  );
  @override
  late final GeneratedColumn<String> contentCode = GeneratedColumn<String>(
    'content_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listenedAtMeta = const VerificationMeta(
    'listenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> listenedAt = GeneratedColumn<DateTime>(
    'listened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _listenCountMeta = const VerificationMeta(
    'listenCount',
  );
  @override
  late final GeneratedColumn<int> listenCount = GeneratedColumn<int>(
    'listen_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPositionMsMeta = const VerificationMeta(
    'lastPositionMs',
  );
  @override
  late final GeneratedColumn<int> lastPositionMs = GeneratedColumn<int>(
    'last_position_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completionSourceMeta = const VerificationMeta(
    'completionSource',
  );
  @override
  late final GeneratedColumn<String> completionSource = GeneratedColumn<String>(
    'completion_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastRevisionSeenMeta = const VerificationMeta(
    'lastRevisionSeen',
  );
  @override
  late final GeneratedColumn<int> lastRevisionSeen = GeneratedColumn<int>(
    'last_revision_seen',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    contentCode,
    contentType,
    listenedAt,
    listenCount,
    lastPlayedAt,
    lastPositionMs,
    completedAt,
    completionSource,
    lastRevisionSeen,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_learning_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentLearningState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('content_code')) {
      context.handle(
        _contentCodeMeta,
        contentCode.isAcceptableOrUnknown(
          data['content_code']!,
          _contentCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentCodeMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('listened_at')) {
      context.handle(
        _listenedAtMeta,
        listenedAt.isAcceptableOrUnknown(data['listened_at']!, _listenedAtMeta),
      );
    }
    if (data.containsKey('listen_count')) {
      context.handle(
        _listenCountMeta,
        listenCount.isAcceptableOrUnknown(
          data['listen_count']!,
          _listenCountMeta,
        ),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_position_ms')) {
      context.handle(
        _lastPositionMsMeta,
        lastPositionMs.isAcceptableOrUnknown(
          data['last_position_ms']!,
          _lastPositionMsMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('completion_source')) {
      context.handle(
        _completionSourceMeta,
        completionSource.isAcceptableOrUnknown(
          data['completion_source']!,
          _completionSourceMeta,
        ),
      );
    }
    if (data.containsKey('last_revision_seen')) {
      context.handle(
        _lastRevisionSeenMeta,
        lastRevisionSeen.isAcceptableOrUnknown(
          data['last_revision_seen']!,
          _lastRevisionSeenMeta,
        ),
      );
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
  Set<GeneratedColumn> get $primaryKey => {contentCode, contentType};
  @override
  ContentLearningState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentLearningState(
      contentCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_code'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      listenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}listened_at'],
      ),
      listenCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}listen_count'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
      lastPositionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_position_ms'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      completionSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completion_source'],
      ),
      lastRevisionSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_revision_seen'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ContentLearningStatesTable createAlias(String alias) {
    return $ContentLearningStatesTable(attachedDatabase, alias);
  }
}

class ContentLearningState extends DataClass
    implements Insertable<ContentLearningState> {
  final String contentCode;
  final String contentType;
  final DateTime? listenedAt;
  final int listenCount;
  final DateTime? lastPlayedAt;
  final int? lastPositionMs;
  final DateTime? completedAt;
  final String? completionSource;
  final int? lastRevisionSeen;
  final DateTime updatedAt;
  const ContentLearningState({
    required this.contentCode,
    required this.contentType,
    this.listenedAt,
    required this.listenCount,
    this.lastPlayedAt,
    this.lastPositionMs,
    this.completedAt,
    this.completionSource,
    this.lastRevisionSeen,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['content_code'] = Variable<String>(contentCode);
    map['content_type'] = Variable<String>(contentType);
    if (!nullToAbsent || listenedAt != null) {
      map['listened_at'] = Variable<DateTime>(listenedAt);
    }
    map['listen_count'] = Variable<int>(listenCount);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    if (!nullToAbsent || lastPositionMs != null) {
      map['last_position_ms'] = Variable<int>(lastPositionMs);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || completionSource != null) {
      map['completion_source'] = Variable<String>(completionSource);
    }
    if (!nullToAbsent || lastRevisionSeen != null) {
      map['last_revision_seen'] = Variable<int>(lastRevisionSeen);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ContentLearningStatesCompanion toCompanion(bool nullToAbsent) {
    return ContentLearningStatesCompanion(
      contentCode: Value(contentCode),
      contentType: Value(contentType),
      listenedAt: listenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(listenedAt),
      listenCount: Value(listenCount),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      lastPositionMs: lastPositionMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPositionMs),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      completionSource: completionSource == null && nullToAbsent
          ? const Value.absent()
          : Value(completionSource),
      lastRevisionSeen: lastRevisionSeen == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRevisionSeen),
      updatedAt: Value(updatedAt),
    );
  }

  factory ContentLearningState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentLearningState(
      contentCode: serializer.fromJson<String>(json['contentCode']),
      contentType: serializer.fromJson<String>(json['contentType']),
      listenedAt: serializer.fromJson<DateTime?>(json['listenedAt']),
      listenCount: serializer.fromJson<int>(json['listenCount']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
      lastPositionMs: serializer.fromJson<int?>(json['lastPositionMs']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      completionSource: serializer.fromJson<String?>(json['completionSource']),
      lastRevisionSeen: serializer.fromJson<int?>(json['lastRevisionSeen']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contentCode': serializer.toJson<String>(contentCode),
      'contentType': serializer.toJson<String>(contentType),
      'listenedAt': serializer.toJson<DateTime?>(listenedAt),
      'listenCount': serializer.toJson<int>(listenCount),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
      'lastPositionMs': serializer.toJson<int?>(lastPositionMs),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'completionSource': serializer.toJson<String?>(completionSource),
      'lastRevisionSeen': serializer.toJson<int?>(lastRevisionSeen),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ContentLearningState copyWith({
    String? contentCode,
    String? contentType,
    Value<DateTime?> listenedAt = const Value.absent(),
    int? listenCount,
    Value<DateTime?> lastPlayedAt = const Value.absent(),
    Value<int?> lastPositionMs = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> completionSource = const Value.absent(),
    Value<int?> lastRevisionSeen = const Value.absent(),
    DateTime? updatedAt,
  }) => ContentLearningState(
    contentCode: contentCode ?? this.contentCode,
    contentType: contentType ?? this.contentType,
    listenedAt: listenedAt.present ? listenedAt.value : this.listenedAt,
    listenCount: listenCount ?? this.listenCount,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
    lastPositionMs: lastPositionMs.present
        ? lastPositionMs.value
        : this.lastPositionMs,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    completionSource: completionSource.present
        ? completionSource.value
        : this.completionSource,
    lastRevisionSeen: lastRevisionSeen.present
        ? lastRevisionSeen.value
        : this.lastRevisionSeen,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ContentLearningState copyWithCompanion(ContentLearningStatesCompanion data) {
    return ContentLearningState(
      contentCode: data.contentCode.present
          ? data.contentCode.value
          : this.contentCode,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      listenedAt: data.listenedAt.present
          ? data.listenedAt.value
          : this.listenedAt,
      listenCount: data.listenCount.present
          ? data.listenCount.value
          : this.listenCount,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      lastPositionMs: data.lastPositionMs.present
          ? data.lastPositionMs.value
          : this.lastPositionMs,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      completionSource: data.completionSource.present
          ? data.completionSource.value
          : this.completionSource,
      lastRevisionSeen: data.lastRevisionSeen.present
          ? data.lastRevisionSeen.value
          : this.lastRevisionSeen,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentLearningState(')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('listenedAt: $listenedAt, ')
          ..write('listenCount: $listenCount, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('lastPositionMs: $lastPositionMs, ')
          ..write('completedAt: $completedAt, ')
          ..write('completionSource: $completionSource, ')
          ..write('lastRevisionSeen: $lastRevisionSeen, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    contentCode,
    contentType,
    listenedAt,
    listenCount,
    lastPlayedAt,
    lastPositionMs,
    completedAt,
    completionSource,
    lastRevisionSeen,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentLearningState &&
          other.contentCode == this.contentCode &&
          other.contentType == this.contentType &&
          other.listenedAt == this.listenedAt &&
          other.listenCount == this.listenCount &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.lastPositionMs == this.lastPositionMs &&
          other.completedAt == this.completedAt &&
          other.completionSource == this.completionSource &&
          other.lastRevisionSeen == this.lastRevisionSeen &&
          other.updatedAt == this.updatedAt);
}

class ContentLearningStatesCompanion
    extends UpdateCompanion<ContentLearningState> {
  final Value<String> contentCode;
  final Value<String> contentType;
  final Value<DateTime?> listenedAt;
  final Value<int> listenCount;
  final Value<DateTime?> lastPlayedAt;
  final Value<int?> lastPositionMs;
  final Value<DateTime?> completedAt;
  final Value<String?> completionSource;
  final Value<int?> lastRevisionSeen;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ContentLearningStatesCompanion({
    this.contentCode = const Value.absent(),
    this.contentType = const Value.absent(),
    this.listenedAt = const Value.absent(),
    this.listenCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.lastPositionMs = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completionSource = const Value.absent(),
    this.lastRevisionSeen = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentLearningStatesCompanion.insert({
    required String contentCode,
    required String contentType,
    this.listenedAt = const Value.absent(),
    this.listenCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.lastPositionMs = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completionSource = const Value.absent(),
    this.lastRevisionSeen = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : contentCode = Value(contentCode),
       contentType = Value(contentType),
       updatedAt = Value(updatedAt);
  static Insertable<ContentLearningState> custom({
    Expression<String>? contentCode,
    Expression<String>? contentType,
    Expression<DateTime>? listenedAt,
    Expression<int>? listenCount,
    Expression<DateTime>? lastPlayedAt,
    Expression<int>? lastPositionMs,
    Expression<DateTime>? completedAt,
    Expression<String>? completionSource,
    Expression<int>? lastRevisionSeen,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contentCode != null) 'content_code': contentCode,
      if (contentType != null) 'content_type': contentType,
      if (listenedAt != null) 'listened_at': listenedAt,
      if (listenCount != null) 'listen_count': listenCount,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (lastPositionMs != null) 'last_position_ms': lastPositionMs,
      if (completedAt != null) 'completed_at': completedAt,
      if (completionSource != null) 'completion_source': completionSource,
      if (lastRevisionSeen != null) 'last_revision_seen': lastRevisionSeen,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentLearningStatesCompanion copyWith({
    Value<String>? contentCode,
    Value<String>? contentType,
    Value<DateTime?>? listenedAt,
    Value<int>? listenCount,
    Value<DateTime?>? lastPlayedAt,
    Value<int?>? lastPositionMs,
    Value<DateTime?>? completedAt,
    Value<String?>? completionSource,
    Value<int?>? lastRevisionSeen,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ContentLearningStatesCompanion(
      contentCode: contentCode ?? this.contentCode,
      contentType: contentType ?? this.contentType,
      listenedAt: listenedAt ?? this.listenedAt,
      listenCount: listenCount ?? this.listenCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      lastPositionMs: lastPositionMs ?? this.lastPositionMs,
      completedAt: completedAt ?? this.completedAt,
      completionSource: completionSource ?? this.completionSource,
      lastRevisionSeen: lastRevisionSeen ?? this.lastRevisionSeen,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contentCode.present) {
      map['content_code'] = Variable<String>(contentCode.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (listenedAt.present) {
      map['listened_at'] = Variable<DateTime>(listenedAt.value);
    }
    if (listenCount.present) {
      map['listen_count'] = Variable<int>(listenCount.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (lastPositionMs.present) {
      map['last_position_ms'] = Variable<int>(lastPositionMs.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (completionSource.present) {
      map['completion_source'] = Variable<String>(completionSource.value);
    }
    if (lastRevisionSeen.present) {
      map['last_revision_seen'] = Variable<int>(lastRevisionSeen.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentLearningStatesCompanion(')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('listenedAt: $listenedAt, ')
          ..write('listenCount: $listenCount, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('lastPositionMs: $lastPositionMs, ')
          ..write('completedAt: $completedAt, ')
          ..write('completionSource: $completionSource, ')
          ..write('lastRevisionSeen: $lastRevisionSeen, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CareerSpeakDatabase extends GeneratedDatabase {
  _$CareerSpeakDatabase(QueryExecutor e) : super(e);
  $CareerSpeakDatabaseManager get managers => $CareerSpeakDatabaseManager(this);
  late final $AppPreferencesTable appPreferences = $AppPreferencesTable(this);
  late final $InstallationRuntimeStatesTable installationRuntimeStates =
      $InstallationRuntimeStatesTable(this);
  late final $ContentManifestStatesTable contentManifestStates =
      $ContentManifestStatesTable(this);
  late final $ContentPackRevisionsTable contentPackRevisions =
      $ContentPackRevisionsTable(this);
  late final $LocalContentRecordsTable localContentRecords =
      $LocalContentRecordsTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $ContentLearningStatesTable contentLearningStates =
      $ContentLearningStatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appPreferences,
    installationRuntimeStates,
    contentManifestStates,
    contentPackRevisions,
    localContentRecords,
    favorites,
    contentLearningStates,
  ];
}

typedef $$AppPreferencesTableCreateCompanionBuilder =
    AppPreferencesCompanion Function({
      Value<int> id,
      required String uiLocale,
      required String translationLocale,
      Value<String?> preferredAccent,
      required String themeCode,
      Value<bool> focusMode,
      Value<int?> storageQuotaBytes,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$AppPreferencesTableUpdateCompanionBuilder =
    AppPreferencesCompanion Function({
      Value<int> id,
      Value<String> uiLocale,
      Value<String> translationLocale,
      Value<String?> preferredAccent,
      Value<String> themeCode,
      Value<bool> focusMode,
      Value<int?> storageQuotaBytes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$AppPreferencesTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableFilterComposer({
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

  ColumnFilters<String> get uiLocale => $composableBuilder(
    column: $table.uiLocale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translationLocale => $composableBuilder(
    column: $table.translationLocale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredAccent => $composableBuilder(
    column: $table.preferredAccent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeCode => $composableBuilder(
    column: $table.themeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get focusMode => $composableBuilder(
    column: $table.focusMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get storageQuotaBytes => $composableBuilder(
    column: $table.storageQuotaBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppPreferencesTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableOrderingComposer({
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

  ColumnOrderings<String> get uiLocale => $composableBuilder(
    column: $table.uiLocale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translationLocale => $composableBuilder(
    column: $table.translationLocale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredAccent => $composableBuilder(
    column: $table.preferredAccent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeCode => $composableBuilder(
    column: $table.themeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get focusMode => $composableBuilder(
    column: $table.focusMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get storageQuotaBytes => $composableBuilder(
    column: $table.storageQuotaBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppPreferencesTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uiLocale =>
      $composableBuilder(column: $table.uiLocale, builder: (column) => column);

  GeneratedColumn<String> get translationLocale => $composableBuilder(
    column: $table.translationLocale,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredAccent => $composableBuilder(
    column: $table.preferredAccent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeCode =>
      $composableBuilder(column: $table.themeCode, builder: (column) => column);

  GeneratedColumn<bool> get focusMode =>
      $composableBuilder(column: $table.focusMode, builder: (column) => column);

  GeneratedColumn<int> get storageQuotaBytes => $composableBuilder(
    column: $table.storageQuotaBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppPreferencesTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $AppPreferencesTable,
          AppPreference,
          $$AppPreferencesTableFilterComposer,
          $$AppPreferencesTableOrderingComposer,
          $$AppPreferencesTableAnnotationComposer,
          $$AppPreferencesTableCreateCompanionBuilder,
          $$AppPreferencesTableUpdateCompanionBuilder,
          (
            AppPreference,
            BaseReferences<
              _$CareerSpeakDatabase,
              $AppPreferencesTable,
              AppPreference
            >,
          ),
          AppPreference,
          PrefetchHooks Function()
        > {
  $$AppPreferencesTableTableManager(
    _$CareerSpeakDatabase db,
    $AppPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uiLocale = const Value.absent(),
                Value<String> translationLocale = const Value.absent(),
                Value<String?> preferredAccent = const Value.absent(),
                Value<String> themeCode = const Value.absent(),
                Value<bool> focusMode = const Value.absent(),
                Value<int?> storageQuotaBytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppPreferencesCompanion(
                id: id,
                uiLocale: uiLocale,
                translationLocale: translationLocale,
                preferredAccent: preferredAccent,
                themeCode: themeCode,
                focusMode: focusMode,
                storageQuotaBytes: storageQuotaBytes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uiLocale,
                required String translationLocale,
                Value<String?> preferredAccent = const Value.absent(),
                required String themeCode,
                Value<bool> focusMode = const Value.absent(),
                Value<int?> storageQuotaBytes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => AppPreferencesCompanion.insert(
                id: id,
                uiLocale: uiLocale,
                translationLocale: translationLocale,
                preferredAccent: preferredAccent,
                themeCode: themeCode,
                focusMode: focusMode,
                storageQuotaBytes: storageQuotaBytes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppPreferencesTable, AppPreference>(table),
                  BaseReferences<
                    _$CareerSpeakDatabase,
                    $AppPreferencesTable,
                    AppPreference
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $AppPreferencesTable,
      AppPreference,
      $$AppPreferencesTableFilterComposer,
      $$AppPreferencesTableOrderingComposer,
      $$AppPreferencesTableAnnotationComposer,
      $$AppPreferencesTableCreateCompanionBuilder,
      $$AppPreferencesTableUpdateCompanionBuilder,
      (
        AppPreference,
        BaseReferences<
          _$CareerSpeakDatabase,
          $AppPreferencesTable,
          AppPreference
        >,
      ),
      AppPreference,
      PrefetchHooks Function()
    >;
typedef $$InstallationRuntimeStatesTableCreateCompanionBuilder =
    InstallationRuntimeStatesCompanion Function({
      Value<int> id,
      required String registrationState,
      Value<DateTime?> lastRegistrationAt,
      Value<DateTime?> lastTokenRefreshAt,
      Value<DateTime?> lastSuccessAt,
      Value<String?> lastErrorCode,
      required DateTime updatedAt,
    });
typedef $$InstallationRuntimeStatesTableUpdateCompanionBuilder =
    InstallationRuntimeStatesCompanion Function({
      Value<int> id,
      Value<String> registrationState,
      Value<DateTime?> lastRegistrationAt,
      Value<DateTime?> lastTokenRefreshAt,
      Value<DateTime?> lastSuccessAt,
      Value<String?> lastErrorCode,
      Value<DateTime> updatedAt,
    });

class $$InstallationRuntimeStatesTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $InstallationRuntimeStatesTable> {
  $$InstallationRuntimeStatesTableFilterComposer({
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

  ColumnFilters<String> get registrationState => $composableBuilder(
    column: $table.registrationState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastRegistrationAt => $composableBuilder(
    column: $table.lastRegistrationAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastTokenRefreshAt => $composableBuilder(
    column: $table.lastTokenRefreshAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InstallationRuntimeStatesTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $InstallationRuntimeStatesTable> {
  $$InstallationRuntimeStatesTableOrderingComposer({
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

  ColumnOrderings<String> get registrationState => $composableBuilder(
    column: $table.registrationState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRegistrationAt => $composableBuilder(
    column: $table.lastRegistrationAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastTokenRefreshAt => $composableBuilder(
    column: $table.lastTokenRefreshAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstallationRuntimeStatesTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $InstallationRuntimeStatesTable> {
  $$InstallationRuntimeStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get registrationState => $composableBuilder(
    column: $table.registrationState,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastRegistrationAt => $composableBuilder(
    column: $table.lastRegistrationAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastTokenRefreshAt => $composableBuilder(
    column: $table.lastTokenRefreshAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InstallationRuntimeStatesTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $InstallationRuntimeStatesTable,
          InstallationRuntimeState,
          $$InstallationRuntimeStatesTableFilterComposer,
          $$InstallationRuntimeStatesTableOrderingComposer,
          $$InstallationRuntimeStatesTableAnnotationComposer,
          $$InstallationRuntimeStatesTableCreateCompanionBuilder,
          $$InstallationRuntimeStatesTableUpdateCompanionBuilder,
          (
            InstallationRuntimeState,
            BaseReferences<
              _$CareerSpeakDatabase,
              $InstallationRuntimeStatesTable,
              InstallationRuntimeState
            >,
          ),
          InstallationRuntimeState,
          PrefetchHooks Function()
        > {
  $$InstallationRuntimeStatesTableTableManager(
    _$CareerSpeakDatabase db,
    $InstallationRuntimeStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstallationRuntimeStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InstallationRuntimeStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InstallationRuntimeStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> registrationState = const Value.absent(),
                Value<DateTime?> lastRegistrationAt = const Value.absent(),
                Value<DateTime?> lastTokenRefreshAt = const Value.absent(),
                Value<DateTime?> lastSuccessAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => InstallationRuntimeStatesCompanion(
                id: id,
                registrationState: registrationState,
                lastRegistrationAt: lastRegistrationAt,
                lastTokenRefreshAt: lastTokenRefreshAt,
                lastSuccessAt: lastSuccessAt,
                lastErrorCode: lastErrorCode,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String registrationState,
                Value<DateTime?> lastRegistrationAt = const Value.absent(),
                Value<DateTime?> lastTokenRefreshAt = const Value.absent(),
                Value<DateTime?> lastSuccessAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                required DateTime updatedAt,
              }) => InstallationRuntimeStatesCompanion.insert(
                id: id,
                registrationState: registrationState,
                lastRegistrationAt: lastRegistrationAt,
                lastTokenRefreshAt: lastTokenRefreshAt,
                lastSuccessAt: lastSuccessAt,
                lastErrorCode: lastErrorCode,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $InstallationRuntimeStatesTable,
                    InstallationRuntimeState
                  >(table),
                  BaseReferences<
                    _$CareerSpeakDatabase,
                    $InstallationRuntimeStatesTable,
                    InstallationRuntimeState
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InstallationRuntimeStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $InstallationRuntimeStatesTable,
      InstallationRuntimeState,
      $$InstallationRuntimeStatesTableFilterComposer,
      $$InstallationRuntimeStatesTableOrderingComposer,
      $$InstallationRuntimeStatesTableAnnotationComposer,
      $$InstallationRuntimeStatesTableCreateCompanionBuilder,
      $$InstallationRuntimeStatesTableUpdateCompanionBuilder,
      (
        InstallationRuntimeState,
        BaseReferences<
          _$CareerSpeakDatabase,
          $InstallationRuntimeStatesTable,
          InstallationRuntimeState
        >,
      ),
      InstallationRuntimeState,
      PrefetchHooks Function()
    >;
typedef $$ContentManifestStatesTableCreateCompanionBuilder =
    ContentManifestStatesCompanion Function({
      Value<int> id,
      required int schemaVersion,
      required int currentContentVersion,
      required String currentManifestChecksum,
      Value<int?> remoteContentVersionSeen,
      Value<String?> remoteManifestChecksum,
      Value<String?> etag,
      Value<DateTime?> lastCheckedAt,
      Value<DateTime?> lastSuccessfulSyncAt,
      required DateTime updatedAt,
    });
typedef $$ContentManifestStatesTableUpdateCompanionBuilder =
    ContentManifestStatesCompanion Function({
      Value<int> id,
      Value<int> schemaVersion,
      Value<int> currentContentVersion,
      Value<String> currentManifestChecksum,
      Value<int?> remoteContentVersionSeen,
      Value<String?> remoteManifestChecksum,
      Value<String?> etag,
      Value<DateTime?> lastCheckedAt,
      Value<DateTime?> lastSuccessfulSyncAt,
      Value<DateTime> updatedAt,
    });

class $$ContentManifestStatesTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $ContentManifestStatesTable> {
  $$ContentManifestStatesTableFilterComposer({
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

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentContentVersion => $composableBuilder(
    column: $table.currentContentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentManifestChecksum => $composableBuilder(
    column: $table.currentManifestChecksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteContentVersionSeen => $composableBuilder(
    column: $table.remoteContentVersionSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteManifestChecksum => $composableBuilder(
    column: $table.remoteManifestChecksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContentManifestStatesTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $ContentManifestStatesTable> {
  $$ContentManifestStatesTableOrderingComposer({
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

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentContentVersion => $composableBuilder(
    column: $table.currentContentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentManifestChecksum => $composableBuilder(
    column: $table.currentManifestChecksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteContentVersionSeen => $composableBuilder(
    column: $table.remoteContentVersionSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteManifestChecksum => $composableBuilder(
    column: $table.remoteManifestChecksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentManifestStatesTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $ContentManifestStatesTable> {
  $$ContentManifestStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentContentVersion => $composableBuilder(
    column: $table.currentContentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentManifestChecksum => $composableBuilder(
    column: $table.currentManifestChecksum,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remoteContentVersionSeen => $composableBuilder(
    column: $table.remoteContentVersionSeen,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteManifestChecksum => $composableBuilder(
    column: $table.remoteManifestChecksum,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ContentManifestStatesTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $ContentManifestStatesTable,
          ContentManifestState,
          $$ContentManifestStatesTableFilterComposer,
          $$ContentManifestStatesTableOrderingComposer,
          $$ContentManifestStatesTableAnnotationComposer,
          $$ContentManifestStatesTableCreateCompanionBuilder,
          $$ContentManifestStatesTableUpdateCompanionBuilder,
          (
            ContentManifestState,
            BaseReferences<
              _$CareerSpeakDatabase,
              $ContentManifestStatesTable,
              ContentManifestState
            >,
          ),
          ContentManifestState,
          PrefetchHooks Function()
        > {
  $$ContentManifestStatesTableTableManager(
    _$CareerSpeakDatabase db,
    $ContentManifestStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentManifestStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ContentManifestStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ContentManifestStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> currentContentVersion = const Value.absent(),
                Value<String> currentManifestChecksum = const Value.absent(),
                Value<int?> remoteContentVersionSeen = const Value.absent(),
                Value<String?> remoteManifestChecksum = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<DateTime?> lastCheckedAt = const Value.absent(),
                Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ContentManifestStatesCompanion(
                id: id,
                schemaVersion: schemaVersion,
                currentContentVersion: currentContentVersion,
                currentManifestChecksum: currentManifestChecksum,
                remoteContentVersionSeen: remoteContentVersionSeen,
                remoteManifestChecksum: remoteManifestChecksum,
                etag: etag,
                lastCheckedAt: lastCheckedAt,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int schemaVersion,
                required int currentContentVersion,
                required String currentManifestChecksum,
                Value<int?> remoteContentVersionSeen = const Value.absent(),
                Value<String?> remoteManifestChecksum = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<DateTime?> lastCheckedAt = const Value.absent(),
                Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
                required DateTime updatedAt,
              }) => ContentManifestStatesCompanion.insert(
                id: id,
                schemaVersion: schemaVersion,
                currentContentVersion: currentContentVersion,
                currentManifestChecksum: currentManifestChecksum,
                remoteContentVersionSeen: remoteContentVersionSeen,
                remoteManifestChecksum: remoteManifestChecksum,
                etag: etag,
                lastCheckedAt: lastCheckedAt,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ContentManifestStatesTable,
                    ContentManifestState
                  >(table),
                  BaseReferences<
                    _$CareerSpeakDatabase,
                    $ContentManifestStatesTable,
                    ContentManifestState
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentManifestStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $ContentManifestStatesTable,
      ContentManifestState,
      $$ContentManifestStatesTableFilterComposer,
      $$ContentManifestStatesTableOrderingComposer,
      $$ContentManifestStatesTableAnnotationComposer,
      $$ContentManifestStatesTableCreateCompanionBuilder,
      $$ContentManifestStatesTableUpdateCompanionBuilder,
      (
        ContentManifestState,
        BaseReferences<
          _$CareerSpeakDatabase,
          $ContentManifestStatesTable,
          ContentManifestState
        >,
      ),
      ContentManifestState,
      PrefetchHooks Function()
    >;
typedef $$ContentPackRevisionsTableCreateCompanionBuilder =
    ContentPackRevisionsCompanion Function({
      required String packCode,
      required String variantKey,
      required int revision,
      required int schemaVersion,
      required String checksum,
      required String state,
      required int sourceContentVersion,
      required DateTime stagedAt,
      Value<DateTime?> verifiedAt,
      Value<DateTime?> currentAt,
      Value<DateTime?> supersededAt,
      Value<int> rowid,
    });
typedef $$ContentPackRevisionsTableUpdateCompanionBuilder =
    ContentPackRevisionsCompanion Function({
      Value<String> packCode,
      Value<String> variantKey,
      Value<int> revision,
      Value<int> schemaVersion,
      Value<String> checksum,
      Value<String> state,
      Value<int> sourceContentVersion,
      Value<DateTime> stagedAt,
      Value<DateTime?> verifiedAt,
      Value<DateTime?> currentAt,
      Value<DateTime?> supersededAt,
      Value<int> rowid,
    });

class $$ContentPackRevisionsTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $ContentPackRevisionsTable> {
  $$ContentPackRevisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get packCode => $composableBuilder(
    column: $table.packCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantKey => $composableBuilder(
    column: $table.variantKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceContentVersion => $composableBuilder(
    column: $table.sourceContentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get stagedAt => $composableBuilder(
    column: $table.stagedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get currentAt => $composableBuilder(
    column: $table.currentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get supersededAt => $composableBuilder(
    column: $table.supersededAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContentPackRevisionsTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $ContentPackRevisionsTable> {
  $$ContentPackRevisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get packCode => $composableBuilder(
    column: $table.packCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantKey => $composableBuilder(
    column: $table.variantKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceContentVersion => $composableBuilder(
    column: $table.sourceContentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get stagedAt => $composableBuilder(
    column: $table.stagedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get currentAt => $composableBuilder(
    column: $table.currentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get supersededAt => $composableBuilder(
    column: $table.supersededAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentPackRevisionsTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $ContentPackRevisionsTable> {
  $$ContentPackRevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get packCode =>
      $composableBuilder(column: $table.packCode, builder: (column) => column);

  GeneratedColumn<String> get variantKey => $composableBuilder(
    column: $table.variantKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get sourceContentVersion => $composableBuilder(
    column: $table.sourceContentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get stagedAt =>
      $composableBuilder(column: $table.stagedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get currentAt =>
      $composableBuilder(column: $table.currentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get supersededAt => $composableBuilder(
    column: $table.supersededAt,
    builder: (column) => column,
  );
}

class $$ContentPackRevisionsTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $ContentPackRevisionsTable,
          ContentPackRevision,
          $$ContentPackRevisionsTableFilterComposer,
          $$ContentPackRevisionsTableOrderingComposer,
          $$ContentPackRevisionsTableAnnotationComposer,
          $$ContentPackRevisionsTableCreateCompanionBuilder,
          $$ContentPackRevisionsTableUpdateCompanionBuilder,
          (
            ContentPackRevision,
            BaseReferences<
              _$CareerSpeakDatabase,
              $ContentPackRevisionsTable,
              ContentPackRevision
            >,
          ),
          ContentPackRevision,
          PrefetchHooks Function()
        > {
  $$ContentPackRevisionsTableTableManager(
    _$CareerSpeakDatabase db,
    $ContentPackRevisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentPackRevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentPackRevisionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ContentPackRevisionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> packCode = const Value.absent(),
                Value<String> variantKey = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> sourceContentVersion = const Value.absent(),
                Value<DateTime> stagedAt = const Value.absent(),
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<DateTime?> currentAt = const Value.absent(),
                Value<DateTime?> supersededAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentPackRevisionsCompanion(
                packCode: packCode,
                variantKey: variantKey,
                revision: revision,
                schemaVersion: schemaVersion,
                checksum: checksum,
                state: state,
                sourceContentVersion: sourceContentVersion,
                stagedAt: stagedAt,
                verifiedAt: verifiedAt,
                currentAt: currentAt,
                supersededAt: supersededAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String packCode,
                required String variantKey,
                required int revision,
                required int schemaVersion,
                required String checksum,
                required String state,
                required int sourceContentVersion,
                required DateTime stagedAt,
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<DateTime?> currentAt = const Value.absent(),
                Value<DateTime?> supersededAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentPackRevisionsCompanion.insert(
                packCode: packCode,
                variantKey: variantKey,
                revision: revision,
                schemaVersion: schemaVersion,
                checksum: checksum,
                state: state,
                sourceContentVersion: sourceContentVersion,
                stagedAt: stagedAt,
                verifiedAt: verifiedAt,
                currentAt: currentAt,
                supersededAt: supersededAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContentPackRevisionsTable, ContentPackRevision>(
                    table,
                  ),
                  BaseReferences<
                    _$CareerSpeakDatabase,
                    $ContentPackRevisionsTable,
                    ContentPackRevision
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentPackRevisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $ContentPackRevisionsTable,
      ContentPackRevision,
      $$ContentPackRevisionsTableFilterComposer,
      $$ContentPackRevisionsTableOrderingComposer,
      $$ContentPackRevisionsTableAnnotationComposer,
      $$ContentPackRevisionsTableCreateCompanionBuilder,
      $$ContentPackRevisionsTableUpdateCompanionBuilder,
      (
        ContentPackRevision,
        BaseReferences<
          _$CareerSpeakDatabase,
          $ContentPackRevisionsTable,
          ContentPackRevision
        >,
      ),
      ContentPackRevision,
      PrefetchHooks Function()
    >;
typedef $$LocalContentRecordsTableCreateCompanionBuilder =
    LocalContentRecordsCompanion Function({
      required String contentCode,
      required String contentType,
      required int revision,
      required String checksum,
      Value<int?> sortOrder,
      Value<DateTime?> publishedAt,
      required String snapshotState,
      required int sourceSchemaVersion,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalContentRecordsTableUpdateCompanionBuilder =
    LocalContentRecordsCompanion Function({
      Value<String> contentCode,
      Value<String> contentType,
      Value<int> revision,
      Value<String> checksum,
      Value<int?> sortOrder,
      Value<DateTime?> publishedAt,
      Value<String> snapshotState,
      Value<int> sourceSchemaVersion,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalContentRecordsTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $LocalContentRecordsTable> {
  $$LocalContentRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contentCode => $composableBuilder(
    column: $table.contentCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshotState => $composableBuilder(
    column: $table.snapshotState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceSchemaVersion => $composableBuilder(
    column: $table.sourceSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalContentRecordsTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $LocalContentRecordsTable> {
  $$LocalContentRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contentCode => $composableBuilder(
    column: $table.contentCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshotState => $composableBuilder(
    column: $table.snapshotState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceSchemaVersion => $composableBuilder(
    column: $table.sourceSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalContentRecordsTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $LocalContentRecordsTable> {
  $$LocalContentRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contentCode => $composableBuilder(
    column: $table.contentCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get snapshotState => $composableBuilder(
    column: $table.snapshotState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceSchemaVersion => $composableBuilder(
    column: $table.sourceSchemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalContentRecordsTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $LocalContentRecordsTable,
          LocalContentRecord,
          $$LocalContentRecordsTableFilterComposer,
          $$LocalContentRecordsTableOrderingComposer,
          $$LocalContentRecordsTableAnnotationComposer,
          $$LocalContentRecordsTableCreateCompanionBuilder,
          $$LocalContentRecordsTableUpdateCompanionBuilder,
          (
            LocalContentRecord,
            BaseReferences<
              _$CareerSpeakDatabase,
              $LocalContentRecordsTable,
              LocalContentRecord
            >,
          ),
          LocalContentRecord,
          PrefetchHooks Function()
        > {
  $$LocalContentRecordsTableTableManager(
    _$CareerSpeakDatabase db,
    $LocalContentRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalContentRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalContentRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalContentRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> contentCode = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<int?> sortOrder = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<String> snapshotState = const Value.absent(),
                Value<int> sourceSchemaVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalContentRecordsCompanion(
                contentCode: contentCode,
                contentType: contentType,
                revision: revision,
                checksum: checksum,
                sortOrder: sortOrder,
                publishedAt: publishedAt,
                snapshotState: snapshotState,
                sourceSchemaVersion: sourceSchemaVersion,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contentCode,
                required String contentType,
                required int revision,
                required String checksum,
                Value<int?> sortOrder = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                required String snapshotState,
                required int sourceSchemaVersion,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalContentRecordsCompanion.insert(
                contentCode: contentCode,
                contentType: contentType,
                revision: revision,
                checksum: checksum,
                sortOrder: sortOrder,
                publishedAt: publishedAt,
                snapshotState: snapshotState,
                sourceSchemaVersion: sourceSchemaVersion,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalContentRecordsTable, LocalContentRecord>(
                    table,
                  ),
                  BaseReferences<
                    _$CareerSpeakDatabase,
                    $LocalContentRecordsTable,
                    LocalContentRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalContentRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $LocalContentRecordsTable,
      LocalContentRecord,
      $$LocalContentRecordsTableFilterComposer,
      $$LocalContentRecordsTableOrderingComposer,
      $$LocalContentRecordsTableAnnotationComposer,
      $$LocalContentRecordsTableCreateCompanionBuilder,
      $$LocalContentRecordsTableUpdateCompanionBuilder,
      (
        LocalContentRecord,
        BaseReferences<
          _$CareerSpeakDatabase,
          $LocalContentRecordsTable,
          LocalContentRecord
        >,
      ),
      LocalContentRecord,
      PrefetchHooks Function()
    >;
typedef $$FavoritesTableCreateCompanionBuilder =
    FavoritesCompanion Function({
      required String contentCode,
      required String contentType,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$FavoritesTableUpdateCompanionBuilder =
    FavoritesCompanion Function({
      Value<String> contentCode,
      Value<String> contentType,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$FavoritesTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contentCode => $composableBuilder(
    column: $table.contentCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contentCode => $composableBuilder(
    column: $table.contentCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contentCode => $composableBuilder(
    column: $table.contentCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (
            Favorite,
            BaseReferences<_$CareerSpeakDatabase, $FavoritesTable, Favorite>,
          ),
          Favorite,
          PrefetchHooks Function()
        > {
  $$FavoritesTableTableManager(_$CareerSpeakDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> contentCode = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion(
                contentCode: contentCode,
                contentType: contentType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contentCode,
                required String contentType,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion.insert(
                contentCode: contentCode,
                contentType: contentType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoritesTable, Favorite>(table),
                  BaseReferences<
                    _$CareerSpeakDatabase,
                    $FavoritesTable,
                    Favorite
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (
        Favorite,
        BaseReferences<_$CareerSpeakDatabase, $FavoritesTable, Favorite>,
      ),
      Favorite,
      PrefetchHooks Function()
    >;
typedef $$ContentLearningStatesTableCreateCompanionBuilder =
    ContentLearningStatesCompanion Function({
      required String contentCode,
      required String contentType,
      Value<DateTime?> listenedAt,
      Value<int> listenCount,
      Value<DateTime?> lastPlayedAt,
      Value<int?> lastPositionMs,
      Value<DateTime?> completedAt,
      Value<String?> completionSource,
      Value<int?> lastRevisionSeen,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ContentLearningStatesTableUpdateCompanionBuilder =
    ContentLearningStatesCompanion Function({
      Value<String> contentCode,
      Value<String> contentType,
      Value<DateTime?> listenedAt,
      Value<int> listenCount,
      Value<DateTime?> lastPlayedAt,
      Value<int?> lastPositionMs,
      Value<DateTime?> completedAt,
      Value<String?> completionSource,
      Value<int?> lastRevisionSeen,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ContentLearningStatesTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $ContentLearningStatesTable> {
  $$ContentLearningStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contentCode => $composableBuilder(
    column: $table.contentCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get listenedAt => $composableBuilder(
    column: $table.listenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get listenCount => $composableBuilder(
    column: $table.listenCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completionSource => $composableBuilder(
    column: $table.completionSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastRevisionSeen => $composableBuilder(
    column: $table.lastRevisionSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContentLearningStatesTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $ContentLearningStatesTable> {
  $$ContentLearningStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contentCode => $composableBuilder(
    column: $table.contentCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get listenedAt => $composableBuilder(
    column: $table.listenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get listenCount => $composableBuilder(
    column: $table.listenCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completionSource => $composableBuilder(
    column: $table.completionSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastRevisionSeen => $composableBuilder(
    column: $table.lastRevisionSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentLearningStatesTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $ContentLearningStatesTable> {
  $$ContentLearningStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contentCode => $composableBuilder(
    column: $table.contentCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get listenedAt => $composableBuilder(
    column: $table.listenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get listenCount => $composableBuilder(
    column: $table.listenCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get completionSource => $composableBuilder(
    column: $table.completionSource,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastRevisionSeen => $composableBuilder(
    column: $table.lastRevisionSeen,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ContentLearningStatesTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $ContentLearningStatesTable,
          ContentLearningState,
          $$ContentLearningStatesTableFilterComposer,
          $$ContentLearningStatesTableOrderingComposer,
          $$ContentLearningStatesTableAnnotationComposer,
          $$ContentLearningStatesTableCreateCompanionBuilder,
          $$ContentLearningStatesTableUpdateCompanionBuilder,
          (
            ContentLearningState,
            BaseReferences<
              _$CareerSpeakDatabase,
              $ContentLearningStatesTable,
              ContentLearningState
            >,
          ),
          ContentLearningState,
          PrefetchHooks Function()
        > {
  $$ContentLearningStatesTableTableManager(
    _$CareerSpeakDatabase db,
    $ContentLearningStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentLearningStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ContentLearningStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ContentLearningStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> contentCode = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<DateTime?> listenedAt = const Value.absent(),
                Value<int> listenCount = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int?> lastPositionMs = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> completionSource = const Value.absent(),
                Value<int?> lastRevisionSeen = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentLearningStatesCompanion(
                contentCode: contentCode,
                contentType: contentType,
                listenedAt: listenedAt,
                listenCount: listenCount,
                lastPlayedAt: lastPlayedAt,
                lastPositionMs: lastPositionMs,
                completedAt: completedAt,
                completionSource: completionSource,
                lastRevisionSeen: lastRevisionSeen,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contentCode,
                required String contentType,
                Value<DateTime?> listenedAt = const Value.absent(),
                Value<int> listenCount = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int?> lastPositionMs = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> completionSource = const Value.absent(),
                Value<int?> lastRevisionSeen = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ContentLearningStatesCompanion.insert(
                contentCode: contentCode,
                contentType: contentType,
                listenedAt: listenedAt,
                listenCount: listenCount,
                lastPlayedAt: lastPlayedAt,
                lastPositionMs: lastPositionMs,
                completedAt: completedAt,
                completionSource: completionSource,
                lastRevisionSeen: lastRevisionSeen,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ContentLearningStatesTable,
                    ContentLearningState
                  >(table),
                  BaseReferences<
                    _$CareerSpeakDatabase,
                    $ContentLearningStatesTable,
                    ContentLearningState
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentLearningStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $ContentLearningStatesTable,
      ContentLearningState,
      $$ContentLearningStatesTableFilterComposer,
      $$ContentLearningStatesTableOrderingComposer,
      $$ContentLearningStatesTableAnnotationComposer,
      $$ContentLearningStatesTableCreateCompanionBuilder,
      $$ContentLearningStatesTableUpdateCompanionBuilder,
      (
        ContentLearningState,
        BaseReferences<
          _$CareerSpeakDatabase,
          $ContentLearningStatesTable,
          ContentLearningState
        >,
      ),
      ContentLearningState,
      PrefetchHooks Function()
    >;

class $CareerSpeakDatabaseManager {
  final _$CareerSpeakDatabase _db;
  $CareerSpeakDatabaseManager(this._db);
  $$AppPreferencesTableTableManager get appPreferences =>
      $$AppPreferencesTableTableManager(_db, _db.appPreferences);
  $$InstallationRuntimeStatesTableTableManager get installationRuntimeStates =>
      $$InstallationRuntimeStatesTableTableManager(
        _db,
        _db.installationRuntimeStates,
      );
  $$ContentManifestStatesTableTableManager get contentManifestStates =>
      $$ContentManifestStatesTableTableManager(_db, _db.contentManifestStates);
  $$ContentPackRevisionsTableTableManager get contentPackRevisions =>
      $$ContentPackRevisionsTableTableManager(_db, _db.contentPackRevisions);
  $$LocalContentRecordsTableTableManager get localContentRecords =>
      $$LocalContentRecordsTableTableManager(_db, _db.localContentRecords);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$ContentLearningStatesTableTableManager get contentLearningStates =>
      $$ContentLearningStatesTableTableManager(_db, _db.contentLearningStates);
}
