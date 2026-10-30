import '../../domain/installation_credentials.dart';
import '../content_sync/content_sync_coordinator.dart';
import '../content_sync/preference_aware_content_sync.dart';
import '../content_sync/sync_models.dart';
import '../result/result.dart';
import 'installation_bootstrap_service.dart';

typedef StartupRunIdFactory = String Function();

final class ApplicationBootstrapOutcome {
  const ApplicationBootstrapOutcome({
    required this.credentials,
    required this.contentSyncOutcome,
  });

  final InstallationCredentials credentials;
  final ContentSyncOutcome contentSyncOutcome;
}

final class ApplicationBootstrapService {
  factory ApplicationBootstrapService({
    required InstallationBootstrapService installationBootstrapService,
    required PreferenceAwareContentSync contentSync,
    StartupRunIdFactory? runIdFactory,
  }) {
    return ApplicationBootstrapService._(
      installationBootstrapService,
      contentSync,
      runIdFactory ?? _defaultStartupRunId,
    );
  }

  ApplicationBootstrapService._(
    this._installationBootstrapService,
    this._contentSync,
    this._runIdFactory,
  );

  final InstallationBootstrapService _installationBootstrapService;
  final PreferenceAwareContentSync _contentSync;
  final StartupRunIdFactory _runIdFactory;

  Future<Result<ApplicationBootstrapOutcome>>? _inFlight;

  Future<Result<ApplicationBootstrapOutcome>> bootstrap() {
    final existing = _inFlight;
    if (existing != null) return existing;

    final operation = _bootstrap();
    _inFlight = operation;
    operation.whenComplete(() {
      if (identical(_inFlight, operation)) {
        _inFlight = null;
      }
    });
    return operation;
  }

  Future<Result<ApplicationBootstrapOutcome>> _bootstrap() async {
    final credentialsResult =
        await _installationBootstrapService.ensureCredentials();
    if (credentialsResult is FailureResult<InstallationCredentials>) {
      return FailureResult<ApplicationBootstrapOutcome>(
        credentialsResult.failure,
      );
    }
    final credentials =
        (credentialsResult as Success<InstallationCredentials>).value;

    final syncResult = await _contentSync.synchronize(
      runId: _runIdFactory(),
      trigger: SyncTrigger.startup,
    );
    if (syncResult is FailureResult<ContentSyncOutcome>) {
      return FailureResult<ApplicationBootstrapOutcome>(syncResult.failure);
    }

    return Success<ApplicationBootstrapOutcome>(
      ApplicationBootstrapOutcome(
        credentials: credentials,
        contentSyncOutcome: (syncResult as Success<ContentSyncOutcome>).value,
      ),
    );
  }
}

String _defaultStartupRunId() {
  return 'startup-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
