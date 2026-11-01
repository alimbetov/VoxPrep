import '../../domain/catalogue_source_mode.dart';
import '../result/result.dart';

abstract interface class CatalogueSourcePreferenceRepository {
  Future<Result<CatalogueSourceMode>> getMode();
  Future<Result<void>> setMode(CatalogueSourceMode mode);
}
