// ignore_for_file: prefer_initializing_formals

import '../../domain/installation_credentials.dart';
import '../ports/api_client.dart';
import '../ports/installation_credential_store.dart';
import '../result/result.dart';

/// Fail-closed installation auth boundary.
///
/// A backend 401 proves that the Bearer token used for that request was not
/// accepted. Registration requires proof of the *current* valid Bearer token,
/// so attempting to rotate that same rejected token can never recover safely.
/// Do not silently create a new identity or try anonymous UUID registration.
///
/// Only retry the logical request if another actor has already replaced the
/// locally stored token during the in-flight request. The replay is performed
/// through the raw delegate and is never retried a second time.
final class InstallationAuthRecoveryApiClient implements ApiClient {
  const InstallationAuthRecoveryApiClient({
    required ApiClient delegate,
    required InstallationCredentialStore credentialStore,
  }) : _delegate = delegate,
       _credentialStore = credentialStore;

  final ApiClient _delegate;
  final InstallationCredentialStore _credentialStore;

  @override
  Future<Result<ApiResponse>> send(ApiRequest request) async {
    if (request.authentication != ApiAuthentication.installation) {
      return _delegate.send(request);
    }

    final InstallationToken? before;
    try {
      before = await _credentialStore.readInstallationToken();
    } on Object {
      return const FailureResult<ApiResponse>(
        ApplicationFailure(
          code: 'CREDENTIAL_STORE_ERROR',
          message: 'Installation credential could not be read.',
        ),
      );
    }

    final response = await _delegate.send(request);
    if (response is! FailureResult<ApiResponse> ||
        response.failure.code != 'UNAUTHORIZED' ||
        before == null) {
      return response;
    }

    final InstallationToken? current;
    try {
      current = await _credentialStore.readInstallationToken();
    } on Object {
      return const FailureResult<ApiResponse>(
        ApplicationFailure(
          code: 'CREDENTIAL_STORE_ERROR',
          message: 'Installation credential could not be read.',
        ),
      );
    }

    if (current == null || current == before) {
      // Preserve the stable installation identity and all offline data.
      // A genuinely revoked/rejected token is not a rotation proof.
      return response;
    }

    return _delegate.send(request);
  }
}
