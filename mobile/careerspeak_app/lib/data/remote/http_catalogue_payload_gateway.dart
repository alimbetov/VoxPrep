import '../../application/content_delivery/catalogue_payload.dart';
import '../../application/content_delivery/catalogue_revision_ref.dart';
import '../../application/ports/api_client.dart';
import '../../application/ports/catalogue_payload_gateway.dart';
import '../../application/result/result.dart';

final class HttpCataloguePayloadGateway implements CataloguePayloadGateway {
  const HttpCataloguePayloadGateway({required this._apiClient});

  final ApiClient _apiClient;

  @override
  Future<Result<CataloguePayload>> fetch(CatalogueRevisionRef target) async {
    final response = await _apiClient.send(
      ApiRequest(
        method: ApiMethod.get,
        path:
            '/api/v1/catalogues/${Uri.encodeComponent(target.kind.wireName)}/revisions/${target.revision}',
      ),
    );
    if (response case FailureResult<ApiResponse>(:final failure)) {
      return FailureResult<CataloguePayload>(failure);
    }

    final apiResponse = (response as Success<ApiResponse>).value;
    if (apiResponse.statusCode != 200) {
      return FailureResult<CataloguePayload>(
        ApplicationFailure(
          code: 'CATALOGUE_RESPONSE_INVALID',
          message: 'The exact catalogue endpoint returned an invalid status.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{'statusCode': apiResponse.statusCode},
        ),
      );
    }

    final body = apiResponse.jsonBody;
    if (body is! Map<String, dynamic>) {
      return const FailureResult<CataloguePayload>(
        ApplicationFailure(
          code: 'CATALOGUE_PAYLOAD_INVALID',
          message: 'Catalogue payload must be a JSON object.',
        ),
      );
    }
    const allowed = <String>{'kind', 'revision', 'checksum', 'items'};
    if (body.keys.any((key) => !allowed.contains(key))) {
      return const FailureResult<CataloguePayload>(
        ApplicationFailure(
          code: 'CATALOGUE_NON_PUBLICATION_FIELD',
          message: 'Catalogue payload contains a non-publication field.',
        ),
      );
    }

    final kind = body['kind'];
    final revision = body['revision'];
    final checksum = body['checksum'];
    final items = body['items'];
    if (kind != target.kind.wireName ||
        revision != target.revision ||
        checksum != target.checksum ||
        items is! List<dynamic>) {
      return FailureResult<CataloguePayload>(
        ApplicationFailure(
          code: 'CATALOGUE_REVISION_MISMATCH',
          message:
              'The catalogue payload does not match the exact publication target.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{
            'expectedKind': target.kind.wireName,
            'expectedRevision': target.revision,
          },
        ),
      );
    }
    if (items.any((item) => item is! Map<String, dynamic>)) {
      return const FailureResult<CataloguePayload>(
        ApplicationFailure(
          code: 'CATALOGUE_PAYLOAD_INVALID',
          message: 'Catalogue items must be JSON objects.',
        ),
      );
    }

    return Success<CataloguePayload>(
      CataloguePayload(
        ref: target,
        items: items.cast<Object>(),
        wireJson: Map<String, Object?>.from(body),
      ),
    );
  }
}
