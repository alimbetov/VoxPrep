import '../domain/content_identity.dart';
import '../domain/content_item.dart';

String contentDetailLocation(ContentIdentity identity) {
  return '/content/${_typeCode(identity.type)}/${Uri.encodeComponent(identity.code)}';
}

ContentIdentity? contentIdentityFromRoute({
  required String? typeCode,
  required String? code,
}) {
  if (typeCode == null || code == null || code.trim().isEmpty) {
    return null;
  }

  final type = switch (typeCode) {
    'vocabulary' => ContentType.vocabulary,
    'interview' => ContentType.interview,
    'topic' => ContentType.topic,
    'shadowing' => ContentType.shadowing,
    'phrase' => ContentType.phrase,
    _ => null,
  };

  if (type == null) return null;
  return ContentIdentity(code: code, type: type);
}

String _typeCode(ContentType type) => switch (type) {
  ContentType.vocabulary => 'vocabulary',
  ContentType.interview => 'interview',
  ContentType.topic => 'topic',
  ContentType.shadowing => 'shadowing',
  ContentType.phrase => 'phrase',
};
