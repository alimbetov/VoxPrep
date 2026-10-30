import '../../domain/installation_credentials.dart';
import '../ports/installation_registration_gateway.dart';
import '../result/result.dart';
import 'installation_identity_service.dart';

final class InstallationBootstrapService {
  factory InstallationBootstrapService({
    required InstallationIdentityService identityService,
    required InstallationRegistrationGateway registrationGateway,
  }) {
    return InstallationBootstrapService._(identityService, registrationGateway);
  }

  InstallationBootstrapService._(
    this._identityService,
    this._registrationGateway,
  );

  final InstallationIdentityService _identityService;
  final InstallationRegistrationGateway _registrationGateway;

  Future<Result<InstallationCredentials>>? _inFlight;

  Future<Result<InstallationCredentials>> ensureCredentials() {
    final existing = _inFlight;
    if (existing != null) return existing;

    final operation = _ensureCredentials();
    _inFlight = operation;
    operation.whenComplete(() {
      if (identical(_inFlight, operation)) {
        _inFlight = null;
      }
    });
    return operation;
  }

  Future<Result<InstallationCredentials>> _ensureCredentials() async {
    try {
      final existing = await _identityService.readCredentials();
      if (existing != null) {
        return Success(existing);
      }

      final installationId = await _identityService.ensureInstallationId();
      final registration = await _registrationGateway.register(installationId);
      if (registration case FailureResult<InstallationToken>(:final failure)) {
        return FailureResult(failure);
      }

      final token = (registration as Success<InstallationToken>).value;
      await _identityService.saveInstallationToken(token);
      return Success(
        InstallationCredentials(
          installationId: installationId,
          installationToken: token,
        ),
      );
    } on StateError {
      return const FailureResult(
        ApplicationFailure(
          code: 'INSTALLATION_STATE_CORRUPT',
          message: 'Installation credential state is inconsistent.',
        ),
      );
    } on Object catch (error) {
      return FailureResult(
        ApplicationFailure(
          code: 'CREDENTIAL_STORE_ERROR',
          message:
              'Installation bootstrap could not access secure credentials.',
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }
}
