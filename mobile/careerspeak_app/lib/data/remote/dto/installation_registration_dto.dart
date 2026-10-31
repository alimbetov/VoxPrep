final class InstallationRegistrationRequestDto {
  const InstallationRegistrationRequestDto({required this.installationId});

  final String installationId;

  Map<String, Object?> toJson() => <String, Object?>{
    'installationId': installationId,
  };
}

final class InstallationRegistrationResponseDto {
  const InstallationRegistrationResponseDto({required this.installationToken});

  final String installationToken;
}
