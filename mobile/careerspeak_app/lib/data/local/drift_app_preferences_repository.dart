import 'package:drift/drift.dart';

import '../../application/ports/app_preferences_repository.dart';
import '../../application/result/result.dart';
import '../../domain/application_preferences.dart';
import 'database/careerspeak_database.dart';

final class DriftAppPreferencesRepository implements AppPreferencesRepository {
  const DriftAppPreferencesRepository(this._database);

  final CareerSpeakDatabase _database;

  @override
  Stream<Result<ApplicationPreferences>> watchPreferences() async* {
    final initialized = await _ensureDefaults();
    if (initialized is FailureResult<void>) {
      yield FailureResult<ApplicationPreferences>(initialized.failure);
      return;
    }

    final query = _database.select(_database.appPreferences)
      ..where((table) => table.id.equals(_singletonId));

    try {
      await for (final row in query.watchSingleOrNull()) {
        if (row == null) {
          yield FailureResult<ApplicationPreferences>(
            _invalidStoredPreferences('singleton row is missing'),
          );
          continue;
        }
        try {
          yield Success<ApplicationPreferences>(
            _mapStored(
              uiLocale: row.uiLocale,
              translationLocale: row.translationLocale,
              preferredAccent: row.preferredAccent,
              themeCode: row.themeCode,
              focusMode: row.focusMode,
              storageQuotaBytes: row.storageQuotaBytes,
            ),
          );
        } on _StoredPreferencesViolation catch (error) {
          yield FailureResult<ApplicationPreferences>(
            _invalidStoredPreferences(error.reason),
          );
        }
      }
    } on Object catch (error) {
      yield FailureResult<ApplicationPreferences>(_readFailure(error));
    }
  }

  @override
  Future<Result<ApplicationPreferences>> getPreferences() async {
    final initialized = await _ensureDefaults();
    if (initialized is FailureResult<void>) {
      return FailureResult<ApplicationPreferences>(initialized.failure);
    }

    try {
      final query = _database.select(_database.appPreferences)
        ..where((table) => table.id.equals(_singletonId));
      final row = await query.getSingleOrNull();
      if (row == null) {
        return FailureResult<ApplicationPreferences>(
          _invalidStoredPreferences('singleton row is missing'),
        );
      }
      return Success<ApplicationPreferences>(
        _mapStored(
          uiLocale: row.uiLocale,
          translationLocale: row.translationLocale,
          preferredAccent: row.preferredAccent,
          themeCode: row.themeCode,
          focusMode: row.focusMode,
          storageQuotaBytes: row.storageQuotaBytes,
        ),
      );
    } on _StoredPreferencesViolation catch (error) {
      return FailureResult<ApplicationPreferences>(
        _invalidStoredPreferences(error.reason),
      );
    } on Object catch (error) {
      return FailureResult<ApplicationPreferences>(_readFailure(error));
    }
  }

  @override
  Future<Result<void>> setUiLocale(AppUiLocale locale) {
    return _update(
      AppPreferencesCompanion(uiLocale: Value<String>(locale.code)),
    );
  }

  @override
  Future<Result<void>> setTranslationLocale(AppTranslationLocale locale) {
    return _update(
      AppPreferencesCompanion(
        translationLocale: Value<String>(locale.code),
      ),
    );
  }

  @override
  Future<Result<void>> setPreferredAccent(PreferredEnglishAccent? accent) {
    return _update(
      AppPreferencesCompanion(
        preferredAccent: Value<String?>(accent?.code),
      ),
    );
  }

  @override
  Future<Result<void>> setTheme(AppThemePreference theme) {
    return _update(
      AppPreferencesCompanion(themeCode: Value<String>(theme.code)),
    );
  }

  @override
  Future<Result<void>> setFocusMode(bool enabled) {
    return _update(
      AppPreferencesCompanion(focusMode: Value<bool>(enabled)),
    );
  }

  @override
  Future<Result<void>> setStorageQuotaBytes(int? bytes) {
    if (bytes != null && bytes < 0) {
      return Future<Result<void>>.value(
        const FailureResult<void>(
          ApplicationFailure(
            code: 'PREFERENCES_INVALID',
            message: 'Storage quota must be null or non-negative.',
          ),
        ),
      );
    }
    return _update(
      AppPreferencesCompanion(storageQuotaBytes: Value<int?>(bytes)),
    );
  }

  Future<Result<void>> _ensureDefaults() async {
    try {
      final now = DateTime.now().toUtc();
      await _database.into(_database.appPreferences).insert(
            AppPreferencesCompanion.insert(
              id: _singletonId,
              uiLocale: ApplicationPreferences.defaults.uiLocale.code,
              translationLocale:
                  ApplicationPreferences.defaults.translationLocale.code,
              preferredAccent: Value<String?>(
                ApplicationPreferences.defaults.preferredAccent?.code,
              ),
              themeCode: ApplicationPreferences.defaults.theme.code,
              focusMode: Value<bool>(ApplicationPreferences.defaults.focusMode),
              storageQuotaBytes: Value<int?>(
                ApplicationPreferences.defaults.storageQuotaBytes,
              ),
              createdAt: now,
              updatedAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(_writeFailure(error));
    }
  }

  Future<Result<void>> _update(AppPreferencesCompanion values) async {
    final initialized = await _ensureDefaults();
    if (initialized is FailureResult<void>) {
      return initialized;
    }

    try {
      final statement = _database.update(_database.appPreferences)
        ..where((table) => table.id.equals(_singletonId));
      final affected = await statement.write(
        values.copyWith(updatedAt: Value<DateTime>(DateTime.now().toUtc())),
      );
      if (affected != 1) {
        return FailureResult<void>(
          _invalidStoredPreferences('singleton update affected $affected rows'),
        );
      }
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(_writeFailure(error));
    }
  }

  ApplicationPreferences _mapStored({
    required String uiLocale,
    required String translationLocale,
    required String? preferredAccent,
    required String themeCode,
    required bool focusMode,
    required int? storageQuotaBytes,
  }) {
    final ui = AppUiLocale.fromCode(uiLocale);
    if (ui == null) {
      throw _StoredPreferencesViolation('unsupported uiLocale: $uiLocale');
    }
    final translation = AppTranslationLocale.fromCode(translationLocale);
    if (translation == null) {
      throw _StoredPreferencesViolation(
        'unsupported translationLocale: $translationLocale',
      );
    }
    final accent = PreferredEnglishAccent.fromCode(preferredAccent);
    if (preferredAccent != null && accent == null) {
      throw _StoredPreferencesViolation(
        'unsupported preferredAccent: $preferredAccent',
      );
    }
    final theme = AppThemePreference.fromCode(themeCode);
    if (theme == null) {
      throw _StoredPreferencesViolation('unsupported themeCode: $themeCode');
    }
    if (storageQuotaBytes != null && storageQuotaBytes < 0) {
      throw const _StoredPreferencesViolation(
        'storageQuotaBytes must be null or non-negative',
      );
    }

    return ApplicationPreferences(
      uiLocale: ui,
      translationLocale: translation,
      preferredAccent: accent,
      theme: theme,
      focusMode: focusMode,
      storageQuotaBytes: storageQuotaBytes,
    );
  }

  ApplicationFailure _invalidStoredPreferences(String reason) {
    return ApplicationFailure(
      code: 'PREFERENCES_INVALID',
      message: 'Stored application preferences are invalid.',
      details: <String, Object?>{'reason': reason},
    );
  }

  ApplicationFailure _readFailure(Object error) {
    return ApplicationFailure(
      code: 'PREFERENCES_READ_FAILED',
      message: 'Application preferences could not be read.',
      retryable: true,
      details: <String, Object?>{'cause': error.runtimeType.toString()},
    );
  }

  ApplicationFailure _writeFailure(Object error) {
    return ApplicationFailure(
      code: 'PREFERENCES_WRITE_FAILED',
      message: 'Application preferences could not be persisted.',
      retryable: true,
      details: <String, Object?>{'cause': error.runtimeType.toString()},
    );
  }
}

final class _StoredPreferencesViolation implements Exception {
  const _StoredPreferencesViolation(this.reason);

  final String reason;
}

const _singletonId = 1;
