import '../../domain/installation_credentials.dart';
import '../result/result.dart';

abstract interface class InstallationRegistrationGateway {
  Future<Result<InstallationToken>> register(InstallationId installationId);
}
