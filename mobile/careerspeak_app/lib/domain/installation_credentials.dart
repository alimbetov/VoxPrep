final class InstallationId {
  InstallationId(String value) : value = _requireNonBlank(value, 'installationId');

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is InstallationId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class InstallationCredentials {
  InstallationCredentials({
    required this.installationId,
    required String installationToken,
  }) : installationToken =
            _requireNonBlank(installationToken, 'installationToken');

  final InstallationId installationId;
  final String installationToken;

  @override
  String toString() =>
      'InstallationCredentials(installationId: $installationId, installationToken: <redacted>)';
}

String _requireNonBlank(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be blank');
  }
  return value;
}
