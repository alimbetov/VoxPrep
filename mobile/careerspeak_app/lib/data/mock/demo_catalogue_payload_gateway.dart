import '../../application/content_delivery/catalogue_payload.dart';
import '../../application/content_delivery/catalogue_revision_ref.dart';
import '../../application/ports/catalogue_payload_gateway.dart';
import '../../application/result/result.dart';

final class DemoCataloguePayloadGateway implements CataloguePayloadGateway {
  DemoCataloguePayloadGateway({
    required Map<String, CataloguePayload> payloads,
    this.latency = const Duration(milliseconds: 350),
  }) : _payloads = Map<String, CataloguePayload>.unmodifiable(payloads);

  final Map<String, CataloguePayload> _payloads;
  final Duration latency;

  @override
  Future<Result<CataloguePayload>> fetch(CatalogueRevisionRef target) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }

    final payload = _payloads[_key(target)];
    if (payload == null) {
      return FailureResult<CataloguePayload>(
        ApplicationFailure(
          code: 'DEMO_CATALOGUE_NOT_FOUND',
          message: 'Demo backend has no exact catalogue revision.',
          details: <String, Object?>{
            'kind': target.kind.wireName,
            'revision': target.revision,
          },
        ),
      );
    }

    if (payload.ref.kind != target.kind ||
        payload.ref.revision != target.revision ||
        payload.ref.checksum != target.checksum) {
      return const FailureResult<CataloguePayload>(
        ApplicationFailure(
          code: 'DEMO_CATALOGUE_REVISION_MISMATCH',
          message: 'Demo payload does not match the requested exact revision.',
        ),
      );
    }

    return Success<CataloguePayload>(payload);
  }

  static String keyOf(CatalogueRevisionRef ref) => _key(ref);

  static String _key(CatalogueRevisionRef ref) =>
      '${ref.kind.wireName}|${ref.revision}|${ref.checksum}';
}
