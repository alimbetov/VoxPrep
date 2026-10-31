import '../../domain/content_item.dart';

final class ContentRevisionRef {
  factory ContentRevisionRef({
    required String contentCode,
    required ContentType contentType,
    required int revision,
    required String checksum,
  }) {
    if (revision <= 0) {
      throw ArgumentError.value(revision, 'revision', 'must be positive');
    }
    return ContentRevisionRef._(
      contentCode: _businessCode(contentCode, 'contentCode'),
      contentType: contentType,
      revision: revision,
      checksum: _checksum(checksum),
    );
  }

  const ContentRevisionRef._({
    required this.contentCode,
    required this.contentType,
    required this.revision,
    required this.checksum,
  });

  final String contentCode;
  final ContentType contentType;
  final int revision;
  final String checksum;

  String get identityKey => '$contentCode|${contentType.name}|$revision';
}

final class PracticeTestRevisionRef {
  factory PracticeTestRevisionRef({
    required String practiceTestCode,
    required int revision,
    required String checksum,
  }) {
    if (revision <= 0) {
      throw ArgumentError.value(revision, 'revision', 'must be positive');
    }
    return PracticeTestRevisionRef._(
      practiceTestCode: _businessCode(practiceTestCode, 'practiceTestCode'),
      revision: revision,
      checksum: _checksum(checksum),
    );
  }

  const PracticeTestRevisionRef._({
    required this.practiceTestCode,
    required this.revision,
    required this.checksum,
  });

  final String practiceTestCode;
  final int revision;
  final String checksum;

  String get identityKey => '$practiceTestCode|$revision';
}

enum LearningCollectionMemberType {
  content('CONTENT'),
  practiceTest('PRACTICE_TEST');

  const LearningCollectionMemberType(this.wireName);

  final String wireName;

  static LearningCollectionMemberType fromWireName(String value) {
    for (final type in values) {
      if (type.wireName == value) return type;
    }
    throw FormatException('Unsupported collection member type: $value');
  }
}

final class LearningCollectionMember {
  factory LearningCollectionMember.content({
    required int position,
    required ContentRevisionRef content,
  }) {
    return LearningCollectionMember._(
      position: _position(position),
      type: LearningCollectionMemberType.content,
      contentRef: content,
      practiceTestRef: null,
    );
  }

  factory LearningCollectionMember.practiceTest({
    required int position,
    required PracticeTestRevisionRef practiceTest,
  }) {
    return LearningCollectionMember._(
      position: _position(position),
      type: LearningCollectionMemberType.practiceTest,
      contentRef: null,
      practiceTestRef: practiceTest,
    );
  }

  const LearningCollectionMember._({
    required this.position,
    required this.type,
    required this.contentRef,
    required this.practiceTestRef,
  });

  final int position;
  final LearningCollectionMemberType type;
  final ContentRevisionRef? contentRef;
  final PracticeTestRevisionRef? practiceTestRef;

  String get identityKey => switch (type) {
        LearningCollectionMemberType.content =>
          '${type.wireName}|${contentRef!.identityKey}',
        LearningCollectionMemberType.practiceTest =>
          '${type.wireName}|${practiceTestRef!.identityKey}',
      };
}

final class LearningGoalProjection {
  factory LearningGoalProjection({
    required String code,
    required String verticalCode,
    required String title,
    required String description,
    required int sortOrder,
    required bool active,
  }) {
    return LearningGoalProjection._(
      code: _stableCode(code, 'code'),
      verticalCode: _stableCode(verticalCode, 'verticalCode'),
      title: _nonBlank(title, 'title'),
      description: _nonBlank(description, 'description'),
      sortOrder: _sortOrder(sortOrder),
      active: active,
    );
  }

  const LearningGoalProjection._({
    required this.code,
    required this.verticalCode,
    required this.title,
    required this.description,
    required this.sortOrder,
    required this.active,
  });

  final String code;
  final String verticalCode;
  final String title;
  final String description;
  final int sortOrder;
  final bool active;
}

final class LearningTrackProjection {
  factory LearningTrackProjection({
    required String code,
    required String verticalCode,
    required String goalCode,
    required String title,
    required String description,
    required String levelCode,
    String? careerTrackCode,
    required int sortOrder,
    required bool active,
  }) {
    return LearningTrackProjection._(
      code: _stableCode(code, 'code'),
      verticalCode: _stableCode(verticalCode, 'verticalCode'),
      goalCode: _stableCode(goalCode, 'goalCode'),
      title: _nonBlank(title, 'title'),
      description: _nonBlank(description, 'description'),
      levelCode: _stableCode(levelCode, 'levelCode'),
      careerTrackCode: _optionalStableCode(careerTrackCode, 'careerTrackCode'),
      sortOrder: _sortOrder(sortOrder),
      active: active,
    );
  }

  const LearningTrackProjection._({
    required this.code,
    required this.verticalCode,
    required this.goalCode,
    required this.title,
    required this.description,
    required this.levelCode,
    required this.careerTrackCode,
    required this.sortOrder,
    required this.active,
  });

  final String code;
  final String verticalCode;
  final String goalCode;
  final String title;
  final String description;
  final String levelCode;
  final String? careerTrackCode;
  final int sortOrder;
  final bool active;
}

final class LearningCollectionProjection {
  factory LearningCollectionProjection({
    required String code,
    required String verticalCode,
    required String trackCode,
    required String title,
    required String description,
    required int sortOrder,
    required bool active,
    required List<LearningCollectionMember> members,
  }) {
    if (members.isEmpty) {
      throw ArgumentError('a learning collection must contain at least one member');
    }
    for (var index = 0; index < members.length; index++) {
      if (members[index].position != index) {
        throw ArgumentError.value(
          members[index].position,
          'members',
          'positions must be contiguous and start at zero',
        );
      }
    }
    _requireUnique(members.map((member) => member.identityKey), 'members');
    return LearningCollectionProjection._(
      code: _stableCode(code, 'code'),
      verticalCode: _stableCode(verticalCode, 'verticalCode'),
      trackCode: _stableCode(trackCode, 'trackCode'),
      title: _nonBlank(title, 'title'),
      description: _nonBlank(description, 'description'),
      sortOrder: _sortOrder(sortOrder),
      active: active,
      members: List<LearningCollectionMember>.unmodifiable(members),
    );
  }

  const LearningCollectionProjection._({
    required this.code,
    required this.verticalCode,
    required this.trackCode,
    required this.title,
    required this.description,
    required this.sortOrder,
    required this.active,
    required this.members,
  });

  final String code;
  final String verticalCode;
  final String trackCode;
  final String title;
  final String description;
  final int sortOrder;
  final bool active;
  final List<LearningCollectionMember> members;
}

final class TaxonomyProjection {
  factory TaxonomyProjection({
    required String code,
    required String label,
    required int sortOrder,
    required bool active,
  }) {
    return TaxonomyProjection._(
      code: _stableCode(code, 'code'),
      label: _nonBlank(label, 'label'),
      sortOrder: _sortOrder(sortOrder),
      active: active,
    );
  }

  const TaxonomyProjection._({
    required this.code,
    required this.label,
    required this.sortOrder,
    required this.active,
  });

  final String code;
  final String label;
  final int sortOrder;
  final bool active;
}

final class SupportedLocaleProjection {
  factory SupportedLocaleProjection({
    required String code,
    required String label,
    required int sortOrder,
    required bool active,
  }) {
    final normalizedCode = code.trim();
    if (!_localePattern.hasMatch(normalizedCode)) {
      throw ArgumentError.value(code, 'code', 'must be a BCP-47 locale code');
    }
    return SupportedLocaleProjection._(
      code: normalizedCode,
      label: _nonBlank(label, 'label'),
      sortOrder: _sortOrder(sortOrder),
      active: active,
    );
  }

  const SupportedLocaleProjection._({
    required this.code,
    required this.label,
    required this.sortOrder,
    required this.active,
  });

  final String code;
  final String label;
  final int sortOrder;
  final bool active;
}

final class TtsVoiceProjection {
  factory TtsVoiceProjection({
    required String code,
    required String locale,
    required String accentCode,
    required String label,
    required int sortOrder,
    required bool active,
  }) {
    final normalizedLocale = locale.trim();
    if (!_localePattern.hasMatch(normalizedLocale)) {
      throw ArgumentError.value(
        locale,
        'locale',
        'must be a BCP-47 locale code',
      );
    }
    return TtsVoiceProjection._(
      code: _stableCode(code, 'code'),
      locale: normalizedLocale,
      accentCode: _stableCode(accentCode, 'accentCode'),
      label: _nonBlank(label, 'label'),
      sortOrder: _sortOrder(sortOrder),
      active: active,
    );
  }

  const TtsVoiceProjection._({
    required this.code,
    required this.locale,
    required this.accentCode,
    required this.label,
    required this.sortOrder,
    required this.active,
  });

  final String code;
  final String locale;
  final String accentCode;
  final String label;
  final int sortOrder;
  final bool active;
}

String _nonBlank(String value, String fieldName) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be blank');
  }
  return normalized;
}

String _businessCode(String value, String fieldName) {
  final normalized = value.trim();
  if (!_businessCodePattern.hasMatch(normalized)) {
    throw ArgumentError.value(value, fieldName, 'must be a business code');
  }
  return normalized;
}

String _stableCode(String value, String fieldName) {
  final normalized = value.trim();
  if (!_stableCodePattern.hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      fieldName,
      'must be an uppercase stable code',
    );
  }
  return normalized;
}

String? _optionalStableCode(String? value, String fieldName) {
  if (value == null) return null;
  return _stableCode(value, fieldName);
}

int _sortOrder(int value) {
  if (value < 0) {
    throw ArgumentError.value(value, 'sortOrder', 'must be non-negative');
  }
  return value;
}

int _position(int value) {
  if (value < 0) {
    throw ArgumentError.value(value, 'position', 'must be non-negative');
  }
  return value;
}

String _checksum(String value) {
  final normalized = value.trim().toLowerCase();
  if (!_sha256Pattern.hasMatch(normalized)) {
    throw ArgumentError.value(value, 'checksum', 'must be a SHA-256 digest');
  }
  return normalized;
}

void _requireUnique(Iterable<String> keys, String fieldName) {
  final seen = <String>{};
  for (final key in keys) {
    if (!seen.add(key)) {
      throw ArgumentError.value(key, fieldName, 'contains a duplicate exact ref');
    }
  }
}

final _businessCodePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');
final _stableCodePattern = RegExp(r'^[A-Z0-9][A-Z0-9._-]*$');
final _localePattern = RegExp(r'^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$');
final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
