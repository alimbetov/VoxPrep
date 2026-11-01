import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/careerspeak_app.dart';
import 'app/catalogue_source_providers.dart';
import 'domain/catalogue_source_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      overrides: [
        catalogueSourceModeProvider.overrideWith(
          () => CatalogueSourceModeNotifier(CatalogueSourceMode.production),
        ),
      ],
      child: const CareerSpeakApp(),
    ),
  );
}
