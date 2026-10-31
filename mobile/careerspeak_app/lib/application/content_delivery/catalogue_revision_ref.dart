enum CatalogueKind {
  learningGoals('learning-goals'),
  learningTracks('learning-tracks'),
  learningCollections('learning-collections'),
  categories('categories'),
  levels('levels'),
  skills('skills'),
  supportedLocales('supported-locales'),
  ttsVoices('tts-voices');

  const CatalogueKind(this.wireName);

  final String wireName;

  static CatalogueKind? fromWireName(String value) {
    for (final kind in values) {
      if (kind.wireName == value) return kind;
    }
    return null;
  }
}

final class CatalogueRevisionRef {
  factory CatalogueRevisionRef({
    required CatalogueKind kind,
    required int revision,
    required String checksum,
  }) {
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'must be positive');
    }
    final normalizedChecksum = checksum.trim().toLowerCase();
    if (!_sha256Pattern.hasMatch(normalizedChecksum)) {
      throw ArgumentError.value(
        checksum,
        'checksum',
        'must be a SHA-256 hex digest',
      );
    }
    return CatalogueRevisionRef._(
      kind: kind,
      revision: revision,
      checksum: normalizedChecksum,
    );
  }

  const CatalogueRevisionRef._({
    required this.kind,
    required this.revision,
    required this.checksum,
  });

  final CatalogueKind kind;
  final int revision;
  final String checksum;

  String get identityKey => kind.wireName;
}

final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
