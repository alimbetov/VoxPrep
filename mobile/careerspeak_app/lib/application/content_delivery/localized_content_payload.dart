import 'content_manifest.dart';

/// Exact immutable localized learner projection for one canonical revision.
///
/// Canonical English content and shared media are intentionally not duplicated
/// here. Every non-null text field is locale-owned support copy.
final class LocalizedContentPayload {
  factory LocalizedContentPayload({
    required LocalizedContentRef ref,
    String? title,
    String? subtitle,
    String? description,
    String? translation,
    String? hint,
    String? explanation,
  }) {
    final normalizedTitle = _optionalText(title, 'title');
    final normalizedSubtitle = _optionalText(subtitle, 'subtitle');
    final normalizedDescription = _optionalText(description, 'description');
    final normalizedTranslation = _optionalText(translation, 'translation');
    final normalizedHint = _optionalText(hint, 'hint');
    final normalizedExplanation = _optionalText(explanation, 'explanation');

    if (<String?>[
      normalizedTitle,
      normalizedSubtitle,
      normalizedDescription,
      normalizedTranslation,
      normalizedHint,
      normalizedExplanation,
    ].every((value) => value == null)) {
      throw ArgumentError(
        'localized payload must contain at least one localized text field',
      );
    }

    return LocalizedContentPayload._(
      ref: ref,
      title: normalizedTitle,
      subtitle: normalizedSubtitle,
      description: normalizedDescription,
      translation: normalizedTranslation,
      hint: normalizedHint,
      explanation: normalizedExplanation,
    );
  }

  const LocalizedContentPayload._({
    required this.ref,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.translation,
    required this.hint,
    required this.explanation,
  });

  final LocalizedContentRef ref;
  final String? title;
  final String? subtitle;
  final String? description;
  final String? translation;
  final String? hint;
  final String? explanation;
}

String? _optionalText(String? value, String fieldName) {
  if (value == null) {
    return null;
  }
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must be null or non-blank');
  }
  return normalized;
}
