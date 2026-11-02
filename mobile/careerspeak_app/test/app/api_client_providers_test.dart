import 'package:careerspeak_app/app/api_client_providers.dart';
import 'package:careerspeak_app/app/app_preferences_providers.dart';
import 'package:careerspeak_app/app/installation_identity_providers.dart';
import 'package:careerspeak_app/application/ports/app_preferences_repository.dart';
import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/installation_auth_recovery_api_client.dart';
import 'package:careerspeak_app/data/remote/http_api_client.dart';
import 'package:careerspeak_app/domain/application_preferences.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        appPreferencesRepositoryProvider.overrideWithValue(
          const _TestPreferencesRepository(),
        ),
        installationCredentialStoreProvider.overrideWithValue(
          _MemoryInstallationCredentialStore(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('raw API composition selects the production HTTP transport', () {
    final container = createContainer();

    expect(container.read(rawApiClientProvider), isA<HttpApiClient>());
  });

  test('learner API composition wraps raw transport with auth recovery', () {
    final container = createContainer();

    expect(
      container.read(apiClientProvider),
      isA<InstallationAuthRecoveryApiClient>(),
    );
  });

  test('default API base URL is deliberately non-routable', () {
    final container = createContainer();

    expect(container.read(apiBaseUriProvider).host, 'api.careerspeak.invalid');
  });
}

final class _TestPreferencesRepository implements AppPreferencesRepository {
  const _TestPreferencesRepository();

  @override
  Stream<Result<ApplicationPreferences>> watchPreferences() =>
      Stream<Result<ApplicationPreferences>>.value(
        const Success<ApplicationPreferences>(ApplicationPreferences.defaults),
      );

  @override
  Future<Result<ApplicationPreferences>> getPreferences() async =>
      const Success<ApplicationPreferences>(ApplicationPreferences.defaults);

  @override
  Future<Result<void>> setLocaleSelection({
    required String countryCode,
    required AppTranslationLocale locale,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> setUiLocale(AppUiLocale locale) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> setTranslationLocale(
    AppTranslationLocale locale,
  ) async => const Success<void>(null);

  @override
  Future<Result<void>> setPreferredAccent(
    PreferredEnglishAccent? accent,
  ) async => const Success<void>(null);

  @override
  Future<Result<void>> setTheme(AppThemePreference theme) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> setFocusMode(bool enabled) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> setStorageQuotaBytes(int? bytes) async =>
      const Success<void>(null);
}

final class _MemoryInstallationCredentialStore
    implements InstallationCredentialStore {
  InstallationId? _installationId;
  InstallationToken? _installationToken;

  @override
  Future<InstallationId?> readInstallationId() async => _installationId;

  @override
  Future<void> writeInstallationId(InstallationId installationId) async {
    _installationId = installationId;
  }

  @override
  Future<InstallationToken?> readInstallationToken() async => _installationToken;

  @override
  Future<void> writeInstallationToken(InstallationToken installationToken) async {
    _installationToken = installationToken;
  }

  @override
  Future<void> clearInstallationToken() async {
    _installationToken = null;
  }

  @override
  Future<void> clear() async {
    _installationId = null;
    _installationToken = null;
  }
}
