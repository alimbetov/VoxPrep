import '../../domain/installation_credentials.dart';
import 'dto/installation_registration_dto.dart';

final class InstallationRegistrationMapper {
  const InstallationRegistrationMapper();

  InstallationRegistrationRequestDto request(InstallationId installationId) {
    return InstallationRegistrationRequestDto(
      installationId: installationId.value,
    );
  }

  InstallationToken response(InstallationRegistrationResponseDto dto) {
    return InstallationToken(dto.installationToken);
  }
}
