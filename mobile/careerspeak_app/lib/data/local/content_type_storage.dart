import '../../domain/content_item.dart';

String contentTypeToStorage(ContentType type) => switch (type) {
  ContentType.vocabulary => 'VOCABULARY',
  ContentType.interview => 'INTERVIEW',
  ContentType.topic => 'TOPIC',
  ContentType.shadowing => 'SHADOWING',
  ContentType.phrase => 'PHRASE',
};

ContentType contentTypeFromStorage(String value) => switch (value) {
  'VOCABULARY' => ContentType.vocabulary,
  'INTERVIEW' => ContentType.interview,
  'TOPIC' => ContentType.topic,
  'SHADOWING' => ContentType.shadowing,
  'PHRASE' => ContentType.phrase,
  _ => throw FormatException('Unsupported content type: $value'),
};
