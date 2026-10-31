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

class $SyncRunsTable extends SyncRuns with TableInfo<$SyncRunsTable, SyncRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggerMeta = const VerificationMeta(
    'trigger',
  );
  @override
  late final GeneratedColumn<String> trigger = GeneratedColumn<String>(
    'trigger',
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
  static const VerificationMeta _fromContentVersionMeta =
      const VerificationMeta('fromContentVersion');
  @override
  late final GeneratedColumn<int> fromContentVersion = GeneratedColumn<int>(
    'from_content_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetContentVersionMeta =
      const VerificationMeta('targetContentVersion');
  @override
  late final GeneratedColumn<int> targetContentVersion = GeneratedColumn<int>(
    'target_content_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetSchemaVersionMeta =
      const VerificationMeta('targetSchemaVersion');
  @override
  late final GeneratedColumn<int> targetSchemaVersion = GeneratedColumn<int>(
    'target_schema_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _resyncRequestedMeta = const VerificationMeta(
    'resyncRequested',
  );
  @override
  late final GeneratedColumn<bool> resyncRequested = GeneratedColumn<bool>(
    'resync_requested',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("resync_requested" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _retryableMeta = const VerificationMeta(
    'retryable',
  );
  @override
  late final GeneratedColumn<bool> retryable = GeneratedColumn<bool>(
    'retryable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("retryable" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
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
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    runId,
    trigger,
    translationLocale,
    fromContentVersion,
    targetContentVersion,
    targetSchemaVersion,
    state,
    resyncRequested,
    attemptCount,
    retryable,
    errorCode,
    errorMessage,
    startedAt,
    updatedAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncRun> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('trigger')) {
      context.handle(
        _triggerMeta,
        trigger.isAcceptableOrUnknown(data['trigger']!, _triggerMeta),
      );
    } else if (isInserting) {
      context.missing(_triggerMeta);
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
    if (data.containsKey('from_content_version')) {
      context.handle(
        _fromContentVersionMeta,
        fromContentVersion.isAcceptableOrUnknown(
          data['from_content_version']!,
          _fromContentVersionMeta,
        ),
      );
    }
    if (data.containsKey('target_content_version')) {
      context.handle(
        _targetContentVersionMeta,
        targetContentVersion.isAcceptableOrUnknown(
          data['target_content_version']!,
          _targetContentVersionMeta,
        ),
      );
    }
    if (data.containsKey('target_schema_version')) {
      context.handle(
        _targetSchemaVersionMeta,
        targetSchemaVersion.isAcceptableOrUnknown(
          data['target_schema_version']!,
          _targetSchemaVersionMeta,
        ),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('resync_requested')) {
      context.handle(
        _resyncRequestedMeta,
        resyncRequested.isAcceptableOrUnknown(
          data['resync_requested']!,
          _resyncRequestedMeta,
        ),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('retryable')) {
      context.handle(
        _retryableMeta,
        retryable.isAcceptableOrUnknown(data['retryable']!, _retryableMeta),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
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
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {runId};
  @override
  SyncRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncRun(
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      trigger: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trigger'],
      )!,
      translationLocale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation_locale'],
      )!,
      fromContentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_content_version'],
      ),
      targetContentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_content_version'],
      ),
      targetSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_schema_version'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      resyncRequested: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}resync_requested'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      retryable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}retryable'],
      )!,
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $SyncRunsTable createAlias(String alias) {
    return $SyncRunsTable(attachedDatabase, alias);
  }
}

class SyncRun extends DataClass implements Insertable<SyncRun> {
  final String runId;
  final String trigger;
  final String translationLocale;
  final int? fromContentVersion;
  final int? targetContentVersion;
  final int? targetSchemaVersion;
  final String state;
  final bool resyncRequested;
  final int attemptCount;
  final bool retryable;
  final String? errorCode;
  final String? errorMessage;
  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? finishedAt;
  const SyncRun({
    required this.runId,
    required this.trigger,
    required this.translationLocale,
    this.fromContentVersion,
    this.targetContentVersion,
    this.targetSchemaVersion,
    required this.state,
    required this.resyncRequested,
    required this.attemptCount,
    required this.retryable,
    this.errorCode,
    this.errorMessage,
    required this.startedAt,
    required this.updatedAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['run_id'] = Variable<String>(runId);
    map['trigger'] = Variable<String>(trigger);
    map['translation_locale'] = Variable<String>(translationLocale);
    if (!nullToAbsent || fromContentVersion != null) {
      map['from_content_version'] = Variable<int>(fromContentVersion);
    }
    if (!nullToAbsent || targetContentVersion != null) {
      map['target_content_version'] = Variable<int>(targetContentVersion);
    }
    if (!nullToAbsent || targetSchemaVersion != null) {
      map['target_schema_version'] = Variable<int>(targetSchemaVersion);
    }
    map['state'] = Variable<String>(state);
    map['resync_requested'] = Variable<bool>(resyncRequested);
    map['attempt_count'] = Variable<int>(attemptCount);
    map['retryable'] = Variable<bool>(retryable);
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  SyncRunsCompanion toCompanion(bool nullToAbsent) {
    return SyncRunsCompanion(
      runId: Value(runId),
      trigger: Value(trigger),
      translationLocale: Value(translationLocale),
      fromContentVersion: fromContentVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(fromContentVersion),
      targetContentVersion: targetContentVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(targetContentVersion),
      targetSchemaVersion: targetSchemaVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(targetSchemaVersion),
      state: Value(state),
      resyncRequested: Value(resyncRequested),
      attemptCount: Value(attemptCount),
      retryable: Value(retryable),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      startedAt: Value(startedAt),
      updatedAt: Value(updatedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory SyncRun.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncRun(
      runId: serializer.fromJson<String>(json['runId']),
      trigger: serializer.fromJson<String>(json['trigger']),
      translationLocale: serializer.fromJson<String>(json['translationLocale']),
      fromContentVersion: serializer.fromJson<int?>(json['fromContentVersion']),
      targetContentVersion: serializer.fromJson<int?>(
        json['targetContentVersion'],
      ),
      targetSchemaVersion: serializer.fromJson<int?>(
        json['targetSchemaVersion'],
      ),
      state: serializer.fromJson<String>(json['state']),
      resyncRequested: serializer.fromJson<bool>(json['resyncRequested']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      retryable: serializer.fromJson<bool>(json['retryable']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'runId': serializer.toJson<String>(runId),
      'trigger': serializer.toJson<String>(trigger),
      'translationLocale': serializer.toJson<String>(translationLocale),
      'fromContentVersion': serializer.toJson<int?>(fromContentVersion),
      'targetContentVersion': serializer.toJson<int?>(targetContentVersion),
      'targetSchemaVersion': serializer.toJson<int?>(targetSchemaVersion),
      'state': serializer.toJson<String>(state),
      'resyncRequested': serializer.toJson<bool>(resyncRequested),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'retryable': serializer.toJson<bool>(retryable),
      'errorCode': serializer.toJson<String?>(errorCode),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  SyncRun copyWith({
    String? runId,
    String? trigger,
    String? translationLocale,
    Value<int?> fromContentVersion = const Value.absent(),
    Value<int?> targetContentVersion = const Value.absent(),
    Value<int?> targetSchemaVersion = const Value.absent(),
    String? state,
    bool? resyncRequested,
    int? attemptCount,
    bool? retryable,
    Value<String?> errorCode = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
    DateTime? startedAt,
    DateTime? updatedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
  }) => SyncRun(
    runId: runId ?? this.runId,
    trigger: trigger ?? this.trigger,
    translationLocale: translationLocale ?? this.translationLocale,
    fromContentVersion: fromContentVersion.present
        ? fromContentVersion.value
        : this.fromContentVersion,
    targetContentVersion: targetContentVersion.present
        ? targetContentVersion.value
        : this.targetContentVersion,
    targetSchemaVersion: targetSchemaVersion.present
        ? targetSchemaVersion.value
        : this.targetSchemaVersion,
    state: state ?? this.state,
    resyncRequested: resyncRequested ?? this.resyncRequested,
    attemptCount: attemptCount ?? this.attemptCount,
    retryable: retryable ?? this.retryable,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    startedAt: startedAt ?? this.startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  SyncRun copyWithCompanion(SyncRunsCompanion data) {
    return SyncRun(
      runId: data.runId.present ? data.runId.value : this.runId,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      translationLocale: data.translationLocale.present
          ? data.translationLocale.value
          : this.translationLocale,
      fromContentVersion: data.fromContentVersion.present
          ? data.fromContentVersion.value
          : this.fromContentVersion,
      targetContentVersion: data.targetContentVersion.present
          ? data.targetContentVersion.value
          : this.targetContentVersion,
      targetSchemaVersion: data.targetSchemaVersion.present
          ? data.targetSchemaVersion.value
          : this.targetSchemaVersion,
      state: data.state.present ? data.state.value : this.state,
      resyncRequested: data.resyncRequested.present
          ? data.resyncRequested.value
          : this.resyncRequested,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      retryable: data.retryable.present ? data.retryable.value : this.retryable,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncRun(')
          ..write('runId: $runId, ')
          ..write('trigger: $trigger, ')
          ..write('translationLocale: $translationLocale, ')
          ..write('fromContentVersion: $fromContentVersion, ')
          ..write('targetContentVersion: $targetContentVersion, ')
          ..write('targetSchemaVersion: $targetSchemaVersion, ')
          ..write('state: $state, ')
          ..write('resyncRequested: $resyncRequested, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('retryable: $retryable, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    runId,
    trigger,
    translationLocale,
    fromContentVersion,
    targetContentVersion,
    targetSchemaVersion,
    state,
    resyncRequested,
    attemptCount,
    retryable,
    errorCode,
    errorMessage,
    startedAt,
    updatedAt,
    finishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncRun &&
          other.runId == this.runId &&
          other.trigger == this.trigger &&
          other.translationLocale == this.translationLocale &&
          other.fromContentVersion == this.fromContentVersion &&
          other.targetContentVersion == this.targetContentVersion &&
          other.targetSchemaVersion == this.targetSchemaVersion &&
          other.state == this.state &&
          other.resyncRequested == this.resyncRequested &&
          other.attemptCount == this.attemptCount &&
          other.retryable == this.retryable &&
          other.errorCode == this.errorCode &&
          other.errorMessage == this.errorMessage &&
          other.startedAt == this.startedAt &&
          other.updatedAt == this.updatedAt &&
          other.finishedAt == this.finishedAt);
}

class SyncRunsCompanion extends UpdateCompanion<SyncRun> {
  final Value<String> runId;
  final Value<String> trigger;
  final Value<String> translationLocale;
  final Value<int?> fromContentVersion;
  final Value<int?> targetContentVersion;
  final Value<int?> targetSchemaVersion;
  final Value<String> state;
  final Value<bool> resyncRequested;
  final Value<int> attemptCount;
  final Value<bool> retryable;
  final Value<String?> errorCode;
  final Value<String?> errorMessage;
  final Value<DateTime> startedAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> rowid;
  const SyncRunsCompanion({
    this.runId = const Value.absent(),
    this.trigger = const Value.absent(),
    this.translationLocale = const Value.absent(),
    this.fromContentVersion = const Value.absent(),
    this.targetContentVersion = const Value.absent(),
    this.targetSchemaVersion = const Value.absent(),
    this.state = const Value.absent(),
    this.resyncRequested = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.retryable = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncRunsCompanion.insert({
    required String runId,
    required String trigger,
    required String translationLocale,
    this.fromContentVersion = const Value.absent(),
    this.targetContentVersion = const Value.absent(),
    this.targetSchemaVersion = const Value.absent(),
    required String state,
    this.resyncRequested = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.retryable = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required DateTime startedAt,
    required DateTime updatedAt,
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : runId = Value(runId),
       trigger = Value(trigger),
       translationLocale = Value(translationLocale),
       state = Value(state),
       startedAt = Value(startedAt),
       updatedAt = Value(updatedAt);
  static Insertable<SyncRun> custom({
    Expression<String>? runId,
    Expression<String>? trigger,
    Expression<String>? translationLocale,
    Expression<int>? fromContentVersion,
    Expression<int>? targetContentVersion,
    Expression<int>? targetSchemaVersion,
    Expression<String>? state,
    Expression<bool>? resyncRequested,
    Expression<int>? attemptCount,
    Expression<bool>? retryable,
    Expression<String>? errorCode,
    Expression<String>? errorMessage,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (runId != null) 'run_id': runId,
      if (trigger != null) 'trigger': trigger,
      if (translationLocale != null) 'translation_locale': translationLocale,
      if (fromContentVersion != null)
        'from_content_version': fromContentVersion,
      if (targetContentVersion != null)
        'target_content_version': targetContentVersion,
      if (targetSchemaVersion != null)
        'target_schema_version': targetSchemaVersion,
      if (state != null) 'state': state,
      if (resyncRequested != null) 'resync_requested': resyncRequested,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (retryable != null) 'retryable': retryable,
      if (errorCode != null) 'error_code': errorCode,
      if (errorMessage != null) 'error_message': errorMessage,
      if (startedAt != null) 'started_at': startedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncRunsCompanion copyWith({
    Value<String>? runId,
    Value<String>? trigger,
    Value<String>? translationLocale,
    Value<int?>? fromContentVersion,
    Value<int?>? targetContentVersion,
    Value<int?>? targetSchemaVersion,
    Value<String>? state,
    Value<bool>? resyncRequested,
    Value<int>? attemptCount,
    Value<bool>? retryable,
    Value<String?>? errorCode,
    Value<String?>? errorMessage,
    Value<DateTime>? startedAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? finishedAt,
    Value<int>? rowid,
  }) {
    return SyncRunsCompanion(
      runId: runId ?? this.runId,
      trigger: trigger ?? this.trigger,
      translationLocale: translationLocale ?? this.translationLocale,
      fromContentVersion: fromContentVersion ?? this.fromContentVersion,
      targetContentVersion: targetContentVersion ?? this.targetContentVersion,
      targetSchemaVersion: targetSchemaVersion ?? this.targetSchemaVersion,
      state: state ?? this.state,
      resyncRequested: resyncRequested ?? this.resyncRequested,
      attemptCount: attemptCount ?? this.attemptCount,
      retryable: retryable ?? this.retryable,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (trigger.present) {
      map['trigger'] = Variable<String>(trigger.value);
    }
    if (translationLocale.present) {
      map['translation_locale'] = Variable<String>(translationLocale.value);
    }
    if (fromContentVersion.present) {
      map['from_content_version'] = Variable<int>(fromContentVersion.value);
    }
    if (targetContentVersion.present) {
      map['target_content_version'] = Variable<int>(targetContentVersion.value);
    }
    if (targetSchemaVersion.present) {
      map['target_schema_version'] = Variable<int>(targetSchemaVersion.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (resyncRequested.present) {
      map['resync_requested'] = Variable<bool>(resyncRequested.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (retryable.present) {
      map['retryable'] = Variable<bool>(retryable.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncRunsCompanion(')
          ..write('runId: $runId, ')
          ..write('trigger: $trigger, ')
          ..write('translationLocale: $translationLocale, ')
          ..write('fromContentVersion: $fromContentVersion, ')
          ..write('targetContentVersion: $targetContentVersion, ')
          ..write('targetSchemaVersion: $targetSchemaVersion, ')
          ..write('state: $state, ')
          ..write('resyncRequested: $resyncRequested, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('retryable: $retryable, ')
          ..write('errorCode: $errorCode, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncPackUpdatesTable extends SyncPackUpdates
    with TableInfo<$SyncPackUpdatesTable, SyncPackUpdate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncPackUpdatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sync_runs (run_id) ON DELETE CASCADE',
    ),
  );
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
  static const VerificationMeta _targetRevisionMeta = const VerificationMeta(
    'targetRevision',
  );
  @override
  late final GeneratedColumn<int> targetRevision = GeneratedColumn<int>(
    'target_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetChecksumMeta = const VerificationMeta(
    'targetChecksum',
  );
  @override
  late final GeneratedColumn<String> targetChecksum = GeneratedColumn<String>(
    'target_checksum',
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
  static const VerificationMeta _requiredAssetCountMeta =
      const VerificationMeta('requiredAssetCount');
  @override
  late final GeneratedColumn<int> requiredAssetCount = GeneratedColumn<int>(
    'required_asset_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _verifiedAssetCountMeta =
      const VerificationMeta('verifiedAssetCount');
  @override
  late final GeneratedColumn<int> verifiedAssetCount = GeneratedColumn<int>(
    'verified_asset_count',
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
    runId,
    packCode,
    variantKey,
    targetRevision,
    targetChecksum,
    state,
    requiredAssetCount,
    verifiedAssetCount,
    errorCode,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_pack_updates';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncPackUpdate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
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
    if (data.containsKey('target_revision')) {
      context.handle(
        _targetRevisionMeta,
        targetRevision.isAcceptableOrUnknown(
          data['target_revision']!,
          _targetRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetRevisionMeta);
    }
    if (data.containsKey('target_checksum')) {
      context.handle(
        _targetChecksumMeta,
        targetChecksum.isAcceptableOrUnknown(
          data['target_checksum']!,
          _targetChecksumMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetChecksumMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('required_asset_count')) {
      context.handle(
        _requiredAssetCountMeta,
        requiredAssetCount.isAcceptableOrUnknown(
          data['required_asset_count']!,
          _requiredAssetCountMeta,
        ),
      );
    }
    if (data.containsKey('verified_asset_count')) {
      context.handle(
        _verifiedAssetCountMeta,
        verifiedAssetCount.isAcceptableOrUnknown(
          data['verified_asset_count']!,
          _verifiedAssetCountMeta,
        ),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
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
  Set<GeneratedColumn> get $primaryKey => {runId, packCode, variantKey};
  @override
  SyncPackUpdate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncPackUpdate(
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      packCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack_code'],
      )!,
      variantKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_key'],
      )!,
      targetRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_revision'],
      )!,
      targetChecksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_checksum'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      requiredAssetCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}required_asset_count'],
      )!,
      verifiedAssetCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verified_asset_count'],
      )!,
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncPackUpdatesTable createAlias(String alias) {
    return $SyncPackUpdatesTable(attachedDatabase, alias);
  }
}

class SyncPackUpdate extends DataClass implements Insertable<SyncPackUpdate> {
  final String runId;
  final String packCode;
  final String variantKey;
  final int targetRevision;
  final String targetChecksum;
  final String state;
  final int requiredAssetCount;
  final int verifiedAssetCount;
  final String? errorCode;
  final DateTime updatedAt;
  const SyncPackUpdate({
    required this.runId,
    required this.packCode,
    required this.variantKey,
    required this.targetRevision,
    required this.targetChecksum,
    required this.state,
    required this.requiredAssetCount,
    required this.verifiedAssetCount,
    this.errorCode,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['run_id'] = Variable<String>(runId);
    map['pack_code'] = Variable<String>(packCode);
    map['variant_key'] = Variable<String>(variantKey);
    map['target_revision'] = Variable<int>(targetRevision);
    map['target_checksum'] = Variable<String>(targetChecksum);
    map['state'] = Variable<String>(state);
    map['required_asset_count'] = Variable<int>(requiredAssetCount);
    map['verified_asset_count'] = Variable<int>(verifiedAssetCount);
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncPackUpdatesCompanion toCompanion(bool nullToAbsent) {
    return SyncPackUpdatesCompanion(
      runId: Value(runId),
      packCode: Value(packCode),
      variantKey: Value(variantKey),
      targetRevision: Value(targetRevision),
      targetChecksum: Value(targetChecksum),
      state: Value(state),
      requiredAssetCount: Value(requiredAssetCount),
      verifiedAssetCount: Value(verifiedAssetCount),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncPackUpdate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncPackUpdate(
      runId: serializer.fromJson<String>(json['runId']),
      packCode: serializer.fromJson<String>(json['packCode']),
      variantKey: serializer.fromJson<String>(json['variantKey']),
      targetRevision: serializer.fromJson<int>(json['targetRevision']),
      targetChecksum: serializer.fromJson<String>(json['targetChecksum']),
      state: serializer.fromJson<String>(json['state']),
      requiredAssetCount: serializer.fromJson<int>(json['requiredAssetCount']),
      verifiedAssetCount: serializer.fromJson<int>(json['verifiedAssetCount']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'runId': serializer.toJson<String>(runId),
      'packCode': serializer.toJson<String>(packCode),
      'variantKey': serializer.toJson<String>(variantKey),
      'targetRevision': serializer.toJson<int>(targetRevision),
      'targetChecksum': serializer.toJson<String>(targetChecksum),
      'state': serializer.toJson<String>(state),
      'requiredAssetCount': serializer.toJson<int>(requiredAssetCount),
      'verifiedAssetCount': serializer.toJson<int>(verifiedAssetCount),
      'errorCode': serializer.toJson<String?>(errorCode),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncPackUpdate copyWith({
    String? runId,
    String? packCode,
    String? variantKey,
    int? targetRevision,
    String? targetChecksum,
    String? state,
    int? requiredAssetCount,
    int? verifiedAssetCount,
    Value<String?> errorCode = const Value.absent(),
    DateTime? updatedAt,
  }) => SyncPackUpdate(
    runId: runId ?? this.runId,
    packCode: packCode ?? this.packCode,
    variantKey: variantKey ?? this.variantKey,
    targetRevision: targetRevision ?? this.targetRevision,
    targetChecksum: targetChecksum ?? this.targetChecksum,
    state: state ?? this.state,
    requiredAssetCount: requiredAssetCount ?? this.requiredAssetCount,
    verifiedAssetCount: verifiedAssetCount ?? this.verifiedAssetCount,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncPackUpdate copyWithCompanion(SyncPackUpdatesCompanion data) {
    return SyncPackUpdate(
      runId: data.runId.present ? data.runId.value : this.runId,
      packCode: data.packCode.present ? data.packCode.value : this.packCode,
      variantKey: data.variantKey.present
          ? data.variantKey.value
          : this.variantKey,
      targetRevision: data.targetRevision.present
          ? data.targetRevision.value
          : this.targetRevision,
      targetChecksum: data.targetChecksum.present
          ? data.targetChecksum.value
          : this.targetChecksum,
      state: data.state.present ? data.state.value : this.state,
      requiredAssetCount: data.requiredAssetCount.present
          ? data.requiredAssetCount.value
          : this.requiredAssetCount,
      verifiedAssetCount: data.verifiedAssetCount.present
          ? data.verifiedAssetCount.value
          : this.verifiedAssetCount,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncPackUpdate(')
          ..write('runId: $runId, ')
          ..write('packCode: $packCode, ')
          ..write('variantKey: $variantKey, ')
          ..write('targetRevision: $targetRevision, ')
          ..write('targetChecksum: $targetChecksum, ')
          ..write('state: $state, ')
          ..write('requiredAssetCount: $requiredAssetCount, ')
          ..write('verifiedAssetCount: $verifiedAssetCount, ')
          ..write('errorCode: $errorCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    runId,
    packCode,
    variantKey,
    targetRevision,
    targetChecksum,
    state,
    requiredAssetCount,
    verifiedAssetCount,
    errorCode,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncPackUpdate &&
          other.runId == this.runId &&
          other.packCode == this.packCode &&
          other.variantKey == this.variantKey &&
          other.targetRevision == this.targetRevision &&
          other.targetChecksum == this.targetChecksum &&
          other.state == this.state &&
          other.requiredAssetCount == this.requiredAssetCount &&
          other.verifiedAssetCount == this.verifiedAssetCount &&
          other.errorCode == this.errorCode &&
          other.updatedAt == this.updatedAt);
}

class SyncPackUpdatesCompanion extends UpdateCompanion<SyncPackUpdate> {
  final Value<String> runId;
  final Value<String> packCode;
  final Value<String> variantKey;
  final Value<int> targetRevision;
  final Value<String> targetChecksum;
  final Value<String> state;
  final Value<int> requiredAssetCount;
  final Value<int> verifiedAssetCount;
  final Value<String?> errorCode;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncPackUpdatesCompanion({
    this.runId = const Value.absent(),
    this.packCode = const Value.absent(),
    this.variantKey = const Value.absent(),
    this.targetRevision = const Value.absent(),
    this.targetChecksum = const Value.absent(),
    this.state = const Value.absent(),
    this.requiredAssetCount = const Value.absent(),
    this.verifiedAssetCount = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncPackUpdatesCompanion.insert({
    required String runId,
    required String packCode,
    required String variantKey,
    required int targetRevision,
    required String targetChecksum,
    required String state,
    this.requiredAssetCount = const Value.absent(),
    this.verifiedAssetCount = const Value.absent(),
    this.errorCode = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : runId = Value(runId),
       packCode = Value(packCode),
       variantKey = Value(variantKey),
       targetRevision = Value(targetRevision),
       targetChecksum = Value(targetChecksum),
       state = Value(state),
       updatedAt = Value(updatedAt);
  static Insertable<SyncPackUpdate> custom({
    Expression<String>? runId,
    Expression<String>? packCode,
    Expression<String>? variantKey,
    Expression<int>? targetRevision,
    Expression<String>? targetChecksum,
    Expression<String>? state,
    Expression<int>? requiredAssetCount,
    Expression<int>? verifiedAssetCount,
    Expression<String>? errorCode,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (runId != null) 'run_id': runId,
      if (packCode != null) 'pack_code': packCode,
      if (variantKey != null) 'variant_key': variantKey,
      if (targetRevision != null) 'target_revision': targetRevision,
      if (targetChecksum != null) 'target_checksum': targetChecksum,
      if (state != null) 'state': state,
      if (requiredAssetCount != null)
        'required_asset_count': requiredAssetCount,
      if (verifiedAssetCount != null)
        'verified_asset_count': verifiedAssetCount,
      if (errorCode != null) 'error_code': errorCode,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncPackUpdatesCompanion copyWith({
    Value<String>? runId,
    Value<String>? packCode,
    Value<String>? variantKey,
    Value<int>? targetRevision,
    Value<String>? targetChecksum,
    Value<String>? state,
    Value<int>? requiredAssetCount,
    Value<int>? verifiedAssetCount,
    Value<String?>? errorCode,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncPackUpdatesCompanion(
      runId: runId ?? this.runId,
      packCode: packCode ?? this.packCode,
      variantKey: variantKey ?? this.variantKey,
      targetRevision: targetRevision ?? this.targetRevision,
      targetChecksum: targetChecksum ?? this.targetChecksum,
      state: state ?? this.state,
      requiredAssetCount: requiredAssetCount ?? this.requiredAssetCount,
      verifiedAssetCount: verifiedAssetCount ?? this.verifiedAssetCount,
      errorCode: errorCode ?? this.errorCode,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (packCode.present) {
      map['pack_code'] = Variable<String>(packCode.value);
    }
    if (variantKey.present) {
      map['variant_key'] = Variable<String>(variantKey.value);
    }
    if (targetRevision.present) {
      map['target_revision'] = Variable<int>(targetRevision.value);
    }
    if (targetChecksum.present) {
      map['target_checksum'] = Variable<String>(targetChecksum.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (requiredAssetCount.present) {
      map['required_asset_count'] = Variable<int>(requiredAssetCount.value);
    }
    if (verifiedAssetCount.present) {
      map['verified_asset_count'] = Variable<int>(verifiedAssetCount.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
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
    return (StringBuffer('SyncPackUpdatesCompanion(')
          ..write('runId: $runId, ')
          ..write('packCode: $packCode, ')
          ..write('variantKey: $variantKey, ')
          ..write('targetRevision: $targetRevision, ')
          ..write('targetChecksum: $targetChecksum, ')
          ..write('state: $state, ')
          ..write('requiredAssetCount: $requiredAssetCount, ')
          ..write('verifiedAssetCount: $verifiedAssetCount, ')
          ..write('errorCode: $errorCode, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncTombstonesTable extends SyncTombstones
    with TableInfo<$SyncTombstonesTable, SyncTombstone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncTombstonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sync_runs (run_id) ON DELETE CASCADE',
    ),
  );
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
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
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
  static const VerificationMeta _appliedAtMeta = const VerificationMeta(
    'appliedAt',
  );
  @override
  late final GeneratedColumn<DateTime> appliedAt = GeneratedColumn<DateTime>(
    'applied_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    runId,
    contentCode,
    contentType,
    revision,
    reason,
    state,
    appliedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_tombstones';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncTombstone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
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
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('applied_at')) {
      context.handle(
        _appliedAtMeta,
        appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {runId, contentCode, contentType};
  @override
  SyncTombstone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncTombstone(
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
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
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      appliedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}applied_at'],
      ),
    );
  }

  @override
  $SyncTombstonesTable createAlias(String alias) {
    return $SyncTombstonesTable(attachedDatabase, alias);
  }
}

class SyncTombstone extends DataClass implements Insertable<SyncTombstone> {
  final String runId;
  final String contentCode;
  final String contentType;
  final int? revision;
  final String reason;
  final String state;
  final DateTime? appliedAt;
  const SyncTombstone({
    required this.runId,
    required this.contentCode,
    required this.contentType,
    this.revision,
    required this.reason,
    required this.state,
    this.appliedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['run_id'] = Variable<String>(runId);
    map['content_code'] = Variable<String>(contentCode);
    map['content_type'] = Variable<String>(contentType);
    if (!nullToAbsent || revision != null) {
      map['revision'] = Variable<int>(revision);
    }
    map['reason'] = Variable<String>(reason);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || appliedAt != null) {
      map['applied_at'] = Variable<DateTime>(appliedAt);
    }
    return map;
  }

  SyncTombstonesCompanion toCompanion(bool nullToAbsent) {
    return SyncTombstonesCompanion(
      runId: Value(runId),
      contentCode: Value(contentCode),
      contentType: Value(contentType),
      revision: revision == null && nullToAbsent
          ? const Value.absent()
          : Value(revision),
      reason: Value(reason),
      state: Value(state),
      appliedAt: appliedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(appliedAt),
    );
  }

  factory SyncTombstone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncTombstone(
      runId: serializer.fromJson<String>(json['runId']),
      contentCode: serializer.fromJson<String>(json['contentCode']),
      contentType: serializer.fromJson<String>(json['contentType']),
      revision: serializer.fromJson<int?>(json['revision']),
      reason: serializer.fromJson<String>(json['reason']),
      state: serializer.fromJson<String>(json['state']),
      appliedAt: serializer.fromJson<DateTime?>(json['appliedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'runId': serializer.toJson<String>(runId),
      'contentCode': serializer.toJson<String>(contentCode),
      'contentType': serializer.toJson<String>(contentType),
      'revision': serializer.toJson<int?>(revision),
      'reason': serializer.toJson<String>(reason),
      'state': serializer.toJson<String>(state),
      'appliedAt': serializer.toJson<DateTime?>(appliedAt),
    };
  }

  SyncTombstone copyWith({
    String? runId,
    String? contentCode,
    String? contentType,
    Value<int?> revision = const Value.absent(),
    String? reason,
    String? state,
    Value<DateTime?> appliedAt = const Value.absent(),
  }) => SyncTombstone(
    runId: runId ?? this.runId,
    contentCode: contentCode ?? this.contentCode,
    contentType: contentType ?? this.contentType,
    revision: revision.present ? revision.value : this.revision,
    reason: reason ?? this.reason,
    state: state ?? this.state,
    appliedAt: appliedAt.present ? appliedAt.value : this.appliedAt,
  );
  SyncTombstone copyWithCompanion(SyncTombstonesCompanion data) {
    return SyncTombstone(
      runId: data.runId.present ? data.runId.value : this.runId,
      contentCode: data.contentCode.present
          ? data.contentCode.value
          : this.contentCode,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      revision: data.revision.present ? data.revision.value : this.revision,
      reason: data.reason.present ? data.reason.value : this.reason,
      state: data.state.present ? data.state.value : this.state,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncTombstone(')
          ..write('runId: $runId, ')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('revision: $revision, ')
          ..write('reason: $reason, ')
          ..write('state: $state, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    runId,
    contentCode,
    contentType,
    revision,
    reason,
    state,
    appliedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncTombstone &&
          other.runId == this.runId &&
          other.contentCode == this.contentCode &&
          other.contentType == this.contentType &&
          other.revision == this.revision &&
          other.reason == this.reason &&
          other.state == this.state &&
          other.appliedAt == this.appliedAt);
}

class SyncTombstonesCompanion extends UpdateCompanion<SyncTombstone> {
  final Value<String> runId;
  final Value<String> contentCode;
  final Value<String> contentType;
  final Value<int?> revision;
  final Value<String> reason;
  final Value<String> state;
  final Value<DateTime?> appliedAt;
  final Value<int> rowid;
  const SyncTombstonesCompanion({
    this.runId = const Value.absent(),
    this.contentCode = const Value.absent(),
    this.contentType = const Value.absent(),
    this.revision = const Value.absent(),
    this.reason = const Value.absent(),
    this.state = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncTombstonesCompanion.insert({
    required String runId,
    required String contentCode,
    required String contentType,
    this.revision = const Value.absent(),
    required String reason,
    required String state,
    this.appliedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : runId = Value(runId),
       contentCode = Value(contentCode),
       contentType = Value(contentType),
       reason = Value(reason),
       state = Value(state);
  static Insertable<SyncTombstone> custom({
    Expression<String>? runId,
    Expression<String>? contentCode,
    Expression<String>? contentType,
    Expression<int>? revision,
    Expression<String>? reason,
    Expression<String>? state,
    Expression<DateTime>? appliedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (runId != null) 'run_id': runId,
      if (contentCode != null) 'content_code': contentCode,
      if (contentType != null) 'content_type': contentType,
      if (revision != null) 'revision': revision,
      if (reason != null) 'reason': reason,
      if (state != null) 'state': state,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncTombstonesCompanion copyWith({
    Value<String>? runId,
    Value<String>? contentCode,
    Value<String>? contentType,
    Value<int?>? revision,
    Value<String>? reason,
    Value<String>? state,
    Value<DateTime?>? appliedAt,
    Value<int>? rowid,
  }) {
    return SyncTombstonesCompanion(
      runId: runId ?? this.runId,
      contentCode: contentCode ?? this.contentCode,
      contentType: contentType ?? this.contentType,
      revision: revision ?? this.revision,
      reason: reason ?? this.reason,
      state: state ?? this.state,
      appliedAt: appliedAt ?? this.appliedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (contentCode.present) {
      map['content_code'] = Variable<String>(contentCode.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<DateTime>(appliedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncTombstonesCompanion(')
          ..write('runId: $runId, ')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('revision: $revision, ')
          ..write('reason: $reason, ')
          ..write('state: $state, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('rowid: $rowid')
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

class $PackContentRefsTable extends PackContentRefs
    with TableInfo<$PackContentRefsTable, PackContentRef> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PackContentRefsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _packRevisionMeta = const VerificationMeta(
    'packRevision',
  );
  @override
  late final GeneratedColumn<int> packRevision = GeneratedColumn<int>(
    'pack_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _contentRevisionMeta = const VerificationMeta(
    'contentRevision',
  );
  @override
  late final GeneratedColumn<int> contentRevision = GeneratedColumn<int>(
    'content_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    packCode,
    variantKey,
    packRevision,
    contentCode,
    contentType,
    contentRevision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pack_content_refs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PackContentRef> instance, {
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
    if (data.containsKey('pack_revision')) {
      context.handle(
        _packRevisionMeta,
        packRevision.isAcceptableOrUnknown(
          data['pack_revision']!,
          _packRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packRevisionMeta);
    }
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
    if (data.containsKey('content_revision')) {
      context.handle(
        _contentRevisionMeta,
        contentRevision.isAcceptableOrUnknown(
          data['content_revision']!,
          _contentRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentRevisionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    packCode,
    variantKey,
    packRevision,
    contentCode,
    contentType,
    contentRevision,
  };
  @override
  PackContentRef map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PackContentRef(
      packCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack_code'],
      )!,
      variantKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_key'],
      )!,
      packRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pack_revision'],
      )!,
      contentCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_code'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      contentRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}content_revision'],
      )!,
    );
  }

  @override
  $PackContentRefsTable createAlias(String alias) {
    return $PackContentRefsTable(attachedDatabase, alias);
  }
}

class PackContentRef extends DataClass implements Insertable<PackContentRef> {
  final String packCode;
  final String variantKey;
  final int packRevision;
  final String contentCode;
  final String contentType;
  final int contentRevision;
  const PackContentRef({
    required this.packCode,
    required this.variantKey,
    required this.packRevision,
    required this.contentCode,
    required this.contentType,
    required this.contentRevision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pack_code'] = Variable<String>(packCode);
    map['variant_key'] = Variable<String>(variantKey);
    map['pack_revision'] = Variable<int>(packRevision);
    map['content_code'] = Variable<String>(contentCode);
    map['content_type'] = Variable<String>(contentType);
    map['content_revision'] = Variable<int>(contentRevision);
    return map;
  }

  PackContentRefsCompanion toCompanion(bool nullToAbsent) {
    return PackContentRefsCompanion(
      packCode: Value(packCode),
      variantKey: Value(variantKey),
      packRevision: Value(packRevision),
      contentCode: Value(contentCode),
      contentType: Value(contentType),
      contentRevision: Value(contentRevision),
    );
  }

  factory PackContentRef.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PackContentRef(
      packCode: serializer.fromJson<String>(json['packCode']),
      variantKey: serializer.fromJson<String>(json['variantKey']),
      packRevision: serializer.fromJson<int>(json['packRevision']),
      contentCode: serializer.fromJson<String>(json['contentCode']),
      contentType: serializer.fromJson<String>(json['contentType']),
      contentRevision: serializer.fromJson<int>(json['contentRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packCode': serializer.toJson<String>(packCode),
      'variantKey': serializer.toJson<String>(variantKey),
      'packRevision': serializer.toJson<int>(packRevision),
      'contentCode': serializer.toJson<String>(contentCode),
      'contentType': serializer.toJson<String>(contentType),
      'contentRevision': serializer.toJson<int>(contentRevision),
    };
  }

  PackContentRef copyWith({
    String? packCode,
    String? variantKey,
    int? packRevision,
    String? contentCode,
    String? contentType,
    int? contentRevision,
  }) => PackContentRef(
    packCode: packCode ?? this.packCode,
    variantKey: variantKey ?? this.variantKey,
    packRevision: packRevision ?? this.packRevision,
    contentCode: contentCode ?? this.contentCode,
    contentType: contentType ?? this.contentType,
    contentRevision: contentRevision ?? this.contentRevision,
  );
  PackContentRef copyWithCompanion(PackContentRefsCompanion data) {
    return PackContentRef(
      packCode: data.packCode.present ? data.packCode.value : this.packCode,
      variantKey: data.variantKey.present
          ? data.variantKey.value
          : this.variantKey,
      packRevision: data.packRevision.present
          ? data.packRevision.value
          : this.packRevision,
      contentCode: data.contentCode.present
          ? data.contentCode.value
          : this.contentCode,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      contentRevision: data.contentRevision.present
          ? data.contentRevision.value
          : this.contentRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PackContentRef(')
          ..write('packCode: $packCode, ')
          ..write('variantKey: $variantKey, ')
          ..write('packRevision: $packRevision, ')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('contentRevision: $contentRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    packCode,
    variantKey,
    packRevision,
    contentCode,
    contentType,
    contentRevision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PackContentRef &&
          other.packCode == this.packCode &&
          other.variantKey == this.variantKey &&
          other.packRevision == this.packRevision &&
          other.contentCode == this.contentCode &&
          other.contentType == this.contentType &&
          other.contentRevision == this.contentRevision);
}

class PackContentRefsCompanion extends UpdateCompanion<PackContentRef> {
  final Value<String> packCode;
  final Value<String> variantKey;
  final Value<int> packRevision;
  final Value<String> contentCode;
  final Value<String> contentType;
  final Value<int> contentRevision;
  final Value<int> rowid;
  const PackContentRefsCompanion({
    this.packCode = const Value.absent(),
    this.variantKey = const Value.absent(),
    this.packRevision = const Value.absent(),
    this.contentCode = const Value.absent(),
    this.contentType = const Value.absent(),
    this.contentRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PackContentRefsCompanion.insert({
    required String packCode,
    required String variantKey,
    required int packRevision,
    required String contentCode,
    required String contentType,
    required int contentRevision,
    this.rowid = const Value.absent(),
  }) : packCode = Value(packCode),
       variantKey = Value(variantKey),
       packRevision = Value(packRevision),
       contentCode = Value(contentCode),
       contentType = Value(contentType),
       contentRevision = Value(contentRevision);
  static Insertable<PackContentRef> custom({
    Expression<String>? packCode,
    Expression<String>? variantKey,
    Expression<int>? packRevision,
    Expression<String>? contentCode,
    Expression<String>? contentType,
    Expression<int>? contentRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packCode != null) 'pack_code': packCode,
      if (variantKey != null) 'variant_key': variantKey,
      if (packRevision != null) 'pack_revision': packRevision,
      if (contentCode != null) 'content_code': contentCode,
      if (contentType != null) 'content_type': contentType,
      if (contentRevision != null) 'content_revision': contentRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PackContentRefsCompanion copyWith({
    Value<String>? packCode,
    Value<String>? variantKey,
    Value<int>? packRevision,
    Value<String>? contentCode,
    Value<String>? contentType,
    Value<int>? contentRevision,
    Value<int>? rowid,
  }) {
    return PackContentRefsCompanion(
      packCode: packCode ?? this.packCode,
      variantKey: variantKey ?? this.variantKey,
      packRevision: packRevision ?? this.packRevision,
      contentCode: contentCode ?? this.contentCode,
      contentType: contentType ?? this.contentType,
      contentRevision: contentRevision ?? this.contentRevision,
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
    if (packRevision.present) {
      map['pack_revision'] = Variable<int>(packRevision.value);
    }
    if (contentCode.present) {
      map['content_code'] = Variable<String>(contentCode.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (contentRevision.present) {
      map['content_revision'] = Variable<int>(contentRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PackContentRefsCompanion(')
          ..write('packCode: $packCode, ')
          ..write('variantKey: $variantKey, ')
          ..write('packRevision: $packRevision, ')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('contentRevision: $contentRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PackLocalizationRefsTable extends PackLocalizationRefs
    with TableInfo<$PackLocalizationRefsTable, PackLocalizationRef> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PackLocalizationRefsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _packRevisionMeta = const VerificationMeta(
    'packRevision',
  );
  @override
  late final GeneratedColumn<int> packRevision = GeneratedColumn<int>(
    'pack_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _contentRevisionMeta = const VerificationMeta(
    'contentRevision',
  );
  @override
  late final GeneratedColumn<int> contentRevision = GeneratedColumn<int>(
    'content_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localizationRevisionMeta =
      const VerificationMeta('localizationRevision');
  @override
  late final GeneratedColumn<int> localizationRevision = GeneratedColumn<int>(
    'localization_revision',
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
  @override
  List<GeneratedColumn> get $columns => [
    packCode,
    variantKey,
    packRevision,
    contentCode,
    contentType,
    contentRevision,
    locale,
    localizationRevision,
    checksum,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pack_localization_refs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PackLocalizationRef> instance, {
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
    if (data.containsKey('pack_revision')) {
      context.handle(
        _packRevisionMeta,
        packRevision.isAcceptableOrUnknown(
          data['pack_revision']!,
          _packRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packRevisionMeta);
    }
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
    if (data.containsKey('content_revision')) {
      context.handle(
        _contentRevisionMeta,
        contentRevision.isAcceptableOrUnknown(
          data['content_revision']!,
          _contentRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentRevisionMeta);
    }
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    } else if (isInserting) {
      context.missing(_localeMeta);
    }
    if (data.containsKey('localization_revision')) {
      context.handle(
        _localizationRevisionMeta,
        localizationRevision.isAcceptableOrUnknown(
          data['localization_revision']!,
          _localizationRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localizationRevisionMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    packCode,
    variantKey,
    packRevision,
    contentCode,
    contentType,
    contentRevision,
    locale,
  };
  @override
  PackLocalizationRef map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PackLocalizationRef(
      packCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack_code'],
      )!,
      variantKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_key'],
      )!,
      packRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pack_revision'],
      )!,
      contentCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_code'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      contentRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}content_revision'],
      )!,
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      )!,
      localizationRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}localization_revision'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
    );
  }

  @override
  $PackLocalizationRefsTable createAlias(String alias) {
    return $PackLocalizationRefsTable(attachedDatabase, alias);
  }
}

class PackLocalizationRef extends DataClass
    implements Insertable<PackLocalizationRef> {
  final String packCode;
  final String variantKey;
  final int packRevision;
  final String contentCode;
  final String contentType;
  final int contentRevision;
  final String locale;
  final int localizationRevision;
  final String checksum;
  const PackLocalizationRef({
    required this.packCode,
    required this.variantKey,
    required this.packRevision,
    required this.contentCode,
    required this.contentType,
    required this.contentRevision,
    required this.locale,
    required this.localizationRevision,
    required this.checksum,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pack_code'] = Variable<String>(packCode);
    map['variant_key'] = Variable<String>(variantKey);
    map['pack_revision'] = Variable<int>(packRevision);
    map['content_code'] = Variable<String>(contentCode);
    map['content_type'] = Variable<String>(contentType);
    map['content_revision'] = Variable<int>(contentRevision);
    map['locale'] = Variable<String>(locale);
    map['localization_revision'] = Variable<int>(localizationRevision);
    map['checksum'] = Variable<String>(checksum);
    return map;
  }

  PackLocalizationRefsCompanion toCompanion(bool nullToAbsent) {
    return PackLocalizationRefsCompanion(
      packCode: Value(packCode),
      variantKey: Value(variantKey),
      packRevision: Value(packRevision),
      contentCode: Value(contentCode),
      contentType: Value(contentType),
      contentRevision: Value(contentRevision),
      locale: Value(locale),
      localizationRevision: Value(localizationRevision),
      checksum: Value(checksum),
    );
  }

  factory PackLocalizationRef.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PackLocalizationRef(
      packCode: serializer.fromJson<String>(json['packCode']),
      variantKey: serializer.fromJson<String>(json['variantKey']),
      packRevision: serializer.fromJson<int>(json['packRevision']),
      contentCode: serializer.fromJson<String>(json['contentCode']),
      contentType: serializer.fromJson<String>(json['contentType']),
      contentRevision: serializer.fromJson<int>(json['contentRevision']),
      locale: serializer.fromJson<String>(json['locale']),
      localizationRevision: serializer.fromJson<int>(
        json['localizationRevision'],
      ),
      checksum: serializer.fromJson<String>(json['checksum']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packCode': serializer.toJson<String>(packCode),
      'variantKey': serializer.toJson<String>(variantKey),
      'packRevision': serializer.toJson<int>(packRevision),
      'contentCode': serializer.toJson<String>(contentCode),
      'contentType': serializer.toJson<String>(contentType),
      'contentRevision': serializer.toJson<int>(contentRevision),
      'locale': serializer.toJson<String>(locale),
      'localizationRevision': serializer.toJson<int>(localizationRevision),
      'checksum': serializer.toJson<String>(checksum),
    };
  }

  PackLocalizationRef copyWith({
    String? packCode,
    String? variantKey,
    int? packRevision,
    String? contentCode,
    String? contentType,
    int? contentRevision,
    String? locale,
    int? localizationRevision,
    String? checksum,
  }) => PackLocalizationRef(
    packCode: packCode ?? this.packCode,
    variantKey: variantKey ?? this.variantKey,
    packRevision: packRevision ?? this.packRevision,
    contentCode: contentCode ?? this.contentCode,
    contentType: contentType ?? this.contentType,
    contentRevision: contentRevision ?? this.contentRevision,
    locale: locale ?? this.locale,
    localizationRevision: localizationRevision ?? this.localizationRevision,
    checksum: checksum ?? this.checksum,
  );
  PackLocalizationRef copyWithCompanion(PackLocalizationRefsCompanion data) {
    return PackLocalizationRef(
      packCode: data.packCode.present ? data.packCode.value : this.packCode,
      variantKey: data.variantKey.present
          ? data.variantKey.value
          : this.variantKey,
      packRevision: data.packRevision.present
          ? data.packRevision.value
          : this.packRevision,
      contentCode: data.contentCode.present
          ? data.contentCode.value
          : this.contentCode,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      contentRevision: data.contentRevision.present
          ? data.contentRevision.value
          : this.contentRevision,
      locale: data.locale.present ? data.locale.value : this.locale,
      localizationRevision: data.localizationRevision.present
          ? data.localizationRevision.value
          : this.localizationRevision,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PackLocalizationRef(')
          ..write('packCode: $packCode, ')
          ..write('variantKey: $variantKey, ')
          ..write('packRevision: $packRevision, ')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('contentRevision: $contentRevision, ')
          ..write('locale: $locale, ')
          ..write('localizationRevision: $localizationRevision, ')
          ..write('checksum: $checksum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    packCode,
    variantKey,
    packRevision,
    contentCode,
    contentType,
    contentRevision,
    locale,
    localizationRevision,
    checksum,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PackLocalizationRef &&
          other.packCode == this.packCode &&
          other.variantKey == this.variantKey &&
          other.packRevision == this.packRevision &&
          other.contentCode == this.contentCode &&
          other.contentType == this.contentType &&
          other.contentRevision == this.contentRevision &&
          other.locale == this.locale &&
          other.localizationRevision == this.localizationRevision &&
          other.checksum == this.checksum);
}

class PackLocalizationRefsCompanion
    extends UpdateCompanion<PackLocalizationRef> {
  final Value<String> packCode;
  final Value<String> variantKey;
  final Value<int> packRevision;
  final Value<String> contentCode;
  final Value<String> contentType;
  final Value<int> contentRevision;
  final Value<String> locale;
  final Value<int> localizationRevision;
  final Value<String> checksum;
  final Value<int> rowid;
  const PackLocalizationRefsCompanion({
    this.packCode = const Value.absent(),
    this.variantKey = const Value.absent(),
    this.packRevision = const Value.absent(),
    this.contentCode = const Value.absent(),
    this.contentType = const Value.absent(),
    this.contentRevision = const Value.absent(),
    this.locale = const Value.absent(),
    this.localizationRevision = const Value.absent(),
    this.checksum = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PackLocalizationRefsCompanion.insert({
    required String packCode,
    required String variantKey,
    required int packRevision,
    required String contentCode,
    required String contentType,
    required int contentRevision,
    required String locale,
    required int localizationRevision,
    required String checksum,
    this.rowid = const Value.absent(),
  }) : packCode = Value(packCode),
       variantKey = Value(variantKey),
       packRevision = Value(packRevision),
       contentCode = Value(contentCode),
       contentType = Value(contentType),
       contentRevision = Value(contentRevision),
       locale = Value(locale),
       localizationRevision = Value(localizationRevision),
       checksum = Value(checksum);
  static Insertable<PackLocalizationRef> custom({
    Expression<String>? packCode,
    Expression<String>? variantKey,
    Expression<int>? packRevision,
    Expression<String>? contentCode,
    Expression<String>? contentType,
    Expression<int>? contentRevision,
    Expression<String>? locale,
    Expression<int>? localizationRevision,
    Expression<String>? checksum,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packCode != null) 'pack_code': packCode,
      if (variantKey != null) 'variant_key': variantKey,
      if (packRevision != null) 'pack_revision': packRevision,
      if (contentCode != null) 'content_code': contentCode,
      if (contentType != null) 'content_type': contentType,
      if (contentRevision != null) 'content_revision': contentRevision,
      if (locale != null) 'locale': locale,
      if (localizationRevision != null)
        'localization_revision': localizationRevision,
      if (checksum != null) 'checksum': checksum,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PackLocalizationRefsCompanion copyWith({
    Value<String>? packCode,
    Value<String>? variantKey,
    Value<int>? packRevision,
    Value<String>? contentCode,
    Value<String>? contentType,
    Value<int>? contentRevision,
    Value<String>? locale,
    Value<int>? localizationRevision,
    Value<String>? checksum,
    Value<int>? rowid,
  }) {
    return PackLocalizationRefsCompanion(
      packCode: packCode ?? this.packCode,
      variantKey: variantKey ?? this.variantKey,
      packRevision: packRevision ?? this.packRevision,
      contentCode: contentCode ?? this.contentCode,
      contentType: contentType ?? this.contentType,
      contentRevision: contentRevision ?? this.contentRevision,
      locale: locale ?? this.locale,
      localizationRevision: localizationRevision ?? this.localizationRevision,
      checksum: checksum ?? this.checksum,
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
    if (packRevision.present) {
      map['pack_revision'] = Variable<int>(packRevision.value);
    }
    if (contentCode.present) {
      map['content_code'] = Variable<String>(contentCode.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (contentRevision.present) {
      map['content_revision'] = Variable<int>(contentRevision.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (localizationRevision.present) {
      map['localization_revision'] = Variable<int>(localizationRevision.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PackLocalizationRefsCompanion(')
          ..write('packCode: $packCode, ')
          ..write('variantKey: $variantKey, ')
          ..write('packRevision: $packRevision, ')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('contentRevision: $contentRevision, ')
          ..write('locale: $locale, ')
          ..write('localizationRevision: $localizationRevision, ')
          ..write('checksum: $checksum, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetCatalogTable extends AssetCatalog
    with TableInfo<$AssetCatalogTable, AssetCatalogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetCatalogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumSha256Meta = const VerificationMeta(
    'checksumSha256',
  );
  @override
  late final GeneratedColumn<String> checksumSha256 = GeneratedColumn<String>(
    'checksum_sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assetKindMeta = const VerificationMeta(
    'assetKind',
  );
  @override
  late final GeneratedColumn<String> assetKind = GeneratedColumn<String>(
    'asset_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deliveryKeyMeta = const VerificationMeta(
    'deliveryKey',
  );
  @override
  late final GeneratedColumn<String> deliveryKey = GeneratedColumn<String>(
    'delivery_key',
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
  List<GeneratedColumn> get $columns => [
    assetId,
    checksumSha256,
    assetKind,
    mimeType,
    sizeBytes,
    durationMs,
    deliveryKey,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_catalog';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetCatalogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('checksum_sha256')) {
      context.handle(
        _checksumSha256Meta,
        checksumSha256.isAcceptableOrUnknown(
          data['checksum_sha256']!,
          _checksumSha256Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_checksumSha256Meta);
    }
    if (data.containsKey('asset_kind')) {
      context.handle(
        _assetKindMeta,
        assetKind.isAcceptableOrUnknown(data['asset_kind']!, _assetKindMeta),
      );
    } else if (isInserting) {
      context.missing(_assetKindMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('delivery_key')) {
      context.handle(
        _deliveryKeyMeta,
        deliveryKey.isAcceptableOrUnknown(
          data['delivery_key']!,
          _deliveryKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryKeyMeta);
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
  Set<GeneratedColumn> get $primaryKey => {assetId};
  @override
  AssetCatalogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetCatalogData(
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      checksumSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum_sha256'],
      )!,
      assetKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_kind'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      deliveryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AssetCatalogTable createAlias(String alias) {
    return $AssetCatalogTable(attachedDatabase, alias);
  }
}

class AssetCatalogData extends DataClass
    implements Insertable<AssetCatalogData> {
  final String assetId;
  final String checksumSha256;
  final String assetKind;
  final String mimeType;
  final int sizeBytes;
  final int? durationMs;
  final String deliveryKey;
  final DateTime createdAt;
  const AssetCatalogData({
    required this.assetId,
    required this.checksumSha256,
    required this.assetKind,
    required this.mimeType,
    required this.sizeBytes,
    this.durationMs,
    required this.deliveryKey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['asset_id'] = Variable<String>(assetId);
    map['checksum_sha256'] = Variable<String>(checksumSha256);
    map['asset_kind'] = Variable<String>(assetKind);
    map['mime_type'] = Variable<String>(mimeType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['delivery_key'] = Variable<String>(deliveryKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AssetCatalogCompanion toCompanion(bool nullToAbsent) {
    return AssetCatalogCompanion(
      assetId: Value(assetId),
      checksumSha256: Value(checksumSha256),
      assetKind: Value(assetKind),
      mimeType: Value(mimeType),
      sizeBytes: Value(sizeBytes),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      deliveryKey: Value(deliveryKey),
      createdAt: Value(createdAt),
    );
  }

  factory AssetCatalogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetCatalogData(
      assetId: serializer.fromJson<String>(json['assetId']),
      checksumSha256: serializer.fromJson<String>(json['checksumSha256']),
      assetKind: serializer.fromJson<String>(json['assetKind']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      deliveryKey: serializer.fromJson<String>(json['deliveryKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assetId': serializer.toJson<String>(assetId),
      'checksumSha256': serializer.toJson<String>(checksumSha256),
      'assetKind': serializer.toJson<String>(assetKind),
      'mimeType': serializer.toJson<String>(mimeType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'durationMs': serializer.toJson<int?>(durationMs),
      'deliveryKey': serializer.toJson<String>(deliveryKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AssetCatalogData copyWith({
    String? assetId,
    String? checksumSha256,
    String? assetKind,
    String? mimeType,
    int? sizeBytes,
    Value<int?> durationMs = const Value.absent(),
    String? deliveryKey,
    DateTime? createdAt,
  }) => AssetCatalogData(
    assetId: assetId ?? this.assetId,
    checksumSha256: checksumSha256 ?? this.checksumSha256,
    assetKind: assetKind ?? this.assetKind,
    mimeType: mimeType ?? this.mimeType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    deliveryKey: deliveryKey ?? this.deliveryKey,
    createdAt: createdAt ?? this.createdAt,
  );
  AssetCatalogData copyWithCompanion(AssetCatalogCompanion data) {
    return AssetCatalogData(
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      checksumSha256: data.checksumSha256.present
          ? data.checksumSha256.value
          : this.checksumSha256,
      assetKind: data.assetKind.present ? data.assetKind.value : this.assetKind,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      deliveryKey: data.deliveryKey.present
          ? data.deliveryKey.value
          : this.deliveryKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetCatalogData(')
          ..write('assetId: $assetId, ')
          ..write('checksumSha256: $checksumSha256, ')
          ..write('assetKind: $assetKind, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('durationMs: $durationMs, ')
          ..write('deliveryKey: $deliveryKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    assetId,
    checksumSha256,
    assetKind,
    mimeType,
    sizeBytes,
    durationMs,
    deliveryKey,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetCatalogData &&
          other.assetId == this.assetId &&
          other.checksumSha256 == this.checksumSha256 &&
          other.assetKind == this.assetKind &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.durationMs == this.durationMs &&
          other.deliveryKey == this.deliveryKey &&
          other.createdAt == this.createdAt);
}

class AssetCatalogCompanion extends UpdateCompanion<AssetCatalogData> {
  final Value<String> assetId;
  final Value<String> checksumSha256;
  final Value<String> assetKind;
  final Value<String> mimeType;
  final Value<int> sizeBytes;
  final Value<int?> durationMs;
  final Value<String> deliveryKey;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AssetCatalogCompanion({
    this.assetId = const Value.absent(),
    this.checksumSha256 = const Value.absent(),
    this.assetKind = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.deliveryKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetCatalogCompanion.insert({
    required String assetId,
    required String checksumSha256,
    required String assetKind,
    required String mimeType,
    required int sizeBytes,
    this.durationMs = const Value.absent(),
    required String deliveryKey,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : assetId = Value(assetId),
       checksumSha256 = Value(checksumSha256),
       assetKind = Value(assetKind),
       mimeType = Value(mimeType),
       sizeBytes = Value(sizeBytes),
       deliveryKey = Value(deliveryKey),
       createdAt = Value(createdAt);
  static Insertable<AssetCatalogData> custom({
    Expression<String>? assetId,
    Expression<String>? checksumSha256,
    Expression<String>? assetKind,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<int>? durationMs,
    Expression<String>? deliveryKey,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
      if (checksumSha256 != null) 'checksum_sha256': checksumSha256,
      if (assetKind != null) 'asset_kind': assetKind,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (durationMs != null) 'duration_ms': durationMs,
      if (deliveryKey != null) 'delivery_key': deliveryKey,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetCatalogCompanion copyWith({
    Value<String>? assetId,
    Value<String>? checksumSha256,
    Value<String>? assetKind,
    Value<String>? mimeType,
    Value<int>? sizeBytes,
    Value<int?>? durationMs,
    Value<String>? deliveryKey,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AssetCatalogCompanion(
      assetId: assetId ?? this.assetId,
      checksumSha256: checksumSha256 ?? this.checksumSha256,
      assetKind: assetKind ?? this.assetKind,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      durationMs: durationMs ?? this.durationMs,
      deliveryKey: deliveryKey ?? this.deliveryKey,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (checksumSha256.present) {
      map['checksum_sha256'] = Variable<String>(checksumSha256.value);
    }
    if (assetKind.present) {
      map['asset_kind'] = Variable<String>(assetKind.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (deliveryKey.present) {
      map['delivery_key'] = Variable<String>(deliveryKey.value);
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
    return (StringBuffer('AssetCatalogCompanion(')
          ..write('assetId: $assetId, ')
          ..write('checksumSha256: $checksumSha256, ')
          ..write('assetKind: $assetKind, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('durationMs: $durationMs, ')
          ..write('deliveryKey: $deliveryKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentAssetRefsTable extends ContentAssetRefs
    with TableInfo<$ContentAssetRefsTable, ContentAssetRef> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentAssetRefsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _contentRevisionMeta = const VerificationMeta(
    'contentRevision',
  );
  @override
  late final GeneratedColumn<int> contentRevision = GeneratedColumn<int>(
    'content_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES asset_catalog (asset_id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _assetRoleMeta = const VerificationMeta(
    'assetRole',
  );
  @override
  late final GeneratedColumn<String> assetRole = GeneratedColumn<String>(
    'asset_role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requiredOfflineMeta = const VerificationMeta(
    'requiredOffline',
  );
  @override
  late final GeneratedColumn<bool> requiredOffline = GeneratedColumn<bool>(
    'required_offline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("required_offline" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    contentCode,
    contentType,
    contentRevision,
    assetId,
    assetRole,
    requiredOffline,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_asset_refs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentAssetRef> instance, {
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
    if (data.containsKey('content_revision')) {
      context.handle(
        _contentRevisionMeta,
        contentRevision.isAcceptableOrUnknown(
          data['content_revision']!,
          _contentRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentRevisionMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('asset_role')) {
      context.handle(
        _assetRoleMeta,
        assetRole.isAcceptableOrUnknown(data['asset_role']!, _assetRoleMeta),
      );
    } else if (isInserting) {
      context.missing(_assetRoleMeta);
    }
    if (data.containsKey('required_offline')) {
      context.handle(
        _requiredOfflineMeta,
        requiredOffline.isAcceptableOrUnknown(
          data['required_offline']!,
          _requiredOfflineMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    contentCode,
    contentType,
    contentRevision,
    assetId,
    assetRole,
  };
  @override
  ContentAssetRef map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentAssetRef(
      contentCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_code'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      contentRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}content_revision'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      assetRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_role'],
      )!,
      requiredOffline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}required_offline'],
      )!,
    );
  }

  @override
  $ContentAssetRefsTable createAlias(String alias) {
    return $ContentAssetRefsTable(attachedDatabase, alias);
  }
}

class ContentAssetRef extends DataClass implements Insertable<ContentAssetRef> {
  final String contentCode;
  final String contentType;
  final int contentRevision;
  final String assetId;
  final String assetRole;
  final bool requiredOffline;
  const ContentAssetRef({
    required this.contentCode,
    required this.contentType,
    required this.contentRevision,
    required this.assetId,
    required this.assetRole,
    required this.requiredOffline,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['content_code'] = Variable<String>(contentCode);
    map['content_type'] = Variable<String>(contentType);
    map['content_revision'] = Variable<int>(contentRevision);
    map['asset_id'] = Variable<String>(assetId);
    map['asset_role'] = Variable<String>(assetRole);
    map['required_offline'] = Variable<bool>(requiredOffline);
    return map;
  }

  ContentAssetRefsCompanion toCompanion(bool nullToAbsent) {
    return ContentAssetRefsCompanion(
      contentCode: Value(contentCode),
      contentType: Value(contentType),
      contentRevision: Value(contentRevision),
      assetId: Value(assetId),
      assetRole: Value(assetRole),
      requiredOffline: Value(requiredOffline),
    );
  }

  factory ContentAssetRef.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentAssetRef(
      contentCode: serializer.fromJson<String>(json['contentCode']),
      contentType: serializer.fromJson<String>(json['contentType']),
      contentRevision: serializer.fromJson<int>(json['contentRevision']),
      assetId: serializer.fromJson<String>(json['assetId']),
      assetRole: serializer.fromJson<String>(json['assetRole']),
      requiredOffline: serializer.fromJson<bool>(json['requiredOffline']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contentCode': serializer.toJson<String>(contentCode),
      'contentType': serializer.toJson<String>(contentType),
      'contentRevision': serializer.toJson<int>(contentRevision),
      'assetId': serializer.toJson<String>(assetId),
      'assetRole': serializer.toJson<String>(assetRole),
      'requiredOffline': serializer.toJson<bool>(requiredOffline),
    };
  }

  ContentAssetRef copyWith({
    String? contentCode,
    String? contentType,
    int? contentRevision,
    String? assetId,
    String? assetRole,
    bool? requiredOffline,
  }) => ContentAssetRef(
    contentCode: contentCode ?? this.contentCode,
    contentType: contentType ?? this.contentType,
    contentRevision: contentRevision ?? this.contentRevision,
    assetId: assetId ?? this.assetId,
    assetRole: assetRole ?? this.assetRole,
    requiredOffline: requiredOffline ?? this.requiredOffline,
  );
  ContentAssetRef copyWithCompanion(ContentAssetRefsCompanion data) {
    return ContentAssetRef(
      contentCode: data.contentCode.present
          ? data.contentCode.value
          : this.contentCode,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      contentRevision: data.contentRevision.present
          ? data.contentRevision.value
          : this.contentRevision,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      assetRole: data.assetRole.present ? data.assetRole.value : this.assetRole,
      requiredOffline: data.requiredOffline.present
          ? data.requiredOffline.value
          : this.requiredOffline,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentAssetRef(')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('contentRevision: $contentRevision, ')
          ..write('assetId: $assetId, ')
          ..write('assetRole: $assetRole, ')
          ..write('requiredOffline: $requiredOffline')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    contentCode,
    contentType,
    contentRevision,
    assetId,
    assetRole,
    requiredOffline,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentAssetRef &&
          other.contentCode == this.contentCode &&
          other.contentType == this.contentType &&
          other.contentRevision == this.contentRevision &&
          other.assetId == this.assetId &&
          other.assetRole == this.assetRole &&
          other.requiredOffline == this.requiredOffline);
}

class ContentAssetRefsCompanion extends UpdateCompanion<ContentAssetRef> {
  final Value<String> contentCode;
  final Value<String> contentType;
  final Value<int> contentRevision;
  final Value<String> assetId;
  final Value<String> assetRole;
  final Value<bool> requiredOffline;
  final Value<int> rowid;
  const ContentAssetRefsCompanion({
    this.contentCode = const Value.absent(),
    this.contentType = const Value.absent(),
    this.contentRevision = const Value.absent(),
    this.assetId = const Value.absent(),
    this.assetRole = const Value.absent(),
    this.requiredOffline = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentAssetRefsCompanion.insert({
    required String contentCode,
    required String contentType,
    required int contentRevision,
    required String assetId,
    required String assetRole,
    this.requiredOffline = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : contentCode = Value(contentCode),
       contentType = Value(contentType),
       contentRevision = Value(contentRevision),
       assetId = Value(assetId),
       assetRole = Value(assetRole);
  static Insertable<ContentAssetRef> custom({
    Expression<String>? contentCode,
    Expression<String>? contentType,
    Expression<int>? contentRevision,
    Expression<String>? assetId,
    Expression<String>? assetRole,
    Expression<bool>? requiredOffline,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contentCode != null) 'content_code': contentCode,
      if (contentType != null) 'content_type': contentType,
      if (contentRevision != null) 'content_revision': contentRevision,
      if (assetId != null) 'asset_id': assetId,
      if (assetRole != null) 'asset_role': assetRole,
      if (requiredOffline != null) 'required_offline': requiredOffline,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentAssetRefsCompanion copyWith({
    Value<String>? contentCode,
    Value<String>? contentType,
    Value<int>? contentRevision,
    Value<String>? assetId,
    Value<String>? assetRole,
    Value<bool>? requiredOffline,
    Value<int>? rowid,
  }) {
    return ContentAssetRefsCompanion(
      contentCode: contentCode ?? this.contentCode,
      contentType: contentType ?? this.contentType,
      contentRevision: contentRevision ?? this.contentRevision,
      assetId: assetId ?? this.assetId,
      assetRole: assetRole ?? this.assetRole,
      requiredOffline: requiredOffline ?? this.requiredOffline,
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
    if (contentRevision.present) {
      map['content_revision'] = Variable<int>(contentRevision.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (assetRole.present) {
      map['asset_role'] = Variable<String>(assetRole.value);
    }
    if (requiredOffline.present) {
      map['required_offline'] = Variable<bool>(requiredOffline.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentAssetRefsCompanion(')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('contentRevision: $contentRevision, ')
          ..write('assetId: $assetId, ')
          ..write('assetRole: $assetRole, ')
          ..write('requiredOffline: $requiredOffline, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PackAssetRefsTable extends PackAssetRefs
    with TableInfo<$PackAssetRefsTable, PackAssetRef> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PackAssetRefsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _packRevisionMeta = const VerificationMeta(
    'packRevision',
  );
  @override
  late final GeneratedColumn<int> packRevision = GeneratedColumn<int>(
    'pack_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES asset_catalog (asset_id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _requiredOfflineMeta = const VerificationMeta(
    'requiredOffline',
  );
  @override
  late final GeneratedColumn<bool> requiredOffline = GeneratedColumn<bool>(
    'required_offline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("required_offline" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    packCode,
    variantKey,
    packRevision,
    assetId,
    requiredOffline,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pack_asset_refs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PackAssetRef> instance, {
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
    if (data.containsKey('pack_revision')) {
      context.handle(
        _packRevisionMeta,
        packRevision.isAcceptableOrUnknown(
          data['pack_revision']!,
          _packRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packRevisionMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('required_offline')) {
      context.handle(
        _requiredOfflineMeta,
        requiredOffline.isAcceptableOrUnknown(
          data['required_offline']!,
          _requiredOfflineMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    packCode,
    variantKey,
    packRevision,
    assetId,
  };
  @override
  PackAssetRef map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PackAssetRef(
      packCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack_code'],
      )!,
      variantKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_key'],
      )!,
      packRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pack_revision'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      requiredOffline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}required_offline'],
      )!,
    );
  }

  @override
  $PackAssetRefsTable createAlias(String alias) {
    return $PackAssetRefsTable(attachedDatabase, alias);
  }
}

class PackAssetRef extends DataClass implements Insertable<PackAssetRef> {
  final String packCode;
  final String variantKey;
  final int packRevision;
  final String assetId;
  final bool requiredOffline;
  const PackAssetRef({
    required this.packCode,
    required this.variantKey,
    required this.packRevision,
    required this.assetId,
    required this.requiredOffline,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pack_code'] = Variable<String>(packCode);
    map['variant_key'] = Variable<String>(variantKey);
    map['pack_revision'] = Variable<int>(packRevision);
    map['asset_id'] = Variable<String>(assetId);
    map['required_offline'] = Variable<bool>(requiredOffline);
    return map;
  }

  PackAssetRefsCompanion toCompanion(bool nullToAbsent) {
    return PackAssetRefsCompanion(
      packCode: Value(packCode),
      variantKey: Value(variantKey),
      packRevision: Value(packRevision),
      assetId: Value(assetId),
      requiredOffline: Value(requiredOffline),
    );
  }

  factory PackAssetRef.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PackAssetRef(
      packCode: serializer.fromJson<String>(json['packCode']),
      variantKey: serializer.fromJson<String>(json['variantKey']),
      packRevision: serializer.fromJson<int>(json['packRevision']),
      assetId: serializer.fromJson<String>(json['assetId']),
      requiredOffline: serializer.fromJson<bool>(json['requiredOffline']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packCode': serializer.toJson<String>(packCode),
      'variantKey': serializer.toJson<String>(variantKey),
      'packRevision': serializer.toJson<int>(packRevision),
      'assetId': serializer.toJson<String>(assetId),
      'requiredOffline': serializer.toJson<bool>(requiredOffline),
    };
  }

  PackAssetRef copyWith({
    String? packCode,
    String? variantKey,
    int? packRevision,
    String? assetId,
    bool? requiredOffline,
  }) => PackAssetRef(
    packCode: packCode ?? this.packCode,
    variantKey: variantKey ?? this.variantKey,
    packRevision: packRevision ?? this.packRevision,
    assetId: assetId ?? this.assetId,
    requiredOffline: requiredOffline ?? this.requiredOffline,
  );
  PackAssetRef copyWithCompanion(PackAssetRefsCompanion data) {
    return PackAssetRef(
      packCode: data.packCode.present ? data.packCode.value : this.packCode,
      variantKey: data.variantKey.present
          ? data.variantKey.value
          : this.variantKey,
      packRevision: data.packRevision.present
          ? data.packRevision.value
          : this.packRevision,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      requiredOffline: data.requiredOffline.present
          ? data.requiredOffline.value
          : this.requiredOffline,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PackAssetRef(')
          ..write('packCode: $packCode, ')
          ..write('variantKey: $variantKey, ')
          ..write('packRevision: $packRevision, ')
          ..write('assetId: $assetId, ')
          ..write('requiredOffline: $requiredOffline')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(packCode, variantKey, packRevision, assetId, requiredOffline);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PackAssetRef &&
          other.packCode == this.packCode &&
          other.variantKey == this.variantKey &&
          other.packRevision == this.packRevision &&
          other.assetId == this.assetId &&
          other.requiredOffline == this.requiredOffline);
}

class PackAssetRefsCompanion extends UpdateCompanion<PackAssetRef> {
  final Value<String> packCode;
  final Value<String> variantKey;
  final Value<int> packRevision;
  final Value<String> assetId;
  final Value<bool> requiredOffline;
  final Value<int> rowid;
  const PackAssetRefsCompanion({
    this.packCode = const Value.absent(),
    this.variantKey = const Value.absent(),
    this.packRevision = const Value.absent(),
    this.assetId = const Value.absent(),
    this.requiredOffline = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PackAssetRefsCompanion.insert({
    required String packCode,
    required String variantKey,
    required int packRevision,
    required String assetId,
    this.requiredOffline = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : packCode = Value(packCode),
       variantKey = Value(variantKey),
       packRevision = Value(packRevision),
       assetId = Value(assetId);
  static Insertable<PackAssetRef> custom({
    Expression<String>? packCode,
    Expression<String>? variantKey,
    Expression<int>? packRevision,
    Expression<String>? assetId,
    Expression<bool>? requiredOffline,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packCode != null) 'pack_code': packCode,
      if (variantKey != null) 'variant_key': variantKey,
      if (packRevision != null) 'pack_revision': packRevision,
      if (assetId != null) 'asset_id': assetId,
      if (requiredOffline != null) 'required_offline': requiredOffline,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PackAssetRefsCompanion copyWith({
    Value<String>? packCode,
    Value<String>? variantKey,
    Value<int>? packRevision,
    Value<String>? assetId,
    Value<bool>? requiredOffline,
    Value<int>? rowid,
  }) {
    return PackAssetRefsCompanion(
      packCode: packCode ?? this.packCode,
      variantKey: variantKey ?? this.variantKey,
      packRevision: packRevision ?? this.packRevision,
      assetId: assetId ?? this.assetId,
      requiredOffline: requiredOffline ?? this.requiredOffline,
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
    if (packRevision.present) {
      map['pack_revision'] = Variable<int>(packRevision.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (requiredOffline.present) {
      map['required_offline'] = Variable<bool>(requiredOffline.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PackAssetRefsCompanion(')
          ..write('packCode: $packCode, ')
          ..write('variantKey: $variantKey, ')
          ..write('packRevision: $packRevision, ')
          ..write('assetId: $assetId, ')
          ..write('requiredOffline: $requiredOffline, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentCatalogReadsTable extends ContentCatalogReads
    with TableInfo<$ContentCatalogReadsTable, ContentCatalogRead> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentCatalogReadsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
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
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hasAudioMeta = const VerificationMeta(
    'hasAudio',
  );
  @override
  late final GeneratedColumn<bool> hasAudio = GeneratedColumn<bool>(
    'has_audio',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_audio" IN (0, 1))',
    ),
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
    title,
    subtitle,
    description,
    category,
    level,
    minutes,
    hasAudio,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_catalog_reads';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentCatalogRead> instance, {
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
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    } else if (isInserting) {
      context.missing(_subtitleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('has_audio')) {
      context.handle(
        _hasAudioMeta,
        hasAudio.isAcceptableOrUnknown(data['has_audio']!, _hasAudioMeta),
      );
    } else if (isInserting) {
      context.missing(_hasAudioMeta);
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
  ContentCatalogRead map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentCatalogRead(
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
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
      hasAudio: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_audio'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ContentCatalogReadsTable createAlias(String alias) {
    return $ContentCatalogReadsTable(attachedDatabase, alias);
  }
}

class ContentCatalogRead extends DataClass
    implements Insertable<ContentCatalogRead> {
  final String contentCode;
  final String contentType;
  final int revision;
  final String checksum;
  final String title;
  final String subtitle;
  final String description;
  final String category;
  final String level;
  final int minutes;
  final bool hasAudio;
  final DateTime createdAt;
  const ContentCatalogRead({
    required this.contentCode,
    required this.contentType,
    required this.revision,
    required this.checksum,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.level,
    required this.minutes,
    required this.hasAudio,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['content_code'] = Variable<String>(contentCode);
    map['content_type'] = Variable<String>(contentType);
    map['revision'] = Variable<int>(revision);
    map['checksum'] = Variable<String>(checksum);
    map['title'] = Variable<String>(title);
    map['subtitle'] = Variable<String>(subtitle);
    map['description'] = Variable<String>(description);
    map['category'] = Variable<String>(category);
    map['level'] = Variable<String>(level);
    map['minutes'] = Variable<int>(minutes);
    map['has_audio'] = Variable<bool>(hasAudio);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ContentCatalogReadsCompanion toCompanion(bool nullToAbsent) {
    return ContentCatalogReadsCompanion(
      contentCode: Value(contentCode),
      contentType: Value(contentType),
      revision: Value(revision),
      checksum: Value(checksum),
      title: Value(title),
      subtitle: Value(subtitle),
      description: Value(description),
      category: Value(category),
      level: Value(level),
      minutes: Value(minutes),
      hasAudio: Value(hasAudio),
      createdAt: Value(createdAt),
    );
  }

  factory ContentCatalogRead.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentCatalogRead(
      contentCode: serializer.fromJson<String>(json['contentCode']),
      contentType: serializer.fromJson<String>(json['contentType']),
      revision: serializer.fromJson<int>(json['revision']),
      checksum: serializer.fromJson<String>(json['checksum']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String>(json['subtitle']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      level: serializer.fromJson<String>(json['level']),
      minutes: serializer.fromJson<int>(json['minutes']),
      hasAudio: serializer.fromJson<bool>(json['hasAudio']),
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
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String>(subtitle),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(category),
      'level': serializer.toJson<String>(level),
      'minutes': serializer.toJson<int>(minutes),
      'hasAudio': serializer.toJson<bool>(hasAudio),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ContentCatalogRead copyWith({
    String? contentCode,
    String? contentType,
    int? revision,
    String? checksum,
    String? title,
    String? subtitle,
    String? description,
    String? category,
    String? level,
    int? minutes,
    bool? hasAudio,
    DateTime? createdAt,
  }) => ContentCatalogRead(
    contentCode: contentCode ?? this.contentCode,
    contentType: contentType ?? this.contentType,
    revision: revision ?? this.revision,
    checksum: checksum ?? this.checksum,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    description: description ?? this.description,
    category: category ?? this.category,
    level: level ?? this.level,
    minutes: minutes ?? this.minutes,
    hasAudio: hasAudio ?? this.hasAudio,
    createdAt: createdAt ?? this.createdAt,
  );
  ContentCatalogRead copyWithCompanion(ContentCatalogReadsCompanion data) {
    return ContentCatalogRead(
      contentCode: data.contentCode.present
          ? data.contentCode.value
          : this.contentCode,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      revision: data.revision.present ? data.revision.value : this.revision,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      level: data.level.present ? data.level.value : this.level,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      hasAudio: data.hasAudio.present ? data.hasAudio.value : this.hasAudio,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentCatalogRead(')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('revision: $revision, ')
          ..write('checksum: $checksum, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('level: $level, ')
          ..write('minutes: $minutes, ')
          ..write('hasAudio: $hasAudio, ')
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
    title,
    subtitle,
    description,
    category,
    level,
    minutes,
    hasAudio,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentCatalogRead &&
          other.contentCode == this.contentCode &&
          other.contentType == this.contentType &&
          other.revision == this.revision &&
          other.checksum == this.checksum &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.description == this.description &&
          other.category == this.category &&
          other.level == this.level &&
          other.minutes == this.minutes &&
          other.hasAudio == this.hasAudio &&
          other.createdAt == this.createdAt);
}

class ContentCatalogReadsCompanion extends UpdateCompanion<ContentCatalogRead> {
  final Value<String> contentCode;
  final Value<String> contentType;
  final Value<int> revision;
  final Value<String> checksum;
  final Value<String> title;
  final Value<String> subtitle;
  final Value<String> description;
  final Value<String> category;
  final Value<String> level;
  final Value<int> minutes;
  final Value<bool> hasAudio;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ContentCatalogReadsCompanion({
    this.contentCode = const Value.absent(),
    this.contentType = const Value.absent(),
    this.revision = const Value.absent(),
    this.checksum = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.level = const Value.absent(),
    this.minutes = const Value.absent(),
    this.hasAudio = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentCatalogReadsCompanion.insert({
    required String contentCode,
    required String contentType,
    required int revision,
    required String checksum,
    required String title,
    required String subtitle,
    required String description,
    required String category,
    required String level,
    required int minutes,
    required bool hasAudio,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : contentCode = Value(contentCode),
       contentType = Value(contentType),
       revision = Value(revision),
       checksum = Value(checksum),
       title = Value(title),
       subtitle = Value(subtitle),
       description = Value(description),
       category = Value(category),
       level = Value(level),
       minutes = Value(minutes),
       hasAudio = Value(hasAudio),
       createdAt = Value(createdAt);
  static Insertable<ContentCatalogRead> custom({
    Expression<String>? contentCode,
    Expression<String>? contentType,
    Expression<int>? revision,
    Expression<String>? checksum,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? level,
    Expression<int>? minutes,
    Expression<bool>? hasAudio,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contentCode != null) 'content_code': contentCode,
      if (contentType != null) 'content_type': contentType,
      if (revision != null) 'revision': revision,
      if (checksum != null) 'checksum': checksum,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (level != null) 'level': level,
      if (minutes != null) 'minutes': minutes,
      if (hasAudio != null) 'has_audio': hasAudio,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentCatalogReadsCompanion copyWith({
    Value<String>? contentCode,
    Value<String>? contentType,
    Value<int>? revision,
    Value<String>? checksum,
    Value<String>? title,
    Value<String>? subtitle,
    Value<String>? description,
    Value<String>? category,
    Value<String>? level,
    Value<int>? minutes,
    Value<bool>? hasAudio,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ContentCatalogReadsCompanion(
      contentCode: contentCode ?? this.contentCode,
      contentType: contentType ?? this.contentType,
      revision: revision ?? this.revision,
      checksum: checksum ?? this.checksum,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      category: category ?? this.category,
      level: level ?? this.level,
      minutes: minutes ?? this.minutes,
      hasAudio: hasAudio ?? this.hasAudio,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (hasAudio.present) {
      map['has_audio'] = Variable<bool>(hasAudio.value);
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
    return (StringBuffer('ContentCatalogReadsCompanion(')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('revision: $revision, ')
          ..write('checksum: $checksum, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('level: $level, ')
          ..write('minutes: $minutes, ')
          ..write('hasAudio: $hasAudio, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalizedContentReadsTable extends LocalizedContentReads
    with TableInfo<$LocalizedContentReadsTable, LocalizedContentRead> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalizedContentReadsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _contentRevisionMeta = const VerificationMeta(
    'contentRevision',
  );
  @override
  late final GeneratedColumn<int> contentRevision = GeneratedColumn<int>(
    'content_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localizationRevisionMeta =
      const VerificationMeta('localizationRevision');
  @override
  late final GeneratedColumn<int> localizationRevision = GeneratedColumn<int>(
    'localization_revision',
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _translationMeta = const VerificationMeta(
    'translation',
  );
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
    'translation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hintMeta = const VerificationMeta('hint');
  @override
  late final GeneratedColumn<String> hint = GeneratedColumn<String>(
    'hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  @override
  List<GeneratedColumn> get $columns => [
    contentCode,
    contentType,
    contentRevision,
    locale,
    localizationRevision,
    checksum,
    title,
    subtitle,
    description,
    translation,
    hint,
    explanation,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'localized_content_reads';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalizedContentRead> instance, {
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
    if (data.containsKey('content_revision')) {
      context.handle(
        _contentRevisionMeta,
        contentRevision.isAcceptableOrUnknown(
          data['content_revision']!,
          _contentRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentRevisionMeta);
    }
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    } else if (isInserting) {
      context.missing(_localeMeta);
    }
    if (data.containsKey('localization_revision')) {
      context.handle(
        _localizationRevisionMeta,
        localizationRevision.isAcceptableOrUnknown(
          data['localization_revision']!,
          _localizationRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localizationRevisionMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('translation')) {
      context.handle(
        _translationMeta,
        translation.isAcceptableOrUnknown(
          data['translation']!,
          _translationMeta,
        ),
      );
    }
    if (data.containsKey('hint')) {
      context.handle(
        _hintMeta,
        hint.isAcceptableOrUnknown(data['hint']!, _hintMeta),
      );
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    contentCode,
    contentType,
    contentRevision,
    locale,
    localizationRevision,
  };
  @override
  LocalizedContentRead map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalizedContentRead(
      contentCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_code'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      contentRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}content_revision'],
      )!,
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      )!,
      localizationRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}localization_revision'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      translation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation'],
      ),
      hint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hint'],
      ),
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalizedContentReadsTable createAlias(String alias) {
    return $LocalizedContentReadsTable(attachedDatabase, alias);
  }
}

class LocalizedContentRead extends DataClass
    implements Insertable<LocalizedContentRead> {
  final String contentCode;
  final String contentType;
  final int contentRevision;
  final String locale;
  final int localizationRevision;
  final String checksum;
  final String? title;
  final String? subtitle;
  final String? description;
  final String? translation;
  final String? hint;
  final String? explanation;
  final DateTime createdAt;
  const LocalizedContentRead({
    required this.contentCode,
    required this.contentType,
    required this.contentRevision,
    required this.locale,
    required this.localizationRevision,
    required this.checksum,
    this.title,
    this.subtitle,
    this.description,
    this.translation,
    this.hint,
    this.explanation,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['content_code'] = Variable<String>(contentCode);
    map['content_type'] = Variable<String>(contentType);
    map['content_revision'] = Variable<int>(contentRevision);
    map['locale'] = Variable<String>(locale);
    map['localization_revision'] = Variable<int>(localizationRevision);
    map['checksum'] = Variable<String>(checksum);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || translation != null) {
      map['translation'] = Variable<String>(translation);
    }
    if (!nullToAbsent || hint != null) {
      map['hint'] = Variable<String>(hint);
    }
    if (!nullToAbsent || explanation != null) {
      map['explanation'] = Variable<String>(explanation);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalizedContentReadsCompanion toCompanion(bool nullToAbsent) {
    return LocalizedContentReadsCompanion(
      contentCode: Value(contentCode),
      contentType: Value(contentType),
      contentRevision: Value(contentRevision),
      locale: Value(locale),
      localizationRevision: Value(localizationRevision),
      checksum: Value(checksum),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      translation: translation == null && nullToAbsent
          ? const Value.absent()
          : Value(translation),
      hint: hint == null && nullToAbsent ? const Value.absent() : Value(hint),
      explanation: explanation == null && nullToAbsent
          ? const Value.absent()
          : Value(explanation),
      createdAt: Value(createdAt),
    );
  }

  factory LocalizedContentRead.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalizedContentRead(
      contentCode: serializer.fromJson<String>(json['contentCode']),
      contentType: serializer.fromJson<String>(json['contentType']),
      contentRevision: serializer.fromJson<int>(json['contentRevision']),
      locale: serializer.fromJson<String>(json['locale']),
      localizationRevision: serializer.fromJson<int>(
        json['localizationRevision'],
      ),
      checksum: serializer.fromJson<String>(json['checksum']),
      title: serializer.fromJson<String?>(json['title']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      description: serializer.fromJson<String?>(json['description']),
      translation: serializer.fromJson<String?>(json['translation']),
      hint: serializer.fromJson<String?>(json['hint']),
      explanation: serializer.fromJson<String?>(json['explanation']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contentCode': serializer.toJson<String>(contentCode),
      'contentType': serializer.toJson<String>(contentType),
      'contentRevision': serializer.toJson<int>(contentRevision),
      'locale': serializer.toJson<String>(locale),
      'localizationRevision': serializer.toJson<int>(localizationRevision),
      'checksum': serializer.toJson<String>(checksum),
      'title': serializer.toJson<String?>(title),
      'subtitle': serializer.toJson<String?>(subtitle),
      'description': serializer.toJson<String?>(description),
      'translation': serializer.toJson<String?>(translation),
      'hint': serializer.toJson<String?>(hint),
      'explanation': serializer.toJson<String?>(explanation),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalizedContentRead copyWith({
    String? contentCode,
    String? contentType,
    int? contentRevision,
    String? locale,
    int? localizationRevision,
    String? checksum,
    Value<String?> title = const Value.absent(),
    Value<String?> subtitle = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> translation = const Value.absent(),
    Value<String?> hint = const Value.absent(),
    Value<String?> explanation = const Value.absent(),
    DateTime? createdAt,
  }) => LocalizedContentRead(
    contentCode: contentCode ?? this.contentCode,
    contentType: contentType ?? this.contentType,
    contentRevision: contentRevision ?? this.contentRevision,
    locale: locale ?? this.locale,
    localizationRevision: localizationRevision ?? this.localizationRevision,
    checksum: checksum ?? this.checksum,
    title: title.present ? title.value : this.title,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    description: description.present ? description.value : this.description,
    translation: translation.present ? translation.value : this.translation,
    hint: hint.present ? hint.value : this.hint,
    explanation: explanation.present ? explanation.value : this.explanation,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalizedContentRead copyWithCompanion(LocalizedContentReadsCompanion data) {
    return LocalizedContentRead(
      contentCode: data.contentCode.present
          ? data.contentCode.value
          : this.contentCode,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      contentRevision: data.contentRevision.present
          ? data.contentRevision.value
          : this.contentRevision,
      locale: data.locale.present ? data.locale.value : this.locale,
      localizationRevision: data.localizationRevision.present
          ? data.localizationRevision.value
          : this.localizationRevision,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      description: data.description.present
          ? data.description.value
          : this.description,
      translation: data.translation.present
          ? data.translation.value
          : this.translation,
      hint: data.hint.present ? data.hint.value : this.hint,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalizedContentRead(')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('contentRevision: $contentRevision, ')
          ..write('locale: $locale, ')
          ..write('localizationRevision: $localizationRevision, ')
          ..write('checksum: $checksum, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('description: $description, ')
          ..write('translation: $translation, ')
          ..write('hint: $hint, ')
          ..write('explanation: $explanation, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    contentCode,
    contentType,
    contentRevision,
    locale,
    localizationRevision,
    checksum,
    title,
    subtitle,
    description,
    translation,
    hint,
    explanation,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalizedContentRead &&
          other.contentCode == this.contentCode &&
          other.contentType == this.contentType &&
          other.contentRevision == this.contentRevision &&
          other.locale == this.locale &&
          other.localizationRevision == this.localizationRevision &&
          other.checksum == this.checksum &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.description == this.description &&
          other.translation == this.translation &&
          other.hint == this.hint &&
          other.explanation == this.explanation &&
          other.createdAt == this.createdAt);
}

class LocalizedContentReadsCompanion
    extends UpdateCompanion<LocalizedContentRead> {
  final Value<String> contentCode;
  final Value<String> contentType;
  final Value<int> contentRevision;
  final Value<String> locale;
  final Value<int> localizationRevision;
  final Value<String> checksum;
  final Value<String?> title;
  final Value<String?> subtitle;
  final Value<String?> description;
  final Value<String?> translation;
  final Value<String?> hint;
  final Value<String?> explanation;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalizedContentReadsCompanion({
    this.contentCode = const Value.absent(),
    this.contentType = const Value.absent(),
    this.contentRevision = const Value.absent(),
    this.locale = const Value.absent(),
    this.localizationRevision = const Value.absent(),
    this.checksum = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.description = const Value.absent(),
    this.translation = const Value.absent(),
    this.hint = const Value.absent(),
    this.explanation = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalizedContentReadsCompanion.insert({
    required String contentCode,
    required String contentType,
    required int contentRevision,
    required String locale,
    required int localizationRevision,
    required String checksum,
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.description = const Value.absent(),
    this.translation = const Value.absent(),
    this.hint = const Value.absent(),
    this.explanation = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : contentCode = Value(contentCode),
       contentType = Value(contentType),
       contentRevision = Value(contentRevision),
       locale = Value(locale),
       localizationRevision = Value(localizationRevision),
       checksum = Value(checksum),
       createdAt = Value(createdAt);
  static Insertable<LocalizedContentRead> custom({
    Expression<String>? contentCode,
    Expression<String>? contentType,
    Expression<int>? contentRevision,
    Expression<String>? locale,
    Expression<int>? localizationRevision,
    Expression<String>? checksum,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? description,
    Expression<String>? translation,
    Expression<String>? hint,
    Expression<String>? explanation,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contentCode != null) 'content_code': contentCode,
      if (contentType != null) 'content_type': contentType,
      if (contentRevision != null) 'content_revision': contentRevision,
      if (locale != null) 'locale': locale,
      if (localizationRevision != null)
        'localization_revision': localizationRevision,
      if (checksum != null) 'checksum': checksum,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (description != null) 'description': description,
      if (translation != null) 'translation': translation,
      if (hint != null) 'hint': hint,
      if (explanation != null) 'explanation': explanation,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalizedContentReadsCompanion copyWith({
    Value<String>? contentCode,
    Value<String>? contentType,
    Value<int>? contentRevision,
    Value<String>? locale,
    Value<int>? localizationRevision,
    Value<String>? checksum,
    Value<String?>? title,
    Value<String?>? subtitle,
    Value<String?>? description,
    Value<String?>? translation,
    Value<String?>? hint,
    Value<String?>? explanation,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalizedContentReadsCompanion(
      contentCode: contentCode ?? this.contentCode,
      contentType: contentType ?? this.contentType,
      contentRevision: contentRevision ?? this.contentRevision,
      locale: locale ?? this.locale,
      localizationRevision: localizationRevision ?? this.localizationRevision,
      checksum: checksum ?? this.checksum,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      translation: translation ?? this.translation,
      hint: hint ?? this.hint,
      explanation: explanation ?? this.explanation,
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
    if (contentRevision.present) {
      map['content_revision'] = Variable<int>(contentRevision.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (localizationRevision.present) {
      map['localization_revision'] = Variable<int>(localizationRevision.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    if (hint.present) {
      map['hint'] = Variable<String>(hint.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
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
    return (StringBuffer('LocalizedContentReadsCompanion(')
          ..write('contentCode: $contentCode, ')
          ..write('contentType: $contentType, ')
          ..write('contentRevision: $contentRevision, ')
          ..write('locale: $locale, ')
          ..write('localizationRevision: $localizationRevision, ')
          ..write('checksum: $checksum, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('description: $description, ')
          ..write('translation: $translation, ')
          ..write('hint: $hint, ')
          ..write('explanation: $explanation, ')
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
  late final $SyncRunsTable syncRuns = $SyncRunsTable(this);
  late final $SyncPackUpdatesTable syncPackUpdates = $SyncPackUpdatesTable(
    this,
  );
  late final $SyncTombstonesTable syncTombstones = $SyncTombstonesTable(this);
  late final $ContentPackRevisionsTable contentPackRevisions =
      $ContentPackRevisionsTable(this);
  late final $LocalContentRecordsTable localContentRecords =
      $LocalContentRecordsTable(this);
  late final $PackContentRefsTable packContentRefs = $PackContentRefsTable(
    this,
  );
  late final $PackLocalizationRefsTable packLocalizationRefs =
      $PackLocalizationRefsTable(this);
  late final $AssetCatalogTable assetCatalog = $AssetCatalogTable(this);
  late final $ContentAssetRefsTable contentAssetRefs = $ContentAssetRefsTable(
    this,
  );
  late final $PackAssetRefsTable packAssetRefs = $PackAssetRefsTable(this);
  late final $ContentCatalogReadsTable contentCatalogReads =
      $ContentCatalogReadsTable(this);
  late final $LocalizedContentReadsTable localizedContentReads =
      $LocalizedContentReadsTable(this);
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
    syncRuns,
    syncPackUpdates,
    syncTombstones,
    contentPackRevisions,
    localContentRecords,
    packContentRefs,
    packLocalizationRefs,
    assetCatalog,
    contentAssetRefs,
    packAssetRefs,
    contentCatalogReads,
    localizedContentReads,
    favorites,
    contentLearningStates,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sync_runs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sync_pack_updates', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sync_runs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sync_tombstones', kind: UpdateKind.delete)],
    ),
  ]);
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
typedef $$SyncRunsTableCreateCompanionBuilder =
    SyncRunsCompanion Function({
      required String runId,
      required String trigger,
      required String translationLocale,
      Value<int?> fromContentVersion,
      Value<int?> targetContentVersion,
      Value<int?> targetSchemaVersion,
      required String state,
      Value<bool> resyncRequested,
      Value<int> attemptCount,
      Value<bool> retryable,
      Value<String?> errorCode,
      Value<String?> errorMessage,
      required DateTime startedAt,
      required DateTime updatedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });
typedef $$SyncRunsTableUpdateCompanionBuilder =
    SyncRunsCompanion Function({
      Value<String> runId,
      Value<String> trigger,
      Value<String> translationLocale,
      Value<int?> fromContentVersion,
      Value<int?> targetContentVersion,
      Value<int?> targetSchemaVersion,
      Value<String> state,
      Value<bool> resyncRequested,
      Value<int> attemptCount,
      Value<bool> retryable,
      Value<String?> errorCode,
      Value<String?> errorMessage,
      Value<DateTime> startedAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });

final class $$SyncRunsTableReferences
    extends BaseReferences<_$CareerSpeakDatabase, $SyncRunsTable, SyncRun> {
  $$SyncRunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SyncPackUpdatesTable, List<SyncPackUpdate>>
  _syncPackUpdatesRefsTable(_$CareerSpeakDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.syncPackUpdates,
        aliasName: 'sync_runs__run_id__sync_pack_updates__run_id',
      );

  $$SyncPackUpdatesTableProcessedTableManager get syncPackUpdatesRefs {
    final manager = $$SyncPackUpdatesTableTableManager(
      $_db,
      $_db.syncPackUpdates,
    ).filter((f) => f.runId.runId.sqlEquals($_itemColumn<String>('run_id')!));

    final cache = $_typedResult.readTableOrNull(
      _syncPackUpdatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyncTombstonesTable, List<SyncTombstone>>
  _syncTombstonesRefsTable(_$CareerSpeakDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.syncTombstones,
        aliasName: 'sync_runs__run_id__sync_tombstones__run_id',
      );

  $$SyncTombstonesTableProcessedTableManager get syncTombstonesRefs {
    final manager = $$SyncTombstonesTableTableManager(
      $_db,
      $_db.syncTombstones,
    ).filter((f) => f.runId.runId.sqlEquals($_itemColumn<String>('run_id')!));

    final cache = $_typedResult.readTableOrNull(_syncTombstonesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SyncRunsTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $SyncRunsTable> {
  $$SyncRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translationLocale => $composableBuilder(
    column: $table.translationLocale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fromContentVersion => $composableBuilder(
    column: $table.fromContentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetContentVersion => $composableBuilder(
    column: $table.targetContentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetSchemaVersion => $composableBuilder(
    column: $table.targetSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get resyncRequested => $composableBuilder(
    column: $table.resyncRequested,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get retryable => $composableBuilder(
    column: $table.retryable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> syncPackUpdatesRefs(
    Expression<bool> Function($$SyncPackUpdatesTableFilterComposer f) f,
  ) {
    final $$SyncPackUpdatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.syncPackUpdates,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncPackUpdatesTableFilterComposer(
            $db: $db,
            $table: $db.syncPackUpdates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncTombstonesRefs(
    Expression<bool> Function($$SyncTombstonesTableFilterComposer f) f,
  ) {
    final $$SyncTombstonesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.syncTombstones,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncTombstonesTableFilterComposer(
            $db: $db,
            $table: $db.syncTombstones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SyncRunsTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $SyncRunsTable> {
  $$SyncRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translationLocale => $composableBuilder(
    column: $table.translationLocale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fromContentVersion => $composableBuilder(
    column: $table.fromContentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetContentVersion => $composableBuilder(
    column: $table.targetContentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetSchemaVersion => $composableBuilder(
    column: $table.targetSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get resyncRequested => $composableBuilder(
    column: $table.resyncRequested,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get retryable => $composableBuilder(
    column: $table.retryable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncRunsTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $SyncRunsTable> {
  $$SyncRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get runId =>
      $composableBuilder(column: $table.runId, builder: (column) => column);

  GeneratedColumn<String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumn<String> get translationLocale => $composableBuilder(
    column: $table.translationLocale,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fromContentVersion => $composableBuilder(
    column: $table.fromContentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetContentVersion => $composableBuilder(
    column: $table.targetContentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetSchemaVersion => $composableBuilder(
    column: $table.targetSchemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<bool> get resyncRequested => $composableBuilder(
    column: $table.resyncRequested,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get retryable =>
      $composableBuilder(column: $table.retryable, builder: (column) => column);

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  Expression<T> syncPackUpdatesRefs<T extends Object>(
    Expression<T> Function($$SyncPackUpdatesTableAnnotationComposer a) f,
  ) {
    final $$SyncPackUpdatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.syncPackUpdates,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncPackUpdatesTableAnnotationComposer(
            $db: $db,
            $table: $db.syncPackUpdates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syncTombstonesRefs<T extends Object>(
    Expression<T> Function($$SyncTombstonesTableAnnotationComposer a) f,
  ) {
    final $$SyncTombstonesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.syncTombstones,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncTombstonesTableAnnotationComposer(
            $db: $db,
            $table: $db.syncTombstones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SyncRunsTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $SyncRunsTable,
          SyncRun,
          $$SyncRunsTableFilterComposer,
          $$SyncRunsTableOrderingComposer,
          $$SyncRunsTableAnnotationComposer,
          $$SyncRunsTableCreateCompanionBuilder,
          $$SyncRunsTableUpdateCompanionBuilder,
          (SyncRun, $$SyncRunsTableReferences),
          SyncRun,
          PrefetchHooks Function({
            bool syncPackUpdatesRefs,
            bool syncTombstonesRefs,
          })
        > {
  $$SyncRunsTableTableManager(_$CareerSpeakDatabase db, $SyncRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> runId = const Value.absent(),
                Value<String> trigger = const Value.absent(),
                Value<String> translationLocale = const Value.absent(),
                Value<int?> fromContentVersion = const Value.absent(),
                Value<int?> targetContentVersion = const Value.absent(),
                Value<int?> targetSchemaVersion = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<bool> resyncRequested = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<bool> retryable = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRunsCompanion(
                runId: runId,
                trigger: trigger,
                translationLocale: translationLocale,
                fromContentVersion: fromContentVersion,
                targetContentVersion: targetContentVersion,
                targetSchemaVersion: targetSchemaVersion,
                state: state,
                resyncRequested: resyncRequested,
                attemptCount: attemptCount,
                retryable: retryable,
                errorCode: errorCode,
                errorMessage: errorMessage,
                startedAt: startedAt,
                updatedAt: updatedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String runId,
                required String trigger,
                required String translationLocale,
                Value<int?> fromContentVersion = const Value.absent(),
                Value<int?> targetContentVersion = const Value.absent(),
                Value<int?> targetSchemaVersion = const Value.absent(),
                required String state,
                Value<bool> resyncRequested = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<bool> retryable = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                required DateTime startedAt,
                required DateTime updatedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRunsCompanion.insert(
                runId: runId,
                trigger: trigger,
                translationLocale: translationLocale,
                fromContentVersion: fromContentVersion,
                targetContentVersion: targetContentVersion,
                targetSchemaVersion: targetSchemaVersion,
                state: state,
                resyncRequested: resyncRequested,
                attemptCount: attemptCount,
                retryable: retryable,
                errorCode: errorCode,
                errorMessage: errorMessage,
                startedAt: startedAt,
                updatedAt: updatedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncRunsTable, SyncRun>(table),
                  $$SyncRunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({syncPackUpdatesRefs = false, syncTombstonesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (syncPackUpdatesRefs) db.syncPackUpdates,
                    if (syncTombstonesRefs) db.syncTombstones,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (syncPackUpdatesRefs)
                        await $_getPrefetchedDataByColumns<
                          SyncRun,
                          $SyncRunsTable,
                          SyncPackUpdate,
                          $SyncPackUpdatesTable
                        >(
                          currentTable: table,
                          referencedTable: $$SyncRunsTableReferences
                              ._syncPackUpdatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SyncRunsTableReferences(
                                db,
                                table,
                                p0,
                              ).syncPackUpdatesRefs,
                          currentColumn: 'run_id',
                          referencedColumn: 'run_id',
                          typedResults: items,
                        ),
                      if (syncTombstonesRefs)
                        await $_getPrefetchedDataByColumns<
                          SyncRun,
                          $SyncRunsTable,
                          SyncTombstone,
                          $SyncTombstonesTable
                        >(
                          currentTable: table,
                          referencedTable: $$SyncRunsTableReferences
                              ._syncTombstonesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SyncRunsTableReferences(
                                db,
                                table,
                                p0,
                              ).syncTombstonesRefs,
                          currentColumn: 'run_id',
                          referencedColumn: 'run_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SyncRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $SyncRunsTable,
      SyncRun,
      $$SyncRunsTableFilterComposer,
      $$SyncRunsTableOrderingComposer,
      $$SyncRunsTableAnnotationComposer,
      $$SyncRunsTableCreateCompanionBuilder,
      $$SyncRunsTableUpdateCompanionBuilder,
      (SyncRun, $$SyncRunsTableReferences),
      SyncRun,
      PrefetchHooks Function({
        bool syncPackUpdatesRefs,
        bool syncTombstonesRefs,
      })
    >;
typedef $$SyncPackUpdatesTableCreateCompanionBuilder =
    SyncPackUpdatesCompanion Function({
      required String runId,
      required String packCode,
      required String variantKey,
      required int targetRevision,
      required String targetChecksum,
      required String state,
      Value<int> requiredAssetCount,
      Value<int> verifiedAssetCount,
      Value<String?> errorCode,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SyncPackUpdatesTableUpdateCompanionBuilder =
    SyncPackUpdatesCompanion Function({
      Value<String> runId,
      Value<String> packCode,
      Value<String> variantKey,
      Value<int> targetRevision,
      Value<String> targetChecksum,
      Value<String> state,
      Value<int> requiredAssetCount,
      Value<int> verifiedAssetCount,
      Value<String?> errorCode,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SyncPackUpdatesTableReferences
    extends
        BaseReferences<
          _$CareerSpeakDatabase,
          $SyncPackUpdatesTable,
          SyncPackUpdate
        > {
  $$SyncPackUpdatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SyncRunsTable _runIdTable(_$CareerSpeakDatabase db) =>
      db.syncRuns.createAlias('sync_pack_updates__run_id__sync_runs__run_id');

  $$SyncRunsTableProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $$SyncRunsTableTableManager(
      $_db,
      $_db.syncRuns,
    ).filter((f) => f.runId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncPackUpdatesTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $SyncPackUpdatesTable> {
  $$SyncPackUpdatesTableFilterComposer({
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

  ColumnFilters<int> get targetRevision => $composableBuilder(
    column: $table.targetRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetChecksum => $composableBuilder(
    column: $table.targetChecksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requiredAssetCount => $composableBuilder(
    column: $table.requiredAssetCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verifiedAssetCount => $composableBuilder(
    column: $table.verifiedAssetCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SyncRunsTableFilterComposer get runId {
    final $$SyncRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.syncRuns,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncRunsTableFilterComposer(
            $db: $db,
            $table: $db.syncRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncPackUpdatesTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $SyncPackUpdatesTable> {
  $$SyncPackUpdatesTableOrderingComposer({
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

  ColumnOrderings<int> get targetRevision => $composableBuilder(
    column: $table.targetRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetChecksum => $composableBuilder(
    column: $table.targetChecksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requiredAssetCount => $composableBuilder(
    column: $table.requiredAssetCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verifiedAssetCount => $composableBuilder(
    column: $table.verifiedAssetCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SyncRunsTableOrderingComposer get runId {
    final $$SyncRunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.syncRuns,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncRunsTableOrderingComposer(
            $db: $db,
            $table: $db.syncRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncPackUpdatesTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $SyncPackUpdatesTable> {
  $$SyncPackUpdatesTableAnnotationComposer({
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

  GeneratedColumn<int> get targetRevision => $composableBuilder(
    column: $table.targetRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetChecksum => $composableBuilder(
    column: $table.targetChecksum,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get requiredAssetCount => $composableBuilder(
    column: $table.requiredAssetCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get verifiedAssetCount => $composableBuilder(
    column: $table.verifiedAssetCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SyncRunsTableAnnotationComposer get runId {
    final $$SyncRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.syncRuns,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.syncRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncPackUpdatesTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $SyncPackUpdatesTable,
          SyncPackUpdate,
          $$SyncPackUpdatesTableFilterComposer,
          $$SyncPackUpdatesTableOrderingComposer,
          $$SyncPackUpdatesTableAnnotationComposer,
          $$SyncPackUpdatesTableCreateCompanionBuilder,
          $$SyncPackUpdatesTableUpdateCompanionBuilder,
          (SyncPackUpdate, $$SyncPackUpdatesTableReferences),
          SyncPackUpdate,
          PrefetchHooks Function({bool runId})
        > {
  $$SyncPackUpdatesTableTableManager(
    _$CareerSpeakDatabase db,
    $SyncPackUpdatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncPackUpdatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncPackUpdatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncPackUpdatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> runId = const Value.absent(),
                Value<String> packCode = const Value.absent(),
                Value<String> variantKey = const Value.absent(),
                Value<int> targetRevision = const Value.absent(),
                Value<String> targetChecksum = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> requiredAssetCount = const Value.absent(),
                Value<int> verifiedAssetCount = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncPackUpdatesCompanion(
                runId: runId,
                packCode: packCode,
                variantKey: variantKey,
                targetRevision: targetRevision,
                targetChecksum: targetChecksum,
                state: state,
                requiredAssetCount: requiredAssetCount,
                verifiedAssetCount: verifiedAssetCount,
                errorCode: errorCode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String runId,
                required String packCode,
                required String variantKey,
                required int targetRevision,
                required String targetChecksum,
                required String state,
                Value<int> requiredAssetCount = const Value.absent(),
                Value<int> verifiedAssetCount = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncPackUpdatesCompanion.insert(
                runId: runId,
                packCode: packCode,
                variantKey: variantKey,
                targetRevision: targetRevision,
                targetChecksum: targetChecksum,
                state: state,
                requiredAssetCount: requiredAssetCount,
                verifiedAssetCount: verifiedAssetCount,
                errorCode: errorCode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncPackUpdatesTable, SyncPackUpdate>(table),
                  $$SyncPackUpdatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable:
                                    $$SyncPackUpdatesTableReferences
                                        ._runIdTable(db),
                                referencedColumn:
                                    $$SyncPackUpdatesTableReferences
                                        ._runIdTable(db)
                                        .runId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SyncPackUpdatesTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $SyncPackUpdatesTable,
      SyncPackUpdate,
      $$SyncPackUpdatesTableFilterComposer,
      $$SyncPackUpdatesTableOrderingComposer,
      $$SyncPackUpdatesTableAnnotationComposer,
      $$SyncPackUpdatesTableCreateCompanionBuilder,
      $$SyncPackUpdatesTableUpdateCompanionBuilder,
      (SyncPackUpdate, $$SyncPackUpdatesTableReferences),
      SyncPackUpdate,
      PrefetchHooks Function({bool runId})
    >;
typedef $$SyncTombstonesTableCreateCompanionBuilder =
    SyncTombstonesCompanion Function({
      required String runId,
      required String contentCode,
      required String contentType,
      Value<int?> revision,
      required String reason,
      required String state,
      Value<DateTime?> appliedAt,
      Value<int> rowid,
    });
typedef $$SyncTombstonesTableUpdateCompanionBuilder =
    SyncTombstonesCompanion Function({
      Value<String> runId,
      Value<String> contentCode,
      Value<String> contentType,
      Value<int?> revision,
      Value<String> reason,
      Value<String> state,
      Value<DateTime?> appliedAt,
      Value<int> rowid,
    });

final class $$SyncTombstonesTableReferences
    extends
        BaseReferences<
          _$CareerSpeakDatabase,
          $SyncTombstonesTable,
          SyncTombstone
        > {
  $$SyncTombstonesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SyncRunsTable _runIdTable(_$CareerSpeakDatabase db) =>
      db.syncRuns.createAlias('sync_tombstones__run_id__sync_runs__run_id');

  $$SyncRunsTableProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $$SyncRunsTableTableManager(
      $_db,
      $_db.syncRuns,
    ).filter((f) => f.runId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncTombstonesTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableFilterComposer({
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

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SyncRunsTableFilterComposer get runId {
    final $$SyncRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.syncRuns,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncRunsTableFilterComposer(
            $db: $db,
            $table: $db.syncRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncTombstonesTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableOrderingComposer({
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

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SyncRunsTableOrderingComposer get runId {
    final $$SyncRunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.syncRuns,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncRunsTableOrderingComposer(
            $db: $db,
            $table: $db.syncRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncTombstonesTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableAnnotationComposer({
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

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);

  $$SyncRunsTableAnnotationComposer get runId {
    final $$SyncRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.syncRuns,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.syncRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncTombstonesTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $SyncTombstonesTable,
          SyncTombstone,
          $$SyncTombstonesTableFilterComposer,
          $$SyncTombstonesTableOrderingComposer,
          $$SyncTombstonesTableAnnotationComposer,
          $$SyncTombstonesTableCreateCompanionBuilder,
          $$SyncTombstonesTableUpdateCompanionBuilder,
          (SyncTombstone, $$SyncTombstonesTableReferences),
          SyncTombstone,
          PrefetchHooks Function({bool runId})
        > {
  $$SyncTombstonesTableTableManager(
    _$CareerSpeakDatabase db,
    $SyncTombstonesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncTombstonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncTombstonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncTombstonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> runId = const Value.absent(),
                Value<String> contentCode = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<int?> revision = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<DateTime?> appliedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncTombstonesCompanion(
                runId: runId,
                contentCode: contentCode,
                contentType: contentType,
                revision: revision,
                reason: reason,
                state: state,
                appliedAt: appliedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String runId,
                required String contentCode,
                required String contentType,
                Value<int?> revision = const Value.absent(),
                required String reason,
                required String state,
                Value<DateTime?> appliedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncTombstonesCompanion.insert(
                runId: runId,
                contentCode: contentCode,
                contentType: contentType,
                revision: revision,
                reason: reason,
                state: state,
                appliedAt: appliedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncTombstonesTable, SyncTombstone>(table),
                  $$SyncTombstonesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $$SyncTombstonesTableReferences
                                    ._runIdTable(db),
                                referencedColumn:
                                    $$SyncTombstonesTableReferences
                                        ._runIdTable(db)
                                        .runId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SyncTombstonesTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $SyncTombstonesTable,
      SyncTombstone,
      $$SyncTombstonesTableFilterComposer,
      $$SyncTombstonesTableOrderingComposer,
      $$SyncTombstonesTableAnnotationComposer,
      $$SyncTombstonesTableCreateCompanionBuilder,
      $$SyncTombstonesTableUpdateCompanionBuilder,
      (SyncTombstone, $$SyncTombstonesTableReferences),
      SyncTombstone,
      PrefetchHooks Function({bool runId})
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
typedef $$PackContentRefsTableCreateCompanionBuilder =
    PackContentRefsCompanion Function({
      required String packCode,
      required String variantKey,
      required int packRevision,
      required String contentCode,
      required String contentType,
      required int contentRevision,
      Value<int> rowid,
    });
typedef $$PackContentRefsTableUpdateCompanionBuilder =
    PackContentRefsCompanion Function({
      Value<String> packCode,
      Value<String> variantKey,
      Value<int> packRevision,
      Value<String> contentCode,
      Value<String> contentType,
      Value<int> contentRevision,
      Value<int> rowid,
    });

class $$PackContentRefsTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $PackContentRefsTable> {
  $$PackContentRefsTableFilterComposer({
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

  ColumnFilters<int> get packRevision => $composableBuilder(
    column: $table.packRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentCode => $composableBuilder(
    column: $table.contentCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contentRevision => $composableBuilder(
    column: $table.contentRevision,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PackContentRefsTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $PackContentRefsTable> {
  $$PackContentRefsTableOrderingComposer({
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

  ColumnOrderings<int> get packRevision => $composableBuilder(
    column: $table.packRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentCode => $composableBuilder(
    column: $table.contentCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contentRevision => $composableBuilder(
    column: $table.contentRevision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PackContentRefsTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $PackContentRefsTable> {
  $$PackContentRefsTableAnnotationComposer({
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

  GeneratedColumn<int> get packRevision => $composableBuilder(
    column: $table.packRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentCode => $composableBuilder(
    column: $table.contentCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get contentRevision => $composableBuilder(
    column: $table.contentRevision,
    builder: (column) => column,
  );
}

class $$PackContentRefsTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $PackContentRefsTable,
          PackContentRef,
          $$PackContentRefsTableFilterComposer,
          $$PackContentRefsTableOrderingComposer,
          $$PackContentRefsTableAnnotationComposer,
          $$PackContentRefsTableCreateCompanionBuilder,
          $$PackContentRefsTableUpdateCompanionBuilder,
          (
            PackContentRef,
            BaseReferences<
              _$CareerSpeakDatabase,
              $PackContentRefsTable,
              PackContentRef
            >,
          ),
          PackContentRef,
          PrefetchHooks Function()
        > {
  $$PackContentRefsTableTableManager(
    _$CareerSpeakDatabase db,
    $PackContentRefsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PackContentRefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PackContentRefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PackContentRefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> packCode = const Value.absent(),
                Value<String> variantKey = const Value.absent(),
                Value<int> packRevision = const Value.absent(),
                Value<String> contentCode = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<int> contentRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PackContentRefsCompanion(
                packCode: packCode,
                variantKey: variantKey,
                packRevision: packRevision,
                contentCode: contentCode,
                contentType: contentType,
                contentRevision: contentRevision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String packCode,
                required String variantKey,
                required int packRevision,
                required String contentCode,
                required String contentType,
                required int contentRevision,
                Value<int> rowid = const Value.absent(),
              }) => PackContentRefsCompanion.insert(
                packCode: packCode,
                variantKey: variantKey,
                packRevision: packRevision,
                contentCode: contentCode,
                contentType: contentType,
                contentRevision: contentRevision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PackContentRefsTable, PackContentRef>(table),
                  BaseReferences<
                    _$CareerSpeakDatabase,
                    $PackContentRefsTable,
                    PackContentRef
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PackContentRefsTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $PackContentRefsTable,
      PackContentRef,
      $$PackContentRefsTableFilterComposer,
      $$PackContentRefsTableOrderingComposer,
      $$PackContentRefsTableAnnotationComposer,
      $$PackContentRefsTableCreateCompanionBuilder,
      $$PackContentRefsTableUpdateCompanionBuilder,
      (
        PackContentRef,
        BaseReferences<
          _$CareerSpeakDatabase,
          $PackContentRefsTable,
          PackContentRef
        >,
      ),
      PackContentRef,
      PrefetchHooks Function()
    >;
typedef $$PackLocalizationRefsTableCreateCompanionBuilder =
    PackLocalizationRefsCompanion Function({
      required String packCode,
      required String variantKey,
      required int packRevision,
      required String contentCode,
      required String contentType,
      required int contentRevision,
      required String locale,
      required int localizationRevision,
      required String checksum,
      Value<int> rowid,
    });
typedef $$PackLocalizationRefsTableUpdateCompanionBuilder =
    PackLocalizationRefsCompanion Function({
      Value<String> packCode,
      Value<String> variantKey,
      Value<int> packRevision,
      Value<String> contentCode,
      Value<String> contentType,
      Value<int> contentRevision,
      Value<String> locale,
      Value<int> localizationRevision,
      Value<String> checksum,
      Value<int> rowid,
    });

class $$PackLocalizationRefsTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $PackLocalizationRefsTable> {
  $$PackLocalizationRefsTableFilterComposer({
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

  ColumnFilters<int> get packRevision => $composableBuilder(
    column: $table.packRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentCode => $composableBuilder(
    column: $table.contentCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contentRevision => $composableBuilder(
    column: $table.contentRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localizationRevision => $composableBuilder(
    column: $table.localizationRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PackLocalizationRefsTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $PackLocalizationRefsTable> {
  $$PackLocalizationRefsTableOrderingComposer({
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

  ColumnOrderings<int> get packRevision => $composableBuilder(
    column: $table.packRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentCode => $composableBuilder(
    column: $table.contentCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contentRevision => $composableBuilder(
    column: $table.contentRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localizationRevision => $composableBuilder(
    column: $table.localizationRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PackLocalizationRefsTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $PackLocalizationRefsTable> {
  $$PackLocalizationRefsTableAnnotationComposer({
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

  GeneratedColumn<int> get packRevision => $composableBuilder(
    column: $table.packRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentCode => $composableBuilder(
    column: $table.contentCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get contentRevision => $composableBuilder(
    column: $table.contentRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<int> get localizationRevision => $composableBuilder(
    column: $table.localizationRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);
}

class $$PackLocalizationRefsTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $PackLocalizationRefsTable,
          PackLocalizationRef,
          $$PackLocalizationRefsTableFilterComposer,
          $$PackLocalizationRefsTableOrderingComposer,
          $$PackLocalizationRefsTableAnnotationComposer,
          $$PackLocalizationRefsTableCreateCompanionBuilder,
          $$PackLocalizationRefsTableUpdateCompanionBuilder,
          (
            PackLocalizationRef,
            BaseReferences<
              _$CareerSpeakDatabase,
              $PackLocalizationRefsTable,
              PackLocalizationRef
            >,
          ),
          PackLocalizationRef,
          PrefetchHooks Function()
        > {
  $$PackLocalizationRefsTableTableManager(
    _$CareerSpeakDatabase db,
    $PackLocalizationRefsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PackLocalizationRefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PackLocalizationRefsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PackLocalizationRefsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> packCode = const Value.absent(),
                Value<String> variantKey = const Value.absent(),
                Value<int> packRevision = const Value.absent(),
                Value<String> contentCode = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<int> contentRevision = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<int> localizationRevision = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PackLocalizationRefsCompanion(
                packCode: packCode,
                variantKey: variantKey,
                packRevision: packRevision,
                contentCode: contentCode,
                contentType: contentType,
                contentRevision: contentRevision,
                locale: locale,
                localizationRevision: localizationRevision,
                checksum: checksum,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String packCode,
                required String variantKey,
                required int packRevision,
                required String contentCode,
                required String contentType,
                required int contentRevision,
                required String locale,
                required int localizationRevision,
                required String checksum,
                Value<int> rowid = const Value.absent(),
              }) => PackLocalizationRefsCompanion.insert(
                packCode: packCode,
                variantKey: variantKey,
                packRevision: packRevision,
                contentCode: contentCode,
                contentType: contentType,
                contentRevision: contentRevision,
                locale: locale,
                localizationRevision: localizationRevision,
                checksum: checksum,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PackLocalizationRefsTable, PackLocalizationRef>(
                    table,
                  ),
                  BaseReferences<
                    _$CareerSpeakDatabase,
                    $PackLocalizationRefsTable,
                    PackLocalizationRef
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PackLocalizationRefsTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $PackLocalizationRefsTable,
      PackLocalizationRef,
      $$PackLocalizationRefsTableFilterComposer,
      $$PackLocalizationRefsTableOrderingComposer,
      $$PackLocalizationRefsTableAnnotationComposer,
      $$PackLocalizationRefsTableCreateCompanionBuilder,
      $$PackLocalizationRefsTableUpdateCompanionBuilder,
      (
        PackLocalizationRef,
        BaseReferences<
          _$CareerSpeakDatabase,
          $PackLocalizationRefsTable,
          PackLocalizationRef
        >,
      ),
      PackLocalizationRef,
      PrefetchHooks Function()
    >;
typedef $$AssetCatalogTableCreateCompanionBuilder =
    AssetCatalogCompanion Function({
      required String assetId,
      required String checksumSha256,
      required String assetKind,
      required String mimeType,
      required int sizeBytes,
      Value<int?> durationMs,
      required String deliveryKey,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AssetCatalogTableUpdateCompanionBuilder =
    AssetCatalogCompanion Function({
      Value<String> assetId,
      Value<String> checksumSha256,
      Value<String> assetKind,
      Value<String> mimeType,
      Value<int> sizeBytes,
      Value<int?> durationMs,
      Value<String> deliveryKey,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AssetCatalogTableReferences
    extends
        BaseReferences<
          _$CareerSpeakDatabase,
          $AssetCatalogTable,
          AssetCatalogData
        > {
  $$AssetCatalogTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ContentAssetRefsTable, List<ContentAssetRef>>
  _contentAssetRefsRefsTable(_$CareerSpeakDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.contentAssetRefs,
        aliasName: 'asset_catalog__asset_id__content_asset_refs__asset_id',
      );

  $$ContentAssetRefsTableProcessedTableManager get contentAssetRefsRefs {
    final manager =
        $$ContentAssetRefsTableTableManager($_db, $_db.contentAssetRefs).filter(
          (f) => f.assetId.assetId.sqlEquals($_itemColumn<String>('asset_id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _contentAssetRefsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PackAssetRefsTable, List<PackAssetRef>>
  _packAssetRefsRefsTable(_$CareerSpeakDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.packAssetRefs,
        aliasName: 'asset_catalog__asset_id__pack_asset_refs__asset_id',
      );

  $$PackAssetRefsTableProcessedTableManager get packAssetRefsRefs {
    final manager = $$PackAssetRefsTableTableManager($_db, $_db.packAssetRefs)
        .filter(
          (f) => f.assetId.assetId.sqlEquals($_itemColumn<String>('asset_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_packAssetRefsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AssetCatalogTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $AssetCatalogTable> {
  $$AssetCatalogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksumSha256 => $composableBuilder(
    column: $table.checksumSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetKind => $composableBuilder(
    column: $table.assetKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryKey => $composableBuilder(
    column: $table.deliveryKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> contentAssetRefsRefs(
    Expression<bool> Function($$ContentAssetRefsTableFilterComposer f) f,
  ) {
    final $$ContentAssetRefsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.contentAssetRefs,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentAssetRefsTableFilterComposer(
            $db: $db,
            $table: $db.contentAssetRefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> packAssetRefsRefs(
    Expression<bool> Function($$PackAssetRefsTableFilterComposer f) f,
  ) {
    final $$PackAssetRefsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.packAssetRefs,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PackAssetRefsTableFilterComposer(
            $db: $db,
            $table: $db.packAssetRefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetCatalogTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $AssetCatalogTable> {
  $$AssetCatalogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksumSha256 => $composableBuilder(
    column: $table.checksumSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetKind => $composableBuilder(
    column: $table.assetKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryKey => $composableBuilder(
    column: $table.deliveryKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssetCatalogTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $AssetCatalogTable> {
  $$AssetCatalogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get checksumSha256 => $composableBuilder(
    column: $table.checksumSha256,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assetKind =>
      $composableBuilder(column: $table.assetKind, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryKey => $composableBuilder(
    column: $table.deliveryKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> contentAssetRefsRefs<T extends Object>(
    Expression<T> Function($$ContentAssetRefsTableAnnotationComposer a) f,
  ) {
    final $$ContentAssetRefsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.contentAssetRefs,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentAssetRefsTableAnnotationComposer(
            $db: $db,
            $table: $db.contentAssetRefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> packAssetRefsRefs<T extends Object>(
    Expression<T> Function($$PackAssetRefsTableAnnotationComposer a) f,
  ) {
    final $$PackAssetRefsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.packAssetRefs,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PackAssetRefsTableAnnotationComposer(
            $db: $db,
            $table: $db.packAssetRefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetCatalogTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $AssetCatalogTable,
          AssetCatalogData,
          $$AssetCatalogTableFilterComposer,
          $$AssetCatalogTableOrderingComposer,
          $$AssetCatalogTableAnnotationComposer,
          $$AssetCatalogTableCreateCompanionBuilder,
          $$AssetCatalogTableUpdateCompanionBuilder,
          (AssetCatalogData, $$AssetCatalogTableReferences),
          AssetCatalogData,
          PrefetchHooks Function({
            bool contentAssetRefsRefs,
            bool packAssetRefsRefs,
          })
        > {
  $$AssetCatalogTableTableManager(
    _$CareerSpeakDatabase db,
    $AssetCatalogTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetCatalogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetCatalogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetCatalogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> assetId = const Value.absent(),
                Value<String> checksumSha256 = const Value.absent(),
                Value<String> assetKind = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String> deliveryKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetCatalogCompanion(
                assetId: assetId,
                checksumSha256: checksumSha256,
                assetKind: assetKind,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                durationMs: durationMs,
                deliveryKey: deliveryKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String assetId,
                required String checksumSha256,
                required String assetKind,
                required String mimeType,
                required int sizeBytes,
                Value<int?> durationMs = const Value.absent(),
                required String deliveryKey,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AssetCatalogCompanion.insert(
                assetId: assetId,
                checksumSha256: checksumSha256,
                assetKind: assetKind,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                durationMs: durationMs,
                deliveryKey: deliveryKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AssetCatalogTable, AssetCatalogData>(table),
                  $$AssetCatalogTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({contentAssetRefsRefs = false, packAssetRefsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (contentAssetRefsRefs) db.contentAssetRefs,
                    if (packAssetRefsRefs) db.packAssetRefs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (contentAssetRefsRefs)
                        await $_getPrefetchedDataByColumns<
                          AssetCatalogData,
                          $AssetCatalogTable,
                          ContentAssetRef,
                          $ContentAssetRefsTable
                        >(
                          currentTable: table,
                          referencedTable: $$AssetCatalogTableReferences
                              ._contentAssetRefsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetCatalogTableReferences(
                                db,
                                table,
                                p0,
                              ).contentAssetRefsRefs,
                          currentColumn: 'asset_id',
                          referencedColumn: 'asset_id',
                          typedResults: items,
                        ),
                      if (packAssetRefsRefs)
                        await $_getPrefetchedDataByColumns<
                          AssetCatalogData,
                          $AssetCatalogTable,
                          PackAssetRef,
                          $PackAssetRefsTable
                        >(
                          currentTable: table,
                          referencedTable: $$AssetCatalogTableReferences
                              ._packAssetRefsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetCatalogTableReferences(
                                db,
                                table,
                                p0,
                              ).packAssetRefsRefs,
                          currentColumn: 'asset_id',
                          referencedColumn: 'asset_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AssetCatalogTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $AssetCatalogTable,
      AssetCatalogData,
      $$AssetCatalogTableFilterComposer,
      $$AssetCatalogTableOrderingComposer,
      $$AssetCatalogTableAnnotationComposer,
      $$AssetCatalogTableCreateCompanionBuilder,
      $$AssetCatalogTableUpdateCompanionBuilder,
      (AssetCatalogData, $$AssetCatalogTableReferences),
      AssetCatalogData,
      PrefetchHooks Function({
        bool contentAssetRefsRefs,
        bool packAssetRefsRefs,
      })
    >;
typedef $$ContentAssetRefsTableCreateCompanionBuilder =
    ContentAssetRefsCompanion Function({
      required String contentCode,
      required String contentType,
      required int contentRevision,
      required String assetId,
      required String assetRole,
      Value<bool> requiredOffline,
      Value<int> rowid,
    });
typedef $$ContentAssetRefsTableUpdateCompanionBuilder =
    ContentAssetRefsCompanion Function({
      Value<String> contentCode,
      Value<String> contentType,
      Value<int> contentRevision,
      Value<String> assetId,
      Value<String> assetRole,
      Value<bool> requiredOffline,
      Value<int> rowid,
    });

final class $$ContentAssetRefsTableReferences
    extends
        BaseReferences<
          _$CareerSpeakDatabase,
          $ContentAssetRefsTable,
          ContentAssetRef
        > {
  $$ContentAssetRefsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AssetCatalogTable _assetIdTable(_$CareerSpeakDatabase db) => db
      .assetCatalog
      .createAlias('content_asset_refs__asset_id__asset_catalog__asset_id');

  $$AssetCatalogTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<String>('asset_id')!;

    final manager = $$AssetCatalogTableTableManager(
      $_db,
      $_db.assetCatalog,
    ).filter((f) => f.assetId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ContentAssetRefsTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $ContentAssetRefsTable> {
  $$ContentAssetRefsTableFilterComposer({
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

  ColumnFilters<int> get contentRevision => $composableBuilder(
    column: $table.contentRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetRole => $composableBuilder(
    column: $table.assetRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get requiredOffline => $composableBuilder(
    column: $table.requiredOffline,
    builder: (column) => ColumnFilters(column),
  );

  $$AssetCatalogTableFilterComposer get assetId {
    final $$AssetCatalogTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assetCatalog,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetCatalogTableFilterComposer(
            $db: $db,
            $table: $db.assetCatalog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContentAssetRefsTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $ContentAssetRefsTable> {
  $$ContentAssetRefsTableOrderingComposer({
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

  ColumnOrderings<int> get contentRevision => $composableBuilder(
    column: $table.contentRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetRole => $composableBuilder(
    column: $table.assetRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get requiredOffline => $composableBuilder(
    column: $table.requiredOffline,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetCatalogTableOrderingComposer get assetId {
    final $$AssetCatalogTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assetCatalog,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetCatalogTableOrderingComposer(
            $db: $db,
            $table: $db.assetCatalog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContentAssetRefsTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $ContentAssetRefsTable> {
  $$ContentAssetRefsTableAnnotationComposer({
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

  GeneratedColumn<int> get contentRevision => $composableBuilder(
    column: $table.contentRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assetRole =>
      $composableBuilder(column: $table.assetRole, builder: (column) => column);

  GeneratedColumn<bool> get requiredOffline => $composableBuilder(
    column: $table.requiredOffline,
    builder: (column) => column,
  );

  $$AssetCatalogTableAnnotationComposer get assetId {
    final $$AssetCatalogTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assetCatalog,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetCatalogTableAnnotationComposer(
            $db: $db,
            $table: $db.assetCatalog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContentAssetRefsTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $ContentAssetRefsTable,
          ContentAssetRef,
          $$ContentAssetRefsTableFilterComposer,
          $$ContentAssetRefsTableOrderingComposer,
          $$ContentAssetRefsTableAnnotationComposer,
          $$ContentAssetRefsTableCreateCompanionBuilder,
          $$ContentAssetRefsTableUpdateCompanionBuilder,
          (ContentAssetRef, $$ContentAssetRefsTableReferences),
          ContentAssetRef,
          PrefetchHooks Function({bool assetId})
        > {
  $$ContentAssetRefsTableTableManager(
    _$CareerSpeakDatabase db,
    $ContentAssetRefsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentAssetRefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentAssetRefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentAssetRefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> contentCode = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<int> contentRevision = const Value.absent(),
                Value<String> assetId = const Value.absent(),
                Value<String> assetRole = const Value.absent(),
                Value<bool> requiredOffline = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentAssetRefsCompanion(
                contentCode: contentCode,
                contentType: contentType,
                contentRevision: contentRevision,
                assetId: assetId,
                assetRole: assetRole,
                requiredOffline: requiredOffline,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contentCode,
                required String contentType,
                required int contentRevision,
                required String assetId,
                required String assetRole,
                Value<bool> requiredOffline = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentAssetRefsCompanion.insert(
                contentCode: contentCode,
                contentType: contentType,
                contentRevision: contentRevision,
                assetId: assetId,
                assetRole: assetRole,
                requiredOffline: requiredOffline,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContentAssetRefsTable, ContentAssetRef>(table),
                  $$ContentAssetRefsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (assetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assetId,
                                referencedTable:
                                    $$ContentAssetRefsTableReferences
                                        ._assetIdTable(db),
                                referencedColumn:
                                    $$ContentAssetRefsTableReferences
                                        ._assetIdTable(db)
                                        .assetId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ContentAssetRefsTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $ContentAssetRefsTable,
      ContentAssetRef,
      $$ContentAssetRefsTableFilterComposer,
      $$ContentAssetRefsTableOrderingComposer,
      $$ContentAssetRefsTableAnnotationComposer,
      $$ContentAssetRefsTableCreateCompanionBuilder,
      $$ContentAssetRefsTableUpdateCompanionBuilder,
      (ContentAssetRef, $$ContentAssetRefsTableReferences),
      ContentAssetRef,
      PrefetchHooks Function({bool assetId})
    >;
typedef $$PackAssetRefsTableCreateCompanionBuilder =
    PackAssetRefsCompanion Function({
      required String packCode,
      required String variantKey,
      required int packRevision,
      required String assetId,
      Value<bool> requiredOffline,
      Value<int> rowid,
    });
typedef $$PackAssetRefsTableUpdateCompanionBuilder =
    PackAssetRefsCompanion Function({
      Value<String> packCode,
      Value<String> variantKey,
      Value<int> packRevision,
      Value<String> assetId,
      Value<bool> requiredOffline,
      Value<int> rowid,
    });

final class $$PackAssetRefsTableReferences
    extends
        BaseReferences<
          _$CareerSpeakDatabase,
          $PackAssetRefsTable,
          PackAssetRef
        > {
  $$PackAssetRefsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AssetCatalogTable _assetIdTable(_$CareerSpeakDatabase db) => db
      .assetCatalog
      .createAlias('pack_asset_refs__asset_id__asset_catalog__asset_id');

  $$AssetCatalogTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<String>('asset_id')!;

    final manager = $$AssetCatalogTableTableManager(
      $_db,
      $_db.assetCatalog,
    ).filter((f) => f.assetId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PackAssetRefsTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $PackAssetRefsTable> {
  $$PackAssetRefsTableFilterComposer({
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

  ColumnFilters<int> get packRevision => $composableBuilder(
    column: $table.packRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get requiredOffline => $composableBuilder(
    column: $table.requiredOffline,
    builder: (column) => ColumnFilters(column),
  );

  $$AssetCatalogTableFilterComposer get assetId {
    final $$AssetCatalogTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assetCatalog,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetCatalogTableFilterComposer(
            $db: $db,
            $table: $db.assetCatalog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PackAssetRefsTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $PackAssetRefsTable> {
  $$PackAssetRefsTableOrderingComposer({
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

  ColumnOrderings<int> get packRevision => $composableBuilder(
    column: $table.packRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get requiredOffline => $composableBuilder(
    column: $table.requiredOffline,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetCatalogTableOrderingComposer get assetId {
    final $$AssetCatalogTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assetCatalog,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetCatalogTableOrderingComposer(
            $db: $db,
            $table: $db.assetCatalog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PackAssetRefsTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $PackAssetRefsTable> {
  $$PackAssetRefsTableAnnotationComposer({
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

  GeneratedColumn<int> get packRevision => $composableBuilder(
    column: $table.packRevision,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get requiredOffline => $composableBuilder(
    column: $table.requiredOffline,
    builder: (column) => column,
  );

  $$AssetCatalogTableAnnotationComposer get assetId {
    final $$AssetCatalogTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assetCatalog,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetCatalogTableAnnotationComposer(
            $db: $db,
            $table: $db.assetCatalog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PackAssetRefsTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $PackAssetRefsTable,
          PackAssetRef,
          $$PackAssetRefsTableFilterComposer,
          $$PackAssetRefsTableOrderingComposer,
          $$PackAssetRefsTableAnnotationComposer,
          $$PackAssetRefsTableCreateCompanionBuilder,
          $$PackAssetRefsTableUpdateCompanionBuilder,
          (PackAssetRef, $$PackAssetRefsTableReferences),
          PackAssetRef,
          PrefetchHooks Function({bool assetId})
        > {
  $$PackAssetRefsTableTableManager(
    _$CareerSpeakDatabase db,
    $PackAssetRefsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PackAssetRefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PackAssetRefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PackAssetRefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> packCode = const Value.absent(),
                Value<String> variantKey = const Value.absent(),
                Value<int> packRevision = const Value.absent(),
                Value<String> assetId = const Value.absent(),
                Value<bool> requiredOffline = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PackAssetRefsCompanion(
                packCode: packCode,
                variantKey: variantKey,
                packRevision: packRevision,
                assetId: assetId,
                requiredOffline: requiredOffline,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String packCode,
                required String variantKey,
                required int packRevision,
                required String assetId,
                Value<bool> requiredOffline = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PackAssetRefsCompanion.insert(
                packCode: packCode,
                variantKey: variantKey,
                packRevision: packRevision,
                assetId: assetId,
                requiredOffline: requiredOffline,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PackAssetRefsTable, PackAssetRef>(table),
                  $$PackAssetRefsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (assetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assetId,
                                referencedTable: $$PackAssetRefsTableReferences
                                    ._assetIdTable(db),
                                referencedColumn: $$PackAssetRefsTableReferences
                                    ._assetIdTable(db)
                                    .assetId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PackAssetRefsTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $PackAssetRefsTable,
      PackAssetRef,
      $$PackAssetRefsTableFilterComposer,
      $$PackAssetRefsTableOrderingComposer,
      $$PackAssetRefsTableAnnotationComposer,
      $$PackAssetRefsTableCreateCompanionBuilder,
      $$PackAssetRefsTableUpdateCompanionBuilder,
      (PackAssetRef, $$PackAssetRefsTableReferences),
      PackAssetRef,
      PrefetchHooks Function({bool assetId})
    >;
typedef $$ContentCatalogReadsTableCreateCompanionBuilder =
    ContentCatalogReadsCompanion Function({
      required String contentCode,
      required String contentType,
      required int revision,
      required String checksum,
      required String title,
      required String subtitle,
      required String description,
      required String category,
      required String level,
      required int minutes,
      required bool hasAudio,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ContentCatalogReadsTableUpdateCompanionBuilder =
    ContentCatalogReadsCompanion Function({
      Value<String> contentCode,
      Value<String> contentType,
      Value<int> revision,
      Value<String> checksum,
      Value<String> title,
      Value<String> subtitle,
      Value<String> description,
      Value<String> category,
      Value<String> level,
      Value<int> minutes,
      Value<bool> hasAudio,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ContentCatalogReadsTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $ContentCatalogReadsTable> {
  $$ContentCatalogReadsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasAudio => $composableBuilder(
    column: $table.hasAudio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContentCatalogReadsTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $ContentCatalogReadsTable> {
  $$ContentCatalogReadsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasAudio => $composableBuilder(
    column: $table.hasAudio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentCatalogReadsTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $ContentCatalogReadsTable> {
  $$ContentCatalogReadsTableAnnotationComposer({
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

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<bool> get hasAudio =>
      $composableBuilder(column: $table.hasAudio, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ContentCatalogReadsTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $ContentCatalogReadsTable,
          ContentCatalogRead,
          $$ContentCatalogReadsTableFilterComposer,
          $$ContentCatalogReadsTableOrderingComposer,
          $$ContentCatalogReadsTableAnnotationComposer,
          $$ContentCatalogReadsTableCreateCompanionBuilder,
          $$ContentCatalogReadsTableUpdateCompanionBuilder,
          (
            ContentCatalogRead,
            BaseReferences<
              _$CareerSpeakDatabase,
              $ContentCatalogReadsTable,
              ContentCatalogRead
            >,
          ),
          ContentCatalogRead,
          PrefetchHooks Function()
        > {
  $$ContentCatalogReadsTableTableManager(
    _$CareerSpeakDatabase db,
    $ContentCatalogReadsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentCatalogReadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentCatalogReadsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ContentCatalogReadsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> contentCode = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> subtitle = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<bool> hasAudio = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentCatalogReadsCompanion(
                contentCode: contentCode,
                contentType: contentType,
                revision: revision,
                checksum: checksum,
                title: title,
                subtitle: subtitle,
                description: description,
                category: category,
                level: level,
                minutes: minutes,
                hasAudio: hasAudio,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contentCode,
                required String contentType,
                required int revision,
                required String checksum,
                required String title,
                required String subtitle,
                required String description,
                required String category,
                required String level,
                required int minutes,
                required bool hasAudio,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ContentCatalogReadsCompanion.insert(
                contentCode: contentCode,
                contentType: contentType,
                revision: revision,
                checksum: checksum,
                title: title,
                subtitle: subtitle,
                description: description,
                category: category,
                level: level,
                minutes: minutes,
                hasAudio: hasAudio,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContentCatalogReadsTable, ContentCatalogRead>(
                    table,
                  ),
                  BaseReferences<
                    _$CareerSpeakDatabase,
                    $ContentCatalogReadsTable,
                    ContentCatalogRead
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentCatalogReadsTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $ContentCatalogReadsTable,
      ContentCatalogRead,
      $$ContentCatalogReadsTableFilterComposer,
      $$ContentCatalogReadsTableOrderingComposer,
      $$ContentCatalogReadsTableAnnotationComposer,
      $$ContentCatalogReadsTableCreateCompanionBuilder,
      $$ContentCatalogReadsTableUpdateCompanionBuilder,
      (
        ContentCatalogRead,
        BaseReferences<
          _$CareerSpeakDatabase,
          $ContentCatalogReadsTable,
          ContentCatalogRead
        >,
      ),
      ContentCatalogRead,
      PrefetchHooks Function()
    >;
typedef $$LocalizedContentReadsTableCreateCompanionBuilder =
    LocalizedContentReadsCompanion Function({
      required String contentCode,
      required String contentType,
      required int contentRevision,
      required String locale,
      required int localizationRevision,
      required String checksum,
      Value<String?> title,
      Value<String?> subtitle,
      Value<String?> description,
      Value<String?> translation,
      Value<String?> hint,
      Value<String?> explanation,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalizedContentReadsTableUpdateCompanionBuilder =
    LocalizedContentReadsCompanion Function({
      Value<String> contentCode,
      Value<String> contentType,
      Value<int> contentRevision,
      Value<String> locale,
      Value<int> localizationRevision,
      Value<String> checksum,
      Value<String?> title,
      Value<String?> subtitle,
      Value<String?> description,
      Value<String?> translation,
      Value<String?> hint,
      Value<String?> explanation,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalizedContentReadsTableFilterComposer
    extends Composer<_$CareerSpeakDatabase, $LocalizedContentReadsTable> {
  $$LocalizedContentReadsTableFilterComposer({
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

  ColumnFilters<int> get contentRevision => $composableBuilder(
    column: $table.contentRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localizationRevision => $composableBuilder(
    column: $table.localizationRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hint => $composableBuilder(
    column: $table.hint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalizedContentReadsTableOrderingComposer
    extends Composer<_$CareerSpeakDatabase, $LocalizedContentReadsTable> {
  $$LocalizedContentReadsTableOrderingComposer({
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

  ColumnOrderings<int> get contentRevision => $composableBuilder(
    column: $table.contentRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localizationRevision => $composableBuilder(
    column: $table.localizationRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hint => $composableBuilder(
    column: $table.hint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalizedContentReadsTableAnnotationComposer
    extends Composer<_$CareerSpeakDatabase, $LocalizedContentReadsTable> {
  $$LocalizedContentReadsTableAnnotationComposer({
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

  GeneratedColumn<int> get contentRevision => $composableBuilder(
    column: $table.contentRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<int> get localizationRevision => $composableBuilder(
    column: $table.localizationRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hint =>
      $composableBuilder(column: $table.hint, builder: (column) => column);

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalizedContentReadsTableTableManager
    extends
        RootTableManager<
          _$CareerSpeakDatabase,
          $LocalizedContentReadsTable,
          LocalizedContentRead,
          $$LocalizedContentReadsTableFilterComposer,
          $$LocalizedContentReadsTableOrderingComposer,
          $$LocalizedContentReadsTableAnnotationComposer,
          $$LocalizedContentReadsTableCreateCompanionBuilder,
          $$LocalizedContentReadsTableUpdateCompanionBuilder,
          (
            LocalizedContentRead,
            BaseReferences<
              _$CareerSpeakDatabase,
              $LocalizedContentReadsTable,
              LocalizedContentRead
            >,
          ),
          LocalizedContentRead,
          PrefetchHooks Function()
        > {
  $$LocalizedContentReadsTableTableManager(
    _$CareerSpeakDatabase db,
    $LocalizedContentReadsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalizedContentReadsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalizedContentReadsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalizedContentReadsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> contentCode = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<int> contentRevision = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<int> localizationRevision = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> translation = const Value.absent(),
                Value<String?> hint = const Value.absent(),
                Value<String?> explanation = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalizedContentReadsCompanion(
                contentCode: contentCode,
                contentType: contentType,
                contentRevision: contentRevision,
                locale: locale,
                localizationRevision: localizationRevision,
                checksum: checksum,
                title: title,
                subtitle: subtitle,
                description: description,
                translation: translation,
                hint: hint,
                explanation: explanation,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contentCode,
                required String contentType,
                required int contentRevision,
                required String locale,
                required int localizationRevision,
                required String checksum,
                Value<String?> title = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> translation = const Value.absent(),
                Value<String?> hint = const Value.absent(),
                Value<String?> explanation = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalizedContentReadsCompanion.insert(
                contentCode: contentCode,
                contentType: contentType,
                contentRevision: contentRevision,
                locale: locale,
                localizationRevision: localizationRevision,
                checksum: checksum,
                title: title,
                subtitle: subtitle,
                description: description,
                translation: translation,
                hint: hint,
                explanation: explanation,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalizedContentReadsTable,
                    LocalizedContentRead
                  >(table),
                  BaseReferences<
                    _$CareerSpeakDatabase,
                    $LocalizedContentReadsTable,
                    LocalizedContentRead
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalizedContentReadsTableProcessedTableManager =
    ProcessedTableManager<
      _$CareerSpeakDatabase,
      $LocalizedContentReadsTable,
      LocalizedContentRead,
      $$LocalizedContentReadsTableFilterComposer,
      $$LocalizedContentReadsTableOrderingComposer,
      $$LocalizedContentReadsTableAnnotationComposer,
      $$LocalizedContentReadsTableCreateCompanionBuilder,
      $$LocalizedContentReadsTableUpdateCompanionBuilder,
      (
        LocalizedContentRead,
        BaseReferences<
          _$CareerSpeakDatabase,
          $LocalizedContentReadsTable,
          LocalizedContentRead
        >,
      ),
      LocalizedContentRead,
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
  $$SyncRunsTableTableManager get syncRuns =>
      $$SyncRunsTableTableManager(_db, _db.syncRuns);
  $$SyncPackUpdatesTableTableManager get syncPackUpdates =>
      $$SyncPackUpdatesTableTableManager(_db, _db.syncPackUpdates);
  $$SyncTombstonesTableTableManager get syncTombstones =>
      $$SyncTombstonesTableTableManager(_db, _db.syncTombstones);
  $$ContentPackRevisionsTableTableManager get contentPackRevisions =>
      $$ContentPackRevisionsTableTableManager(_db, _db.contentPackRevisions);
  $$LocalContentRecordsTableTableManager get localContentRecords =>
      $$LocalContentRecordsTableTableManager(_db, _db.localContentRecords);
  $$PackContentRefsTableTableManager get packContentRefs =>
      $$PackContentRefsTableTableManager(_db, _db.packContentRefs);
  $$PackLocalizationRefsTableTableManager get packLocalizationRefs =>
      $$PackLocalizationRefsTableTableManager(_db, _db.packLocalizationRefs);
  $$AssetCatalogTableTableManager get assetCatalog =>
      $$AssetCatalogTableTableManager(_db, _db.assetCatalog);
  $$ContentAssetRefsTableTableManager get contentAssetRefs =>
      $$ContentAssetRefsTableTableManager(_db, _db.contentAssetRefs);
  $$PackAssetRefsTableTableManager get packAssetRefs =>
      $$PackAssetRefsTableTableManager(_db, _db.packAssetRefs);
  $$ContentCatalogReadsTableTableManager get contentCatalogReads =>
      $$ContentCatalogReadsTableTableManager(_db, _db.contentCatalogReads);
  $$LocalizedContentReadsTableTableManager get localizedContentReads =>
      $$LocalizedContentReadsTableTableManager(_db, _db.localizedContentReads);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$ContentLearningStatesTableTableManager get contentLearningStates =>
      $$ContentLearningStatesTableTableManager(_db, _db.contentLearningStates);
}
