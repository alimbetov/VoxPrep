import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../application/ports/catalogue_source_preference_repository.dart';
import '../application/result/result.dart';
import '../data/local/secure_catalogue_source_preference_repository.dart';
import '../domain/catalogue_source_mode.dart';

final catalogueSourcePreferenceRepositoryProvider =
    Provider<CatalogueSourcePreferenceRepository>((ref) {
      return const SecureCatalogueSourcePreferenceRepository(
        FlutterSecureStorage(),
      );
    });

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

final catalogueSourceModeControllerProvider =
    Provider<CatalogueSourceModeController>((ref) {
      return CatalogueSourceModeController(
        repository: ref.watch(catalogueSourcePreferenceRepositoryProvider),
        applyRuntimeMode: ref.read(catalogueSourceModeProvider.notifier).setRuntimeMode,
      );
    });

final class CatalogueSourceModeController {
  const CatalogueSourceModeController({
    required CatalogueSourcePreferenceRepository repository,
    required void Function(CatalogueSourceMode mode) applyRuntimeMode,
  }) : _repository = repository,
       _applyRuntimeMode = applyRuntimeMode;

  final CatalogueSourcePreferenceRepository _repository;
  final void Function(CatalogueSourceMode mode) _applyRuntimeMode;

  Future<Result<void>> setMode(CatalogueSourceMode mode) async {
    final saved = await _repository.setMode(mode);
    if (saved is Success<void>) {
      _applyRuntimeMode(mode);
    }
    return saved;
  }
}
