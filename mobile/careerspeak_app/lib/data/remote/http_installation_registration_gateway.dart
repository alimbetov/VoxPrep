import '../../application/ports/api_client.dart';
import '../../application/ports/installation_registration_gateway.dart';
import '../../application/result/result.dart';
import '../../domain/installation_credentials.dart';
import 'installation_registration_decoder.dart';
import 'installation_registration_mapper.dart';

final class HttpInstallationRegistrationGateway
    implements InstallationRegistrationGateway {
  const HttpInstallationRegistrationGateway({
    required ApiClient apiClient,
    InstallationRegistrationDecoder decoder =
        const InstallationRegistrationDecoder(),
    InstallationRegistrationMapper mapper =
        const InstallationRegistrationMapper(),
  }) : _apiClient = apiClient,
       _decoder = decoder,
       _mapper = mapper;

  final ApiClient _apiClient;
  final InstallationRegistrationDecoder _decoder;
  final InstallationRegistrationMapper _mapper;

  @override
  Future<Result<InstallationToken>> register(
    InstallationId installationId,
  ) async {
    final requestDto = _mapper.request(installationId);
    final responseResult = await _apiClient.send(
      ApiRequest(
        method: ApiMethod.post,
        path: '/api/v1/installations',
        jsonBody: requestDto.toJson(),
        authentication: ApiAuthentication.none,
      ),
    );

    if (responseResult is FailureResult<ApiResponse>) {
      return FailureResult<InstallationToken>(responseResult.failure);
    }

    final response = (responseResult as Success<ApiResponse>).value;
    if (response.statusCode != 200) {
      return FailureResult<InstallationToken>(
        ApplicationFailure(
          code: 'INSTALLATION_REGISTRATION_STATUS_INVALID',
          message: 'Installation registration returned an unexpected status.',
          traceId: response.traceId,
          details: <String, Object?>{'statusCode': response.statusCode},
        ),
      );
    }

    return _decoder.decode(response.jsonBody);
  }
}
