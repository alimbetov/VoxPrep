final class InstallationId {
  factory InstallationId(String value) {
    return InstallationId._(_requireNonBlank(value, 'installationId'));
  }

  const InstallationId._(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is InstallationId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class InstallationToken {
  factory InstallationToken(String value) {
    return InstallationToken._(_requireNonBlank(value, 'installationToken'));
  }

  const InstallationToken._(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationToken && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '<redacted>';
}

final class InstallationCredentials {
  const InstallationCredentials({
    required this.installationId,
    required this.installationToken,
  });

  final InstallationId installationId;
  final InstallationToken installationToken;

  @override
  String toString() {
    return 'InstallationCredentials('
        'installationId: $installationId, '
        'installationToken: <redacted>)';
  }
}

String _requireNonBlank(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be blank');
  }
  return value;
}
