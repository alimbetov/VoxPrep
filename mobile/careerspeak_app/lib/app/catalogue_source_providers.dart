import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/catalogue_source_mode.dart';

/// Runtime source selector for tests and local development only.
///
/// Production composition does not expose UI or persisted switching and
/// therefore remains [CatalogueSourceMode.production] by default.
class CatalogueSourceModeNotifier extends Notifier<CatalogueSourceMode> {
  CatalogueSourceModeNotifier([
    this.initialMode = CatalogueSourceMode.production,
  ]);

  final CatalogueSourceMode initialMode;

  @override
  CatalogueSourceMode build() => initialMode;

  void setRuntimeMode(CatalogueSourceMode mode) {
    state = mode;
  }
}

final catalogueSourceModeProvider =
    NotifierProvider<CatalogueSourceModeNotifier, CatalogueSourceMode>(
      CatalogueSourceModeNotifier.new,
    );
