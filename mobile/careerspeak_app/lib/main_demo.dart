import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'app/app_configuration.dart';
import 'app/locale_configuration_providers.dart';
import 'app/application_bootstrap_providers.dart';
import 'app/app_preferences_providers.dart';
import 'domain/application_preferences.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'app/learner_state_providers.dart';
import 'app/installation_identity_providers.dart';
import 'app/asset_download_providers.dart';
import 'data/local/database/careerspeak_database.dart';
import 'data/mock/demo_runtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/careerspeak_app.dart';
import 'app/catalogue_source_providers.dart';
import 'application/ports/installation_registration_gateway.dart';
import 'application/result/result.dart';
import 'domain/catalogue_source_mode.dart';
import 'domain/installation_credentials.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kDebugMode) throw StateError('Demo requires a debug build');
  final container = ProviderContainer(
    overrides: [
      localeConfigurationGatewayProvider.overrideWithValue(DemoLocaleConfigurationGateway()),
      appConfigurationProvider.overrideWithValue(
        AppConfiguration.fromBuildValues(
          releaseMode: false,
          appEnvironment: 'development',
          apiBaseUrl: 'http://127.0.0.1:18081',
          mockBilling: 'true',
          mockPurchaseVerification: 'true',
        ),
      ),
      careerSpeakDatabaseProvider.overrideWith((ref) {
        final database = CareerSpeakDatabase(
          driftDatabase(name: 'voxprep_full_demo_v2'),
        );
        ref.onDispose(database.close);
        return database;
      }),
      installationCredentialStoreProvider.overrideWithValue(
        DemoCredentialStore(),
      ),
      assetByteSourceProvider.overrideWithValue(DemoAssetByteSource()),
      catalogueSourceModeProvider.overrideWith(
        () => CatalogueSourceModeNotifier(CatalogueSourceMode.demo),
      ),
      installationRegistrationGatewayProvider.overrideWithValue(
        const _DemoInstallationRegistrationGateway(),
      ),
    ],
  );
  final preferences = container.read(appPreferencesRepositoryProvider);
  final initialPreferences = (await preferences.getPreferences()).getOrThrow();
  if (initialPreferences.needsLocaleOnboarding) {
    (await preferences.setLocaleSelection(
      countryCode: 'US',
      locale: AppTranslationLocale('en'),
    )).getOrThrow();
  }
  final result = await container.read(applicationBootstrapProvider.future);
  if (result case FailureResult(:final failure)) {
    debugPrint(
      'DEMO_BOOTSTRAP_FAILED ${failure.code}: ${failure.message} ${failure.details}',
    );
  } else {
    debugPrint('DEMO_BOOTSTRAP_READY');
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CareerSpeakApp(bootstrapEnabled: true),
    ),
  );
}

final class _DemoInstallationRegistrationGateway
    implements InstallationRegistrationGateway {
  const _DemoInstallationRegistrationGateway();

  @override
  Future<Result<InstallationToken>> register(
    InstallationId installationId,
  ) async {
    return Success<InstallationToken>(
      InstallationToken('demo-installation-token'),
    );
  }
}
