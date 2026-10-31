import '../../application/result/result.dart';
import '../../domain/assessment.dart';

final class AssessmentPayloadDecoder {
  const AssessmentPayloadDecoder();

  Result<PracticeTestRevision> decodePracticeTestRevision(Object? value) {
    try {
      final object = _object(value, r'$');
      _requireExactKeys(object, _practiceTestKeys, r'$');

      final refs = _objectList(object, 'questionRefs', r'$').indexed
          .map((entry) {
            final path =
                r'$.questionRefs['
                '${entry.$1}]';
            final ref = entry.$2;
            _requireExactKeys(ref, _testQuestionRefKeys, path);
            final questionPath = '$path.question';
            final question = _object(ref['question'], questionPath);
            _requireExactKeys(question, _questionRefKeys, questionPath);
            return PracticeTestQuestionRef(
              order: _integer(ref, 'order', path),
              question: QuestionRevisionId(
                questionCode: _string(question, 'questionCode', questionPath),
                revision: _integer(question, 'revision', questionPath),
                checksum: _string(question, 'checksum', questionPath),
              ),
              points: _integer(ref, 'points', path),
            );
          })
          .toList(growable: false);

      return Success<PracticeTestRevision>(
        PracticeTestRevision(
          practiceTestCode: _string(object, 'practiceTestCode', r'$'),
          revision: _integer(object, 'revision', r'$'),
          checksum: _string(object, 'checksum', r'$'),
          title: _string(object, 'title', r'$'),
          subtitle: _string(object, 'subtitle', r'$'),
          mode: _mode(_string(object, 'mode', r'$')),
          passingScoreBasisPoints: _integer(
            object,
            'passingScoreBasisPoints',
            r'$',
          ),
          questionRefs: refs,
        ),
      );
    } on _AssessmentPayloadViolation catch (error) {
      return FailureResult<PracticeTestRevision>(_failure(error));
    } on ArgumentError catch (error) {
      return FailureResult<PracticeTestRevision>(_argumentFailure(error));
    }
  }

  Result<AssessmentQuestionRevision> decodeQuestionRevision(Object? value) {
    try {
      final object = _object(value, r'$');
      _requireExactKeys(object, _questionKeys, r'$');
      final body = _object(object['body'], r'$.body');
      _requireExactKeys(body, _singleChoiceKeys, r'$.body');
      final kind = _string(body, 'kind', r'$.body');
      if (kind != 'singleChoice') {
        throw const _AssessmentPayloadViolation(
          r'$.body.kind',
          'contains an unsupported question kind',
        );
      }

      return Success<AssessmentQuestionRevision>(
        AssessmentQuestionRevision(
          id: QuestionRevisionId(
            questionCode: _string(object, 'questionCode', r'$'),
            revision: _integer(object, 'revision', r'$'),
            checksum: _string(object, 'checksum', r'$'),
          ),
          body: SingleChoiceQuestionBody(
            prompt: _string(body, 'prompt', r'$.body'),
            options: _nonBlankStringList(body, 'options', r'$.body'),
            correctOptionIndex: _integer(body, 'correctOptionIndex', r'$.body'),
            skillCode: _string(body, 'skillCode', r'$.body'),
            explanation: _string(body, 'explanation', r'$.body'),
          ),
        ),
      );
    } on _AssessmentPayloadViolation catch (error) {
      return FailureResult<AssessmentQuestionRevision>(_failure(error));
    } on ArgumentError catch (error) {
      return FailureResult<AssessmentQuestionRevision>(_argumentFailure(error));
    }
  }

  AssessmentMode _mode(String value) => switch (value) {
    'learn' => AssessmentMode.learn,
    'exam' => AssessmentMode.exam,
    'quick' => AssessmentMode.quick,
    _ => throw const _AssessmentPayloadViolation(
      r'$.mode',
      'contains an unsupported assessment mode',
    ),
  };

  Map<String, Object?> _object(Object? value, String path) {
    if (value is! Map) {
      throw _AssessmentPayloadViolation(path, 'must be a JSON object');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw _AssessmentPayloadViolation(path, 'contains a non-string key');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  List<Map<String, Object?>> _objectList(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final value = object[key];
    if (value is! List) {
      throw _AssessmentPayloadViolation('$path.$key', 'must be a JSON array');
    }
    return value.indexed
        .map((entry) => _object(entry.$2, '$path.$key[${entry.$1}]'))
        .toList(growable: false);
  }

  List<String> _nonBlankStringList(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final value = object[key];
    if (value is! List) {
      throw _AssessmentPayloadViolation('$path.$key', 'must be a JSON array');
    }
    return value.indexed
        .map((entry) {
          final item = entry.$2;
          if (item is! String || item.trim().isEmpty) {
            throw _AssessmentPayloadViolation(
              '$path.$key[${entry.$1}]',
              'must be a non-blank string',
            );
          }
          return item;
        })
        .toList(growable: false);
  }

  String _string(Map<String, Object?> object, String key, String path) {
    final value = object[key];
    if (value is! String || value.trim().isEmpty) {
      throw _AssessmentPayloadViolation(
        '$path.$key',
        'must be a non-blank string',
      );
    }
    return value;
  }

  int _integer(Map<String, Object?> object, String key, String path) {
    final value = object[key];
    if (value is! int) {
      throw _AssessmentPayloadViolation('$path.$key', 'must be an integer');
    }
    return value;
  }

  void _requireExactKeys(
    Map<String, Object?> object,
    Set<String> expected,
    String path,
  ) {
    final actual = object.keys.toSet();
    if (actual.length != expected.length || !actual.containsAll(expected)) {
      final unknown = actual.difference(expected).toList()..sort();
      final missing = expected.difference(actual).toList()..sort();
      throw _AssessmentPayloadViolation(
        path,
        'must contain exactly the frozen fields; '
        'unknown=$unknown missing=$missing',
      );
    }
  }
}

ApplicationFailure _failure(_AssessmentPayloadViolation error) {
  return ApplicationFailure(
    code: 'ASSESSMENT_PAYLOAD_INVALID',
    message: 'The server returned an invalid assessment payload.',
    details: <String, Object?>{'field': error.path, 'reason': error.reason},
  );
}

ApplicationFailure _argumentFailure(ArgumentError error) {
  return ApplicationFailure(
    code: 'ASSESSMENT_PAYLOAD_INVALID',
    message: 'The server returned an invalid assessment payload.',
    details: <String, Object?>{
      if (error.name != null) 'field': error.name,
      if (error.message != null) 'reason': error.message.toString(),
    },
  );
}

final class _AssessmentPayloadViolation implements Exception {
  const _AssessmentPayloadViolation(this.path, this.reason);

  final String path;
  final String reason;
}

const _practiceTestKeys = <String>{
  'practiceTestCode',
  'revision',
  'checksum',
  'title',
  'subtitle',
  'mode',
  'passingScoreBasisPoints',
  'questionRefs',
};
const _testQuestionRefKeys = <String>{'order', 'question', 'points'};
const _questionRefKeys = <String>{'questionCode', 'revision', 'checksum'};
const _questionKeys = <String>{'questionCode', 'revision', 'checksum', 'body'};
const _singleChoiceKeys = <String>{
  'kind',
  'prompt',
  'options',
  'correctOptionIndex',
  'skillCode',
  'explanation',
};
