import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app/application_bootstrap_providers.dart';
import 'app/careerspeak_app.dart';
import 'app/catalogue_source_providers.dart';
import 'application/result/result.dart';
import 'data/local/secure_catalogue_source_preference_repository.dart';
import 'domain/catalogue_source_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const repository = SecureCatalogueSourcePreferenceRepository(
    FlutterSecureStorage(),
  );
  final loaded = await repository.getMode();
  final initialMode = switch (loaded) {
    Success<CatalogueSourceMode>(:final value) => value,
    FailureResult<CatalogueSourceMode>() => CatalogueSourceMode.production,
  };

  runApp(
    ProviderScope(
      overrides: [
        catalogueSourceModeProvider.overrideWith(
          () => CatalogueSourceModeNotifier(initialMode),
        ),
      ],
      child: const ProductionBootstrapHost(child: CareerSpeakApp()),
    ),
  );
}
