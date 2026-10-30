import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';

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
    required String category,
    required String level,
    required int minutes,
    required bool hasAudio,
  }) {
    if (minutes <= 0) {
      throw ArgumentError.value(minutes, 'minutes', 'must be positive');
    }
    return ContentPayload._(
      ref: ref,
      title: _requireNonBlank(title, 'title'),
      subtitle: _requireNonBlank(subtitle, 'subtitle'),
      description: _requireNonBlank(description, 'description'),
      category: _requireNonBlank(category, 'category'),
      level: _requireNonBlank(level, 'level'),
      minutes: minutes,
      hasAudio: hasAudio,
    );
  }

  const ContentPayload._({
    required this.ref,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.level,
    required this.minutes,
    required this.hasAudio,
  });

  final ContentPayloadRef ref;
  final String title;
  final String subtitle;
  final String description;
  final String category;
  final String level;
  final int minutes;
  final bool hasAudio;

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

final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
