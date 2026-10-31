import '../../application/content_delivery/content_manifest.dart';
import '../../application/content_delivery/localized_content_payload.dart';
import '../../application/ports/api_client.dart';
import '../../application/ports/localized_content_payload_gateway.dart';
import '../../application/result/result.dart';
import 'localized_content_payload_decoder.dart';

final class HttpLocalizedContentPayloadGateway
    implements LocalizedContentPayloadGateway {
  factory HttpLocalizedContentPayloadGateway({
    required ApiClient apiClient,
    LocalizedContentPayloadDecoder decoder =
        const LocalizedContentPayloadDecoder(),
  }) {
    return HttpLocalizedContentPayloadGateway._(apiClient, decoder);
  }

  const HttpLocalizedContentPayloadGateway._(this._apiClient, this._decoder);

  final ApiClient _apiClient;
  final LocalizedContentPayloadDecoder _decoder;

  @override
  Future<Result<LocalizedContentPayload>> fetch(LocalizedContentRef target) async {
    final identity = target.identity;
    final response = await _apiClient.send(
      ApiRequest(
        method: ApiMethod.get,
        path:
            '/api/v1/content/${Uri.encodeComponent(identity.type.name)}/${Uri.encodeComponent(identity.code)}/revisions/${target.contentRevision}/localizations/${Uri.encodeComponent(target.locale)}/revisions/${target.localizationRevision}',
      ),
    );

    if (response case FailureResult<ApiResponse>(:final failure)) {
      return FailureResult<LocalizedContentPayload>(failure);
    }

    final apiResponse = (response as Success<ApiResponse>).value;
    if (apiResponse.statusCode != 200) {
      return FailureResult<LocalizedContentPayload>(
        ApplicationFailure(
          code: 'LOCALIZED_CONTENT_PAYLOAD_RESPONSE_INVALID',
          message:
              'The localized content payload endpoint returned an invalid status.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{'statusCode': apiResponse.statusCode},
        ),
      );
    }

    final decoded = _decoder.decode(apiResponse.jsonBody);
    if (decoded case FailureResult<LocalizedContentPayload>(:final failure)) {
      return FailureResult<LocalizedContentPayload>(failure);
    }

    final payload = (decoded as Success<LocalizedContentPayload>).value;
    final actual = payload.ref;
    if (actual.identity != target.identity ||
        actual.contentRevision != target.contentRevision ||
        actual.locale != target.locale ||
        actual.localizationRevision != target.localizationRevision ||
        actual.checksum != target.checksum) {
      return FailureResult<LocalizedContentPayload>(
        ApplicationFailure(
          code: 'LOCALIZED_CONTENT_PAYLOAD_MISMATCH',
          message:
              'The localized content payload does not match the requested revision.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{
            'expectedCode': target.identity.code,
            'expectedType': target.identity.type.name,
            'expectedContentRevision': target.contentRevision,
            'expectedLocale': target.locale,
            'expectedLocalizationRevision': target.localizationRevision,
            'actualCode': actual.identity.code,
            'actualType': actual.identity.type.name,
            'actualContentRevision': actual.contentRevision,
            'actualLocale': actual.locale,
            'actualLocalizationRevision': actual.localizationRevision,
          },
        ),
      );
    }

    return Success<LocalizedContentPayload>(payload);
  }
}
