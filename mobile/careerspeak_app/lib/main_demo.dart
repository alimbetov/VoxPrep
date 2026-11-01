import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/api_client_providers.dart';
import 'app/careerspeak_app.dart';
import 'app/catalogue_source_providers.dart';
import 'application/ports/installation_registration_gateway.dart';
import 'application/result/result.dart';
import 'domain/catalogue_source_mode.dart';
import 'domain/installation_credentials.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      overrides: [
        catalogueSourceModeProvider.overrideWith(
          () => CatalogueSourceModeNotifier(CatalogueSourceMode.demo),
        ),
        installationRegistrationGatewayProvider.overrideWithValue(
          const _DemoInstallationRegistrationGateway(),
        ),
      ],
      child: const CareerSpeakApp(),
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
