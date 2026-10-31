// ignore_for_file: prefer_initializing_formals

import '../../domain/application_preferences.dart';
import '../ports/app_preferences_repository.dart';
import '../result/result.dart';
import 'content_sync_coordinator.dart';
import 'sync_models.dart';

final class PreferenceAwareContentSync {
  const PreferenceAwareContentSync({
    required AppPreferencesRepository preferencesRepository,
    required ContentSyncCoordinator coordinator,
  }) : _preferencesRepository = preferencesRepository,
       _coordinator = coordinator;

  final AppPreferencesRepository _preferencesRepository;
  final ContentSyncCoordinator _coordinator;

  Future<Result<ContentSyncOutcome>> synchronize({
    required String runId,
    required SyncTrigger trigger,
  }) async {
    final preferencesResult = await _preferencesRepository.getPreferences();
    if (preferencesResult is FailureResult<ApplicationPreferences>) {
      return FailureResult<ContentSyncOutcome>(preferencesResult.failure);
    }
    final preferences =
        (preferencesResult as Success<ApplicationPreferences>).value;

    return _coordinator.synchronize(
      runId: runId,
      trigger: trigger,
      translationLocale: preferences.translationLocale.code,
    );
  }
}
