import 'package:careerspeak_app/application/content_delivery/localized_content_payload.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/localized_content_payload_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('LocalizedContentPayloadDecoder', () {
    test('decodes exact immutable localization identity and support copy', () {
      const decoder = LocalizedContentPayloadDecoder();

      final result = decoder.decode(<String, Object?>{
        'contentCode': 'JAVA_Q_001',
        'contentType': 'interview',
        'contentRevision': 3,
        'locale': 'ru',
        'localizationRevision': 2,
        'checksum': _hash,
        'title': 'Внедрение зависимостей',
        'subtitle': 'Java Backend',
        'description': 'Объясните constructor injection.',
        'translation': null,
        'hint': 'Сравните constructor и field injection.',
        'explanation': null,
      });

      expect(result, isA<Success<LocalizedContentPayload>>());
      final payload = (result as Success<LocalizedContentPayload>).value;
      expect(payload.ref.identity.code, 'JAVA_Q_001');
      expect(payload.ref.identity.type.name, 'interview');
      expect(payload.ref.contentRevision, 3);
      expect(payload.ref.locale, 'ru');
      expect(payload.ref.localizationRevision, 2);
      expect(payload.ref.checksum, _hash);
      expect(payload.title, 'Внедрение зависимостей');
      expect(payload.hint, 'Сравните constructor и field injection.');
    });

    test('rejects invalid locale', () {
      const decoder = LocalizedContentPayloadDecoder();

      final result = decoder.decode(<String, Object?>{
        'contentCode': 'JAVA_Q_001',
        'contentType': 'interview',
        'contentRevision': 3,
        'locale': 'ru_KZ',
        'localizationRevision': 2,
        'checksum': _hash,
        'title': 'Внедрение зависимостей',
      });

      expect(result, isA<FailureResult<LocalizedContentPayload>>());
      final failure =
          (result as FailureResult<LocalizedContentPayload>).failure;
      expect(failure.code, 'LOCALIZED_CONTENT_PAYLOAD_INVALID');
      expect(failure.details['field'], r'$.locale');
    });

    test('rejects localization with no localized copy', () {
      const decoder = LocalizedContentPayloadDecoder();

      final result = decoder.decode(<String, Object?>{
        'contentCode': 'JAVA_Q_001',
        'contentType': 'interview',
        'contentRevision': 3,
        'locale': 'ru',
        'localizationRevision': 2,
        'checksum': _hash,
      });

      expect(result, isA<FailureResult<LocalizedContentPayload>>());
      expect(
        (result as FailureResult<LocalizedContentPayload>).failure.code,
        'LOCALIZED_CONTENT_PAYLOAD_INVALID',
      );
    });
  });
}
