import '../content_delivery/catalogue_payload.dart';
import '../content_delivery/catalogue_revision_ref.dart';
import '../result/result.dart';

abstract interface class CatalogueSnapshotRepository {
  Future<Result<CataloguePayload?>> readCurrent(CatalogueKind kind);
}
