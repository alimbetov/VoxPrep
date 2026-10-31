import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import 'typed_content_body.dart';

const unspecifiedTaxonomyCode = 'UNSPECIFIED';

final class ContentPayloadRef {
  factory ContentPayloadRef({
    required ContentIdentity identity,
    required int revision,
    required String checksum,
  }) {
    if (revision <= 0) {
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
    return ContentPayloadRef._(
      identity: identity,
      revision: revision,
      checksum: normalizedChecksum,
    );
  }

  const ContentPayloadRef._({
    required this.identity,
    required this.revision,
    required this.checksum,
  });

  final ContentIdentity identity;
  final int revision;
  final String checksum;
}

final class ContentPayload {
  factory ContentPayload({
    required ContentPayloadRef ref,
    required String title,
    required String subtitle,
    required String description,
    String categoryCode = unspecifiedTaxonomyCode,
    required String category,
    String levelCode = unspecifiedTaxonomyCode,
    required String level,
    required int minutes,
    required bool hasAudio,
    List<String> skillCodes = const <String>[],
    TypedContentBody? body,
  }) {
    if (minutes <= 0) {
      throw ArgumentError.value(minutes, 'minutes', 'must be positive');
    }
    if (body != null && body.contentType != ref.identity.type) {
      throw ArgumentError.value(
        body.contentType.name,
        'body',
        'must match the content identity type ${ref.identity.type.name}',
      );
    }
    return ContentPayload._(
      ref: ref,
      title: _requireNonBlank(title, 'title'),
      subtitle: _requireNonBlank(subtitle, 'subtitle'),
      description: _requireNonBlank(description, 'description'),
      categoryCode: _requireStableCode(categoryCode, 'categoryCode'),
      category: _requireNonBlank(category, 'category'),
      levelCode: _requireStableCode(levelCode, 'levelCode'),
      level: _requireNonBlank(level, 'level'),
      minutes: minutes,
      hasAudio: hasAudio,
      skillCodes: _requireUniqueStableCodes(skillCodes, 'skillCodes'),
      body: body,
    );
  }

  factory ContentPayload.typed({
    required ContentPayloadRef ref,
    required String title,
    required String subtitle,
    required String description,
    required String categoryCode,
    required String category,
    required String levelCode,
    required String level,
    required int minutes,
    required bool hasAudio,
    required List<String> skillCodes,
    required TypedContentBody body,
  }) {
    return ContentPayload(
      ref: ref,
      title: title,
      subtitle: subtitle,
      description: description,
      categoryCode: categoryCode,
      category: category,
      levelCode: levelCode,
      level: level,
      minutes: minutes,
      hasAudio: hasAudio,
      skillCodes: skillCodes,
      body: body,
    );
  }

  const ContentPayload._({
    required this.ref,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.categoryCode,
    required this.category,
    required this.levelCode,
    required this.level,
    required this.minutes,
    required this.hasAudio,
    required this.skillCodes,
    required this.body,
  });

  final ContentPayloadRef ref;
  final String title;
  final String subtitle;
  final String description;
  final String categoryCode;
  final String category;
  final String levelCode;
  final String level;
  final int minutes;
  final bool hasAudio;
  final List<String> skillCodes;
  final TypedContentBody? body;

  bool get isTyped => body != null;

  ContentItem toContentItem() {
    return ContentItem(
      code: ref.identity.code,
      type: ref.identity.type,
      title: title,
      subtitle: subtitle,
      description: description,
      category: category,
      level: level,
      minutes: minutes,
      revision: ref.revision,
      hasAudio: hasAudio,
    );
  }
}

String _requireNonBlank(String value, String fieldName) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be blank');
  }
  return normalized;
}

String _requireStableCode(String value, String fieldName) {
  final normalized = value.trim();
  if (!_stableCodePattern.hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      fieldName,
      'must be an uppercase stable business code',
    );
  }
  return normalized;
}

List<String> _requireUniqueStableCodes(List<String> values, String fieldName) {
  final normalized = <String>[];
  final seen = <String>{};
  for (var index = 0; index < values.length; index++) {
    final code = _requireStableCode(values[index], '$fieldName[$index]');
    if (!seen.add(code)) {
      throw ArgumentError.value(code, fieldName, 'must not contain duplicates');
    }
    normalized.add(code);
  }
  return List<String>.unmodifiable(normalized);
}

final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
final _stableCodePattern = RegExp(r'^[A-Z0-9][A-Z0-9._-]*$');
