import 'package:flutter_test/flutter_test.dart';
import 'package:careerspeak_app/application/content_delivery/external_learning_video.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';

void main() {
  const videoId = 'AbCdEfGh123';
  final identity = ContentIdentity(
    code: 'PHRASE_ONE',
    type: ContentType.phrase,
  );

  Map<String, Object?> projection() => <String, Object?>{
    'schemaVersion': 1,
    'contentType': 'phrase',
    'contentCode': 'PHRASE_ONE',
    'revision': 3,
    'contentVersion': 6,
    'rootSha256': 'a' * 64,
    'provider': 'YOUTUBE',
    'providerVideoId': videoId,
    'title': 'Lesson: professional English',
    'url': 'https://www.youtube.com/watch?v=AbCdEfGh123',
  };

  test('accepts validated immutable video reference and canonical URL', () {
    final video = ExternalLearningVideo.parse(
      projection(),
      identity: identity,
      revision: 3,
    );
    expect(video.uri.host, 'www.youtube.com');
    expect(video.uri.queryParameters['v'], videoId);
    expect(video.revision, 3);
  });

  test('never accepts another revision, content, provider or URL', () {
    final baseline = projection();
    for (final mutation in <Map<String, Object?>>[
      <String, Object?>{'revision': 4},
      <String, Object?>{'contentCode': 'ANOTHER'},
      <String, Object?>{'provider': 'ARBITRARY'},
      <String, Object?>{'url': 'https://evil.example/video'},
      <String, Object?>{'providerVideoId': '../escape'},
      <String, Object?>{'rootSha256': 'bad'},
      <String, Object?>{'extra': true},
      <String, Object?>{'schemaVersion': 99},
    ]) {
      expect(
        () => ExternalLearningVideo.parse(
          <String, Object?>{...baseline, ...mutation},
          identity: identity,
          revision: 3,
        ),
        throwsFormatException,
      );
    }
  }
}
