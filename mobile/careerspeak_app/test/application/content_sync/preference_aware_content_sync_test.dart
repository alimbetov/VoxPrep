import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_coordinator.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/preference_aware_content_sync.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/app_preferences_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/domain/application_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/sync_orchestration_fakes.dart';

void main() {
  test('uses persisted translation locale for root manifest request', () async {
    final preferencesRepository = _FakePreferencesRepository(
      ApplicationPreferences.defaults.copyWith(
        translationLocale: AppTranslationLocale.kazakh,
      ),
    );
    final journal = FakeJournal(Success(emptySnapshot()));
    final gateway = FakeGateway(
      Success(
        RootManifestChanged(
          manifest: manifest(109, packs: <PackRevisionRef>[pack()]),
          etag: 'etag',
        ),
      ),
    );
    final coordinator = ContentSyncCoordinator(
      journal: journal,
      manifestGateway: gateway,
      planner: const ContentSyncPlanner(),
      executor: FakeExecutor(),
    );
    final sync = PreferenceAwareContentSync(
      preferencesRepository: preferencesRepository,
      coordinator: coordinator,
    );

    final result = await sync.synchronize(
      runId: 'run-locale',
      trigger: SyncTrigger.manual,
    );

    expect(result, isA<Success<ContentSyncOutcome>>());
    expect(gateway.translationLocales, <String>['kk']);
  });

  test('preference read failure prevents remote sync', () async {
    final preferencesRepository = _FakePreferencesRepository.failure(
      const ApplicationFailure(
        code: 'PREFERENCES_READ_FAILED',
        message: 'failed',
        retryable: true,
      ),
    );
    final gateway = FakeGateway(
      Success(RootManifestChanged(manifest: manifest(108), etag: 'etag')),
    );
    final coordinator = ContentSyncCoordinator(
      journal: FakeJournal(Success(emptySnapshot())),
      manifestGateway: gateway,
      planner: const ContentSyncPlanner(),
      executor: FakeExecutor(),
    );
    final sync = PreferenceAwareContentSync(
      preferencesRepository: preferencesRepository,
      coordinator: coordinator,
    );

    final result = await sync.synchronize(
      runId: 'run-failure',
      trigger: SyncTrigger.startup,
    );

    expect(result, isA<FailureResult<ContentSyncOutcome>>());
    expect(
      (result as FailureResult<ContentSyncOutcome>).failure.code,
      'PREFERENCES_READ_FAILED',
    );
    expect(gateway.calls, 0);
  });
}

final class _FakePreferencesRepository implements AppPreferencesRepository {
  _FakePreferencesRepository(ApplicationPreferences preferences)
    : _result = Success<ApplicationPreferences>(preferences);

  _FakePreferencesRepository.failure(ApplicationFailure failure)
    : _result = FailureResult<ApplicationPreferences>(failure);

  final Result<ApplicationPreferences> _result;

  @override
  Future<Result<ApplicationPreferences>> getPreferences() async => _result;

  @override
  Stream<Result<ApplicationPreferences>> watchPreferences() =>
      Stream<Result<ApplicationPreferences>>.value(_result);

  @override
  Future<Result<void>> setFocusMode(bool enabled) async => const Success(null);

  @override
  Future<Result<void>> setPreferredAccent(
    PreferredEnglishAccent? accent,
  ) async => const Success(null);

  @override
  Future<Result<void>> setStorageQuotaBytes(int? bytes) async =>
      const Success(null);

  @override
  Future<Result<void>> setTheme(AppThemePreference theme) async =>
      const Success(null);

  @override
  Future<Result<void>> setTranslationLocale(
    AppTranslationLocale locale,
  ) async => const Success(null);

  @override
  Future<Result<void>> setUiLocale(AppUiLocale locale) async =>
      const Success(null);
}
