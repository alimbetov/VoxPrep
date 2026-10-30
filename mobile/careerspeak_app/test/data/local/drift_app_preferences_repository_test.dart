import 'dart:io';

import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_app_preferences_repository.dart';
import 'package:careerspeak_app/domain/application_preferences.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  late CareerSpeakDatabase database;
  late DriftAppPreferencesRepository repository;

  setUp(() {
    database = createTestDatabase();
    repository = DriftAppPreferencesRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('materializes deterministic singleton defaults', () async {
    final preferences = (await repository.getPreferences()).getOrThrow();

    expect(preferences.uiLocale, AppUiLocale.english);
    expect(preferences.translationLocale, AppTranslationLocale.russian);
    expect(preferences.preferredAccent, PreferredEnglishAccent.us);
    expect(preferences.theme, AppThemePreference.system);
    expect(preferences.focusMode, isFalse);
    expect(preferences.storageQuotaBytes, isNull);

    final rows = await database.select(database.appPreferences).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, 1);
  });

  test('typed updates are reactive and idempotent', () async {
    await repository.setUiLocale(AppUiLocale.kazakh);
    await repository.setTranslationLocale(AppTranslationLocale.kazakh);
    await repository.setPreferredAccent(PreferredEnglishAccent.uk);
    await repository.setTheme(AppThemePreference.dark);
    await repository.setFocusMode(true);
    await repository.setStorageQuotaBytes(1024 * 1024);
    await repository.setTranslationLocale(AppTranslationLocale.kazakh);

    final preferences = await repository.watchPreferences().first;
    final value = preferences.getOrThrow();

    expect(value.uiLocale, AppUiLocale.kazakh);
    expect(value.translationLocale, AppTranslationLocale.kazakh);
    expect(value.preferredAccent, PreferredEnglishAccent.uk);
    expect(value.theme, AppThemePreference.dark);
    expect(value.focusMode, isTrue);
    expect(value.storageQuotaBytes, 1024 * 1024);
    expect(await database.select(database.appPreferences).get(), hasLength(1));
  });

  test('negative storage quota fails without changing stored value', () async {
    await repository.setStorageQuotaBytes(2048);

    final result = await repository.setStorageQuotaBytes(-1);

    expect(result, isA<FailureResult<void>>());
    expect((result as FailureResult<void>).failure.code, 'PREFERENCES_INVALID');
    expect(
      (await repository.getPreferences()).getOrThrow().storageQuotaBytes,
      2048,
    );
  });

  test('unsupported stored preference fails closed', () async {
    final now = DateTime.utc(2026, 10, 30, 19);
    await database.into(database.appPreferences).insert(
          AppPreferencesCompanion.insert(
            id: 1,
            uiLocale: 'unsupported',
            translationLocale: 'ru',
            preferredAccent: const Value<String?>('en-US'),
            themeCode: 'system',
            createdAt: now,
            updatedAt: now,
          ),
        );

    final result = await repository.getPreferences();

    expect(result, isA<FailureResult<ApplicationPreferences>>());
    expect(
      (result as FailureResult<ApplicationPreferences>).failure.code,
      'PREFERENCES_INVALID',
    );
  });

  test('preferences survive database close and reopen', () async {
    await database.close();

    final directory = await Directory.systemTemp.createTemp(
      'careerspeak-p2-10-4-preferences-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/careerspeak.sqlite');

    final firstDatabase = CareerSpeakDatabase(NativeDatabase(file));
    final firstRepository = DriftAppPreferencesRepository(firstDatabase);
    (await firstRepository.setUiLocale(AppUiLocale.russian)).getOrThrow();
    (await firstRepository.setTranslationLocale(AppTranslationLocale.kazakh))
        .getOrThrow();
    (await firstRepository.setPreferredAccent(PreferredEnglishAccent.australian))
        .getOrThrow();
    (await firstRepository.setTheme(AppThemePreference.light)).getOrThrow();
    await firstDatabase.close();

    final reopenedDatabase = CareerSpeakDatabase(NativeDatabase(file));
    final reopenedRepository = DriftAppPreferencesRepository(reopenedDatabase);
    final restored = (await reopenedRepository.getPreferences()).getOrThrow();

    expect(restored.uiLocale, AppUiLocale.russian);
    expect(restored.translationLocale, AppTranslationLocale.kazakh);
    expect(restored.preferredAccent, PreferredEnglishAccent.australian);
    expect(restored.theme, AppThemePreference.light);

    await reopenedDatabase.close();

    database = createTestDatabase();
    repository = DriftAppPreferencesRepository(database);
  });
}
