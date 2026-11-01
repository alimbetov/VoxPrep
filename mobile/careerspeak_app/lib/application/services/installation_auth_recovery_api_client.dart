import '../../domain/installation_credentials.dart';
import '../ports/api_client.dart';
import '../ports/installation_credential_store.dart';
import '../result/result.dart';

typedef InstallationCredentialRenewer =
    Future<Result<InstallationCredentials>> Function();

/// Adds one bounded installation-authentication recovery cycle around the
/// transport ApiClient.
///
/// Anonymous requests are never recovered. Authenticated requests are retried
/// at most once after a successful token renewal. Parallel 401 responses are
/// coalesced, and a request that observes a token already rotated by another
/// request simply retries with the new token instead of rotating again.
final class InstallationAuthRecoveryApiClient implements ApiClient {
  const InstallationAuthRecoveryApiClient({
    required ApiClient delegate,
    required InstallationCredentialStore credentialStore,
    required InstallationCredentialRenewer renewCredentials,
  }) : _delegate = delegate,
       _credentialStore = credentialStore,
       _renewCredentials = renewCredentials;

  final ApiClient _delegate;
  final InstallationCredentialStore _credentialStore;
  final InstallationCredentialRenewer _renewCredentials;

  static Future<Result<InstallationCredentials>>? _sharedRecovery;

  @override
  Future<Result<ApiResponse>> send(ApiRequest request) async {
    if (request.authentication != ApiAuthentication.installation) {
      return _delegate.send(request);
    }

    final InstallationToken? tokenBefore;
    try {
      tokenBefore = await _credentialStore.readInstallationToken();
    } on Object {
      return const FailureResult<ApiResponse>(
        ApplicationFailure(
          code: 'CREDENTIAL_STORE_ERROR',
          message: 'Installation credential could not be read.',
        ),
      );
    }

    final first = await _delegate.send(request);
    if (!_isUnauthorized(first) || tokenBefore == null) {
      return first;
    }

    final InstallationToken? currentToken;
    try {
      currentToken = await _credentialStore.readInstallationToken();
    } on Object {
      return const FailureResult<ApiResponse>(
        ApplicationFailure(
          code: 'CREDENTIAL_STORE_ERROR',
          message: 'Installation credential could not be read.',
        ),
      );
    }

    if (currentToken == null || currentToken == tokenBefore) {
      final renewed = await _recoverSingleFlight();
      if (renewed case FailureResult<InstallationCredentials>(:final failure)) {
        return FailureResult<ApiResponse>(failure);
      }
    }

    // Deliberately call the delegate directly: the replay gets no second
    // recovery cycle. A repeated 401 is returned fail-closed to the caller.
    return _delegate.send(request);
  }

  Future<Result<InstallationCredentials>> _recoverSingleFlight() {
    final existing = _sharedRecovery;
    if (existing != null) return existing;

    final operation = _renewCredentials();
    _sharedRecovery = operation;
    operation.whenComplete(() {
      if (identical(_sharedRecovery, operation)) {
        _sharedRecovery = null;
      }
    });
    return operation;
  }

  static bool _isUnauthorized(Result<ApiResponse> result) =>
      result case FailureResult<ApiResponse>(
        failure: ApplicationFailure(code: 'UNAUTHORIZED'),
      );
}
