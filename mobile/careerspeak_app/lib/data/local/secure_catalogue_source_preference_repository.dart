import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../application/ports/catalogue_source_preference_repository.dart';
import '../../application/result/result.dart';
import '../../domain/catalogue_source_mode.dart';

final class SecureCatalogueSourcePreferenceRepository
    implements CatalogueSourcePreferenceRepository {
  const SecureCatalogueSourcePreferenceRepository(this._storage);

  static const _key = 'catalogue_source_mode';

  final FlutterSecureStorage _storage;

  @override
  Future<Result<CatalogueSourceMode>> getMode() async {
    try {
      return Success(CatalogueSourceMode.fromCode(await _storage.read(key: _key)));
    } on Object catch (error) {
      return FailureResult(
        ApplicationFailure(
          code: 'CATALOGUE_SOURCE_PREFERENCE_READ_FAILED',
          message: 'Catalogue source preference could not be read.',
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }

  @override
  Future<Result<void>> setMode(CatalogueSourceMode mode) async {
    try {
      await _storage.write(key: _key, value: mode.code);
      return const Success(null);
    } on Object catch (error) {
      return FailureResult(
        ApplicationFailure(
          code: 'CATALOGUE_SOURCE_PREFERENCE_WRITE_FAILED',
          message: 'Catalogue source preference could not be saved.',
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }
}
