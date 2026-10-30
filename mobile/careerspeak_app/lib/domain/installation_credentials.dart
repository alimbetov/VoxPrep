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

final class InstallationCredentials {
  factory InstallationCredentials({
    required InstallationId installationId,
    required String installationToken,
  }) {
    return InstallationCredentials._(
      installationId: installationId,
      installationToken: _requireNonBlank(
        installationToken,
        'installationToken',
      ),
    );
  }

  const InstallationCredentials._({
    required this.installationId,
    required this.installationToken,
  });

  final InstallationId installationId;
  final String installationToken;

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
